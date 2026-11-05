import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/roles/company_admin/views/company_admin_main_view.dart';
import 'package:quickboom_app/roles/employee/models/work_permission_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/work_permissions_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/dashboard_view.dart';
import 'package:quickboom_app/roles/employee/views/edit_profile_view.dart';

class MockLoginStateNotifier extends LoginStateNotifier {
  final LoginState mockState;
  MockLoginStateNotifier(this.mockState);

  @override
  LoginState build() => mockState;
}

class MockWorkPermissionsNotifier extends WorkPermissionsNotifier {
  final WorkPermissionsState mockState;
  MockWorkPermissionsNotifier(this.mockState);

  @override
  WorkPermissionsState build() => mockState;

  @override
  Future<void> loadPermissions() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── Employee Account Types Setup ──
  // 1. Company Admin
  final companyAdminLoginState = LoginState(
    isInitializing: false,
    isLoggedIn: true,
    userName: 'Admin User',
    employeeCode: 'ADM-001',
    userRole: 'companyAdmin',
  );

  // 2. Custom Employee with Leads CRM access (e.g. Sales Executive / Account Manager)
  final customEmployeeWithLeadsState = LoginState(
    isInitializing: false,
    isLoggedIn: true,
    userName: 'Custom Employee',
    employeeCode: 'EMP-101',
    userRole: 'employee',
  );
  final leadsPerms = WorkPermissionsState(
    isLoading: false,
    permissions: const EmployeeWorkPermissions(
      role: 'Sales Executive',
      workPermissions: ['leads'],
      effectivePermissions: {'leads': true},
    ),
  );

  // 3. Freelancer without Leads access (e.g. Freelance Video Editor)
  final freelancerState = LoginState(
    isInitializing: false,
    isLoggedIn: true,
    userName: 'Freelancer Alex',
    employeeCode: 'FL-202',
    userRole: 'employee',
  );
  final freelancerPerms = WorkPermissionsState(
    isLoading: false,
    permissions: const EmployeeWorkPermissions(
      role: 'Freelance Video Editor',
      workPermissions: ['video_edit'],
      effectivePermissions: {'video_edit': true},
    ),
  );

  // 4. In-House Employee (e.g. In-House Graphic Designer)
  final inHouseState = LoginState(
    isInitializing: false,
    isLoggedIn: true,
    userName: 'In-House Designer',
    employeeCode: 'IH-303',
    userRole: 'employee',
  );
  final inHousePerms = WorkPermissionsState(
    isLoading: false,
    permissions: const EmployeeWorkPermissions(
      role: 'Graphic Designer',
      workPermissions: ['post_design'],
      effectivePermissions: {'post_design': true},
    ),
  );

  group(
    'Employee Mobile Navigation: NO Back Icon on Root Screens (All Employee Types)',
    () {
      testWidgets('1. Company Admin: All main tabs have NO back icon', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer(
          overrides: [
            loginStateProvider.overrideWith(
              () => MockLoginStateNotifier(companyAdminLoginState),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const CompanyAdminMainView(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Root tab 0 (Home): Verify NO back icon
        expect(find.byType(BackButton), findsNothing);
        expect(find.byTooltip('Back'), findsNothing);

        // Navigate to Clients tab
        await tester.tap(find.text('Clients'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(BackButton), findsNothing);
        expect(find.byTooltip('Back'), findsNothing);

        // Navigate to Trending tab
        await tester.tap(find.text('Trending'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(BackButton), findsNothing);
        expect(find.byTooltip('Back'), findsNothing);

        // Navigate to Calendar tab
        await tester.tap(find.text('Calendar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(BackButton), findsNothing);
        expect(find.byTooltip('Back'), findsNothing);

        // Navigate to More tab
        await tester.tap(find.text('More'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(BackButton), findsNothing);
        expect(find.byTooltip('Back'), findsNothing);
      });

      testWidgets(
        '2. Custom Employee (with Leads): Home/Data/Leads/Clients/Profile have NO back icon',
        (tester) async {
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final container = ProviderContainer(
            overrides: [
              loginStateProvider.overrideWith(
                () => MockLoginStateNotifier(customEmployeeWithLeadsState),
              ),
              workPermissionsProvider.overrideWith(
                () => MockWorkPermissionsNotifier(leadsPerms),
              ),
            ],
          );

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const DashboardView(),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Tab 0: Home -> NO back button
          expect(find.byType(BackButton), findsNothing);
          expect(find.byTooltip('Back'), findsNothing);

          // Tab 1: Data -> NO back button
          await tester.tap(find.text('Data'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(BackButton), findsNothing);
          expect(find.byTooltip('Back'), findsNothing);

          // Tab 2: Leads -> NO back button
          await tester.tap(find.text('Leads'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(BackButton), findsNothing);
          expect(find.byTooltip('Back'), findsNothing);

          // Tab 3: Clients -> NO back button
          await tester.tap(find.text('Clients'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(BackButton), findsNothing);
          expect(find.byTooltip('Back'), findsNothing);

          // Tab 4: Profile -> NO back button
          await tester.tap(find.text('Profile'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(BackButton), findsNothing);
          expect(find.byTooltip('Back'), findsNothing);
        },
      );

      testWidgets('3. Freelancer: Home/My Work/Profile have NO back icon', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer(
          overrides: [
            loginStateProvider.overrideWith(
              () => MockLoginStateNotifier(freelancerState),
            ),
            workPermissionsProvider.overrideWith(
              () => MockWorkPermissionsNotifier(freelancerPerms),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const DashboardView(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tab 0: Home -> NO back button
        expect(find.byType(BackButton), findsNothing);
        expect(find.byTooltip('Back'), findsNothing);

        // Tab 1: My Work -> NO back button
        await tester.tap(find.text('My Work'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(BackButton), findsNothing);
        expect(find.byTooltip('Back'), findsNothing);

        // Tab 2: Profile -> NO back button
        await tester.tap(find.text('Profile'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(BackButton), findsNothing);
        expect(find.byTooltip('Back'), findsNothing);
      });

      testWidgets(
        '4. In-House Employee: Home/My Work/Profile have NO back icon',
        (tester) async {
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final container = ProviderContainer(
            overrides: [
              loginStateProvider.overrideWith(
                () => MockLoginStateNotifier(inHouseState),
              ),
              workPermissionsProvider.overrideWith(
                () => MockWorkPermissionsNotifier(inHousePerms),
              ),
            ],
          );

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const DashboardView(),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Tab 0: Home
          expect(find.byType(BackButton), findsNothing);
          // Tab 1: My Work
          await tester.tap(find.text('My Work'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(BackButton), findsNothing);
          // Tab 2: Profile
          await tester.tap(find.text('Profile'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(BackButton), findsNothing);
        },
      );

      testWidgets('5. Detail screens: Back icon MUST appear', (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer(
          overrides: [
            loginStateProvider.overrideWith(
              () => MockLoginStateNotifier(inHouseState),
            ),
            workPermissionsProvider.overrideWith(
              () => MockWorkPermissionsNotifier(inHousePerms),
            ),
          ],
        );

        late BuildContext rootCtx;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Builder(
                builder: (ctx) {
                  rootCtx = ctx;
                  return const DashboardView();
                },
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Push a child detail screen (e.g. EditProfileView)
        Navigator.push(
          rootCtx,
          MaterialPageRoute(builder: (_) => const EditProfileView()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // On child screen, Back button MUST appear
        expect(find.byType(BackButton), findsOneWidget);

        // Tapping back button pops back to root screen
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Root screen restored -> NO back button
        expect(find.byType(BackButton), findsNothing);
      });

      testWidgets('6. Android system back on non-home tab switches to Home tab', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer(
          overrides: [
            loginStateProvider.overrideWith(
              () => MockLoginStateNotifier(customEmployeeWithLeadsState),
            ),
            workPermissionsProvider.overrideWith(
              () => MockWorkPermissionsNotifier(leadsPerms),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const DashboardView(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Switch to Leads tab (index 2)
        await tester.tap(find.text('Leads'));
        await tester.pumpAndSettle();

        // Verify currently on Leads tab
        expect(find.text('Leads Pipeline'), findsOneWidget);

        // Trigger system back pop
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        // Switched back to Home tab (Custom Employee greeting visible, Leads title gone)
        expect(find.text('Custom Employee'), findsOneWidget);
      });
    },
  );
}
