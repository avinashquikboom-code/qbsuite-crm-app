import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/roles/employee/models/employee_attendance_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_attendance_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/sidebar_views/attendance_view.dart';

void main() {
  group('Employee Attendance Daily Grouping & Deduplication Tests', () {
    test(
      'AttendanceLogItem.consolidateDaily collapses same-date duplicate sessions into 1 daily record',
      () {
        final duplicates = [
          AttendanceLogItem(
            id: '5',
            date: '2026-09-23',
            day: 'Wednesday',
            checkIn: '11:34 AM',
            checkOut: '06:30 PM',
            workingHours: '7h 56m',
            breakDuration: '0h 1m',
            breaksCount: 1,
            status: 'PRESENT',
            isLate: false,
            location: 'QUIKBOOM MARKETING AGENCY (192m)',
            parsedDate: DateTime(2026, 9, 23),
          ),
          AttendanceLogItem(
            id: '4',
            date: '2026-09-23',
            day: 'Wednesday',
            checkIn: '11:34 AM',
            checkOut: '—',
            workingHours: '0h 0m',
            breakDuration: '0h 0m',
            breaksCount: 0,
            status: 'PRESENT',
            isLate: false,
            location: 'QUIKBOOM MARKETING AGENCY (192m)',
            parsedDate: DateTime(2026, 9, 23),
          ),
          AttendanceLogItem(
            id: '3',
            date: '2026-09-23',
            day: 'Wednesday',
            checkIn: '11:33 AM',
            checkOut: '—',
            workingHours: '0h 0m',
            breakDuration: '0h 0m',
            breaksCount: 0,
            status: 'PRESENT',
            isLate: false,
            location: 'QUIKBOOM MARKETING AGENCY (192m)',
            parsedDate: DateTime(2026, 9, 23),
          ),
          AttendanceLogItem(
            id: '2',
            date: '2026-09-23',
            day: 'Wednesday',
            checkIn: '11:33 AM',
            checkOut: '—',
            workingHours: '0h 0m',
            breakDuration: '0h 0m',
            breaksCount: 0,
            status: 'PRESENT',
            isLate: false,
            location: 'QUIKBOOM MARKETING AGENCY (192m)',
            parsedDate: DateTime(2026, 9, 23),
          ),
          AttendanceLogItem(
            id: '1',
            date: '2026-09-23',
            day: 'Wednesday',
            checkIn: '11:33 AM',
            checkOut: '—',
            workingHours: '0h 0m',
            breakDuration: '0h 0m',
            breaksCount: 0,
            status: 'PRESENT',
            isLate: false,
            location: 'QUIKBOOM MARKETING AGENCY (192m)',
            parsedDate: DateTime(2026, 9, 23),
          ),
        ];

        final consolidated = AttendanceLogItem.consolidateDaily(duplicates);

        expect(consolidated.length, 1);
        final item = consolidated.first;
        expect(item.date, '2026-09-23');
        expect(item.checkIn, '11:34 AM');
        expect(item.checkOut, '06:30 PM');
        expect(item.workingHours, '7h 56m');
        expect(item.breakDuration, '0h 1m');
        expect(item.location, 'QUIKBOOM MARKETING AGENCY (192m)');
        expect(item.status, 'PRESENT');
      },
    );

    testWidgets(
      'AttendanceView renders exactly ONE card for 23 Sep 2026 despite 5 incoming duplicate records',
      (tester) async {
        final duplicates = [
          AttendanceLogItem(
            id: '5',
            date: '2026-09-23',
            day: 'Wednesday',
            checkIn: '11:34 AM',
            checkOut: '06:30 PM',
            workingHours: '7h 56m',
            breakDuration: '0h 1m',
            breaksCount: 1,
            status: 'PRESENT',
            isLate: false,
            location: 'QUIKBOOM MARKETING AGENCY (192m)',
            parsedDate: DateTime(2026, 9, 23),
          ),
          AttendanceLogItem(
            id: '4',
            date: '2026-09-23',
            day: 'Wednesday',
            checkIn: '11:34 AM',
            checkOut: '—',
            workingHours: '0h 0m',
            breakDuration: '0h 0m',
            breaksCount: 0,
            status: 'PRESENT',
            isLate: false,
            location: 'QUIKBOOM MARKETING AGENCY (192m)',
            parsedDate: DateTime(2026, 9, 23),
          ),
          AttendanceLogItem(
            id: '3',
            date: '2026-09-23',
            day: 'Wednesday',
            checkIn: '11:33 AM',
            checkOut: '—',
            workingHours: '0h 0m',
            breakDuration: '0h 0m',
            breaksCount: 0,
            status: 'PRESENT',
            isLate: false,
            location: 'QUIKBOOM MARKETING AGENCY (192m)',
            parsedDate: DateTime(2026, 9, 23),
          ),
          AttendanceLogItem(
            id: '2',
            date: '2026-09-23',
            day: 'Wednesday',
            checkIn: '11:33 AM',
            checkOut: '—',
            workingHours: '0h 0m',
            breakDuration: '0h 0m',
            breaksCount: 0,
            status: 'PRESENT',
            isLate: false,
            location: 'QUIKBOOM MARKETING AGENCY (192m)',
            parsedDate: DateTime(2026, 9, 23),
          ),
          AttendanceLogItem(
            id: '1',
            date: '2026-09-23',
            day: 'Wednesday',
            checkIn: '11:33 AM',
            checkOut: '—',
            workingHours: '0h 0m',
            breakDuration: '0h 0m',
            breaksCount: 0,
            status: 'PRESENT',
            isLate: false,
            location: 'QUIKBOOM MARKETING AGENCY (192m)',
            parsedDate: DateTime(2026, 9, 23),
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            employeeAttendanceProvider.overrideWith(() {
              return _FakeAttendanceNotifier(
                AttendanceState(
                  status: MyAttendanceStatus.empty(),
                  historyLogs: duplicates,
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

        // 1. Verify results count is 1 Record (not 5 Records)
        expect(find.text('1 Record'), findsOneWidget);
        expect(find.text('5 Records'), findsNothing);

        // 2. Verify exactly ONE card header for 23 Sep 2026
        expect(find.text('23 Sep 2026'), findsOneWidget);
        expect(find.text('Wednesday'), findsOneWidget);

        // 3. Verify card metric values
        expect(find.text('11:34 AM'), findsOneWidget);
        expect(find.text('06:30 PM'), findsOneWidget);
        expect(find.text('7h 56m'), findsOneWidget);

        // 4. Verify location and break
        expect(find.text('QUIKBOOM MARKETING AGENCY (192m)'), findsOneWidget);
        expect(find.text('Break: 0h 1m'), findsOneWidget);
      },
    );

    testWidgets(
      'AttendanceView shows --:-- when employee has not checked out',
      (tester) async {
        final openAttendance = [
          AttendanceLogItem(
            id: '10',
            date: '2026-09-23',
            day: 'Wednesday',
            checkIn: '10:00 AM',
            checkOut: '—',
            workingHours: '3h 15m',
            breakDuration: '0h 0m',
            breaksCount: 0,
            status: 'PRESENT',
            isLate: false,
            location: 'Head Office',
            parsedDate: DateTime(2026, 9, 23),
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            employeeAttendanceProvider.overrideWith(() {
              return _FakeAttendanceNotifier(
                AttendanceState(
                  status: MyAttendanceStatus.empty(),
                  historyLogs: openAttendance,
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

        expect(find.text('10:00 AM'), findsOneWidget);
        expect(find.text('--:--'), findsOneWidget);
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
