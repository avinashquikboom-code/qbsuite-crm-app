import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/roles/employee/services/employee_api_service.dart';

class SalaryClient extends Fake implements ApiClient {
  Object? salary;
  bool fail = false;
  String? path;

  @override
  Future<Response<T>> get<T>(String endpoint,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    path = endpoint;
    expect(queryParameters, isNull);
    if (fail) throw Exception('Access denied');
    return Response<T>(
      requestOptions: RequestOptions(path: endpoint),
      data: {'salaryStructure': salary} as T,
    );
  }
}

void main() {
  test('reads current server salary without sending an employee identifier', () async {
    final client = SalaryClient()..salary = {
      'id': 1, 'basicSalary': 10000, 'allowances': 2000,
      'grossSalary': 12000, 'totalDeductions': 0, 'netSalary': 12000,
      'effectiveFrom': '2026-10-01',
    };
    final details = await EmployeeApiService(client).getSalaryDetails();
    expect(client.path, '/admin/payroll/salary');
    expect(details!['basicSalary'], 10000);
    expect(details['grossSalary'], 12000);
    expect(details['totalDeductions'], 0);
  });

  test('distinguishes missing salary from failed authorization', () async {
    final client = SalaryClient();
    final service = EmployeeApiService(client);
    expect(await service.getSalaryDetails(), isNull);
    client.fail = true;
    await expectLater(service.getSalaryDetails(), throwsException);
  });
}
