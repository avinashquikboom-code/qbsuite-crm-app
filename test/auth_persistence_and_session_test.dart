import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/models/user_role.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SecureStorageService.clearMockValues();
  });

  tearDown(() {
    SecureStorageService.clearMockValues();
  });

  group('Auth Persistence & Session Restoration Tests', () {
    test(
      'Scenario 1: App startup with valid non-expired access token restores authenticated session',
      () async {
        // Mock valid future-expiring JWT token
        // Payload: {"exp": 4102444800, "sub": 1, "role": "CUSTOMER"} (Year 2100)
        const validToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjQxMDI0NDQ4MDAsInN1YiI6MSwicm9sZSI6IkNVU1RPTUVSIn0.abcdef';
        const refreshToken = 'mock_refresh_token_12345';

        SecureStorageService.setMockInitialValues({
          'access_token': validToken,
          'refresh_token': refreshToken,
          'user_role': 'CUSTOMER',
          'user_email': 'customer@test.com',
          'customer_id': '11',
          'customer_name': 'Test Customer Company',
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Trigger initialization check
        await container.read(loginStateProvider.notifier).checkLoginStatus();

        final state = container.read(loginStateProvider);

        expect(state.isInitializing, isFalse);
        expect(state.isLoggedIn, isTrue);
        expect(state.role, equals(UserRole.customer));
        expect(state.customerId, equals('11'));
        expect(state.userEmail, equals('customer@test.com'));
        expect(state.customerName, equals('Test Customer Company'));
      },
    );

    test(
      'Scenario 2: Genuinely unauthenticated startup results in unauthenticated state without crashes',
      () async {
        SecureStorageService.setMockInitialValues({});

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(loginStateProvider.notifier).checkLoginStatus();

        final state = container.read(loginStateProvider);

        expect(state.isInitializing, isFalse);
        expect(state.isLoggedIn, isFalse);
        expect(state.role, isNull);
        expect(state.customerId, isNull);
      },
    );

    test(
      'Scenario 3: Explicit user logout clears storage and transitions state to unauthenticated',
      () async {
        const validToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjQxMDI0NDQ4MDAsInN1YiI6MSwicm9sZSI6IkNVU1RPTUVSIn0.abcdef';

        SecureStorageService.setMockInitialValues({
          'access_token': validToken,
          'refresh_token': 'refresh_token_123',
          'user_role': 'CUSTOMER',
          'customer_id': '11',
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(loginStateProvider.notifier).checkLoginStatus();
        expect(container.read(loginStateProvider).isLoggedIn, isTrue);

        // Perform explicit user logout
        await container.read(loginStateProvider.notifier).logout();

        final state = container.read(loginStateProvider);
        expect(state.isLoggedIn, isFalse);

        final storedToken = await SecureStorageService.getAccessToken();
        expect(storedToken, isNull);
      },
    );

    test(
      'Scenario 4: Multi-tier storage persistence survives reads and writes',
      () async {
        await SecureStorageService.saveTokens(
          accessToken: 'access_abc_123',
          refreshToken: 'refresh_xyz_456',
        );

        await SecureStorageService.saveUserData(
          userId: 42,
          role: 'CUSTOMER',
          email: 'customer@brand.com',
          customerId: '99',
          customerName: 'Brand Retail',
        );

        expect(
          await SecureStorageService.getAccessToken(),
          equals('access_abc_123'),
        );
        expect(
          await SecureStorageService.getRefreshToken(),
          equals('refresh_xyz_456'),
        );
        expect(await SecureStorageService.getUserId(), equals(42));
        expect(await SecureStorageService.getUserRole(), equals('CUSTOMER'));
        expect(await SecureStorageService.getCustomerId(), equals('99'));
        expect(
          await SecureStorageService.getCustomerName(),
          equals('Brand Retail'),
        );
      },
    );
  });
}
