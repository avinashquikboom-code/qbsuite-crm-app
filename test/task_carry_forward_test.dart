import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';

void main() {
  group('Task Carry-Forward Unit Tests', () {
    test('Activity parsing correctly identifies carried forward task from notes tag', () {
      final json = {
        'id': '123',
        'customerId': '91',
        'customerName': 'Test Pvt Ltd',
        'businessName': 'Test Pvt Ltd',
        'title': 'Reel #1: Shoot',
        'scheduledDate': '2026-10-09',
        'scheduledTime': '10:00 AM',
        'status': 'ASSIGNED',
        'notes': '[ORIGINAL_SCHEDULE:2026-10-08] Originally scheduled: 08 Oct 2026\nClient requested outdoor shoot',
      };

      final activity = CustomerCalendarActivity.fromJson(json);

      expect(activity.id, '123');
      expect(activity.isCarriedForward, isTrue);
      expect(activity.originalScheduledDateDisplay, contains('08 Oct 2026'));
      expect(activity.scheduledDateStr, '2026-10-09');
      expect(activity.status, 'ASSIGNED');
    });

    test('Activity parsing correctly handles API explicit isCarriedForward and carryForwardNote', () {
      final json = {
        'id': '123',
        'customerId': '91',
        'customerName': 'Test Pvt Ltd',
        'businessName': 'Test Pvt Ltd',
        'title': 'Reel #1: Shoot',
        'scheduledDate': '2026-10-09',
        'scheduledTime': '10:00 AM',
        'status': 'IN_PROGRESS',
        'isCarriedForward': true,
        'originalScheduledDate': '2026-10-08',
        'carryForwardNote': 'Originally scheduled: 08 Oct 2026',
      };

      final activity = CustomerCalendarActivity.fromJson(json);

      expect(activity.id, '123');
      expect(activity.isCarriedForward, isTrue);
      expect(activity.originalScheduledDateDisplay, '08 Oct 2026');
      expect(activity.scheduledDateStr, '2026-10-09');
      expect(activity.status, 'IN_PROGRESS');
    });

    test('Non-carried forward tasks remain regular', () {
      final json = {
        'id': '124',
        'customerId': '91',
        'customerName': 'Test Pvt Ltd',
        'businessName': 'Test Pvt Ltd',
        'title': 'Reel #2: Shoot',
        'scheduledDate': '2026-10-09',
        'scheduledTime': '02:00 PM',
        'status': 'SCHEDULED',
        'notes': 'Normal notes without carry forward tag',
      };

      final activity = CustomerCalendarActivity.fromJson(json);

      expect(activity.id, '124');
      expect(activity.isCarriedForward, isFalse);
      expect(activity.originalScheduledDateDisplay, isNull);
    });
  });
}
