import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/core/services/auth_service.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/core/services/secure_storage_service.dart';
import 'package:quickboom_app/shared/models/data_capture_record.dart';
import 'package:quickboom_app/shared/services/data_capture_records_service.dart';
import 'package:quickboom_app/shared/views/data_capture/data_capture_records_screen.dart';
import 'package:quickboom_app/shared/views/leads/leads_view.dart';

class _Adapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions) handler;
  _Adapter(this.handler);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async => handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody _body(Object value, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(value),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, dynamic> _record({bool imported = false}) => {
  'id': 37,
  'businessName': 'Captured business',
  'status': imported ? 'LEAD_IMPORTED' : 'VALIDATED',
  'isImported': imported,
  'phone': '1234567890',
  'website': 'https://example.test',
  'googleMapsUrl': 'https://maps.google.com',
};

Map<String, dynamic> _result({String outcome = 'imported'}) => {
  for (final key in ['imported', 'alreadyImported', 'skipped', 'failed']) ...{
    key: key == outcome
        ? [
            {
              'captureId': 37,
              'leadId': 137,
              'reason': 'Only validated records can be imported',
            },
          ]
        : [],
    '${key}Count': key == outcome ? 1 : 0,
  },
};

Future<void> _open(WidgetTester tester, {bool imported = false}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: DataCaptureRecordScreen(
          record: DataCaptureRecord.fromJson(_record(imported: imported)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _button(String label) => find.widgetWithText(FilledButton, label);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('employee defaults enable capture import without unrelated edit access', () {
    for (final isCrm in [false, true]) {
      final permissions = PermissionState(
        permissions: AuthService.defaultEmployeeCapabilities(isCrm: isCrm),
        isInitialized: true,
      );
      expect(permissions.canEdit('DATA_CAPTURE'), isTrue);
      expect(permissions.canDelete('DATA_CAPTURE'), isFalse);
      expect(permissions.canEdit('LEADS'), isFalse);
    }
  });
  test('unauthorized import uses the existing sign-in error message', () {
    final request = RequestOptions(path: '/data-capture/import-to-leads');
    expect(
      dataCaptureError(DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 401),
      )),
      'Please sign in again.',
    );
  });
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

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(568, 320),
  ]) {
    testWidgets('safe and scrollable actions at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      ApiClient().dio.httpClientAdapter = _Adapter(
        (_) => _body({'data': _record()}),
      );
      await _open(tester);
      expect(_button('Import to Leads'), findsOneWidget);
      expect(
        tester.getRect(_button('Import to Leads')).bottom,
        lessThanOrEqualTo(size.height - 34),
      );
      for (final label in ['Call', 'Website', 'Maps', 'Share']) {
        final action = find.widgetWithText(OutlinedButton, label);
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final outcome in ['imported', 'alreadyImported']) {
    testWidgets('$outcome uses actual ID and prevents resubmission', (
      tester,
    ) async {
      PermissionManager.instance.setPermissions([
        ...AuthService.defaultEmployeeCapabilities(),
      ], role: 'EMPLOYEE', isCrmEligible: true);
      final pending = Completer<ResponseBody>();
      var calls = 0;
      ApiClient().dio.httpClientAdapter = _Adapter((options) {
        if (options.method == 'POST') {
          calls++;
          expect(options.path, '/data-capture/import-to-leads');
          expect(options.data, {
            'placeIds': ['37'],
          });
          return pending.future;
        }
        return _body({'data': _record()});
      });
      await _open(tester);
      await tester.tap(_button('Import to Leads'));
      await tester.pump();
      expect(_button('Importing…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(_button('Importing…')).onPressed,
        isNull,
      );
      pending.complete(_body({'data': _result(outcome: outcome)}));
      await tester.pumpAndSettle();
      expect(find.byType(LeadsView), findsOneWidget);
      Navigator.of(tester.element(find.byType(LeadsView))).pop();
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(_button('Imported')).onPressed,
        isNull,
      );
      expect(calls, 1);
    });
  }

  testWidgets('existing import status disables action without a POST', (
    tester,
  ) async {
    ApiClient().dio.httpClientAdapter = _Adapter((options) {
      expect(options.method, 'GET');
      return _body({'data': _record(imported: true)});
    });
    await _open(tester, imported: true);
    expect(tester.widget<FilledButton>(_button('Imported')).onPressed, isNull);
  });

  for (final status in [400, 403, 500, 0]) {
    testWidgets('API failure $status displays feedback and enables retry', (
      tester,
    ) async {
      ApiClient().dio.httpClientAdapter = _Adapter((options) {
        if (options.method == 'GET') return _body({'data': _record()});
        if (status == 0) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return _body({
          'message': 'Only validated records can be imported',
        }, status);
      });
      await _open(tester);
      final message = switch (status) {
        403 => 'You do not have permission for this action.',
        500 => 'Data Capture is unavailable. Please retry.',
        0 => 'Unable to connect. Check your connection and retry.',
        _ => 'Only validated records can be imported',
      };
      await tester.tap(_button('Import to Leads'));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(
        tester.widget<FilledButton>(_button('Import to Leads')).onPressed,
        isNotNull,
      );
      expect(_button('Imported'), findsNothing);
    });
  }
}
