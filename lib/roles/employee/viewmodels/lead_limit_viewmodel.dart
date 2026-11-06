import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/constants/app_config.dart';
import '../models/lead_limit_model.dart';
import '../services/employee_api_service.dart';

final leadLimitProvider =
    AsyncNotifierProvider<LeadLimitViewModel, EmployeeLeadLimitModel>(() {
      return LeadLimitViewModel();
    });

class LeadLimitViewModel extends AsyncNotifier<EmployeeLeadLimitModel> {
  @override
  Future<EmployeeLeadLimitModel> build() async {
    return _fetch();
  }

  Future<EmployeeLeadLimitModel> _fetch() async {
    if (AppConfig.uiOnlyMode) {
      return const EmployeeLeadLimitModel(
        daily: LeadLimitPeriod(limit: 20, used: 8, remaining: 12),
        monthly: LeadLimitPeriod(limit: 400, used: 142, remaining: 258),
        hasLeadsPermission: true,
        roleName: 'BPO Executive',
      );
    }
    final api = ref.read(employeeApiServiceProvider);
    return api.getMyLeadLimit();
  }

  Future<void> fetchLimits() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }
}
