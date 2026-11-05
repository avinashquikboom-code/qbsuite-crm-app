import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/roles/employee/models/employee_payroll_model.dart';

void main() {
  group('SalarySlipItem Attendance Summary & Extra Working Tests', () {
    test('parses all 11 attendance summary metrics and extra working from backend JSON attendanceSummary', () {
      final json = {
        'id': '101',
        'payPeriod': 'October 2026',
        'month': 10,
        'year': 2026,
        'basicSalary': 30000.0,
        'hra': 12000.0,
        'allowances': 3000.0,
        'grossSalary': 46500.0,
        'totalDeductions': 5000.0,
        'netSalary': 41500.0,
        'extraWorkingPay': 1500.0,
        'monthlySalary': 45000.0,
        'attendanceSalary': 45000.0,
        'attendanceSummary': {
          'periodStart': '2026-10-01',
          'periodEnd': '2026-10-31',
          'calendarDays': 31,
          'workingDays': 26,
          'presentDays': 22,
          'absentDays': 2,
          'halfDays': 2,
          'paidLeaveDays': 1,
          'unpaidLeaveDays': 1,
          'weeklyOffDays': 4,
          'holidayDays': 1,
          'extraWorkingDays': 1.0,
          'extraWorkingDates': ['2026-10-04'],
          'payableDays': 28.0,
          'overtimeLabel': '5h 30m',
        },
      };

      final slip = SalarySlipItem.fromJson(json);

      expect(slip.calendarDays, 31.0);
      expect(slip.workingDays, 26.0);
      expect(slip.presentDays, 22.0);
      expect(slip.halfDays, 2.0);
      expect(slip.absentDays, 2.0);
      expect(slip.paidLeaveDays, 1.0);
      expect(slip.unpaidLeaveDays, 1.0);
      expect(slip.weeklyOffDays, 4.0);
      expect(slip.holidayDays, 1.0);
      expect(slip.extraWorkingDays, 1.0);
      expect(slip.extraWorkingDates, ['2026-10-04']);
      expect(slip.payableDays, 28.0);
      expect(slip.extraWorkingPay, 1500.0);
      expect(slip.monthlySalary, 45000.0);
      expect(slip.attendanceSalary, 45000.0);
      expect(slip.overtimeHours, '5h 30m');
    });

    test('falls back gracefully to root or payrollItem columns when attendanceSummary is absent', () {
      final json = {
        'id': '102',
        'payPeriod': 'September 2026',
        'basicSalary': 25000.0,
        'grossSalary': 35000.0,
        'totalDeductions': 3000.0,
        'netSalary': 32000.0,
        'calendarDays': 30,
        'workingDays': 24,
        'presentDays': 20,
        'absentDays': 4,
        'halfDays': 1,
        'weeklyOffDays': 4,
        'holidayDays': 2,
        'extraWorkingDays': 0.0,
        'payableDays': 25.5,
        'overtimeHours': '2h 15m',
      };

      final slip = SalarySlipItem.fromJson(json);

      expect(slip.calendarDays, 30.0);
      expect(slip.workingDays, 24.0);
      expect(slip.presentDays, 20.0);
      expect(slip.halfDays, 1.0);
      expect(slip.absentDays, 4.0);
      expect(slip.weeklyOffDays, 4.0);
      expect(slip.holidayDays, 2.0);
      expect(slip.extraWorkingDays, 0.0);
      expect(slip.payableDays, 25.5);
      expect(slip.overtimeHours, '2h 15m');
    });
  });
}
