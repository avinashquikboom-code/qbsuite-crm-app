import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/shared/widgets/animated_notification_bell.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_notification_viewmodel.dart';

class _MockNotificationNotifier extends EmployeeNotificationNotifier {
  final NotificationState _initial;
  _MockNotificationNotifier(this._initial);

  @override
  NotificationState build() => _initial;

  void updateCount(int count) {
    state = state.copyWith(unreadCount: count);
  }
}

void main() {
  group('Home AppBar Notification Bell Animation Tests', () {
    testWidgets(
      '1. 0 unread notifications shows static bell without rotation',
      (tester) async {
        final notifier = _MockNotificationNotifier(
          const NotificationState(isLoading: false, unreadCount: 0),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              employeeNotificationProvider.overrideWith(() => notifier),
            ],
            child: MaterialApp(
              home: Scaffold(
                appBar: AppBar(
                  actions: [AnimatedNotificationBell(onPressed: () {})],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify bell icon is present
        expect(find.byIcon(Remix.notification_3_line), findsOneWidget);

        // Verify rotation transform is at 0.0
        final transformFinder = find.ancestor(
          of: find.byIcon(Remix.notification_3_line),
          matching: find.byType(Transform),
        );
        final transform = tester.widget<Transform>(transformFinder);
        expect(transform.transform, equals(Matrix4.identity()));

        // Advance time and verify it remains static at 0.0
        await tester.pump(const Duration(milliseconds: 200));
        final transformAfter = tester.widget<Transform>(transformFinder);
        expect(transformAfter.transform, equals(Matrix4.identity()));
      },
    );

    testWidgets(
      '2. 1+ unread notifications automatically starts smooth shake animation on mount',
      (tester) async {
        final notifier = _MockNotificationNotifier(
          const NotificationState(isLoading: false, unreadCount: 3),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              employeeNotificationProvider.overrideWith(() => notifier),
            ],
            child: MaterialApp(
              home: Scaffold(
                appBar: AppBar(
                  actions: [AnimatedNotificationBell(onPressed: () {})],
                ),
              ),
            ),
          ),
        );

        await tester.pump(); // trigger post frame callback

        final transformFinder = find.ancestor(
          of: find.byIcon(Remix.notification_3_line),
          matching: find.byType(Transform),
        );

        // Advance 100ms into the swing sequence
        await tester.pump(const Duration(milliseconds: 100));
        final transformAt100 = tester.widget<Transform>(transformFinder);

        // Rotation is non-zero (bell is shaking)
        expect(transformAt100.transform, isNot(equals(Matrix4.identity())));

        // Advance further to opposite swing
        await tester.pump(const Duration(milliseconds: 150));
        final transformAt250 = tester.widget<Transform>(transformFinder);
        expect(
          transformAt250.transform,
          isNot(equals(transformAt100.transform)),
        );
      },
    );

    testWidgets(
      '3. New notification arriving triggers animation automatically',
      (tester) async {
        final notifier = _MockNotificationNotifier(
          const NotificationState(isLoading: false, unreadCount: 0),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              employeeNotificationProvider.overrideWith(() => notifier),
            ],
            child: MaterialApp(
              home: Scaffold(
                appBar: AppBar(
                  actions: [AnimatedNotificationBell(onPressed: () {})],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final transformFinder = find.ancestor(
          of: find.byIcon(Remix.notification_3_line),
          matching: find.byType(Transform),
        );

        // Initially static
        expect(
          tester.widget<Transform>(transformFinder).transform,
          equals(Matrix4.identity()),
        );

        // New notification arrives while Home is open
        notifier.updateCount(1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Bell is now actively shaking
        expect(
          tester.widget<Transform>(transformFinder).transform,
          isNot(equals(Matrix4.identity())),
        );
      },
    );

    testWidgets(
      '4. Marking all notifications as read stops animation and resets to static',
      (tester) async {
        final notifier = _MockNotificationNotifier(
          const NotificationState(isLoading: false, unreadCount: 2),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              employeeNotificationProvider.overrideWith(() => notifier),
            ],
            child: MaterialApp(
              home: Scaffold(
                appBar: AppBar(
                  actions: [AnimatedNotificationBell(onPressed: () {})],
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final transformFinder = find.ancestor(
          of: find.byIcon(Remix.notification_3_line),
          matching: find.byType(Transform),
        );

        // Verify animating
        expect(
          tester.widget<Transform>(transformFinder).transform,
          isNot(equals(Matrix4.identity())),
        );

        // Notifications marked as read -> unreadCount becomes 0
        notifier.updateCount(0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Bell stops and resets to static identity
        expect(
          tester.widget<Transform>(transformFinder).transform,
          equals(Matrix4.identity()),
        );

        // Remains static after time passes
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          tester.widget<Transform>(transformFinder).transform,
          equals(Matrix4.identity()),
        );
      },
    );

    testWidgets('5. Pressing notification bell triggers onPressed callback', (
      tester,
    ) async {
      bool pressed = false;
      final notifier = _MockNotificationNotifier(
        const NotificationState(isLoading: false, unreadCount: 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            employeeNotificationProvider.overrideWith(() => notifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  AnimatedNotificationBell(onPressed: () => pressed = true),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.byTooltip('Notifications'));
      expect(pressed, isTrue);
    });
  });
}
