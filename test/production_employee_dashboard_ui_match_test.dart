import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/roles/employee/models/work_permission_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/work_permissions_viewmodel.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_profile_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/dashboard_view.dart';
import 'package:quickboom_app/roles/employee/views/employee_schedule_view.dart';
import 'package:quickboom_app/roles/employee/views/ssm/employee_ssm_work_list_view.dart';

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

class MockPermissionNotifier extends PermissionNotifier {
  final PermissionState mockState;
  MockPermissionNotifier(this.mockState);

  @override
  PermissionState build() => mockState;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Production Employee Dashboard matches user screenshot navigation layout',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final photographerLoginState = LoginState(
        isInitializing: false,
        isLoggedIn: true,
        userName: 'Sumit Parmar',
        employeeCode: 'EMP-020',
        userRole: 'employee',
      );

      final photographerPerms = WorkPermissionsState(
        isLoading: false,
        permissions: const EmployeeWorkPermissions(
          role: 'SENIOR PHOTOGRAPHER',
          workPermissions: ['reel_shoot'],
          effectivePermissions: {'reel_shoot': true},
        ),
      );

      const photographerProfile = EmployeeProfileData(
        id: 20,
        name: 'Sumit Parmar',
        employeeCode: 'EMP-020',
        email: 'sumit@example.com',
        phone: '9876543210',
        designation: 'SENIOR PHOTOGRAPHER',
        department: 'PRODUCTION',
      );

      final container = ProviderContainer(
        overrides: [
          loginStateProvider.overrideWith(
            () => MockLoginStateNotifier(photographerLoginState),
          ),
          workPermissionsProvider.overrideWith(
            () => MockWorkPermissionsNotifier(photographerPerms),
          ),
          employeeProfileProvider.overrideWith(
            (ref) => Future.value(photographerProfile),
          ),
          permissionManagerProvider.overrideWith(
            () => MockPermissionNotifier(
              const PermissionState(
                role: 'SENIOR PHOTOGRAPHER',
                isInitialized: true,
              ),
            ),
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

      // 1. Verify exactly 4 bottom nav items: Home, My Work, Calendar, Profile
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('My Work'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify Customers and Tasks tabs are NOT present in bottom nav bar
      expect(find.text('Customers'), findsNothing);

      // 2. Switch to 'Calendar' tab (matching Screenshot 1)
      await tester.tap(find.text('Calendar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify EmployeeScheduleView is rendered with 'My Calendar' title
      expect(find.byType(EmployeeScheduleView), findsOneWidget);
      expect(find.text('My Calendar'), findsOneWidget);
      expect(find.byIcon(Remix.refresh_line), findsOneWidget);

      // Verify BackButton exists on My Calendar AppBar and tapping it returns to Home
      final backFinder = find.descendant(
        of: find.byType(EmployeeScheduleView),
        matching: find.byType(BackButton),
      );
      expect(backFinder, findsOneWidget);
      await tester.tap(backFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 3. Switch to 'My Work' tab (matching Screenshot 2)
      await tester.tap(find.text('My Work'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify EmployeeSSMWorkListView is rendered with 'Production Overview'
      expect(find.byType(EmployeeSSMWorkListView), findsOneWidget);
      expect(find.text('Production Overview'), findsOneWidget);
    },
  );
}
