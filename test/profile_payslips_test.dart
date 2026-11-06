import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/roles/employee/models/employee_payroll_model.dart';
import 'package:quickboom_app/roles/employee/services/employee_api_service.dart';
import 'package:quickboom_app/roles/employee/views/profile_view.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/core/models/permission_model.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';

class MockEmployeeApiService extends Fake implements EmployeeApiService {
  List<SalarySlipItem> slipsToReturn = [];
  bool throwError = false;

  @override
  Future<List<SalarySlipItem>> getSalarySlips({
    int page = 1,
    int limit = 20,
  }) async {
    if (throwError) {
      throw Exception('Server error');
    }
    return slipsToReturn;
  }
}

class MockLoginStateNotifier extends LoginStateNotifier {
  @override
  LoginState build() {
    return LoginState(
      isInitializing: false,
      isLoggedIn: true,
      userName: 'John Doe',
      userEmail: 'john@example.com',
      employeeCode: 'EMP-001',
    );
  }
}

class TestPermissionNotifier extends PermissionNotifier {
  final bool allowSalary;
  TestPermissionNotifier({this.allowSalary = true});

  @override
  PermissionState build() {
    return PermissionState(
      isInitialized: true,
      permissions: allowSalary
          ? [const UserPermission(module: AppModule.salary, action: 'VIEW')]
          : [],
    );
  }
}

void main() {
  group('ProfileView Recent Payslips Tests', () {
    late MockEmployeeApiService mockService;

    setUp(() {
      mockService = MockEmployeeApiService();
    });

    testWidgets(
      'RBAC: when salary view permission is NOT granted, Recent Payslips section is completely hidden',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              loginStateProvider.overrideWith(() => MockLoginStateNotifier()),
              employeeApiServiceProvider.overrideWithValue(mockService),
              permissionManagerProvider.overrideWith(
                () => TestPermissionNotifier(allowSalary: false),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: ProfileView()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Recent Payslips'), findsNothing);
      },
    );

    testWidgets(
      'Empty state: when employee has 0 generated payslips, shows empty state and NO static July/June 2026 data',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        mockService.slipsToReturn = [];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              loginStateProvider.overrideWith(() => MockLoginStateNotifier()),
              employeeApiServiceProvider.overrideWithValue(mockService),
              permissionManagerProvider.overrideWith(
                () => TestPermissionNotifier(allowSalary: true),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: ProfileView()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Recent Payslips section header exists
        expect(find.text('Recent Payslips'), findsOneWidget);

        // Verify empty state is displayed
        expect(find.text('No payslips available yet.'), findsOneWidget);
        expect(
          find.text('Your generated payslips will appear here.'),
          findsOneWidget,
        );

        // Verify NO static/mock data
        expect(find.text('July 2026'), findsNothing);
        expect(find.text('June 2026'), findsNothing);
        expect(find.textContaining('47,000'), findsNothing);
        expect(find.textContaining('45,000'), findsNothing);
        expect(find.textContaining('Paid on 01 Aug'), findsNothing);
        expect(find.textContaining('Paid on 01 Jul'), findsNothing);
      },
    );

    testWidgets(
      'Populated state: shows real generated payslips from API and View All link',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        mockService.slipsToReturn = [
          SalarySlipItem(
            id: 'slip-1',
            month: 'August 2026',
            basicSalary: 30000,
            allowances: 10000,
            deductions: 2000,
            commission: 5000,
            netSalary: 52000.0,
            grossSalary: 55000.0,
            status: 'PAID',
            date: '2026-08-01',
            downloadUrl: 'https://example.com/slip-1.pdf',
          ),
          SalarySlipItem(
            id: 'slip-2',
            month: 'July 2026',
            basicSalary: 30000,
            allowances: 10000,
            deductions: 2000,
            commission: 5000,
            netSalary: 51000.0,
            grossSalary: 54000.0,
            status: 'PAID',
            date: '2026-07-01',
            downloadUrl: 'https://example.com/slip-2.pdf',
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              loginStateProvider.overrideWith(() => MockLoginStateNotifier()),
              employeeApiServiceProvider.overrideWithValue(mockService),
              permissionManagerProvider.overrideWith(
                () => TestPermissionNotifier(allowSalary: true),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: ProfileView()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Recent Payslips'), findsOneWidget);
        expect(find.text('View All'), findsOneWidget);
        expect(find.text('August 2026'), findsOneWidget);
        expect(find.text('July 2026'), findsOneWidget);
        expect(find.text('₹52,000.00 Net • Paid on 01 Aug'), findsOneWidget);
        expect(find.text('₹51,000.00 Net • Paid on 01 Jul'), findsOneWidget);
        expect(find.text('No payslips available yet.'), findsNothing);
      },
    );

    testWidgets('Error state: shows retry button when API fails', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      mockService.throwError = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginStateProvider.overrideWith(() => MockLoginStateNotifier()),
            employeeApiServiceProvider.overrideWithValue(mockService),
            permissionManagerProvider.overrideWith(
              () => TestPermissionNotifier(allowSalary: true),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: ProfileView()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recent Payslips'), findsOneWidget);
      expect(find.text('Unable to load payslips'), findsOneWidget);
      final payslipErrorRow = find
          .ancestor(
            of: find.text('Unable to load payslips'),
            matching: find.byType(Row),
          )
          .first;
      expect(
        find.descendant(
          of: payslipErrorRow,
          matching: find.widgetWithText(TextButton, 'Retry'),
        ),
        findsOneWidget,
      );
      expect(find.text('July 2026'), findsNothing);
    });
  });
}
