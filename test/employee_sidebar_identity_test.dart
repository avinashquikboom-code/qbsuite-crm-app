import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/constants/constants.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/roles/employee/models/work_permission_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_profile_viewmodel.dart';
import 'package:quickboom_app/roles/employee/viewmodels/work_permissions_viewmodel.dart';
import 'package:quickboom_app/shared/widgets/app_drawer.dart';
import 'package:quickboom_app/shared/widgets/sidebar.dart';

class MockLoginStateNotifier extends LoginStateNotifier {
  final LoginState mockState;
  MockLoginStateNotifier(this.mockState);

  @override
  LoginState build() => mockState;
}

class MockWorkPermissionsNotifier extends WorkPermissionsNotifier {
  @override
  WorkPermissionsState build() => const WorkPermissionsState(
    permissions: EmployeeWorkPermissions(
      role: 'Field Sales Executive',
      workPermissions: ['leads'],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final authenticatedEmployeeState = LoginState(
    isInitializing: false,
    isLoggedIn: true,
    userName: 'Tirthraj Solanki',
    employeeCode: 'EMP-009',
    userRole: 'Field Sales Executive',
    userEmail: 'tirthraj.solanki@quikboom.com',
  );

  group('Employee Sidebar Identity Tests', () {
    testWidgets(
      'AppDrawer dynamically displays authenticated employee name and code, never Demo User',
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
              () => MockLoginStateNotifier(authenticatedEmployeeState),
            ),
            employeeProfileProvider.overrideWith(
              (ref) async => const EmployeeProfileData(
                id: 9,
                name: 'Tirthraj Solanki',
                employeeCode: 'EMP-009',
                email: 'tirthraj.solanki@quikboom.com',
                department: 'Sales',
                designation: 'Field Sales Executive',
                status: 'ACTIVE',
              ),
            ),
            workPermissionsProvider.overrideWith(
              () => MockWorkPermissionsNotifier(),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                drawer: AppDrawer(),
                body: Center(child: Text('Home')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open the drawer
        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Verify authenticated employee name and employee code are shown
        expect(find.text('Tirthraj Solanki'), findsOneWidget);
        expect(find.text('EMP-009'), findsOneWidget);
        expect(find.text('ACTIVE'), findsOneWidget);

        // Verify "Demo User" is NEVER shown
        expect(find.text('Demo User'), findsNothing);
      },
    );

    testWidgets(
      'Sidebar widget dynamically displays authenticated employee name and code, never Demo User',
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
              () => MockLoginStateNotifier(authenticatedEmployeeState),
            ),
            employeeProfileProvider.overrideWith(
              (ref) async => const EmployeeProfileData(
                id: 9,
                name: 'Tirthraj Solanki',
                employeeCode: 'EMP-009',
                email: 'tirthraj.solanki@quikboom.com',
                department: 'Sales',
                designation: 'Field Sales Executive',
                status: 'ACTIVE',
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Sidebar(
                  currentSelection: SidebarItem.followUps,
                  onItemSelected: (_) {},
                  onLogout: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify authenticated employee name and employee code are shown
        expect(find.text('Tirthraj Solanki'), findsOneWidget);
        expect(find.text('EMP-009'), findsOneWidget);

        // Verify "Demo User" is NEVER shown
        expect(find.text('Demo User'), findsNothing);
      },
    );
  });
}
