import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickboom_app/core/models/permission_model.dart';
import 'package:quickboom_app/core/models/user_role.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/core/services/secure_storage_service.dart';
import 'package:quickboom_app/roles/employee/models/work_permission_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/work_permissions_viewmodel.dart';
import 'package:quickboom_app/shared/widgets/app_drawer.dart';
import 'package:quickboom_app/shared/widgets/permission_guarded_view.dart';
import 'package:quickboom_app/roles/employee/routes/employee_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PermissionManager.instance.clear();
  });

  tearDown(() {
    PermissionManager.instance.clear();
  });

  Widget createDrawerHarness({
    required List<UserPermission> permissions,
    required bool isCrmEligible,
    String role = 'Employee',
    EmployeeWorkPermissions? workPermissions,
  }) {
    PermissionManager.instance.setPermissions(
      permissions,
      role: role,
      isCrmEligible: isCrmEligible,
    );

    final effectiveWorkPerms =
        workPermissions ??
        EmployeeWorkPermissions(
          role: role,
          workPermissions: permissions
              .map((p) => p.module.toLowerCase())
              .toList(),
          isCrmEligible: isCrmEligible,
        );

    final permState = PermissionState(
      permissions: permissions,
      role: role,
      isCrmEligible: isCrmEligible,
      isInitialized: true,
      isLoading: false,
    );

    final authState = LoginState(
      isInitializing: false,
      isLoading: false,
      isLoggedIn: true,
      role: UserRole.employee,
      userRole: role,
      userName: 'Test $role',
      employeeId: '101',
    );

    return ProviderScope(
      overrides: [
        loginStateProvider.overrideWith(() => _MockLoginNotifier(authState)),
        permissionManagerProvider.overrideWith(
          () => _MockPermissionNotifier(permState),
        ),
        workPermissionsProvider.overrideWith(() {
          return _MockWorkPermissionsNotifier(
            WorkPermissionsState(
              permissions: effectiveWorkPerms,
              isLoading: false,
            ),
          );
        }),
      ],
      child: const MaterialApp(
        home: Scaffold(
          drawer: AppDrawer(),
          body: Center(child: Text('CRM Test Shell')),
        ),
      ),
    );
  }

  group('CRM Sidebar Navigation & RBAC Tests', () {
    testWidgets(
      'TEST 1 — TELESALES (CRM eligible: true, all CRM permissions allowed)',
      (tester) async {
        final perms = [
          const UserPermission(module: 'DASHBOARD', action: 'VIEW'),
          const UserPermission(module: 'DATA_CAPTURE', action: 'VIEW'),
          const UserPermission(module: 'LEADS', action: 'VIEW'),
          const UserPermission(module: 'CUSTOMERS', action: 'VIEW'),
          const UserPermission(module: 'ATTENDANCE', action: 'VIEW'),
        ];

        await tester.pumpWidget(
          createDrawerHarness(
            permissions: perms,
            isCrmEligible: true,
            role: 'Telesales Executive',
          ),
        );

        // Open drawer
        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Verify CRM section header exists
        expect(find.text('CRM'), findsOneWidget);

        // Verify Dashboard is above CRM section header
        final dashboardPos = tester.getTopLeft(find.text('Dashboard'));
        final crmPos = tester.getTopLeft(find.text('CRM'));
        expect(dashboardPos.dy, lessThan(crmPos.dy));

        // Verify all items are visible
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Data Capture'), findsOneWidget);
        expect(find.text('Leads'), findsOneWidget);
        expect(find.text('Customers'), findsOneWidget);

        // Verify other permitted modules are also present in the drawer
        await tester.scrollUntilVisible(find.text('Attendance'), 200);
        expect(find.text('Attendance'), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 2 — TELESALES LIMITED (CRM eligible: true, Customers denied)',
      (tester) async {
        final perms = [
          const UserPermission(module: 'DASHBOARD', action: 'VIEW'),
          const UserPermission(module: 'DATA_CAPTURE', action: 'VIEW'),
          const UserPermission(module: 'LEADS', action: 'VIEW'),
          // Customers is omitted / denied
        ];

        await tester.pumpWidget(
          createDrawerHarness(
            permissions: perms,
            isCrmEligible: true,
            role: 'Telesales Executive',
          ),
        );

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Verify CRM section header exists
        expect(find.text('CRM'), findsOneWidget);

        // Verify allowed CRM items are visible
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Data Capture'), findsOneWidget);
        expect(find.text('Leads'), findsOneWidget);

        // Verify Customers is HIDDEN
        expect(find.text('Customers'), findsNothing);
      },
    );

    testWidgets('TEST 3 — DESIGNER (CRM eligible: false, has other modules)', (
      tester,
    ) async {
      final perms = [
        const UserPermission(module: 'DASHBOARD', action: 'VIEW'),
        const UserPermission(module: 'MY_WORK', action: 'VIEW'),
        const UserPermission(module: 'CREATIVE_WORK', action: 'VIEW'),
        const UserPermission(module: 'CALENDAR', action: 'VIEW'),
        const UserPermission(module: 'TASKS', action: 'VIEW'),
        const UserPermission(module: 'ATTENDANCE', action: 'VIEW'),
        // Accidental LEADS:VIEW on non-CRM employee should NOT expose CRM section
        const UserPermission(module: 'LEADS', action: 'VIEW'),
      ];

      await tester.pumpWidget(
        createDrawerHarness(
          permissions: perms,
          isCrmEligible: false,
          role: 'Designer',
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // CRITICAL: CRM Section Header MUST NOT EXIST
      expect(find.text('CRM'), findsNothing);
      expect(find.text('CRM WORKFLOW'), findsNothing);

      // CRM-specific items Data Capture & Customers MUST NOT EXIST
      expect(find.text('Data Capture'), findsNothing);
      expect(find.text('Customers'), findsNothing);

      // Designer's permitted modules MUST exist
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('TEST 4 — PHOTOGRAPHER (CRM eligible: false)', (tester) async {
      final perms = [
        const UserPermission(module: 'DASHBOARD', action: 'VIEW'),
        const UserPermission(module: 'CALENDAR', action: 'VIEW'),
        const UserPermission(module: 'TASKS', action: 'VIEW'),
        const UserPermission(module: 'ATTENDANCE', action: 'VIEW'),
      ];

      await tester.pumpWidget(
        createDrawerHarness(
          permissions: perms,
          isCrmEligible: false,
          role: 'Photographer',
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // CRITICAL: NO CRM SECTION
      expect(find.text('CRM'), findsNothing);
      expect(find.text('CRM WORKFLOW'), findsNothing);
      expect(find.text('Data Capture'), findsNothing);
      expect(find.text('Leads'), findsNothing);
      expect(find.text('Customers'), findsNothing);

      // Permitted items are visible
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('TEST 5 — BPO EMPLOYEE (CRM eligible: true)', (tester) async {
      final perms = [
        const UserPermission(module: 'DASHBOARD', action: 'VIEW'),
        const UserPermission(module: 'DATA_CAPTURE', action: 'VIEW'),
        const UserPermission(module: 'LEADS', action: 'VIEW'),
        const UserPermission(module: 'CUSTOMERS', action: 'VIEW'),
        const UserPermission(module: 'ATTENDANCE', action: 'VIEW'),
      ];

      await tester.pumpWidget(
        createDrawerHarness(
          permissions: perms,
          isCrmEligible: true,
          role: 'BPO Telecaller',
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // CRM Section Header MUST EXIST
      expect(find.text('CRM'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Data Capture'), findsOneWidget);
      expect(find.text('Leads'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
    });

    testWidgets(
      'TEST 7 — DASHBOARD STANDALONE (CRM child modules = OFF, Dashboard = ON)',
      (tester) async {
        final perms = [
          const UserPermission(module: 'DASHBOARD', action: 'VIEW'),
          const UserPermission(module: 'ATTENDANCE', action: 'VIEW'),
        ];

        await tester.pumpWidget(
          createDrawerHarness(
            permissions: perms,
            isCrmEligible:
                true, // Even if CRM eligible, when all CRM children are OFF, CRM section is HIDDEN
            role: 'Telesales Executive',
          ),
        );

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Standalone Dashboard is visible
        expect(find.text('Dashboard'), findsOneWidget);

        // CRM section header MUST NOT appear
        expect(find.text('CRM'), findsNothing);
        expect(find.text('Data Capture'), findsNothing);
        expect(find.text('Leads'), findsNothing);
        expect(find.text('Customers'), findsNothing);

        // Other permitted modules are visible
        expect(find.text('Attendance'), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 6 — EMPLOYEE SWITCH & LOGOUT (Clear state ensures no CRM leak)',
      (tester) async {
        // 1. Telesales employee logs in
        PermissionManager.instance.setPermissions(
          const [
            UserPermission(module: 'LEADS', action: 'VIEW'),
            UserPermission(module: 'DATA_CAPTURE', action: 'VIEW'),
          ],
          role: 'Telesales Executive',
          isCrmEligible: true,
        );

        expect(PermissionManager.instance.isCrmEligible, isTrue);
        expect(PermissionManager.instance.hasCrmAccess, isTrue);

        // 2. Telesales logs out
        PermissionManager.instance.clear();

        expect(PermissionManager.instance.isCrmEligible, isFalse);
        expect(PermissionManager.instance.hasCrmAccess, isFalse);
        expect(PermissionManager.instance.currentState.permissions, isEmpty);

        // 3. Designer logs in
        PermissionManager.instance.setPermissions(
          const [
            UserPermission(module: 'MY_WORK', action: 'VIEW'),
            UserPermission(module: 'CALENDAR', action: 'VIEW'),
          ],
          role: 'Designer',
          isCrmEligible: false,
        );

        expect(PermissionManager.instance.isCrmEligible, isFalse);
        expect(PermissionManager.instance.hasCrmAccess, isFalse);
        expect(PermissionManager.instance.canViewMyWork, isTrue);
        expect(PermissionManager.instance.canViewCalendar, isTrue);
      },
    );

    testWidgets(
      'TEST 8 — BPO TEAM MEMBER FULL SIDEBAR SCREENSHOT VERIFICATION',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final perms = [
          const UserPermission(module: 'DASHBOARD', action: 'VIEW'),
          const UserPermission(module: 'DATA_CAPTURE', action: 'VIEW'),
          const UserPermission(module: 'LEADS', action: 'VIEW'),
          const UserPermission(module: 'CUSTOMERS', action: 'VIEW'),
          const UserPermission(module: 'ATTENDANCE', action: 'VIEW'),
          const UserPermission(module: 'LEAVE', action: 'VIEW'),
          const UserPermission(module: 'EXPENSES', action: 'VIEW'),
          const UserPermission(module: 'REMOTE_WORK', action: 'VIEW'),
          const UserPermission(module: 'TASKS', action: 'VIEW'),
          const UserPermission(module: 'LOAN', action: 'VIEW'),
          const UserPermission(module: 'SALARY', action: 'VIEW'),
          const UserPermission(module: 'VISITS', action: 'VIEW'),
          const UserPermission(module: 'COMMISSION', action: 'VIEW'),
          const UserPermission(module: 'PACKAGES', action: 'VIEW'),
          const UserPermission(module: 'SETTINGS', action: 'VIEW'),
        ];

        await tester.pumpWidget(
          createDrawerHarness(
            permissions: perms,
            isCrmEligible: true,
            role: 'BPO Team Member',
          ),
        );

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        for (final title in [
          'Dashboard',
          'Data Capture',
          'Leads',
          'Customers',
          'Packages',
          'Attendance',
          'Requests & Leaves',
          'Expenses & Claims',
          'Loan Requests',
          'Remote Work',
          'Assigned Tasks',
          'Salary Slips',
          'Field Visits',
          'My Commissions',
          'Settings',
        ]) {
          await tester.scrollUntilVisible(
            find.text(title),
            100,
            scrollable: find.descendant(
              of: find.byKey(const PageStorageKey('employee-sidebar-menu')),
              matching: find.byType(Scrollable),
            ),
          );
          expect(find.text(title), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        // Fixed header and Logout stay outside the scrolling menu.
        expect(find.text('QB Suite'), findsOneWidget);
        expect(tester.getTopLeft(find.text('QB Suite')).dy, lessThan(100));
        // 5. Logout
        expect(find.text('Logout'), findsOneWidget);
      },
    );

    testWidgets(
      'Leads and Customers named routes deny missing permissions before mounting screens',
      (tester) async {
        for (final route in [EmployeeRoutes.leads, EmployeeRoutes.customers]) {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                permissionManagerProvider.overrideWith(
                  () => _MockPermissionNotifier(
                    const PermissionState(
                      isInitialized: true,
                      isCrmEligible: true,
                    ),
                  ),
                ),
              ],
              child: MaterialApp(
                home: Builder(
                  builder: (context) =>
                      EmployeeRoutes.getRoutes()[route]!(context),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(PermissionGuardedView), findsOneWidget);
          expect(find.text('Access Restricted'), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
        }
      },
    );

    testWidgets(
      'SecureStorageService saves and clears CRM mobile access correctly',
      (tester) async {
        await SecureStorageService.saveCrmMobileAccess(
          true,
          tenantId: '10',
          employeeId: '20',
        );
        var access = await SecureStorageService.getCrmMobileAccess(
          tenantId: '10',
          employeeId: '20',
        );
        expect(access, isTrue);

        // Clear all
        await SecureStorageService.clearAll();
        access = await SecureStorageService.getCrmMobileAccess(
          tenantId: '10',
          employeeId: '20',
        );
        expect(access, isFalse);
      },
    );
  });
}

class _MockLoginNotifier extends LoginStateNotifier {
  final LoginState _state;
  _MockLoginNotifier(this._state);

  @override
  LoginState build() => _state;
}

class _MockPermissionNotifier extends PermissionNotifier {
  final PermissionState _initial;
  _MockPermissionNotifier(this._initial);

  @override
  PermissionState build() => _initial;
}

class _MockWorkPermissionsNotifier extends WorkPermissionsNotifier {
  final WorkPermissionsState _initial;
  _MockWorkPermissionsNotifier(this._initial);

  @override
  WorkPermissionsState build() => _initial;

  @override
  Future<void> loadPermissions() async {}
}
