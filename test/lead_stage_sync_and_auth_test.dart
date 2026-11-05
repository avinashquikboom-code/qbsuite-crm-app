import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/core/network/app_url.dart';
import 'package:quickboom_app/core/services/secure_storage_service.dart';
import 'package:quickboom_app/shared/models/lead_stage_model.dart';
import 'package:quickboom_app/shared/services/lead_service.dart';

const stageResponseFixture = <Map<String, dynamic>>[
  {
    'id': 1,
    'key': 'NEW',
    'name': 'New',
    'sortOrder': 1,
    'color': '#0284C7',
    'bgColor': '#E0F2FE',
    'borderColor': '#BAE6FD',
  },
  {
    'id': 2,
    'key': 'CONTACTED',
    'name': 'Contacted',
    'sortOrder': 2,
    'color': '#D97706',
    'bgColor': '#FEF3C7',
    'borderColor': '#FDE68A',
  },
  {
    'id': 3,
    'key': 'DETAILS_SEND',
    'name': 'Details send',
    'sortOrder': 3,
    'color': '#4F46E5',
    'bgColor': '#EEF2FF',
    'borderColor': '#C7D2FE',
  },
  {
    'id': 4,
    'key': 'FOLLOW_UP',
    'name': 'Follow-up',
    'sortOrder': 4,
    'color': '#7C3AED',
    'bgColor': '#F5F3FF',
    'borderColor': '#DDD6FE',
  },
  {
    'id': 5,
    'key': 'VISIT_SCHEDULED',
    'name': 'Visit Scheduled',
    'sortOrder': 5,
    'color': '#0891B2',
    'bgColor': '#ECFEFF',
    'borderColor': '#A5F3FC',
  },
  {
    'id': 6,
    'key': 'VISIT_DONE',
    'name': 'Visit Done',
    'sortOrder': 6,
    'color': '#0D9488',
    'bgColor': '#F0FDFA',
    'borderColor': '#99F6E4',
  },
  {
    'id': 7,
    'key': 'PROPOSAL_SENT',
    'name': 'Proposal Sent',
    'sortOrder': 7,
    'color': '#2563EB',
    'bgColor': '#EFF6FF',
    'borderColor': '#BFDBFE',
  },
  {
    'id': 8,
    'key': 'NEGOTIATION',
    'name': 'Negotiation',
    'sortOrder': 8,
    'color': '#F59E0B',
    'bgColor': '#FFFBEB',
    'borderColor': '#FDE68A',
  },
  {
    'id': 9,
    'key': 'FINAL_CALL',
    'name': 'Final Call',
    'sortOrder': 9,
    'color': '#EA580C',
    'bgColor': '#FFF7ED',
    'borderColor': '#FFEDD5',
  },
  {
    'id': 10,
    'key': 'WON',
    'name': 'Won',
    'sortOrder': 10,
    'color': '#16A34A',
    'bgColor': '#DCFCE7',
    'borderColor': '#BBF7D0',
  },
  {
    'id': 11,
    'key': 'LOST',
    'name': 'Lost',
    'sortOrder': 11,
    'color': '#DC2626',
    'bgColor': '#FFE4E6',
    'borderColor': '#FECDD3',
  },
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SecureStorageService.clearMockValues();
  });

  tearDown(() {
    SecureStorageService.clearMockValues();
  });

  group('CRM Lead Pipeline Stage Synchronization Tests', () {
    test(
      '1. Parses configured stage response preserving order, labels, and colors',
      () {
        final stages = stageResponseFixture
            .map(LeadStageModel.fromJson)
            .toList();
        expect(stages.length, 11);

        const expectedStages = stageResponseFixture;

        for (int i = 0; i < 11; i++) {
          expect(stages[i].id, expectedStages[i]['id']);
          expect(stages[i].key, expectedStages[i]['key']);
          expect(stages[i].name, expectedStages[i]['name']);
          expect(stages[i].color, expectedStages[i]['color']);
          expect(stages[i].bgColor, expectedStages[i]['bgColor']);
          expect(stages[i].borderColor, expectedStages[i]['borderColor']);
          expect(stages[i].isActive, isTrue);
        }
      },
    );

    test(
      '2. LeadService.getStages fetches dynamically from GET /leads/stages',
      () async {
        final dio = Dio();
        final refreshDio = Dio();
        final client = ApiClient.forTesting(dio: dio, refreshDio: refreshDio);

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path.endsWith('/leads/stages')) {
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {'success': true, 'data': stageResponseFixture},
                  ),
                );
              }
              return handler.next(options);
            },
          ),
        );

        final service = LeadService(client);
        final fetched = await service.getStages();
        expect(fetched.length, 11);
        expect(fetched.first.name, 'New');
        expect(fetched.last.name, 'Lost');
      },
    );
  });

  group('401 Authentication & Token Refresh Flow Tests', () {
    test(
      '3. 401 on PATCH /leads/943/status triggers token refresh and retries once with new Bearer token',
      () async {
        const expiredToken = 'expired.jwt.token';
        const freshToken = 'fresh.renewed.jwt.token';
        const refreshToken = 'valid.refresh.token';
        const rotatedRefreshToken = 'rotated.refresh.token';

        SecureStorageService.setMockInitialValues({
          'access_token': expiredToken,
          'refresh_token': refreshToken,
          'customer_id': '10',
        });

        final dio = Dio(BaseOptions(baseUrl: AppUrl.baseUrl));
        final refreshDio = Dio(BaseOptions(baseUrl: AppUrl.baseUrl));

        int refreshCalls = 0;
        int leadPatchCalls = 0;
        final List<String?> sentAuthHeaders = [];

        refreshDio.httpClientAdapter = TestMockAdapter((options) async {
          if (options.path.contains(AppUrl.refreshToken)) {
            refreshCalls++;
            final body = options.data is Map
                ? options.data
                : jsonDecode(options.data.toString());
            expect(body['refreshToken'], equals(refreshToken));
            return ResponseBody.fromString(
              jsonEncode({
                'success': true,
                'tokens': {
                  'accessToken': freshToken,
                  'refreshToken': rotatedRefreshToken,
                },
              }),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          return ResponseBody.fromString('{}', 404);
        });

        dio.httpClientAdapter = TestMockAdapter((options) async {
          if (options.path.contains('/leads/943/status')) {
            leadPatchCalls++;
            sentAuthHeaders.add(options.headers['Authorization']?.toString());
            if (options.extra['__retried'] != true) {
              return ResponseBody.fromString(
                jsonEncode({
                  'message': 'Invalid or expired authentication token',
                  'error': 'Unauthorized',
                  'statusCode': 401,
                }),
                401,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            } else {
              return ResponseBody.fromString(
                jsonEncode({
                  'id': 943,
                  'companyName': 'Acme Corp',
                  'status': 'CONTACTED',
                  'stageId': 2,
                  'source': 'MANUAL',
                  'createdFrom': 'ADMIN_PANEL',
                  'stage': {
                    'id': 2,
                    'key': 'CONTACTED',
                    'name': 'Contacted',
                    'sortOrder': 2,
                    'color': '#D97706',
                    'bgColor': '#FEF3C7',
                    'borderColor': '#FDE68A',
                  },
                }),
                200,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            }
          }
          return ResponseBody.fromString('{}', 404);
        });

        final client = ApiClient.forTesting(dio: dio, refreshDio: refreshDio);

        await client.ensureAuthLoaded();

        final service = LeadService(client);
        final updated = await service.updateStatus(
          '943',
          status: 'CONTACTED',
          stageId: 2,
        );

        expect(leadPatchCalls, equals(2));
        expect(refreshCalls, equals(1));
        expect(sentAuthHeaders[0], equals('Bearer $expiredToken'));
        expect(sentAuthHeaders[1], equals('Bearer $freshToken'));
        expect(updated.id, equals('943'));
        expect(updated.status, equals('CONTACTED'));
        expect(updated.stageName, equals('Contacted'));

        // Storage should have the renewed tokens
        final savedAccess = await SecureStorageService.getAccessToken();
        final savedRefresh = await SecureStorageService.getRefreshToken();
        expect(savedAccess, equals(freshToken));
        expect(savedRefresh, equals(rotatedRefreshToken));
      },
    );

    test(
      '4. Failed token refresh clears authentication state and triggers session expiry callback',
      () async {
        const expiredToken = 'expired.jwt.token';
        const expiredRefreshToken = 'expired.refresh.token';

        SecureStorageService.setMockInitialValues({
          'access_token': expiredToken,
          'refresh_token': expiredRefreshToken,
          'customer_id': '10',
        });

        final dio = Dio(BaseOptions(baseUrl: AppUrl.baseUrl));
        final refreshDio = Dio(BaseOptions(baseUrl: AppUrl.baseUrl));

        bool sessionExpiredFired = false;
        ApiClient.onSessionExpired = () {
          sessionExpiredFired = true;
        };
        addTearDown(() => ApiClient.onSessionExpired = null);

        refreshDio.httpClientAdapter = TestMockAdapter((options) async {
          if (options.path.contains(AppUrl.refreshToken)) {
            return ResponseBody.fromString(
              jsonEncode({'message': 'Invalid or expired refresh token'}),
              401,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          return ResponseBody.fromString('{}', 404);
        });

        dio.httpClientAdapter = TestMockAdapter((options) async {
          if (options.path.contains('/leads/943/status')) {
            return ResponseBody.fromString(
              jsonEncode({
                'message': 'Invalid or expired authentication token',
              }),
              401,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          return ResponseBody.fromString('{}', 404);
        });

        final client = ApiClient.forTesting(dio: dio, refreshDio: refreshDio);

        await client.ensureAuthLoaded();

        final service = LeadService(client);
        await expectLater(
          service.updateStatus('943', status: 'CONTACTED', stageId: 2),
          throwsA(isA<DioException>()),
        );

        expect(sessionExpiredFired, isTrue);
        final tokenAfter = await SecureStorageService.getAccessToken();
        expect(tokenAfter, isNull);
      },
    );

    test(
      '5. Proactive expiration check refreshes token before dispatching PATCH /leads/943/status',
      () async {
        // Token expired in the past
        final pastExpSec = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 60;
        final header = base64Url.encode(
          utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})),
        );
        final body = base64Url.encode(
          utf8.encode(
            jsonEncode({'exp': pastExpSec, 'sub': 1, 'customerId': '10'}),
          ),
        );
        final expiredJwt = '$header.$body.mockSignature';
        const freshToken = 'proactively.renewed.access.token';
        const refreshToken = 'mock.refresh.token';

        SecureStorageService.setMockInitialValues({
          'access_token': expiredJwt,
          'refresh_token': refreshToken,
          'customer_id': '10',
        });

        final dio = Dio(BaseOptions(baseUrl: AppUrl.baseUrl));
        final refreshDio = Dio(BaseOptions(baseUrl: AppUrl.baseUrl));
        final client = ApiClient.forTesting(dio: dio, refreshDio: refreshDio);

        int refreshCalls = 0;
        String? sentAuthHeader;

        refreshDio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path.contains(AppUrl.refreshToken)) {
                refreshCalls++;
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'tokens': {
                        'accessToken': freshToken,
                        'refreshToken': 'new.refresh.token',
                      },
                    },
                  ),
                );
              }
              return handler.next(options);
            },
          ),
        );

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path.contains('/leads/943/status')) {
                sentAuthHeader = options.headers['Authorization'];
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'id': 943,
                      'companyName': 'Acme Corp',
                      'status': 'CONTACTED',
                      'stageId': 2,
                      'source': 'MANUAL',
                      'createdFrom': 'ADMIN_PANEL',
                    },
                  ),
                );
              }
              return handler.next(options);
            },
          ),
        );

        await client.ensureAuthLoaded();

        final service = LeadService(client);
        final updated = await service.updateStatus(
          '943',
          status: 'CONTACTED',
          stageId: 2,
        );

        expect(refreshCalls, equals(1));
        expect(sentAuthHeader, equals('Bearer $freshToken'));
        expect(updated.status, equals('CONTACTED'));
      },
    );
  });
}

class TestMockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) onFetch;
  TestMockAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}
