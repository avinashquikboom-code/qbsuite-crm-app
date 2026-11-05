import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/models/permission_model.dart';
import 'package:quickboom_app/core/models/user_role.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/roles/employee/models/work_permission_model.dart';
import 'package:quickboom_app/roles/employee/routes/employee_routes.dart';
import 'package:quickboom_app/roles/employee/viewmodels/work_permissions_viewmodel.dart';
import 'package:quickboom_app/shared/widgets/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLoginNotifier extends LoginStateNotifier {
  final LoginState _state;
  _MockLoginNotifier(this._state);

  @override
  LoginState build() => _state;
}

class _MockPermissionNotifier extends PermissionNotifier {
  final PermissionState _state;
  _MockPermissionNotifier(this._state);

  @override
  PermissionState build() => _state;
}

class _MockWorkPermissionsNotifier extends WorkPermissionsNotifier {
  final WorkPermissionsState _state;
  _MockWorkPermissionsNotifier(this._state);

  @override
  WorkPermissionsState build() => _state;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PermissionManager.instance.clear();
  });

  tearDown(() {
    PermissionManager.instance.clear();
  });

  Widget createDrawerHarness({
    required List<UserPermission> permissions,
    required String role,
    bool isCrmEligible = false,
    bool isPermissionsReady = true,
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
      isInitialized: isPermissionsReady,
      isLoading: !isPermissionsReady,
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
          body: Center(child: Text('SSM Test Shell')),
        ),
      ),
    );
  }

  group('Employee Sidebar SSM / Creative Work RBAC Tests', () {
    testWidgets(
      '1. Telecaller: WORK & SSM and Social Media Work MUST NOT be visible',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // Canonical Telecaller permissions (CRM leads, data_capture, customers, attendance, etc. No SSM/Creative work)
        final telecallerPerms = [
          const UserPermission(module: 'DASHBOARD', action: 'VIEW'),
          const UserPermission(module: 'DATA_CAPTURE', action: 'VIEW'),
          const UserPermission(module: 'LEADS', action: 'VIEW'),
          const UserPermission(module: 'CUSTOMERS', action: 'VIEW'),
          const UserPermission(module: 'ATTENDANCE', action: 'VIEW'),
          const UserPermission(module: 'SETTINGS', action: 'VIEW'),
        ];

        // Work permissions from backend for Telecaller
        final workPerms = EmployeeWorkPermissions(
          role: 'Telecaller',
          workPermissions: ['leads', 'data_capture'],
          isCrmEligible: true,
        );

        await tester.pumpWidget(
          createDrawerHarness(
            permissions: telecallerPerms,
            role: 'Telecaller',
            isCrmEligible: true,
            workPermissions: workPerms,
          ),
        );

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Expected CRM & HRM modules ARE visible
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('CRM'), findsOneWidget);
        expect(find.text('Data Capture'), findsOneWidget);
        expect(find.text('Leads'), findsOneWidget);
        expect(find.text('Customers'), findsOneWidget);
        expect(find.text('HRM & WORKPLACE'), findsOneWidget);
        expect(find.text('Attendance'), findsOneWidget);

        // CRITICAL: WORK & SSM section and Social Media Work MUST NOT EXIST
        expect(find.text('WORK & SSM'), findsNothing);
        expect(find.text('Social Media Work'), findsNothing);
      },
    );

    testWidgets(
      '2. Telesales Executive: WORK & SSM and Social Media Work MUST NOT be visible',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final telesalesPerms = [
          const UserPermission(module: 'DASHBOARD', action: 'VIEW'),
          const UserPermission(module: 'DATA_CAPTURE', action: 'VIEW'),
          const UserPermission(module: 'LEADS', action: 'VIEW'),
          const UserPermission(module: 'ATTENDANCE', action: 'VIEW'),
        ];

        final workPerms = EmployeeWorkPermissions(
          role: 'Telesales Executive',
          workPermissions: ['leads', 'data_capture'],
          isCrmEligible: true,
        );

        await tester.pumpWidget(
          createDrawerHarness(
            permissions: telesalesPerms,
            role: 'Telesales Executive',
            isCrmEligible: true,
            workPermissions: workPerms,
          ),
        );

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        expect(find.text('WORK & SSM'), findsNothing);
        expect(find.text('Social Media Work'), findsNothing);
      },
    );

    testWidgets(
      '3. Social Media Manager: WORK & SSM and Social Media Work MUST be visible',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final smmPerms = [
          const UserPermission(module: 'DASHBOARD', action: 'VIEW'),
          const UserPermission(module: 'CREATIVE_WORK', action: 'VIEW'),
          const UserPermission(module: 'MY_WORK', action: 'VIEW'),
          const UserPermission(module: 'CALENDAR', action: 'VIEW'),
          const UserPermission(module: 'ATTENDANCE', action: 'VIEW'),
        ];

        final workPerms = EmployeeWorkPermissions(
          role: 'Social Media Manager',
          workPermissions: ['reel_post', 'story_post', 'post_publish'],
          isCrmEligible: false,
        );

        await tester.pumpWidget(
          createDrawerHarness(
            permissions: smmPerms,
            role: 'Social Media Manager',
            isCrmEligible: false,
            workPermissions: workPerms,
          ),
        );

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        expect(find.text('WORK & SSM'), findsOneWidget);
        expect(find.text('Social Media Work'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Employee Override ALLOW on Telecaller: Social Media Work becomes visible',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // Telecaller with employee-level override allowing CREATIVE_WORK
        final telecallerOverrideAllow = [
          const UserPermission(module: 'DASHBOARD', action: 'VIEW'),
          const UserPermission(module: 'DATA_CAPTURE', action: 'VIEW'),
          const UserPermission(module: 'LEADS', action: 'VIEW'),
          const UserPermission(module: 'CREATIVE_WORK', action: 'VIEW'),
        ];

        final workPerms = EmployeeWorkPermissions(
          role: 'Telecaller',
          workPermissions: ['leads', 'data_capture', 'post_design'],
          isCrmEligible: true,
        );

        await tester.pumpWidget(
          createDrawerHarness(
            permissions: telecallerOverrideAllow,
            role: 'Telecaller',
            isCrmEligible: true,
            workPermissions: workPerms,
          ),
        );

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        expect(find.text('WORK & SSM'), findsOneWidget);
        expect(find.text('Social Media Work'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Employee Override DENY on Social Media Manager: Social Media Work is HIDDEN',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // SMM with employee-level override denying CREATIVE_WORK and MY_WORK
        final smmOverrideDeny = [
          const UserPermission(module: 'DASHBOARD', action: 'VIEW'),
          const UserPermission(module: 'ATTENDANCE', action: 'VIEW'),
        ];

        final workPerms = EmployeeWorkPermissions(
          role: 'Social Media Manager',
          workPermissions: [], // denied
          isCrmEligible: false,
        );

        await tester.pumpWidget(
          createDrawerHarness(
            permissions: smmOverrideDeny,
            role: 'Social Media Manager',
            isCrmEligible: false,
            workPermissions: workPerms,
          ),
        );

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        expect(find.text('WORK & SSM'), findsNothing);
        expect(find.text('Social Media Work'), findsNothing);
      },
    );

    testWidgets(
      '6. Safe default: while permissions are loading, SSM is HIDDEN',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createDrawerHarness(
            permissions: [],
            role: 'Employee',
            isPermissionsReady: false,
          ),
        );

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        expect(find.text('WORK & SSM'), findsNothing);
        expect(find.text('Social Media Work'), findsNothing);
      },
    );

    testWidgets(
      '7. PermissionGuardedView blocks direct navigation when SSM is denied',
      (tester) async {
        final permState = PermissionState(
          permissions: [
            const UserPermission(module: 'DASHBOARD', action: 'VIEW'),
            const UserPermission(module: 'LEADS', action: 'VIEW'),
          ],
          role: 'Telecaller',
          isInitialized: true,
          isLoading: false,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              permissionManagerProvider.overrideWith(
                () => _MockPermissionNotifier(permState),
              ),
            ],
            child: MaterialApp(
              routes: EmployeeRoutes.getRoutes(),
              initialRoute: EmployeeRoutes.ssmWorkList,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Access Restricted'), findsOneWidget);
        expect(
          find.textContaining(
            'You do not have permission to access the Social Media Work module',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
