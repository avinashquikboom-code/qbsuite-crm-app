import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/core/network/app_url.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_my_work_viewmodel.dart';

class FilterApi implements ApiClient {
  final requests = <Map<String, dynamic>>[];
  final pending = <Completer<Response<dynamic>>>[];
  bool delay = false;
  @override
  String get token => 'test-session';
  @override
  Future<bool> ensureAuthLoaded() async => true;
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final query = Map<String, dynamic>.from(queryParameters ?? {});
    if (path == AppUrl.employeeCalendar) {
      requests.add(query);
      if (delay) {
        final completer = Completer<Response<dynamic>>();
        pending.add(completer);
        final result = await completer.future;
        return Response<T>(
          requestOptions: result.requestOptions,
          statusCode: result.statusCode,
          data: result.data as T,
        );
      }
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: <dynamic>[] as T,
      );
    }
    final data = path == AppUrl.productionMetrics
        ? {'total': 12, 'pending': 10}
        : <String, dynamic>{};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: data as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Response<dynamic> response(String id, String date) => Response(
  requestOptions: RequestOptions(path: AppUrl.employeeCalendar),
  statusCode: 200,
  data: [
    {
      'id': id,
      'title': 'Editing',
      'type': 'REEL_EDIT',
      'scheduledDate': date,
      'date': date,
      'status': 'SCHEDULED',
    },
  ],
);

Future<void> settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FilterApi api;
  late ProviderContainer container;
  late EmployeeMyWorkNotifier notifier;
  setUp(() async {
    api = FilterApi();
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        employeeMyWorkNowProvider.overrideWithValue(
          () => DateTime(2026, 10, 11, 23, 59),
        ),
      ],
    );
    notifier = container.read(employeeMyWorkProvider.notifier);
    await settle();
    api.requests.clear();
  });
  tearDown(() => container.dispose());

  test(
    'Today, Tomorrow, Monday-Sunday week, Pick Date and refresh send their selected dates',
    () async {
      await notifier.setDateRangeFilter('TODAY');
      expect(api.requests.last, {'date': '2026-10-11'});
      await notifier.setDateRangeFilter('TOMORROW');
      expect(api.requests.last, {'date': '2026-10-12'});
      await notifier.setDateRangeFilter('THIS_WEEK');
      expect(api.requests.last, {
        'dateFrom': '2026-10-05',
        'dateTo': '2026-10-11',
      });
      await notifier.setDate(DateTime(2026, 11, 2, 18));
      expect(api.requests.last, {'date': '2026-11-02'});
      await notifier.refresh();
      expect(api.requests.last, {'date': '2026-11-02'});
      expect(
        container.read(employeeMyWorkProvider).selectedDateRange,
        'CUSTOM',
      );
      expect(container.read(employeeMyWorkProvider).activities, isEmpty);
      expect(container.read(employeeMyWorkProvider).prodTotal, 12);
    },
  );

  test(
    'late Today response cannot overwrite Tomorrow tasks or its filtered count',
    () async {
      api.delay = true;
      final today = notifier.setDateRangeFilter('TODAY');
      await settle();
      final tomorrow = notifier.setDateRangeFilter('TOMORROW');
      await settle();
      api.pending[1].complete(response('tomorrow', '2026-10-12'));
      await tomorrow;
      api.pending[0].complete(response('today', '2026-10-11'));
      await today;
      final state = container.read(employeeMyWorkProvider);
      expect(state.selectedDateRange, 'TOMORROW');
      expect(state.activities.map((a) => a.id), ['tomorrow']);
      expect(state.activities.length, 1);
      expect(state.isLoading, false);
    },
  );

  test(
    'stale failure cannot replace a newer successful Pick Date response',
    () async {
      api.delay = true;
      final first = notifier.setDateRangeFilter('THIS_WEEK');
      await settle();
      final picked = notifier.setDate(DateTime(2026, 10, 15));
      await settle();
      api.pending[1].complete(response('picked', '2026-10-15'));
      await picked;
      api.pending[0].completeError(StateError('old request failed'));
      await first;
      expect(container.read(employeeMyWorkProvider).errorMessage, isNull);
      expect(
        container.read(employeeMyWorkProvider).activities.single.id,
        'picked',
      );
    },
  );

  test('repeated switching keeps the latest genuine empty result', () async {
    api.delay = true;
    final calls = <Future<void>>[];
    for (final range in ['TODAY', 'TOMORROW', 'THIS_WEEK', 'TOMORROW']) {
      calls.add(notifier.setDateRangeFilter(range));
      await settle();
    }
    api.pending.last.complete(
      Response<dynamic>(
        requestOptions: RequestOptions(path: AppUrl.employeeCalendar),
        statusCode: 200,
        data: <dynamic>[],
      ),
    );
    await calls.last;
    for (var i = 2; i >= 0; i--) {
      api.pending[i].complete(response('stale-$i', '2026-10-11'));
      await calls[i];
    }
    expect(container.read(employeeMyWorkProvider).activities, isEmpty);
    expect(
      container.read(employeeMyWorkProvider).selectedDateRange,
      'TOMORROW',
    );
    expect(container.read(employeeMyWorkProvider).prodTotal, 12);
  });
}
