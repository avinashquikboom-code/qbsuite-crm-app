import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/roles/company_admin/views/company_admin_main_view.dart';
import 'package:quickboom_app/roles/employee/models/employee_attendance_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_attendance_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/home_view.dart';
import 'package:quickboom_app/roles/employee/views/sidebar_views/attendance_view.dart';

class MockLoginStateNotifier extends LoginStateNotifier {
  final LoginState mockState;
  MockLoginStateNotifier(this.mockState);

  @override
  LoginState build() => mockState;
}

class _FakeAttendanceNotifier extends EmployeeAttendanceNotifier {
  final AttendanceState _initial;
  _FakeAttendanceNotifier(this._initial);

  @override
  AttendanceState build() => _initial;

  @override
  Future<void> loadHistory({String? date, String? branch}) async {}

  @override
  Future<void> loadStatus() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final notCheckedInState = AttendanceState(
    status: MyAttendanceStatus.empty(),
    historyLogs: const [],
    isHistoryLoading: false,
  );

  final checkedInState = AttendanceState(
    status: MyAttendanceStatus(
      status: AttendanceStatusDetails(
        isPunchedIn: true,
        isOnBreak: false,
        punchInTime: '2026-09-08T09:30:00.000Z',
        punchOutTime: null,
        workingHours: 2.0,
        breakDuration: 0.0,
        rawStatus: 'PRESENT',
      ),
    ),
    historyLogs: const [],
    isHistoryLoading: false,
  );

  final completedState = AttendanceState(
    status: MyAttendanceStatus(
      status: AttendanceStatusDetails(
        isPunchedIn: false,
        isOnBreak: false,
        punchInTime: '2026-09-08T09:30:00.000Z',
        punchOutTime: '2026-09-08T18:30:00.000Z',
        workingHours: 8.5,
        breakDuration: 0.5,
        rawStatus: 'PRESENT',
      ),
    ),
    historyLogs: const [],
    isHistoryLoading: false,
  );

  group('Employee Attendance Dynamic Button Verification', () {
    testWidgets('Employee Home displays PUNCH IN button when not checked in', (
      tester,
    ) async {
      final employeeLoginState = LoginState(
        isInitializing: false,
        isLoggedIn: true,
        userName: 'In-House Employee',
        employeeCode: 'EMP-001',
        userRole: 'employee',
      );

      final container = ProviderContainer(
        overrides: [
          loginStateProvider.overrideWith(
            () => MockLoginStateNotifier(employeeLoginState),
          ),
          employeeAttendanceProvider.overrideWith(
            () => _FakeAttendanceNotifier(notCheckedInState),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: EmployeeHomeView(onOpenDrawer: () {})),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify "PUNCH IN" button is visible
      expect(find.text('PUNCH IN'), findsOneWidget);
      expect(find.text('PUNCH OUT'), findsNothing);
      expect(find.text('Attendance Completed'), findsNothing);
    });

    testWidgets(
      'Employee Home displays PUNCH OUT and Start Break buttons when checked in',
      (tester) async {
        final employeeLoginState = LoginState(
          isInitializing: false,
          isLoggedIn: true,
          userName: 'In-House Employee',
          employeeCode: 'EMP-001',
          userRole: 'employee',
        );

        final container = ProviderContainer(
          overrides: [
            loginStateProvider.overrideWith(
              () => MockLoginStateNotifier(employeeLoginState),
            ),
            employeeAttendanceProvider.overrideWith(
              () => _FakeAttendanceNotifier(checkedInState),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(body: EmployeeHomeView(onOpenDrawer: () {})),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify "PUNCH OUT" and "Start Break" buttons are visible
        expect(find.text('PUNCH OUT'), findsOneWidget);
        expect(find.text('Start Break'), findsOneWidget);
        expect(find.text('PUNCH IN'), findsNothing);
      },
    );

    testWidgets(
      'Employee Home displays Attendance Completed when shift is completed',
      (tester) async {
        final employeeLoginState = LoginState(
          isInitializing: false,
          isLoggedIn: true,
          userName: 'In-House Employee',
          employeeCode: 'EMP-001',
          userRole: 'employee',
        );

        final container = ProviderContainer(
          overrides: [
            loginStateProvider.overrideWith(
              () => MockLoginStateNotifier(employeeLoginState),
            ),
            employeeAttendanceProvider.overrideWith(
              () => _FakeAttendanceNotifier(completedState),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(body: EmployeeHomeView(onOpenDrawer: () {})),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify "Attendance Completed" card is visible
        expect(find.text('Attendance Completed'), findsOneWidget);
        expect(find.text('PUNCH IN'), findsNothing);
        expect(find.text('PUNCH OUT'), findsNothing);
      },
    );

    testWidgets(
      'AttendanceView does not contain Punch In button (it is a dedicated log view)',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            employeeAttendanceProvider.overrideWith(
              () => _FakeAttendanceNotifier(notCheckedInState),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: AttendanceView()),
          ),
        );
        await tester.pumpAndSettle();

        // Attendance Log header and summary are present
        expect(find.text('Attendance Log'), findsOneWidget);
        expect(find.text('Total Working Days'), findsOneWidget);

        // No Punch In button in historical log screen
        expect(find.text('PUNCH IN'), findsNothing);
      },
    );

    testWidgets('Company Admin main view does not contain Punch In button', (
      tester,
    ) async {
      final adminLoginState = LoginState(
        isInitializing: false,
        isLoggedIn: true,
        userName: 'Admin User',
        employeeCode: 'ADM-001',
        userRole: 'company_admin',
      );

      final container = ProviderContainer(
        overrides: [
          loginStateProvider.overrideWith(
            () => MockLoginStateNotifier(adminLoginState),
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
      await tester.pumpAndSettle();

      // Verify no Punch In button exists in Company Admin
      expect(find.text('PUNCH IN'), findsNothing);
    });
  });
}
