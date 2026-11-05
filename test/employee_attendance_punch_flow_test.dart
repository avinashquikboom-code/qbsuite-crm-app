import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/utils/app_date_formatter.dart';
import 'package:quickboom_app/roles/employee/models/employee_attendance_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_attendance_viewmodel.dart';

void main() {
  group('Employee Attendance Models & State Tests', () {
    test('AssignedOffice distanceTo calculates distance accurately', () {
      final office = AssignedOffice(
        id: 1,
        name: 'Head Office',
        city: 'Navi Mumbai',
        latitude: 19.0330,
        longitude: 73.0297,
        radiusMeters: 200.0,
      );

      // Same coordinates -> 0 distance
      expect(office.distanceTo(19.0330, 73.0297), 0.0);

      // Nearby coordinates (~63m) -> distance <= 200m
      final nearbyDistance = office.distanceTo(19.0335, 73.0300);
      expect(nearbyDistance, greaterThan(40.0));
      expect(nearbyDistance, lessThan(100.0));
      expect(nearbyDistance <= office.radiusMeters, isTrue);

      // Far coordinates (~2km) -> distance > 200m
      final farDistance = office.distanceTo(19.0450, 73.0450);
      expect(farDistance, greaterThan(1500.0));
      expect(farDistance <= office.radiusMeters, isFalse);
    });

    test(
      'AttendanceState formatted strings format punch times and hours correctly',
      () {
        final now = DateTime.now();
        final status = MyAttendanceStatus(
          employee: EmployeeShortInfo(
            id: 10,
            employeeCode: 'QB-EMP-010',
            name: 'John Doe',
            email: 'john@example.com',
            department: 'Engineering',
            designation: 'Software Engineer',
          ),
          assignedOffice: AssignedOffice(
            id: 1,
            name: 'Head Office',
            city: 'Navi Mumbai',
            latitude: 19.0330,
            longitude: 73.0297,
            radiusMeters: 200.0,
          ),
          status: AttendanceStatusDetails(
            isPunchedIn: true,
            isOnBreak: false,
            punchInTime: DateTime(
              now.year,
              now.month,
              now.day,
              9,
              30,
            ).toIso8601String(),
            punchOutTime: null,
            workingHours: 4.5,
            breakDuration: 0.5,
            rawStatus: 'PRESENT',
          ),
        );

        final state = AttendanceState(status: status);

        expect(state.isPunchedIn, isTrue);
        expect(state.isOnBreak, isFalse);
        expect(state.isCompleted, isFalse);
        expect(state.punchInTimeFormatted, '09:30 AM');
        expect(state.punchOutTimeFormatted, '--:--');
        expect(state.workingHoursFormatted, '4h 30m');
        expect(state.breakDurationFormatted, '0h 30m');
      },
    );

    test(
      'AttendanceState shift, remote work, late arrival and progress calculations work accurately',
      () {
        final now = DateTime.now();
        final status = MyAttendanceStatus(
          employee: EmployeeShortInfo(
            id: 10,
            employeeCode: 'QB-EMP-010',
            name: 'Avinash Magar',
            email: 'avinash@example.com',
            department: 'IT Department',
            designation: 'Flutter Developer',
          ),
          assignedOffice: AssignedOffice(
            id: 1,
            name: 'BKC HQ',
            city: 'Mumbai',
            latitude: 19.0760,
            longitude: 72.8777,
            radiusMeters: 200.0,
          ),
          assignedShift: AssignedShiftInfo(
            id: 1,
            name: 'Morning Shift',
            code: 'MS-01',
            startTime: '09:30 AM',
            endTime: '06:30 PM',
            durationHours: 9.0,
            gracePeriodMinutes: 15,
            breakDurationMinutes: 60,
          ),
          approvedRemote: ApprovedRemoteInfo(
            id: 101,
            status: 'APPROVED',
            reason: 'Client Site Deployment',
          ),
          status: AttendanceStatusDetails(
            isPunchedIn: true,
            isOnBreak: false,
            punchInTime: DateTime(
              now.year,
              now.month,
              now.day,
              9,
              50,
            ).toIso8601String(),
            punchOutTime: null,
            workingHours: 6.7, // 6h 42m
            breakDuration: 1.08, // 1h 05m
            rawStatus: 'LATE',
          ),
        );

        final state = AttendanceState(status: status);

        expect(state.isRemoteWork, isTrue);
        expect(state.remoteReason, 'Client Site Deployment');
        expect(state.shiftStartTime, '09:30 AM');
        expect(state.shiftEndTime, '06:30 PM');
        expect(state.shiftTimeFormatted, '09:30 AM - 06:30 PM');
        expect(state.gracePeriodMinutes, 15);
        expect(state.expectedWorkingHoursFormatted, '09h 00m');
        expect(state.isLateArrival, isTrue);
        expect(state.assignedShift?.name, 'Morning Shift');
        expect(state.expectedWorkingHoursFormatted, '09h 00m');
        expect(state.workingProgressRatio, closeTo(0.744, 0.01));
      },
    );

    test(
      'EmployeeShortInfo.fromJson resolves full employee names correctly without fallback to company',
      () {
        // 1. Direct name
        final info1 = EmployeeShortInfo.fromJson({
          'id': 101,
          'employeeCode': 'EMP-001',
          'name': 'Avinash Magar',
        });
        expect(info1.name, 'Avinash Magar');
        expect(info1.employeeCode, 'EMP-001');

        // 2. Separate firstName and lastName
        final info2 = EmployeeShortInfo.fromJson({
          'id': 102,
          'employeeCode': 'EMP-002',
          'firstName': 'Priya',
          'lastName': 'Sharma',
        });
        expect(info2.name, 'Priya Sharma');
        expect(info2.employeeCode, 'EMP-002');

        // 3. Only firstName
        final info3 = EmployeeShortInfo.fromJson({
          'id': 103,
          'code': 'EMP-003',
          'firstName': 'Rahul',
        });
        expect(info3.name, 'Rahul');
        expect(info3.employeeCode, 'EMP-003');
      },
    );

    test(
      'AssignedOffice accurately detects out-of-radius coordinates from real GPS',
      () {
        final office = AssignedOffice(
          id: 1,
          name: 'Head Office',
          city: 'Navi Mumbai',
          latitude: 19.0330,
          longitude: 73.0297,
          radiusMeters: 200.0,
        );

        // User reported coordinates: 19.1025537, 73.0086512
        final actualDistance = office.distanceTo(19.1025537, 73.0086512);

        // Distance should be ~8000m (8km), NEVER 0m
        expect(actualDistance, greaterThan(7000.0));
        expect(actualDistance, lessThan(9000.0));
        expect(actualDistance <= office.radiusMeters, isFalse);
      },
    );

    test(
      'AppDateFormatter formats UTC ISO timestamps identically across Home and Attendance Logs',
      () {
        // Reported scenario: 2026-09-01T13:44:00.000Z (which is 07:14 PM in Asia/Kolkata +05:30)
        const isoTimestamp = '2026-09-01T13:44:00.000Z';

        // 1. Home Screen Status
        final statusDetails = AttendanceStatusDetails.fromJson({
          'isPunchedIn': true,
          'isOnBreak': false,
          'punchInTime': isoTimestamp,
          'punchOutTime': null,
          'workingHours': 0.0,
          'breakDuration': 0.0,
          'rawStatus': 'PRESENT',
        });
        final homeState = AttendanceState(
          status: MyAttendanceStatus(status: statusDetails),
        );

        // 2. Attendance Logs Item
        final logItem = AttendanceLogItem.fromJson({
          'id': '101',
          'date': '2026-09-01',
          'punchIn': isoTimestamp,
          'punchOut': null,
          'workingHours': '0h 0m',
          'status': 'PRESENT',
        });

        // Both must match each other and be non-empty
        expect(homeState.punchInTimeFormatted, isNotEmpty);
        expect(logItem.checkIn, isNotEmpty);
        expect(homeState.punchInTimeFormatted, equals(logItem.checkIn));
      },
    );

    test(
      'AppDateFormatter safely handles already formatted strings without double conversion',
      () {
        expect(AppDateFormatter.formatAttendanceTime('07:14 PM'), '07:14 PM');
        expect(AppDateFormatter.formatAttendanceTime('7:14 am'), '07:14 AM');
        expect(AppDateFormatter.formatAttendanceTime('19:14'), '07:14 PM');
        expect(AppDateFormatter.formatAttendanceTime('09:30'), '09:30 AM');
        expect(AppDateFormatter.formatAttendanceTime(null), '--:--');
        expect(AppDateFormatter.formatAttendanceTime('—'), '--:--');
      },
    );

    test(
      'AppDateFormatter.formatDurationHoursMinutes formats minutes and edge cases correctly into Xh Ym',
      () {
        expect(AppDateFormatter.formatDurationHoursMinutes(0), '0h 0m');
        expect(AppDateFormatter.formatDurationHoursMinutes(1), '0h 1m');
        expect(AppDateFormatter.formatDurationHoursMinutes(30), '0h 30m');
        expect(AppDateFormatter.formatDurationHoursMinutes(59), '0h 59m');
        expect(AppDateFormatter.formatDurationHoursMinutes(60), '1h 0m');
        expect(AppDateFormatter.formatDurationHoursMinutes(61), '1h 1m');
        expect(AppDateFormatter.formatDurationHoursMinutes(90), '1h 30m');
        expect(AppDateFormatter.formatDurationHoursMinutes(119), '1h 59m');
        expect(AppDateFormatter.formatDurationHoursMinutes(120), '2h 0m');
        expect(AppDateFormatter.formatDurationHoursMinutes(125), '2h 5m');
        expect(AppDateFormatter.formatDurationHoursMinutes('90 min'), '1h 30m');
        expect(AppDateFormatter.formatDurationHoursMinutes('1h 30m'), '1h 30m');
        expect(AppDateFormatter.formatDurationHoursMinutes(null), '0h 0m');
      },
    );

    test(
      'AttendanceLogItem and Home State match on working duration and break duration',
      () {
        // API returns 480 net working minutes (8h 0m) and 60 total break minutes (1h 0m)
        final statusDetails = AttendanceStatusDetails.fromJson({
          'isPunchedIn': false,
          'isOnBreak': false,
          'punchInTime': '2026-09-01T04:00:00.000Z',
          'punchOutTime': '2026-09-01T13:00:00.000Z',
          'workingHours': 8.0,
          'breakDuration': 1.0,
          'rawStatus': 'PRESENT',
        });
        final homeState = AttendanceState(
          status: MyAttendanceStatus(status: statusDetails),
        );

        final logItem = AttendanceLogItem.fromJson({
          'id': '101',
          'date': '2026-09-01',
          'punchIn': '2026-09-01T04:00:00.000Z',
          'punchOut': '2026-09-01T13:00:00.000Z',
          'workingMinutes': 480,
          'totalBreakMinutes': 60,
          'status': 'PRESENT',
        });

        expect(homeState.workingHoursFormatted, equals(logItem.workingHours));
        expect(homeState.breakDurationFormatted, equals(logItem.breakDuration));
        expect(homeState.workingHoursFormatted, '8h 0m');
        expect(homeState.breakDurationFormatted, '1h 0m');
      },
    );
  });
}
