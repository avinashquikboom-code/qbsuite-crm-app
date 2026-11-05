import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/models/permission_model.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';

void main() {
  group('Employee Calendar RBAC & Permission Tests', () {
    test('PermissionState recognizes CALENDAR with VIEW, READ, MANAGE, ALL, *', () {
      // 1. Explicit VIEW
      final stateView = PermissionState(
        permissions: const [
          UserPermission(module: 'CALENDAR', action: 'VIEW'),
        ],
        role: 'EMPLOYEE',
        employeeId: 'EMP-001',
      );
      expect(stateView.canViewCalendar, isTrue);

      // 2. READ action
      final stateRead = PermissionState(
        permissions: const [
          UserPermission(module: 'CALENDAR', action: 'READ'),
        ],
        role: 'EMPLOYEE',
      );
      expect(stateRead.canViewCalendar, isTrue);

      // 3. MANAGE action
      final stateManage = PermissionState(
        permissions: const [
          UserPermission(module: 'CALENDAR', action: 'MANAGE'),
        ],
        role: 'EMPLOYEE',
      );
      expect(stateManage.canViewCalendar, isTrue);

      // 4. Wildcard * action
      final stateWildcard = PermissionState(
        permissions: const [
          UserPermission(module: 'CALENDAR', action: '*'),
        ],
        role: 'EMPLOYEE',
      );
      expect(stateWildcard.canViewCalendar, isTrue);

      // 5. ALL action
      final stateAll = PermissionState(
        permissions: const [
          UserPermission(module: 'CALENDAR', action: 'ALL'),
        ],
        role: 'EMPLOYEE',
      );
      expect(stateAll.canViewCalendar, isTrue);

      // 6. When calendar is not permitted
      final stateNoCalendar = PermissionState(
        permissions: const [
          UserPermission(module: 'ATTENDANCE', action: 'VIEW'),
        ],
        role: 'EMPLOYEE',
      );
      expect(stateNoCalendar.canViewCalendar, isFalse);
    });

    test('UserPermission.parseAny normalizes and deduplicates varied backend calendar strings', () {
      final parsed = UserPermission.parseAny([
        'employee.calendar.view',
        'CALENDAR:VIEW',
        'calendars:manage',
        'schedule:read',
      ]);

      // All 4 strings normalize to module CALENDAR.
      // 3 of them ('employee.calendar.view', 'CALENDAR:VIEW', 'schedule:read') normalize to action VIEW and deduplicate.
      // 'calendars:manage' normalizes to action MANAGE.
      expect(parsed.length, equals(2));
      for (final p in parsed) {
        expect(p.module, equals(AppModule.calendar));
      }
      expect(parsed.any((p) => p.action == 'VIEW'), isTrue);
      expect(parsed.any((p) => p.action == 'MANAGE'), isTrue);
    });
  });

  group('Calendar Date String & Activity Normalization', () {
    test('CustomerCalendarActivity normalizes rawScheduledDateStr from ISO format', () {
      final jsonWithIsoDate = {
        'id': 'act-1',
        'title': 'Site Visit',
        'scheduledDate': '2026-10-05T09:30:00.000Z',
        'startTime': '09:30',
        'endTime': '10:30',
        'status': 'SCHEDULED',
        'customerName': 'Acme Corp',
        'businessName': 'Acme Business',
      };

      final activity = CustomerCalendarActivity.fromJson(jsonWithIsoDate);
      expect(getScheduledDateString(activity), equals('2026-10-05'));
    });

    test('Calendar date generation creates 7 valid calendar dates without DST drift', () {
      final now = DateTime(2026, 10, 2);
      final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day + i));

      expect(days.length, equals(7));
      expect(days.first.day, equals(2));
      expect(days.last.day, equals(8));
      for (final d in days) {
        expect(normalizeDate(d), matches(r'^\d{4}-\d{2}-\d{2}$'));
      }
    });
  });
}
