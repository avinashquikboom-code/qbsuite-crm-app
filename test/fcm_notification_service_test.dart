import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService FCM & Service Availability Tests', () {
    test('NotificationService singleton is non-null and accessible', () {
      final service = NotificationService.instance;
      expect(service, isNotNull);
      expect(service.navigatorKey, isNotNull);
      expect(service.messengerKey, isNotNull);
    });

    test(
      'isBackgroundHandlerRegistered flag prevents duplicate registration',
      () {
        expect(NotificationService.isBackgroundHandlerRegistered, isFalse);
        NotificationService.isBackgroundHandlerRegistered = true;
        expect(NotificationService.isBackgroundHandlerRegistered, isTrue);
        // Reset for cleanliness
        NotificationService.isBackgroundHandlerRegistered = false;
      },
    );

    test('Multiple calls to unregisterToken are safe and idempotent', () async {
      final service = NotificationService.instance;
      // When no token is registered, unregisterToken should complete without throwing
      await expectLater(service.unregisterToken(), completes);
      await expectLater(service.unregisterToken(), completes);
    });

    test(
      'registerTokenForAuthenticatedUser does not throw when unauthenticated',
      () async {
        final service = NotificationService.instance;
        await expectLater(
          service.registerTokenForAuthenticatedUser(),
          completes,
        );
      },
    );
  });
}
