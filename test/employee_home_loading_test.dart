import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/core/services/secure_storage_service.dart';
import 'package:quickboom_app/roles/employee/services/employee_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/core/models/permission_model.dart';
import 'package:quickboom_app/roles/employee/models/lead_limit_model.dart';
import 'package:quickboom_app/roles/employee/models/work_permission_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_notification_viewmodel.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_profile_viewmodel.dart';
import 'package:quickboom_app/roles/employee/viewmodels/lead_limit_viewmodel.dart';
import 'package:quickboom_app/roles/employee/viewmodels/work_permissions_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/home_view.dart';
import 'package:quickboom_app/roles/employee/widgets/lead_limit_card.dart';

class TestLogin extends LoginStateNotifier {
  @override
  LoginState build() => LoginState(
    isLoggedIn: true,
    isInitializing: false,
    userName: 'Loaded employee',
    userRole: 'BPO',
  );
  @override
  Future<void> refreshPermissions() async {}
}

class TestNotifications extends EmployeeNotificationNotifier {
  final Completer<void> pending;
  TestNotifications(this.pending);
  @override
  NotificationState build() => const NotificationState(isLoading: true);
  @override
  Future<void> loadNotifications() => pending.future;
}

class TestWork extends WorkPermissionsNotifier {
  @override
  WorkPermissionsState build() =>
      WorkPermissionsState(permissions: EmployeeWorkPermissions.empty());
  @override
  Future<void> loadPermissions() async {}
}

class TestQuota extends LeadLimitViewModel {
  @override
  Future<EmployeeLeadLimitModel> build() async => const EmployeeLeadLimitModel(
    daily: LeadLimitPeriod(limit: 20, used: 3, remaining: 17),
    monthly: LeadLimitPeriod(limit: 200, used: 30, remaining: 170),
  );
}

class QuotaAdapter implements HttpClientAdapter {
  int status = 200;
  Object body = {
    'data': {
      'daily': {'limit': 20, 'used': 3, 'remaining': 17},
      'monthly': {'limit': 200, 'used': 30, 'remaining': 170},
    },
  };
  int calls = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    calls++;
    expect(options.path, '/lead-generation-limits/me');
    expect(options.headers['Authorization'], startsWith('Bearer '));
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    PermissionManager.instance.setPermissions(
      [const UserPermission(module: 'LEADS', action: 'VIEW')],
      role: 'BPO',
      isCrmEligible: true,
    );
  });
  tearDown(() => PermissionManager.instance.clear());

  test(
    'quota API success, empty data, failure and retry reach terminal provider states',
    () async {
      final token =
          'fixture.${base64Url.encode(utf8.encode(jsonEncode({'sub': 7, 'exp': 4102444800}))).replaceAll('=', '')}.signature';
      SecureStorageService.setMockInitialValues({'access_token': token});
      addTearDown(SecureStorageService.clearMockValues);
      final adapter = QuotaAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
        ..httpClientAdapter = adapter;
      final api = ApiClient.forTesting(dio: dio, refreshDio: Dio());
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          employeeApiServiceProvider.overrideWithValue(EmployeeApiService(api)),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(leadLimitProvider, (_, _) {});
      addTearDown(subscription.close);
      expect(
        (await container.read(leadLimitProvider.future)).daily.remaining,
        17,
      );
      expect(container.read(leadLimitProvider).isLoading, isFalse);
      adapter.body = {'data': {}};
      await container.read(leadLimitProvider.notifier).fetchLimits();
      expect(container.read(leadLimitProvider).requireValue.daily.limit, 0);
      adapter.status = 500;
      adapter.body = {'message': 'Quota unavailable'};
      await container.read(leadLimitProvider.notifier).fetchLimits();
      expect(container.read(leadLimitProvider).hasError, isTrue);
      expect(container.read(leadLimitProvider).isLoading, isFalse);
      adapter.status = 200;
      adapter.body = {
        'data': {
          'daily': {'limit': 20, 'used': 4, 'remaining': 16},
        },
      };
      await container.read(leadLimitProvider.notifier).fetchLimits();
      expect(
        container.read(leadLimitProvider).requireValue.daily.remaining,
        16,
      );
      expect(adapter.calls, 4);
    },
  );

  testWidgets(
    'loaded BPO sections render while notifications are pending; timeout and retry stop the refresh',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          loginStateProvider.overrideWith(TestLogin.new),
          employeeNotificationProvider.overrideWith(
            () => TestNotifications(pending),
          ),
          workPermissionsProvider.overrideWith(TestWork.new),
          leadLimitProvider.overrideWith(TestQuota.new),
          employeeProfileProvider.overrideWith(
            (ref) async => const EmployeeProfileData(
              id: 7,
              name: 'Loaded employee',
              employeeCode: 'EMP-7',
              email: '',
              department: 'BPO',
              designation: 'BPO',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: EmployeeHomeView()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Loaded employee'), findsOneWidget);
      expect(find.byType(LeadLimitCard), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_view_all_leads')), findsOneWidget);
      expect(pending.isCompleted, isFalse);
      await tester.pump(const Duration(seconds: 61));
      await tester.pump();
      expect(find.text('Retry dashboard'), findsOneWidget);
      pending.complete();
      await tester.tap(find.text('Retry dashboard'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Retry dashboard'), findsNothing);
      expect(find.byType(LeadLimitCard), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
