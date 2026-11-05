import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/employee/models/work_permission_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_calendar_viewmodel.dart';
import 'package:quickboom_app/roles/employee/viewmodels/work_permissions_viewmodel.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_profile_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/employee_schedule_view.dart';

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
    'Category filter pills are completely removed from Employee Schedule View',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final editorLoginState = LoginState(
        isInitializing: false,
        isLoggedIn: true,
        userName: 'Rohan Editor',
        employeeCode: 'EMP-015',
        userRole: 'employee',
      );

      final editorPerms = WorkPermissionsState(
        isLoading: false,
        permissions: const EmployeeWorkPermissions(
          role: 'VIDEO EDITOR',
          workPermissions: ['video_edit'],
          effectivePermissions: {'video_edit': true},
        ),
      );

      const editorProfile = EmployeeProfileData(
        id: 15,
        name: 'Rohan Editor',
        employeeCode: 'EMP-015',
        email: 'rohan@example.com',
        phone: '9876543210',
        designation: 'VIDEO EDITOR',
        department: 'CREATIVE',
      );

      final container = ProviderContainer(
        overrides: [
          loginStateProvider.overrideWith(
            () => MockLoginStateNotifier(editorLoginState),
          ),
          workPermissionsProvider.overrideWith(
            () => MockWorkPermissionsNotifier(editorPerms),
          ),
          employeeProfileProvider.overrideWith(
            (ref) => Future.value(editorProfile),
          ),
          permissionManagerProvider.overrideWith(
            () => MockPermissionNotifier(
              const PermissionState(
                role: 'VIDEO EDITOR',
                isInitialized: true,
              ),
            ),
          ),
          employeeCalendarActivitiesForMonthProvider.overrideWith(
            (ref, month) => Future.value(const <CustomerCalendarActivity>[]),
          ),
          employeeCalendarActivitiesForDateProvider.overrideWith(
            (ref, date) => Future.value(const <CustomerCalendarActivity>[]),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: EmployeeScheduleView(showBackButton: false)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Category filter chips are present on Employee Schedule View
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Video Editing'), findsOneWidget);
      expect(find.text('Reel Shoot'), findsOneWidget);
      expect(find.text('Post Design'), findsOneWidget);

      // Schedule Event button must NOT exist on the Employee Schedule view
      expect(find.text('Schedule Event'), findsNothing);
    },
  );
}
