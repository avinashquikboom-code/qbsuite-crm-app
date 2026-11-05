import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/roles/employee/models/employee_payroll_model.dart';
import 'package:quickboom_app/roles/employee/services/employee_api_service.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_payroll_viewmodel.dart';

class MockEmployeeApiService extends Fake implements EmployeeApiService {
  List<SalarySlipItem>? mockSlips;
  bool shouldThrow = false;

  @override
  Future<List<SalarySlipItem>> getSalarySlips({
    int page = 1,
    int limit = 20,
  }) async {
    if (shouldThrow) {
      throw Exception('Network error');
    }
    return mockSlips ?? [];
  }
}

void main() {
  group('EmployeePayrollNotifier Tests', () {
    late MockEmployeeApiService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockEmployeeApiService();
      container = ProviderContainer(
        overrides: [employeeApiServiceProvider.overrideWithValue(mockService)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state loads empty slips and no error', () async {
      mockService.mockSlips = [];
      await container.read(employeePayrollProvider.notifier).loadSalarySlips();
      final finalState = container.read(employeePayrollProvider);

      expect(finalState.isLoading, false);
      expect(finalState.slips, isEmpty);
      expect(finalState.errorMessage, isNull);
    });

    test('Loads actual slips successfully', () async {
      mockService.mockSlips = [
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
      ];

      await container.read(employeePayrollProvider.notifier).loadSalarySlips();
      final state = container.read(employeePayrollProvider);

      expect(state.isLoading, false);
      expect(state.slips.length, 1);
      expect(state.slips.first.month, 'August 2026');
      expect(state.slips.first.netSalary, 52000.0);
      expect(state.errorMessage, isNull);
    });

    test('Handles API failure with proper error message', () async {
      mockService.shouldThrow = true;

      await container.read(employeePayrollProvider.notifier).loadSalarySlips();
      final state = container.read(employeePayrollProvider);

      expect(state.isLoading, false);
      expect(state.slips, isEmpty);
      expect(state.errorMessage, 'Unable to load payslips');
    });
  });
}
