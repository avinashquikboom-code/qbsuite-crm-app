import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickboom_app/core/models/permission_model.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/core/services/secure_storage_service.dart';
import 'package:quickboom_app/shared/services/data_capture_records_service.dart';
import 'package:quickboom_app/shared/views/data_capture/data_capture_records_screen.dart';
import 'package:quickboom_app/shared/views/leads/leads_view.dart';
import 'package:quickboom_app/shared/viewmodels/leads_viewmodel.dart';

ResponseBody jsonBody(Object body, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class CaptureAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions) handler;
  CaptureAdapter(this.handler);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => handler(options);
  @override
  void close({bool force = false}) {}
}

ApiClient client(FutureOr<ResponseBody> Function(RequestOptions) handler) =>
    ApiClient.forTesting(
      dio: Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
        ..httpClientAdapter = CaptureAdapter(handler),
      refreshDio: Dio(),
    );

Map<String, dynamic> record(int id, {String status = 'VALIDATED', bool isImported = false}) => {
  'id': id,
  'businessName': 'Business $id',
  'status': status,
  'address': 'Address $id',
  'phone': '+919876543210',
  'isImported': isImported,
  'capturedAt': '2026-10-25T06:00:00Z',
};

Map<String, dynamic> result({
  int importedCount = 1,
  int alreadyImportedCount = 0,
  int skippedCount = 0,
  int failedCount = 0,
  List<Map<String, dynamic>>? importedList,
  List<Map<String, dynamic>>? alreadyImportedList,
  List<Map<String, dynamic>>? failedList,
  List<Map<String, dynamic>>? skippedList,
}) => {
  'imported': importedList ?? (importedCount > 0 ? [{'captureId': 12, 'leadId': 112}] : []),
  'importedCount': importedCount,
  'alreadyImported': alreadyImportedList ?? (alreadyImportedCount > 0 ? [{'captureId': 14, 'leadId': 114}] : []),
  'alreadyImportedCount': alreadyImportedCount,
  'skipped': skippedList ?? [],
  'skippedCount': skippedCount,
  'failed': failedList ?? (failedCount > 0 ? [{'captureId': 13, 'reason': 'Record unavailable'}] : []),
  'failedCount': failedCount,
};

Finder checkbox(String label) => find.byWidgetPredicate(
  (widget) => widget is Checkbox && widget.semanticLabel == label,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    final token =
        'fixture.${base64Url.encode(utf8.encode(jsonEncode({'sub': 7, 'exp': 4102444800}))).replaceAll('=', '')}.signature';
    SecureStorageService.setMockInitialValues({'access_token': token});
    PermissionManager.instance.setPermissions([
      const UserPermission(module: 'DATA_CAPTURE', action: 'VIEW'),
      const UserPermission(module: 'DATA_CAPTURE', action: 'EDIT'),
      const UserPermission(module: 'DATA_CAPTURE', action: 'CREATE'),
      const UserPermission(module: 'LEADS', action: 'VIEW'),
    ], role: 'BPO');
  });
  tearDown(() {
    SecureStorageService.clearMockValues();
    PermissionManager.instance.clear();
  });

  test(
    'import uses only selected stable IDs and verifies the existing nested result',
    () async {
      final service = DataCaptureRecordsService(
        client((options) {
          expect(options.method, 'POST');
          expect(options.path, '/data-capture/import-to-leads');
          expect(options.data, {
            'placeIds': ['12'],
          });
          expect(options.headers['Authorization'], startsWith('Bearer '));
          return jsonBody({
            'success': true,
            'data': {'success': true, 'data': result()},
          });
        }),
      );
      expect((await service.importSelected([12, 12]))['importedCount'], 1);
    },
  );

  test('bulk placeIds import preserves duplicate results and actual validation messages', () async {
    final service = DataCaptureRecordsService(client((options) {
      expect(options.data, {'placeIds': ['12', '13']});
      return jsonBody({'data': result(
        alreadyImportedCount: 1,
        alreadyImportedList: [{'captureId': 13, 'leadId': 113}],
      )});
    }));
    final imported = await service.importSelected([12, 13, 12]);
    expect(imported['importedCount'], 1);
    expect(imported['alreadyImportedCount'], 1);
    final invalid = DataCaptureRecordsService(client((_) => jsonBody({
      'message': ['property ids should not exist'],
      'error': 'Bad Request', 'statusCode': 400,
    }, 400)));
    await expectLater(invalid.importSelected([12]), throwsA(predicate((error) =>
      error is DioException && dataCaptureError(error) == 'property ids should not exist')));
  });

  test('legacy response verifies persisted links without repeating import', () async {
    var posts = 0;
    final service = DataCaptureRecordsService(client((options) {
      if (options.method == 'POST') {
        posts++;
        return jsonBody({'success': true, 'data': {}});
      }
      if (options.path == '/data-capture/12') {
        return jsonBody({'data': {...record(12), 'importedLeadId': 112}});
      }
      expect(options.path, '/leads/112');
      return jsonBody({'data': {'id': 112, 'companyName': 'Business 12', 'status': 'NEW'}});
    }));
    expect((await service.importSelected([12]))['importedCount'], 1);
    expect(posts, 1);
  });

  for (final count in [1, 2]) {
    testWidgets('$count successful records keep dialog loading then open fresh pipeline', (tester) async {
      final gate = Completer<ResponseBody>();
      var posts = 0, leadFetches = 0;
      final ids = List.generate(count, (i) => 11 + i);
      final api = client((options) {
        if (options.method == 'POST') {
          posts++;
          expect(options.data, {'placeIds': ids.map((id) => '$id').toList()});
          return gate.future;
        }
        if (options.path == '/leads/stages') {
          return jsonBody({'data': [{'id': 1, 'key': 'NEW', 'name': 'New', 'sortOrder': 1}]});
        }
        if (options.path == '/leads') {
          leadFetches++;
          return jsonBody({'data': ids.map((id) => {
            'id': id + 100, 'companyName': 'Imported $id', 'status': 'NEW', 'stageId': 1,
          }).toList()});
        }
        return jsonBody({'data': ids.map(record).toList(),
          'pagination': {'page': 1, 'totalPages': 1, 'total': count}});
      });
      final container = ProviderContainer(overrides: [apiClientProvider.overrideWithValue(api)]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(container: container,
        child: const MaterialApp(home: DataCaptureRecordsScreen())));
      await tester.pumpAndSettle();
      await tester.tap(checkbox('Select all records on this page'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import to Leads ($count)'));
      await tester.pumpAndSettle();
      final confirm = find.widgetWithText(FilledButton, count == 1 ? 'Import Record' : 'Import Records');
      await tester.tap(confirm);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AlertDialog), findsOneWidget);
      final importButton = find.descendant(of: find.byType(AlertDialog), matching: find.byType(FilledButton));
      expect(tester.widget<FilledButton>(importButton).onPressed, isNull);
      expect(find.descendant(of: importButton, matching: find.byType(CircularProgressIndicator)), findsOneWidget);
      expect(posts, 1);
      gate.complete(jsonBody({'success': true, 'data': result(importedCount: count,
        importedList: ids.map((id) => {'captureId': id, 'leadId': id + 100}).toList())}));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(LeadsView), findsOneWidget);
      expect(find.text('$count ${count == 1 ? 'record' : 'records'} imported successfully!'), findsWidgets);
      for (final id in ids) { expect(find.text('Imported $id'), findsOneWidget); }
      expect(container.read(leadsProvider).requireValue.every((lead) => lead.status == 'NEW'), isTrue);
      final before = leadFetches;
      final refreshed = container.read(leadsProvider.notifier).refreshLeads();
      await tester.pumpAndSettle();
      await refreshed;
      expect(leadFetches, greaterThan(before));
      expect(container.read(leadsProvider).requireValue.length, count);
    });
  }

  test('empty and invalid IDs never reach the API', () async {
    var calls = 0;
    final service = DataCaptureRecordsService(client((_) {
      calls++;
      return jsonBody({'data': result()});
    }));
    for (final ids in <List<int>>[[], [0], [-1]]) {
      await expectLater(service.importSelected(ids), throwsArgumentError);
    }
    expect(calls, 0);
  });

  test(
    'HTTP failure and incomplete result propagate without a fabricated success',
    () async {
      final failure = DataCaptureRecordsService(
        client((_) => jsonBody({'message': 'Not permitted'}, 403)),
      );
      await expectLater(
        failure.importSelected([12]),
        throwsA(isA<DioException>()),
      );
      final incomplete = DataCaptureRecordsService(
        client((_) => jsonBody({'data': result()})),
      );
      await expectLater(
        incomplete.importSelected([12, 13]),
        throwsFormatException,
      );
    },
  );

  testWidgets(
    'Verification: single/multiple selection, Select All, Clear Selection, already imported, pagination, and FAB',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final importGate = Completer<ResponseBody>();
      var postCalls = 0;
      final api = client((options) {
        if (options.method == 'POST') {
          expect(options.path, '/data-capture/import-to-leads');
          expect((options.data as Map).keys, ['placeIds']);
          expect((options.data as Map)['placeIds'], unorderedEquals(['11', '12']));
          postCalls++;
          return importGate.future;
        }
        if (options.path == '/leads/stages') {
          return jsonBody({'data': [{'id': 1, 'key': 'NEW', 'name': 'New', 'sortOrder': 1}]});
        }
        if (options.path == '/leads') {
          return jsonBody({'data': [{'id': 112, 'companyName': 'Imported business', 'status': 'NEW'}]});
        }
        expect(options.path, '/data-capture');
        final page = options.queryParameters['page'] as int;
        return jsonBody({
          'success': true,
          'data': (page == 1 ? [11, 12] : [13]).map(record).toList(),
          'pagination': {'page': page, 'totalPages': 2, 'total': 3},
        });
      });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DataCaptureRecordsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial State: FloatingActionButton is present when 0 records selected
      expect(find.byType(FloatingActionButton), findsOneWidget);
      // Checkboxes are directly available on each card and header
      expect(checkbox('Select all records on this page'), findsOneWidget);
      expect(checkbox('Select Business 11'), findsOneWidget);
      expect(checkbox('Select Business 12'), findsOneWidget);
      // No bottom action bar when 0 records selected
      expect(find.text('Import to Leads (1)'), findsNothing);
      expect(find.text('Clear Selection'), findsNothing);

      // 2. Select single record
      await tester.tap(checkbox('Select Business 11'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Import to Leads (1)'), findsOneWidget);
      expect(find.text('Clear Selection'), findsOneWidget);
      // FloatingActionButton hidden when records are selected to prevent overlap
      expect(find.byType(FloatingActionButton), findsNothing);

      // 3. Clear selection from bottom bar
      await tester.tap(find.text('Clear Selection'));
      await tester.pumpAndSettle();
      expect(find.text('Import to Leads (1)'), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // 4. Select All on page
      await tester.tap(checkbox('Select all records on this page'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
      expect(find.text('Import to Leads (2)'), findsOneWidget);

      // 5. Deselect one record on page
      await tester.tap(checkbox('Select Business 11'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Import to Leads (1)'), findsOneWidget);

      // 6. Reselect Business 11
      await tester.tap(checkbox('Select Business 11'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
      expect(find.text('Import to Leads (2)'), findsOneWidget);

      // 7. Submit Import with Confirmation Cancel then Confirm
      await tester.tap(find.text('Import to Leads (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Import 2 records?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel').last);
      await tester.pumpAndSettle();
      expect(postCalls, 0);

      // Confirm Import
      await tester.tap(find.text('Import to Leads (2)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import Records'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(postCalls, 1);
      expect(find.text('Importing…'), findsOneWidget);

      // 8. Handle Partial Result (1 imported, 1 failed)
      importGate.complete(
        jsonBody({
          'success': true,
          'data': result(
            importedCount: 1,
            failedCount: 1,
            failedList: [
              {'captureId': 11, 'reason': 'Record unavailable'}
            ],
          ),
        }),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LeadsView), findsOneWidget);
      expect(find.textContaining('1 record imported successfully!'), findsWidgets);
      Navigator.of(tester.element(find.byType(LeadsView))).pop();
      await tester.pumpAndSettle();
      // Failed record remains selected for retry
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Import to Leads (1)'), findsOneWidget);

      // Clear remaining selection
      await tester.tap(find.text('Clear Selection'));
      await tester.pumpAndSettle();
      expect(find.text('Import to Leads (1)'), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Verification: Already imported record shows count and status',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = client((options) {
        if (options.method == 'POST') {
          return jsonBody({
            'success': true,
            'data': result(
              importedCount: 0,
              alreadyImportedCount: 1,
              importedList: [],
              alreadyImportedList: [{'captureId': 14, 'leadId': 200}],
            ),
          });
        }
        return jsonBody({
          'success': true,
          'data': [record(14, status: 'LEAD_IMPORTED', isImported: true)],
          'pagination': {'page': 1, 'totalPages': 1, 'total': 1},
        });
      });
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DataCaptureRecordsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lead Imported'), findsOneWidget);
      await tester.tap(checkbox('Select Business 14'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Import to Leads (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Import to Leads?'), findsOneWidget);
      await tester.tap(find.text('Import Record'));
      await tester.pumpAndSettle();

      expect(find.byType(LeadsView), findsOneWidget);
      Navigator.of(tester.element(find.byType(LeadsView))).pop();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Verification: UI responsive on different screen sizes (320, 480, 800 width)',
    (tester) async {
      for (final size in [
        const Size(320, 640),
        const Size(480, 800),
        const Size(800, 1200),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;

        final api = client((options) {
          return jsonBody({
            'success': true,
            'data': [record(20)],
            'pagination': {'page': 1, 'totalPages': 1, 'total': 1},
          });
        });
        final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(api)],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(home: DataCaptureRecordsScreen(key: ValueKey(size))),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(checkbox('Select Business 20'));
        await tester.pumpAndSettle();

        expect(find.text('1 selected'), findsOneWidget);
        expect(find.text('Import to Leads (1)'), findsOneWidget);
        expect(find.text('Clear Selection'), findsOneWidget);
        expect(tester.takeException(), isNull);

        container.dispose();
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
