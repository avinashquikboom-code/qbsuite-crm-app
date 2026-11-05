import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/core/services/secure_storage_service.dart';
import 'package:quickboom_app/shared/services/lead_service.dart';
import 'package:quickboom_app/shared/viewmodels/lead_stages_viewmodel.dart';

class FakeAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  FakeAdapter(this.respond);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
String jwt(int expiration) =>
    'fixture.${base64Url.encode(utf8.encode(jsonEncode({'sub': 7, 'exp': expiration}))).replaceAll('=', '')}.signature';
const future = 4102444800;
final stages = [
  {
    'id': 92,
    'key': 'CONTACTED',
    'name': 'Contacted by BPO',
    'sortOrder': 2,
    'color': '#112233',
    'bgColor': '#DDEEFF',
    'borderColor': '#AABBCC',
    'isActive': true,
  },
  {
    'id': 91,
    'key': 'NEW',
    'name': 'New prospect',
    'sortOrder': 1,
    'color': '#445566',
    'isActive': true,
  },
  {
    'id': 93,
    'key': 'HIDDEN',
    'name': 'Inactive',
    'sortOrder': 3,
    'isActive': false,
  },
];
Map<String, dynamic> lead(String status) => {
  'id': 943,
  'companyName': 'Fixture business',
  'source': 'DATA_CAPTURE',
  'status': status,
  'stageId': status == 'NEW' ? 91 : 92,
  'stage': stages.firstWhere((stage) => stage['key'] == status),
};
ApiClient client(
  FutureOr<ResponseBody> Function(RequestOptions) respond,
  FutureOr<ResponseBody> Function(RequestOptions) refresh,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
    ..httpClientAdapter = FakeAdapter(respond);
  final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
    ..httpClientAdapter = FakeAdapter(refresh);
  return ApiClient.forTesting(dio: dio, refreshDio: refreshDio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SecureStorageService.setMockInitialValues({
      'access_token': jwt(future),
      'refresh_token': 'refresh-fixture',
      'user_id': '7',
    });
    ApiClient.onSessionExpired = null;
  });
  tearDown(() {
    SecureStorageService.clearMockValues();
    ApiClient.onSessionExpired = null;
  });
  test(
    'API stage IDs, order, names and colors are authoritative; inactive stages are hidden',
    () async {
      var calls = 0;
      final api = client((options) {
        expect(options.path, '/leads/stages');
        expect(options.headers['Authorization'], 'Bearer ${jwt(future)}');
        calls++;
        return jsonResponse({'data': stages});
      }, (_) => throw StateError('Unexpected refresh'));
      final container = ProviderContainer(
        overrides: [leadServiceProvider.overrideWithValue(LeadService(api))],
      );
      addTearDown(container.dispose);
      final loaded = await container.read(leadStagesProvider.future);
      expect(loaded.map((stage) => stage.id), [91, 92, 93]);
      expect(loaded[1].name, 'Contacted by BPO');
      expect(loaded[1].color, '#112233');
      expect(
        container.read(activeLeadStagesProvider).map((stage) => stage.id),
        [91, 92],
      );
      expect(calls, 1);
    },
  );
  test('stage fetch errors do not manufacture a hardcoded pipeline', () async {
    final api = client(
      (_) => jsonResponse({'message': 'Not allowed'}, 403),
      (_) => throw StateError('Unexpected refresh'),
    );
    final container = ProviderContainer(
      overrides: [leadServiceProvider.overrideWithValue(LeadService(api))],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(leadStagesProvider.future),
      throwsA(isA<DioException>()),
    );
    expect(container.read(leadStagesProvider).hasError, true);
    expect(container.read(activeLeadStagesProvider), isEmpty);
  });
  test(
    'New to Contacted saves once and reopening details returns persisted stage',
    () async {
      var status = 'NEW';
      var patches = 0;
      final api = client((options) {
        if (options.method == 'PATCH') {
          patches++;
          expect(options.path, '/leads/943/status');
          expect(options.data, {'status': 'CONTACTED', 'stageId': 92});
          status = 'CONTACTED';
        }
        return jsonResponse({'data': lead(status)});
      }, (_) => throw StateError('Unexpected refresh'));
      final service = LeadService(api);
      expect(
        (await service.updateStatus(
          '943',
          status: 'CONTACTED',
          stageId: 92,
        )).stageName,
        'Contacted by BPO',
      );
      expect((await service.getLeadById('943')).status, 'CONTACTED');
      expect(patches, 1);
    },
  );
  test(
    'stage PATCH 401 rotates credentials and replays same method and payload once',
    () async {
      var patches = 0;
      var refreshes = 0;
      final renewed = jwt(future + 100);
      final api = client(
        (options) {
          expect(options.path, '/leads/943/status');
          expect(options.method, 'PATCH');
          expect(options.data, {'status': 'CONTACTED', 'stageId': 92});
          patches++;
          if (patches == 1) {
            return jsonResponse({
              'message': 'Invalid or expired authentication token',
            }, 401);
          }
          expect(options.headers['Authorization'], 'Bearer $renewed');
          return jsonResponse({'data': lead('CONTACTED')});
        },
        (options) {
          refreshes++;
          expect(options.path, '/auth/refresh');
          expect(options.data, {'refreshToken': 'refresh-fixture'});
          return jsonResponse({
            'data': {
              'tokens': {'accessToken': renewed, 'refreshToken': 'rotated'},
            },
          });
        },
      );
      expect(
        (await LeadService(
          api,
        ).updateStatus('943', status: 'CONTACTED', stageId: 92)).status,
        'CONTACTED',
      );
      expect(patches, 2);
      expect(refreshes, 1);
      expect(await SecureStorageService.getAccessToken(), renewed);
      expect(await SecureStorageService.getRefreshToken(), 'rotated');
    },
  );
  test('expired concurrent requests share proactive refresh', () async {
    SecureStorageService.setMockInitialValues({
      'access_token': jwt(1),
      'refresh_token': 'refresh-fixture',
    });
    var refreshes = 0;
    var requests = 0;
    final renewed = jwt(future + 100);
    final api = client(
      (options) {
        requests++;
        expect(options.headers['Authorization'], 'Bearer $renewed');
        return jsonResponse({'data': lead('CONTACTED')});
      },
      (_) async {
        refreshes++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return jsonResponse({
          'data': {'accessToken': renewed, 'refreshToken': 'rotated'},
        });
      },
    );
    await Future.wait([
      api.patch('/leads/943/status', data: {'status': 'CONTACTED'}),
      api.get('/leads/943'),
    ]);
    expect(refreshes, 1);
    expect(requests, 2);
  });
  test('startup and request refresh share one rotating credential', () async {
    SecureStorageService.setMockInitialValues({
      'access_token': jwt(1),
      'refresh_token': 'refresh-fixture',
    });
    var refreshes = 0;
    final gate = Completer<ResponseBody>();
    final api = client((_) => jsonResponse({'data': lead('CONTACTED')}), (_) {
      refreshes++;
      return gate.future;
    });
    final startup = api.refreshAuthDirectly(refreshToken: 'refresh-fixture');
    final request = api.get('/leads/943');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    gate.complete(
      jsonResponse({
        'data': {'accessToken': jwt(future + 100), 'refreshToken': 'rotated'},
      }),
    );
    await Future.wait([startup, request]);
    expect(refreshes, 1);
  });
  test('second 401 is bounded and clears session', () async {
    var patches = 0;
    var refreshes = 0;
    var expired = 0;
    ApiClient.onSessionExpired = () {
      expired++;
    };
    final api = client(
      (_) {
        patches++;
        return jsonResponse({'message': 'Unauthorized'}, 401);
      },
      (_) {
        refreshes++;
        return jsonResponse({
          'accessToken': jwt(future + 100),
          'refreshToken': 'rotated',
        });
      },
    );
    await expectLater(
      api.patch('/leads/943/status'),
      throwsA(isA<DioException>()),
    );
    expect(patches, 2);
    expect(refreshes, 1);
    expect(expired, 1);
    expect(await SecureStorageService.getAccessToken(), isNull);
  });
  test(
    'refresh network failure blocks expired mutation and retains recoverable session',
    () async {
      SecureStorageService.setMockInitialValues({
        'access_token': jwt(1),
        'refresh_token': 'refresh-fixture',
      });
      var requests = 0;
      var expired = 0;
      ApiClient.onSessionExpired = () {
        expired++;
      };
      final api = client((_) {
        requests++;
        return jsonResponse({});
      }, (_) => jsonResponse({'message': 'Unavailable'}, 503));
      await expectLater(
        api.patch('/leads/943/status'),
        throwsA(
          isA<DioException>().having(
            (error) => error.message,
            'message',
            contains('Check your connection'),
          ),
        ),
      );
      expect(requests, 0);
      expect(expired, 0);
      expect(await SecureStorageService.getRefreshToken(), 'refresh-fixture');
    },
  );
  test(
    'revoked refresh requests reauthentication without sending mutation',
    () async {
      SecureStorageService.setMockInitialValues({
        'access_token': jwt(1),
        'refresh_token': 'revoked',
      });
      var requests = 0;
      var expired = 0;
      ApiClient.onSessionExpired = () {
        expired++;
      };
      final api = client((_) {
        requests++;
        return jsonResponse({});
      }, (_) => jsonResponse({'message': 'Invalid refresh token'}, 401));
      await expectLater(
        api.patch('/leads/943/status'),
        throwsA(isA<DioException>()),
      );
      expect(requests, 0);
      expect(expired, 1);
      expect(await SecureStorageService.getRefreshToken(), isNull);
    },
  );
  test('403 and 404 are not retried or shown as successful updates', () async {
    for (final status in [403, 404]) {
      var calls = 0;
      final api = client((_) {
        calls++;
        return jsonResponse({'message': 'Not permitted'}, status);
      }, (_) => throw StateError('Unexpected refresh'));
      await expectLater(
        LeadService(api).updateStatus('943', status: 'CONTACTED', stageId: 92),
        throwsA(isA<DioException>()),
      );
      expect(calls, 1);
    }
  });
  test(
    'removed persisted credentials cannot resurrect an old in-memory Bearer',
    () async {
      final api = client((options) {
        expect(options.headers.containsKey('Authorization'), false);
        return jsonResponse({'data': []});
      }, (_) => throw StateError('Unexpected refresh'));
      api.setAuth(jwt(future), '', refreshToken: 'old-session');
      SecureStorageService.setMockInitialValues({});
      await api.get('/leads');
      expect(api.token, isNull);
    },
  );

  test(
    'refresh finishing after account switch cannot overwrite the new session',
    () async {
      final gate = Completer<ResponseBody>();
      final api = client(
        (_) => throw StateError('Old mutation must not be sent'),
        (_) => gate.future,
      );
      final pending = api.refreshAuthDirectly(refreshToken: 'refresh-fixture');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final newerToken = jwt(future + 200);
      await SecureStorageService.saveTokens(
        accessToken: newerToken,
        refreshToken: 'new-account-refresh',
      );
      api.setAuth(newerToken, '', refreshToken: 'new-account-refresh');
      gate.complete(
        jsonResponse({
          'accessToken': jwt(future + 100),
          'refreshToken': 'old-account-rotated',
        }),
      );
      expect(await pending, isNull);
      expect(await SecureStorageService.getAccessToken(), newerToken);
      expect(
        await SecureStorageService.getRefreshToken(),
        'new-account-refresh',
      );
    },
  );
  test(
    'assigned lead pages are all loaded with unchanged search/status and stable IDs',
    () async {
      final pages = <int>[];
      final api = client((options) {
        final page = options.queryParameters['page'] as int;
        pages.add(page);
        expect(options.path, '/leads');
        expect(options.queryParameters['search'], 'business');
        expect(options.queryParameters['status'], 'CONTACTED');
        expect(options.queryParameters.containsKey('createdById'), isFalse);
        expect(options.queryParameters.containsKey('assignedToId'), isFalse);
        return jsonResponse({
          'data': [
            {...lead('CONTACTED'), 'id': page, 'assignedToId': 70},
          ],
          'pagination': {'page': page, 'totalPages': 3},
        });
      }, (_) => throw StateError('Unexpected refresh'));
      final results = await LeadService(
        api,
      ).getLeads(status: 'CONTACTED', search: ' business ');
      expect(pages, [1, 2, 3]);
      expect(results.map((item) => item.id), ['1', '2', '3']);
      expect(results.every((item) => item.assignedToId == 70), isTrue);
    },
  );

  test(
    'empty employee scope is empty and malformed lead responses are errors',
    () async {
      var malformed = false;
      final api = client(
        (_) => jsonResponse(
          malformed
              ? {'success': true}
              : {
                  'data': [],
                  'pagination': {'page': 1, 'totalPages': 1},
                },
        ),
        (_) => throw StateError('Unexpected refresh'),
      );
      expect(await LeadService(api).getLeads(), isEmpty);
      malformed = true;
      await expectLater(LeadService(api).getLeads(), throwsFormatException);
    },
  );
}
