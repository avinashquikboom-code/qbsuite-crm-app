import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/shared/models/lead_model.dart';
import 'package:quickboom_app/shared/models/lead_stage_model.dart';
import 'package:quickboom_app/shared/services/lead_service.dart';
import 'package:quickboom_app/shared/viewmodels/lead_stages_viewmodel.dart';
import 'package:quickboom_app/shared/views/leads/leads_view.dart';
import 'package:quickboom_app/shared/viewmodels/leads_viewmodel.dart';

List<LeadStageModel> testStages() {
  final file = File('test/fixtures/lead_stages.json');
  return (jsonDecode(file.readAsStringSync()) as List)
      .map((e) => LeadStageModel.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

class MockLeadService extends LeadService {
  final List<LeadModel> allLeads;
  final Duration? delay;
  final bool shouldFail;

  MockLeadService({
    required this.allLeads,
    this.delay,
    this.shouldFail = false,
  });

  @override
  Future<List<LeadStageModel>> getStages() async {
    if (delay != null) await Future.delayed(delay!);
    if (shouldFail) throw Exception('Stages API Failed');
    return testStages();
  }

  @override
  Future<List<LeadModel>> getLeads({
    String? status,
    int? stageId,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    if (delay != null) await Future.delayed(delay!);
    if (shouldFail) throw Exception('Failed to load leads from server');

    var result = List<LeadModel>.from(allLeads);
    if (stageId != null) result = result.where((lead) => lead.stageId == stageId || (lead.stageId == null && testStages().any((stage) => stage.id == stageId && stage.key == lead.status))).toList();
    if (stageId == null && status != null && status.isNotEmpty && status != 'ALL') {
      result = result
          .where((l) => l.status.toUpperCase() == status.toUpperCase())
          .toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result
          .where(
            (l) =>
                l.companyName.toLowerCase().contains(q) ||
                (l.firstName?.toLowerCase().contains(q) ?? false) ||
                (l.lastName?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    return result;
  }
}

Widget buildTestHarness(MockLeadService mockService) {
  return ProviderScope(
    overrides: [
      leadServiceProvider.overrideWithValue(mockService),
    ],
    child: const MaterialApp(
      home: LeadsView(),
    ),
  );
}

Finder findChip(String label) {
  return find.descendant(
    of: find.byType(SingleChildScrollView).first,
    matching: find.ancestor(
      of: find.text(label),
      matching: find.byType(InkWell),
    ),
  );
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('opening pipeline clears a previous route query', (tester) async {
    final service = MockLeadService(allLeads: [
      LeadModel.fromJson({
        'id': 137,
        'companyName': 'Imported capture',
        'status': 'NEW',
        'source': 'DATA_CAPTURE',
      }),
    ]);
    final container = ProviderContainer(overrides: [
      leadServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      container.read(leadsProvider);
      await Future<void>.delayed(Duration.zero);
      await container.read(leadsProvider.notifier).fetchLeads(
        status: 'LOST', search: 'previous search',
      );
    });
    expect(container.read(leadsProvider).requireValue, isEmpty);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LeadsView()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Imported capture'), findsOneWidget);
    expect(container.read(leadsProvider).requireValue.single.id, '137');
    await container.read(leadsProvider.notifier).refreshLeads();
    expect(container.read(leadsProvider).requireValue.single.id, '137');
  });

  final stages = testStages();
  final sampleLeads = [
    LeadModel(
      id: '1',
      companyName: 'Acme Fitness',
      firstName: 'John',
      lastName: 'Doe',
      source: 'MANUAL',
      createdFrom: 'ADMIN_PANEL',
      status: 'NEW',
      stageId: 1,
      stage: stages[0],
    ),
    LeadModel(
      id: '2',
      companyName: 'Bolt Gym',
      firstName: 'Jane',
      lastName: 'Smith',
      source: 'MANUAL',
      createdFrom: 'ADMIN_PANEL',
      status: 'NEW',
      stageId: 1,
      stage: stages[0],
    ),
    LeadModel(
      id: '3',
      companyName: 'Crown Wellness',
      firstName: 'Bob',
      lastName: 'Taylor',
      source: 'MANUAL',
      createdFrom: 'ADMIN_PANEL',
      status: 'CONTACTED',
      stageId: 2,
      stage: stages[1],
    ),
  ];

  testWidgets('1. Initial screen loading and correct filter counts', (tester) async {
    final mockService = MockLeadService(allLeads: sampleLeads);
    await tester.pumpWidget(buildTestHarness(mockService));
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Leads Pipeline'), findsOneWidget);

    // Verify All filter chip has count 3
    expect(findChip('All'), findsOneWidget);
    expect(
      find.descendant(of: findChip('All'), matching: find.text('3')),
      findsOneWidget,
    );

    // Verify New stage chip has count 2
    expect(findChip('New'), findsOneWidget);
    expect(
      find.descendant(of: findChip('New'), matching: find.text('2')),
      findsOneWidget,
    );

    // Verify Contacted stage chip has count 1
    expect(findChip('Contacted'), findsOneWidget);
    expect(
      find.descendant(of: findChip('Contacted'), matching: find.text('1')),
      findsOneWidget,
    );
  });

  testWidgets('2. Switching between All, New, and Contacted filters', (tester) async {
    final mockService = MockLeadService(allLeads: sampleLeads);
    await tester.pumpWidget(buildTestHarness(mockService));
    await tester.pumpAndSettle();

    // Initially on All: all 3 leads are visible
    expect(find.text('Acme Fitness'), findsOneWidget);
    expect(find.text('Bolt Gym'), findsOneWidget);
    expect(find.text('Crown Wellness'), findsOneWidget);

    // Switch to New filter
    await tester.tap(findChip('New'));
    await tester.pumpAndSettle();

    expect(find.text('Acme Fitness'), findsOneWidget);
    expect(find.text('Bolt Gym'), findsOneWidget);
    expect(find.text('Crown Wellness'), findsNothing);

    // Switch to Contacted filter
    await tester.tap(findChip('Contacted'));
    await tester.pumpAndSettle();

    expect(find.text('Crown Wellness'), findsOneWidget);
    expect(find.text('Acme Fitness'), findsNothing);
    expect(find.text('Bolt Gym'), findsNothing);

    // Switch back to All filter
    await tester.tap(findChip('All'));
    await tester.pumpAndSettle();

    expect(find.text('Acme Fitness'), findsOneWidget);
    expect(find.text('Bolt Gym'), findsOneWidget);
    expect(find.text('Crown Wellness'), findsOneWidget);
  });

  testWidgets('3. Search combined with filters', (tester) async {
    final mockService = MockLeadService(allLeads: sampleLeads);
    await tester.pumpWidget(buildTestHarness(mockService));
    await tester.pumpAndSettle();

    // Type 'Bolt' in search box
    await tester.enterText(find.byType(TextField), 'Bolt');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Bolt Gym'), findsOneWidget);
    expect(find.text('Acme Fitness'), findsNothing);
    expect(find.text('Crown Wellness'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Remix.close_circle_line));
    await tester.pumpAndSettle();

    expect(find.text('Bolt Gym'), findsOneWidget);
    expect(find.text('Acme Fitness'), findsOneWidget);
    expect(find.text('Crown Wellness'), findsOneWidget);
  });

  testWidgets('4. Empty results screen handling', (tester) async {
    final mockService = MockLeadService(allLeads: [], shouldFail: false);
    await tester.pumpWidget(buildTestHarness(mockService));
    await tester.pumpAndSettle();

    expect(find.text('No leads found'), findsOneWidget);
  });

  testWidgets('5. API failure displays error state and Retry button', (tester) async {
    final failService = MockLeadService(allLeads: [], shouldFail: true);
    await tester.pumpWidget(buildTestHarness(failService));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsWidgets);
  });

  testWidgets('6. Rapid filter switching does not cause race condition errors', (tester) async {
    final mockService = MockLeadService(
      allLeads: sampleLeads,
      delay: const Duration(milliseconds: 50),
    );
    await tester.pumpWidget(buildTestHarness(mockService));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();

    // Tap quickly across tabs
    await tester.tap(findChip('New'));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.tap(findChip('Contacted'));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.tap(findChip('New'));
    await tester.pumpAndSettle();

    // Should settle on New leads without crash or race condition
    expect(find.text('Acme Fitness'), findsOneWidget);
    expect(find.text('Bolt Gym'), findsOneWidget);
    expect(find.text('Crown Wellness'), findsNothing);
  });

  testWidgets('7. Small screen layouts (320px) render horizontally scrollable without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final mockService = MockLeadService(allLeads: sampleLeads);
    await tester.pumpWidget(buildTestHarness(mockService));
    await tester.pumpAndSettle();

    // Verify chips render without any RenderFlex overflow
    expect(tester.takeException(), isNull);
    expect(findChip('All'), findsOneWidget);
    expect(findChip('New'), findsOneWidget);

    // Scroll horizontally to reveal remaining stage chips
    await tester.drag(findChip('New'), const Offset(-250, 0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
