import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickboom_app/core/models/user_role.dart';
import 'package:quickboom_app/core/services/secure_storage_service.dart';
import 'package:quickboom_app/core/services/auth_service.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/roles/employee/views/dashboard_view.dart';
import 'package:quickboom_app/roles/company_admin/views/company_admin_main_view.dart';
import 'package:quickboom_app/main.dart';

class MockLoginNotifier extends LoginStateNotifier {
  final LoginState _initial;
  MockLoginNotifier(this._initial);

  @override
  LoginState build() => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'quikboom_onboarding_completed': true,
    });
  });

  group('UserRole Enum & Normalization Tests', () {
    test('UserRole.fromString correctly normalizes variations of Customer', () {
      expect(UserRole.fromString('CUSTOMER'), UserRole.customer);
      expect(UserRole.fromString('customer'), UserRole.customer);
      expect(UserRole.fromString('Customer'), UserRole.customer);
      expect(UserRole.fromString('CUSTOMER_ADMIN'), UserRole.customer);
      expect(UserRole.fromString('customer_admin'), UserRole.customer);
      expect(UserRole.fromString('Customer Administrator'), UserRole.customer);
      expect(UserRole.fromString('client'), UserRole.customer);
    });

    test('UserRole.fromString correctly normalizes variations of Employee', () {
      expect(UserRole.fromString('EMPLOYEE'), UserRole.employee);
      expect(UserRole.fromString('employee'), UserRole.employee);
      expect(UserRole.fromString('Employee'), UserRole.employee);
      expect(UserRole.fromString('staff'), UserRole.employee);
      expect(UserRole.fromString('sales_executive'), UserRole.employee);
      expect(UserRole.fromString('sales_manager'), UserRole.employee);
    });

    test(
      'UserRole.fromString correctly normalizes variations of Company Admin',
      () {
        expect(UserRole.fromString('ADMIN'), UserRole.companyAdmin);
        expect(UserRole.fromString('admin'), UserRole.companyAdmin);
        expect(UserRole.fromString('SUPER_ADMIN'), UserRole.companyAdmin);
        expect(UserRole.fromString('super_admin'), UserRole.companyAdmin);
        expect(UserRole.fromString('company_admin'), UserRole.companyAdmin);
        expect(UserRole.fromString('COMPANYADMIN'), UserRole.companyAdmin);
      },
    );

    test(
      'UserRole.fromString throws ArgumentError for unrecognized strings without defaulting to Employee',
      () {
        expect(() => UserRole.fromString(null), throwsArgumentError);
        expect(() => UserRole.fromString(''), throwsArgumentError);
        expect(
          () => UserRole.fromString('xyz_unknown_role'),
          throwsArgumentError,
        );
      },
    );

    test(
      'UserRole.tryParse returns null on invalid role without defaulting to Employee',
      () {
        expect(UserRole.tryParse(null), isNull);
        expect(UserRole.tryParse(''), isNull);
        expect(UserRole.tryParse('invalid_role'), isNull);
        expect(UserRole.tryParse('customer'), UserRole.customer);
        expect(UserRole.tryParse('employee'), UserRole.employee);
        expect(UserRole.tryParse('company_admin'), UserRole.companyAdmin);
      },
    );
  });

  group('SecureStorageService Tests', () {
    test('saveTokens and readTokens work properly', () async {
      await SecureStorageService.saveTokens(
        accessToken: 'test-jwt-access-token',
        refreshToken: 'test-jwt-refresh-token',
      );

      final accessToken = await SecureStorageService.getAccessToken();
      final refreshToken = await SecureStorageService.getRefreshToken();

      expect(accessToken, 'test-jwt-access-token');
      expect(refreshToken, 'test-jwt-refresh-token');
    });

    test('saveUserData and read methods work properly', () async {
      await SecureStorageService.saveUserData(
        userId: 42,
        role: 'CUSTOMER',
        email: 'customer@example.com',
        customerId: 'CUST-900829843',
        customerName: 'Care Fitness Gym',
      );

      final role = await SecureStorageService.getUserRole();
      final email = await SecureStorageService.getUserEmail();
      final customerId = await SecureStorageService.getCustomerId();
      final customerName = await SecureStorageService.getCustomerName();
      final userId = await SecureStorageService.getUserId();

      expect(role, 'CUSTOMER');
      expect(email, 'customer@example.com');
      expect(customerId, 'CUST-900829843');
      expect(customerName, 'Care Fitness Gym');
      expect(userId, 42);
    });

    test('Customer login purges stale employeeId and employeeCode', () async {
      // Step 1: Employee login saves employee data
      await SecureStorageService.saveUserData(
        userId: 99,
        role: 'EMPLOYEE',
        email: 'employee@example.com',
        customerId: 'CUST-1',
        employeeId: 'EMP-001',
        employeeCode: 'EMP-001',
      );

      expect(await SecureStorageService.getEmployeeId(), 'EMP-001');
      expect(await SecureStorageService.getEmployeeCode(), 'EMP-001');

      // Step 2: Customer logs in without employeeId/employeeCode
      await SecureStorageService.saveUserData(
        userId: 42,
        role: 'CUSTOMER',
        email: 'customer@example.com',
        customerId: 'CUST-900829843',
        customerName: 'Care Fitness Gym',
        employeeId: null,
        employeeCode: null,
      );

      expect(await SecureStorageService.getUserRole(), 'CUSTOMER');
      expect(await SecureStorageService.getEmployeeId(), isNull);
      expect(await SecureStorageService.getEmployeeCode(), isNull);
    });

    test('clearAll wipes tokens and user data cleanly', () async {
      await SecureStorageService.saveTokens(
        accessToken: 'test-token',
        refreshToken: 'test-refresh',
      );
      await SecureStorageService.saveUserData(
        userId: 1,
        role: 'COMPANY_ADMIN',
        email: 'admin@quikboom.com',
        customerId: 'CUST-1',
      );

      await SecureStorageService.clearAll();

      final accessToken = await SecureStorageService.getAccessToken();
      final refreshToken = await SecureStorageService.getRefreshToken();
      final role = await SecureStorageService.getUserRole();
      final email = await SecureStorageService.getUserEmail();

      expect(accessToken, isNull);
      expect(refreshToken, isNull);
      expect(role, isNull);
      expect(email, isNull);
    });
  });

  group('Auth Models & Response Parsing Tests', () {
    test(
      'LoginResponse parses nested tokens and user with UserRole.customer correctly',
      () {
        final json = {
          'statusCode': 200,
          'data': {
            'tokens': {
              'accessToken': 'jwt.access.123',
              'refreshToken': 'jwt.refresh.456',
            },
            'user': {
              'id': 10,
              'email': 'carefitness@example.com',
              'firstName': 'Care',
              'lastName': 'Fitness',
              'role': 'CUSTOMER',
              'customerId': 'CUST-900829843',
              'customerName': 'Care Fitness Gym',
            },
          },
        };

        final response = LoginResponse.fromJson(json);

        expect(response.accessToken, 'jwt.access.123');
        expect(response.refreshToken, 'jwt.refresh.456');
        expect(response.user.id, 10);
        expect(response.user.email, 'carefitness@example.com');
        expect(response.user.role, 'CUSTOMER');
        expect(
          UserRoleExtension.fromString(response.user.role),
          UserRole.customer,
        );
        expect(response.user.customerId, 'CUST-900829843');
      },
    );

    test('LoginResponse parses employee user correctly', () {
      final json = {
        'statusCode': 200,
        'data': {
          'tokens': {
            'accessToken': 'jwt.access.emp',
            'refreshToken': 'jwt.refresh.emp',
          },
          'user': {
            'id': 15,
            'email': 'emp@example.com',
            'firstName': 'John',
            'lastName': 'Doe',
            'role': 'EMPLOYEE',
            'customerId': 'CUST-1',
            'employeeId': 'QB-EMP-001',
          },
        },
      };

      final response = LoginResponse.fromJson(json);

      expect(response.user.role, 'EMPLOYEE');
      expect(
        UserRoleExtension.fromString(response.user.role),
        UserRole.employee,
      );
      expect(response.user.email, 'emp@example.com');
    });

    test(
      'LoginResponse parses flat token format with admin role correctly',
      () {
        final json = {
          'data': {
            'accessToken': 'jwt.access.flat',
            'refreshToken': 'jwt.refresh.flat',
            'user': {
              'id': 20,
              'email': 'admin@quikboom.com',
              'role': 'SUPER_ADMIN',
            },
          },
        };

        final response = LoginResponse.fromJson(json);

        expect(response.accessToken, 'jwt.access.flat');
        expect(response.refreshToken, 'jwt.refresh.flat');
        expect(response.user.id, 20);
        expect(response.user.role, 'SUPER_ADMIN');
        expect(
          UserRoleExtension.fromString(response.user.role),
          UserRole.companyAdmin,
        );
      },
    );
  });

  group('Role-Based Session Restoration & Switching Tests', () {
    test(
      'Customer login -> session restore across app restart -> UserRole.customer',
      () async {
        await SecureStorageService.saveTokens(
          accessToken: 'saved-token',
          refreshToken: 'saved-refresh',
        );
        await SecureStorageService.saveUserData(
          userId: 5,
          role: 'CUSTOMER',
          email: 'saved@example.com',
          customerId: 'customer-1787665156632',
          customerName: 'Care Fitness Gym',
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(loginStateProvider.notifier).checkLoginStatus();

        final state = container.read(loginStateProvider);
        expect(state.isInitializing, false);
        expect(state.isLoggedIn, true);
        expect(state.role, UserRole.customer);
        expect(state.userRole, 'CUSTOMER');
        expect(state.userEmail, 'saved@example.com');
        expect(state.customerId, 'customer-1787665156632');
        expect(state.customerName, 'Care Fitness Gym');
      },
    );

    test(
      'Employee login -> session restore across app restart -> UserRole.employee',
      () async {
        await SecureStorageService.saveTokens(
          accessToken: 'emp-saved-token',
          refreshToken: 'emp-saved-refresh',
        );
        await SecureStorageService.saveUserData(
          userId: 12,
          role: 'EMPLOYEE',
          email: 'emp@example.com',
          customerId: 'CUST-10',
          employeeId: 'QB-EMP-012',
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(loginStateProvider.notifier).checkLoginStatus();

        final state = container.read(loginStateProvider);
        expect(state.isInitializing, false);
        expect(state.isLoggedIn, true);
        expect(state.role, UserRole.employee);
        expect(state.userRole, 'EMPLOYEE');
      },
    );

    test(
      'Company Admin login -> session restore across app restart -> UserRole.companyAdmin',
      () async {
        await SecureStorageService.saveTokens(
          accessToken: 'saved-admin-token',
          refreshToken: 'saved-admin-refresh',
        );
        await SecureStorageService.saveUserData(
          userId: 1,
          role: 'COMPANY_ADMIN',
          email: 'admin@company.com',
          customerId: 'CUST-ADMIN',
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(loginStateProvider.notifier).checkLoginStatus();

        final state = container.read(loginStateProvider);
        expect(state.isLoggedIn, true);
        expect(state.role, UserRole.companyAdmin);
        expect(state.userRole, 'COMPANY_ADMIN');
      },
    );

    test(
      'Role switching: Customer login -> logout -> Employee login -> logout -> Company Admin login',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Customer Login
        await SecureStorageService.saveTokens(
          accessToken: 'token-cust',
          refreshToken: 'refresh-cust',
        );
        await SecureStorageService.saveUserData(
          userId: 1,
          role: 'CUSTOMER',
          email: 'customer@crm.com',
          customerId: 'CUST-1',
        );
        await container.read(loginStateProvider.notifier).checkLoginStatus();
        expect(container.read(loginStateProvider).role, UserRole.customer);

        // Logout Customer
        await container.read(loginStateProvider.notifier).logout();
        expect(container.read(loginStateProvider).isLoggedIn, false);
        expect(container.read(loginStateProvider).role, isNull);

        // Employee Login
        await SecureStorageService.saveTokens(
          accessToken: 'token-emp',
          refreshToken: 'refresh-emp',
        );
        await SecureStorageService.saveUserData(
          userId: 2,
          role: 'EMPLOYEE',
          email: 'employee@crm.com',
          customerId: 'CUST-1',
          employeeId: 'EMP-001',
        );
        await container.read(loginStateProvider.notifier).checkLoginStatus();
        expect(container.read(loginStateProvider).role, UserRole.employee);

        // Logout Employee
        await container.read(loginStateProvider.notifier).logout();
        expect(container.read(loginStateProvider).isLoggedIn, false);
        expect(container.read(loginStateProvider).role, isNull);

        // Company Admin Login
        await SecureStorageService.saveTokens(
          accessToken: 'token-admin',
          refreshToken: 'refresh-admin',
        );
        await SecureStorageService.saveUserData(
          userId: 3,
          role: 'COMPANY_ADMIN',
          email: 'admin@crm.com',
          customerId: 'CUST-ADMIN',
        );
        await container.read(loginStateProvider.notifier).checkLoginStatus();
        expect(container.read(loginStateProvider).role, UserRole.companyAdmin);
      },
    );

    test('Strict Role Matrix: Role mismatch rejection validation', () {
      // Helper function simulating backend role check
      String? validateLoginRole(UserRole requestedRole, UserRole actualDbRole) {
        if (requestedRole != actualDbRole) {
          switch (requestedRole) {
            case UserRole.customer:
              return 'These credentials are not registered as a Customer account.';
            case UserRole.employee:
              return 'These credentials are not registered as an Employee account.';
            case UserRole.companyAdmin:
              return 'These credentials are not registered as a Company Admin account.';
          }
        }
        return null; // Allowed
      }

      // Customer Requested
      expect(validateLoginRole(UserRole.customer, UserRole.customer), isNull);
      expect(
        validateLoginRole(UserRole.customer, UserRole.employee),
        'These credentials are not registered as a Customer account.',
      );
      expect(
        validateLoginRole(UserRole.customer, UserRole.companyAdmin),
        'These credentials are not registered as a Customer account.',
      );

      // Employee Requested
      expect(validateLoginRole(UserRole.employee, UserRole.employee), isNull);
      expect(
        validateLoginRole(UserRole.employee, UserRole.customer),
        'These credentials are not registered as an Employee account.',
      );
      expect(
        validateLoginRole(UserRole.employee, UserRole.companyAdmin),
        'These credentials are not registered as an Employee account.',
      );

      // Company Admin Requested
      expect(
        validateLoginRole(UserRole.companyAdmin, UserRole.companyAdmin),
        isNull,
      );
      expect(
        validateLoginRole(UserRole.companyAdmin, UserRole.customer),
        'These credentials are not registered as a Company Admin account.',
      );
      expect(
        validateLoginRole(UserRole.companyAdmin, UserRole.employee),
        'These credentials are not registered as a Company Admin account.',
      );
    });
  });

  group('MyApp Root Navigation Shell Selection Tests', () {
    testWidgets('Employee role renders DashboardView in MyApp', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginStateProvider.overrideWith(
              () => MockLoginNotifier(
                LoginState(
                  isInitializing: false,
                  isLoggedIn: true,
                  role: UserRole.employee,
                  userRole: 'EMPLOYEE',
                ),
              ),
            ),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardView), findsOneWidget);
      expect(find.byType(CompanyAdminMainView), findsNothing);
    });

    testWidgets('Company Admin role renders CompanyAdminMainView in MyApp', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginStateProvider.overrideWith(
              () => MockLoginNotifier(
                LoginState(
                  isInitializing: false,
                  isLoggedIn: true,
                  role: UserRole.companyAdmin,
                  userRole: 'COMPANY_ADMIN',
                ),
              ),
            ),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CompanyAdminMainView), findsOneWidget);
      expect(find.byType(DashboardView), findsNothing);
    });
  });
}
