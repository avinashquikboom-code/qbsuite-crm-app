import 'package:quickboom_app/core/icons/remix_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/core/services/auth_service.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/core/services/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:quickboom_app/shared/models/capture_history.dart';
import 'package:quickboom_app/shared/services/data_capture_records_service.dart';
import 'package:quickboom_app/shared/services/data_capture_service.dart';
import 'package:quickboom_app/shared/views/data_capture/data_capture_history_screen.dart';
import 'data_capture_multiselect_test.dart' as fixture;

Map<String, dynamic> session(String? status) => {
  'jobId': 'job-37',
  'keyword': 'Gym',
  'location': 'Pune',
  'createdAt': '2026-10-25T10:00:00Z',
  'capturedResults': 2,
  'foundResults': 3,
  'captureStatus': status,
};
Map<String, dynamic> page(List records) => {
  'data': records,
  'pagination': {'page': 1, 'totalPages': 1},
};
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SecureStorageService.setMockInitialValues({});
    PermissionManager.instance.setPermissions(
      AuthService.defaultEmployeeCapabilities(),
      role: 'EMPLOYEE',
    );
  });
  tearDown(() {
    SecureStorageService.clearMockValues();
    PermissionManager.instance.clear();
  });
  test('history parses persisted statuses, counts and older sessions', () {
    final result = CaptureHistoryPage.fromJson({
      'data': page([
        session('COMPLETED'),
        session('FAILED'),
        session('PARTIALLY_COMPLETED'),
        session(null),
      ]),
    });
    expect(result.sessions.map((s) => s.statusLabel), [
      'Completed',
      'Failed',
      'Partially Completed',
      'Status unavailable (older session)',
    ]);
    expect(result.sessions.first.captured, 2);
    expect(result.sessions.first.found, 3);
    expect(result.sessions.first.location, 'Pune');
    expect(
      result.sessions.first.createdAt.toUtc(),
      DateTime.utc(2026, 10, 25, 10),
    );
  });
  test(
    'history uses read-only persisted API with paging/search/date filters',
    () async {
      final api = fixture.client((options) {
        expect(options.method, 'GET');
        expect(options.path, '/data-capture/history');
        expect(options.queryParameters, {
          'page': 2,
          'limit': 20,
          'search': 'Gym',
          'from': '2026-10-01T00:00:00.000Z',
          'to': '2026-11-01T00:00:00.000Z',
        });
        return fixture.jsonBody(page([session('COMPLETED')]));
      });
      final result = await DataCaptureService(api).getHistory(
        page: 2,
        search: ' Gym ',
        from: DateTime.utc(2026, 10),
        to: DateTime.utc(2026, 11),
      );
      expect(result.sessions.single.jobId, 'job-37');
    },
  );
  testWidgets(
    'history opens saved session businesses without extracting again',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <String>[];
      ApiClient().dio.httpClientAdapter = fixture.CaptureAdapter((options) {
        expect(options.method, 'GET');
        requests.add(options.path);
        if (options.path == '/data-capture/history')
          return fixture.jsonBody(page([session('PARTIALLY_COMPLETED')]));
        expect(options.path, '/data-capture/history/job-37/records');
        return fixture.jsonBody({
          'data': [],
          'pagination': {'page': 1, 'totalPages': 1, 'total': 0},
        });
      });
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: DataCaptureHistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Partially Completed'), findsOneWidget);
      expect(find.text('Captured: 2'), findsOneWidget);
      await tester.tap(find.text('View captured businesses'));
      await tester.pumpAndSettle();
      expect(requests, [
        '/data-capture/history',
        '/data-capture/history/job-37/records',
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'resilient parsing handles backend TransformInterceptor payload, nulls, and string numbers',
    () {
      final backendPayload = {
        'statusCode': 200,
        'success': true,
        'message': 'Operation completed successfully',
        'data': [
          {
            'jobId': 'job-99',
            'keyword': 'Yoga Studio',
            'location': 'Mumbai',
            'createdAt': '2026-10-25T12:00:00.000Z',
            'capturedResults': null, // null captured
            'foundResults': '15', // string found
            'captureStatus': 'completed', // lowercase
          },
          {
            'jobId': null,
            'keyword': null,
            'location': null,
            'createdAt': null,
            'capturedResults': '10',
            'foundResults': null,
            'captureStatus': null,
          },
        ],
        'pagination': {'page': 1, 'limit': 20, 'total': 2, 'totalPages': 1},
      };

      final result = CaptureHistoryPage.fromJson(backendPayload);
      expect(result.sessions.length, 2);
      expect(result.sessions[0].jobId, 'job-99');
      expect(result.sessions[0].captured, 0); // null converted to 0
      expect(result.sessions[0].found, 15); // string converted to 15
      expect(result.sessions[0].statusLabel, 'Completed');

      expect(result.sessions[1].jobId, '');
      expect(result.sessions[1].keyword, '');
      expect(result.sessions[1].captured, 10);
      expect(result.sessions[1].found, isNull);
      expect(
        result.sessions[1].statusLabel,
        'Status unavailable (older session)',
      );
      expect(result.page, 1);
      expect(result.totalPages, 1);
    },
  );

  test('resilient parsing handles JSON string and missing pagination', () {
    const jsonString =
        '{"data": [{"jobId": "job-1", "keyword": "Gym", "location": "Delhi", "capturedResults": 3}]}';
    final result = CaptureHistoryPage.fromJson(jsonString);
    expect(result.sessions.length, 1);
    expect(result.sessions.first.jobId, 'job-1');
    expect(result.page, 1);
    expect(result.totalPages, 1);
  });

  test(
    'dataCaptureError classifies unauthorized, forbidden, network, and validation errors correctly',
    () {
      // 401
      final err401 = DioException(
        requestOptions: RequestOptions(path: '/data-capture/history'),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 401,
        ),
      );
      expect(dataCaptureError(err401), 'Please sign in again.');

      // 403
      final err403 = DioException(
        requestOptions: RequestOptions(path: '/data-capture/history'),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 403,
        ),
      );
      expect(
        dataCaptureError(err403),
        'You do not have permission for this action.',
      );

      // Network timeout
      final netErr = DioException(
        requestOptions: RequestOptions(path: '/data-capture/history'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        dataCaptureError(netErr),
        'Unable to connect. Check your connection and retry.',
      );

      // 500
      final err500 = DioException(
        requestOptions: RequestOptions(path: '/data-capture/history'),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 500,
        ),
      );
      expect(
        dataCaptureError(err500),
        'Data Capture is unavailable. Please retry.',
      );

      // 400 validation error with message
      final valErr = DioException(
        requestOptions: RequestOptions(path: '/data-capture/history'),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 400,
          data: {
            'message': ['from must be a valid ISO 8601 date string'],
          },
        ),
      );
      expect(
        dataCaptureError(valErr),
        'from must be a valid ISO 8601 date string',
      );

      // FormatException
      expect(
        dataCaptureError(const FormatException('Bad JSON')),
        'Unable to process server data. Please retry.',
      );

      // TypeError
      expect(
        dataCaptureError(TypeError()),
        'Data format mismatch. Please retry.',
      );
    },
  );

  testWidgets('shows empty state when no capture history records exist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    ApiClient().dio.httpClientAdapter = fixture.CaptureAdapter((options) {
      return fixture.jsonBody({
        'data': [],
        'pagination': {'page': 1, 'totalPages': 1, 'total': 0},
      });
    });

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DataCaptureHistoryScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('No capture history found.'), findsOneWidget);
    expect(
      find.byIcon(LegacyRemixIcons.historyToggleOffRounded),
      findsOneWidget,
    );
  });

  testWidgets('displays error state and retries successfully', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int callCount = 0;
    ApiClient().dio.httpClientAdapter = fixture.CaptureAdapter((options) {
      callCount++;
      if (callCount == 1) {
        return fixture.jsonBody({
          'message': 'Data Capture service temporary failure',
        }, 500);
      }
      return fixture.jsonBody(page([session('COMPLETED')]));
    });

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DataCaptureHistoryScreen())),
    );
    await tester.pumpAndSettle();

    // Verify error message and Retry button
    expect(
      find.text('Data Capture is unavailable. Please retry.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    // Tap Retry
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    // Second call should succeed and display the session record
    expect(callCount, 2);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });
}
