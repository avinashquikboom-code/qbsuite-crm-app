import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/roles/employee/models/employee_attendance_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_attendance_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/sidebar_views/attendance_view.dart';

void main() {
  group('Employee Attendance Log Redesign Tests', () {
    test(
      'AttendanceLogItem model parses and derives day and parsedDate correctly',
      () {
        final json = {
          'id': 'att-101',
          'date': '2026-08-10',
          'day': '', // should be derived as Monday
          'checkIn': '09:30 AM',
          'checkOut': '06:30 PM',
          'workingMinutes': 540,
          'totalBreakMinutes': 60,
          'status': 'PRESENT',
          'location': 'Mumbai HQ',
        };

        final item = AttendanceLogItem.fromJson(json);

        expect(item.id, 'att-101');
        expect(item.date, '2026-08-10');
        expect(item.day, 'Monday');
        expect(item.parsedDate?.year, 2026);
        expect(item.parsedDate?.month, 8);
        expect(item.parsedDate?.day, 10);
        expect(item.checkIn, '09:30 AM');
        expect(item.checkOut, '06:30 PM');
        expect(item.workingHours, '9h 0m');
        expect(item.breakDuration, '1h 0m');
        expect(item.status, 'PRESENT');
        expect(item.isLate, isFalse);
      },
    );

    test('AttendanceLogItem correctly flags LATE status', () {
      final json = {
        'id': 'att-102',
        'date': '2026-08-11',
        'day': 'Tuesday',
        'checkIn': '10:15 AM',
        'checkOut': '07:15 PM',
        'workingMinutes': 540,
        'totalBreakMinutes': 30,
        'status': 'LATE',
        'location': 'Navi Mumbai',
      };

      final item = AttendanceLogItem.fromJson(json);

      expect(item.status, 'LATE');
      expect(item.isLate, isTrue);
      expect(item.day, 'Tuesday');
    });

    testWidgets('AttendanceView renders header, summary cards, and filters', (
      tester,
    ) async {
      final now = DateTime.now();
      final logs = [
        AttendanceLogItem(
          id: '1',
          date: '${now.year}-${now.month.toString().padLeft(2, "0")}-01',
          day: 'Monday',
          checkIn: '09:25 AM',
          checkOut: '06:30 PM',
          workingHours: '9h 5m',
          breakDuration: '45m',
          breaksCount: 1,
          status: 'PRESENT',
          isLate: false,
          location: 'HQ Office',
          parsedDate: DateTime(now.year, now.month, 1),
        ),
        AttendanceLogItem(
          id: '2',
          date: '${now.year}-${now.month.toString().padLeft(2, "0")}-02',
          day: 'Tuesday',
          checkIn: '10:15 AM',
          checkOut: '06:30 PM',
          workingHours: '8h 15m',
          breakDuration: '30m',
          breaksCount: 1,
          status: 'LATE',
          isLate: true,
          location: 'HQ Office',
          parsedDate: DateTime(now.year, now.month, 2),
        ),
        AttendanceLogItem(
          id: '3',
          date: '${now.year}-${now.month.toString().padLeft(2, "0")}-03',
          day: 'Wednesday',
          checkIn: '09:30 AM',
          checkOut: '01:30 PM',
          workingHours: '4h 0m',
          breakDuration: '0h 0m',
          breaksCount: 0,
          status: 'HALF_DAY',
          isLate: false,
          location: 'Remote Work',
          parsedDate: DateTime(now.year, now.month, 3),
        ),
        AttendanceLogItem(
          id: '4',
          date: '${now.year}-${now.month.toString().padLeft(2, "0")}-04',
          day: 'Thursday',
          checkIn: '—',
          checkOut: '—',
          workingHours: '0h 0m',
          breakDuration: '0h 0m',
          breaksCount: 0,
          status: 'ABSENT',
          isLate: false,
          location: 'Office',
          parsedDate: DateTime(now.year, now.month, 4),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          employeeAttendanceProvider.overrideWith(() {
            final notifier = _FakeAttendanceNotifier(
              AttendanceState(
                status: MyAttendanceStatus.empty(),
                historyLogs: logs,
                isHistoryLoading: false,
              ),
            );
            return notifier;
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AttendanceView()),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Header verification
      expect(find.text('Attendance Log'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      // 2. Summary cards verification
      expect(find.text('Total Working Days'), findsOneWidget);
      expect(find.text('Present'), findsWidgets); // chip and summary card
      expect(find.text('Late'), findsWidgets);
      expect(find.text('Half Day'), findsWidgets);
      expect(find.text('Absent'), findsWidgets);

      // 3. Filters verification
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Attendance Records'), findsOneWidget);

      // Tap on 'Late' chip
      await tester.tap(find.widgetWithText(GestureDetector, 'Late'));
      await tester.pumpAndSettle();

      // Verify records count text for Late (1 record)
      expect(find.text('1 Record'), findsOneWidget);

      // Tap Reset button
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'AttendanceView displays empty state when no records match filter',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            employeeAttendanceProvider.overrideWith(() {
              return _FakeAttendanceNotifier(
                AttendanceState(
                  status: MyAttendanceStatus.empty(),
                  historyLogs: const [],
                  isHistoryLoading: false,
                ),
              );
            }),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: AttendanceView()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('No Attendance Records'), findsOneWidget);
      },
    );

    testWidgets(
      'AttendanceView displays error state with Retry button on API failure',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            employeeAttendanceProvider.overrideWith(() {
              return _FakeAttendanceNotifier(
                AttendanceState(
                  status: MyAttendanceStatus.empty(),
                  historyLogs: const [],
                  isHistoryLoading: false,
                  pageError:
                      'Network connection error. Failed to reach server.',
                ),
              );
            }),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: AttendanceView()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Unable to Load Attendance'), findsOneWidget);
        expect(
          find.text('Network connection error. Failed to reach server.'),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);
      },
    );
  });
}

class _FakeAttendanceNotifier extends EmployeeAttendanceNotifier {
  final AttendanceState _initial;

  _FakeAttendanceNotifier(this._initial);

  @override
  AttendanceState build() {
    return _initial;
  }

  @override
  Future<void> loadHistory({String? date, String? branch}) async {}

  @override
  Future<void> loadStatus() async {}
}
