import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/roles/employee/views/notifications_view.dart';
import 'package:quickboom_app/roles/employee/services/employee_api_service.dart';

class _FakeEmployeeApiService extends Fake implements EmployeeApiService {
  List<Map<String, dynamic>> fakeNotifications = [];

  @override
  Future<List<Map<String, dynamic>>> getNotifications({
    int page = 1,
    bool unreadOnly = false,
  }) async {
    return fakeNotifications;
  }

  @override
  Future<void> markNotificationAsRead(String id) async {
    fakeNotifications = fakeNotifications.map((n) {
      if (n['id'].toString() == id) {
        final copy = Map<String, dynamic>.from(n);
        copy['isRead'] = true;
        copy['isUnread'] = false;
        return copy;
      }
      return n;
    }).toList();
  }

  @override
  Future<void> markAllNotificationsAsRead() async {
    fakeNotifications = fakeNotifications.map((n) {
      final copy = Map<String, dynamic>.from(n);
      copy['isRead'] = true;
      copy['isUnread'] = false;
      return copy;
    }).toList();
  }
}

void main() {
  late _FakeEmployeeApiService fakeService;

  setUp(() {
    fakeService = _FakeEmployeeApiService();
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [employeeApiServiceProvider.overrideWithValue(fakeService)],
      child: const MaterialApp(home: NotificationsView()),
    );
  }

  group('Notifications Icon Animation Tests', () {
    testWidgets(
      'Unread notification displays bell icon and does not show technical type text',
      (tester) async {
        fakeService.fakeNotifications = [
          {
            'id': '101',
            'type': 'LEAVE_APPROVED',
            'title': 'Leave Request Approved',
            'message':
                'Your Casual Leave request for 2026-09-21 has been approved.',
            'createdAt': '2026-09-17T10:25:00.000Z',
            'isRead': false,
          },
        ];

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // 1. Bell icon is visible
        expect(find.byIcon(Remix.notification_3_line), findsOneWidget);

        // 2. Technical type text is NOT displayed
        expect(find.text('LEAVE_APPROVED'), findsNothing);

        // 3. Title, message, and formatted date are present
        expect(find.text('Leave Request Approved'), findsOneWidget);
        expect(
          find.text(
            'Your Casual Leave request for 2026-09-21 has been approved.',
          ),
          findsOneWidget,
        );

        // 4. Animation swings over time
        final initialTransform = tester.widget<Transform>(
          find.byType(Transform).last,
        );
        await tester.pump(const Duration(milliseconds: 300));
        final nextTransform = tester.widget<Transform>(
          find.byType(Transform).last,
        );

        expect(
          initialTransform.transform,
          isNot(equals(nextTransform.transform)),
        );
      },
    );

    testWidgets(
      'Read notification has static icon without ongoing rotation animation',
      (tester) async {
        fakeService.fakeNotifications = [
          {
            'id': '102',
            'type': 'CALENDAR_SCHEDULE_REMINDER',
            'title': "Tomorrow's Schedule: Reel #2: Shoot",
            'message':
                'Reminder: You are scheduled for Reel #2 Shoot tomorrow.',
            'createdAt': '2026-09-16T18:00:00.000Z',
            'isRead': true,
          },
        ];

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Bell icon is present
        expect(find.byIcon(Remix.notification_3_line), findsOneWidget);

        // Technical type text is NOT displayed
        expect(find.text('CALENDAR_SCHEDULE_REMINDER'), findsNothing);

        // No Transform.rotate widget should be animating inside the icon
        // In read state, icon is rendered directly without animated rotation
        expect(find.byType(AnimatedBuilder), findsNothing);
      },
    );

    testWidgets(
      'Tapping unread notification marks it as read and stops bell animation',
      (tester) async {
        fakeService.fakeNotifications = [
          {
            'id': '103',
            'type': 'GENERAL',
            'title': 'New Update',
            'message': 'System updated successfully.',
            'createdAt': '2026-09-17T12:00:00.000Z',
            'isRead': false,
          },
        ];

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Starts with animation active
        expect(find.byType(AnimatedBuilder), findsOneWidget);

        // Tap the card to mark as read
        await tester.tap(find.text('New Update'));
        await tester.pumpAndSettle();

        // After marked as read, AnimatedBuilder is stopped and removed
        expect(find.byType(AnimatedBuilder), findsNothing);
      },
    );
  });
}
