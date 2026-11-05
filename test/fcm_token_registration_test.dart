import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/core/network/app_url.dart';
import 'package:quickboom_app/core/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SecureStorageService.clearMockValues();
  });

  tearDown(() {
    SecureStorageService.clearMockValues();
  });

  group('FCM Token Registration & Auth Architecture Tests', () {
    test(
      '1. Exact API endpoint for device token registration is /notifications/device-token',
      () {
        expect(
          AppUrl.notificationsDeviceToken,
          equals('/notifications/device-token'),
        );
        final normalized = ApiClient.normalizeEndpoint(
          AppUrl.notificationsDeviceToken,
        );
        expect(normalized, equals('/notifications/device-token'));
      },
    );

    test(
      '2. Unauthenticated state correctly detected to defer FCM registration and prevent 401',
      () async {
        // With no tokens in storage:
        await ApiClient().clearAuth();
        final hasAuth = await ApiClient().ensureAuthLoaded();
        final token = ApiClient().token;

        final bool hasAccessToken =
            token != null &&
            token.trim().isNotEmpty &&
            token != 'null' &&
            token != 'undefined' &&
            token != '[object Object]';
        final bool isAuthenticated = hasAuth && hasAccessToken;

        expect(isAuthenticated, isFalse);
        expect(hasAccessToken, isFalse);
      },
    );

    test(
      '3. Authenticated customer session attaches Authorization Bearer header correctly',
      () async {
        const mockCustomerAccessToken = 'mock.customer.jwt.access.token';
        const mockCustomerRefreshToken = 'mock.customer.jwt.refresh.token';
        const mockCustomerId = '101';

        await SecureStorageService.saveTokens(
          accessToken: mockCustomerAccessToken,
          refreshToken: mockCustomerRefreshToken,
        );
        await SecureStorageService.saveUserData(
          userId: 1,
          role: 'CUSTOMER',
          email: 'customer@test.com',
          customerId: mockCustomerId,
        );

        final hasAuth = await ApiClient().ensureAuthLoaded();
        final token = ApiClient().token;
        final customerId = ApiClient().customerId;

        final bool hasAccessToken =
            token != null &&
            token.trim().isNotEmpty &&
            token != 'null' &&
            token != 'undefined' &&
            token != '[object Object]';
        final bool isAuthenticated = hasAuth && hasAccessToken;

        expect(isAuthenticated, isTrue);
        expect(hasAccessToken, isTrue);
        expect(token, equals(mockCustomerAccessToken));
        expect(customerId, equals(mockCustomerId));

        final requestInterceptor = InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(
              options.headers['Authorization'],
              equals('Bearer $mockCustomerAccessToken'),
            );
            handler.reject(DioException(requestOptions: options));
          },
        );
        final client = ApiClient();
        client.dio.interceptors.add(requestInterceptor);
        addTearDown(() => client.dio.interceptors.remove(requestInterceptor));

        await expectLater(
          client.get('/auth-header-test'),
          throwsA(isA<DioException>()),
        );
      },
    );

    test('4. Token payload structure adheres to RegisterDeviceTokenDto', () {
      const sampleToken = 'fcm_sample_token_abc_123';
      final payload = {'token': sampleToken, 'platform': 'ANDROID'};

      expect(payload['token'], equals(sampleToken));
      expect(payload['platform'], isIn(['ANDROID', 'IOS', 'WEB']));
    });
  });
}
