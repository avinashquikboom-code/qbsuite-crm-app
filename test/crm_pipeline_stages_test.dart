import 'dart:convert';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickboom_app/shared/services/lead_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/shared/models/lead_model.dart';
import 'package:quickboom_app/shared/models/lead_stage_model.dart';
import 'package:quickboom_app/shared/viewmodels/lead_stages_viewmodel.dart';
import 'package:quickboom_app/shared/views/leads/lead_details_view.dart';

List<LeadStageModel> fixtureStages() =>
    (jsonDecode(File('test/fixtures/lead_stages.json').readAsStringSync())
            as List)
        .map(
          (item) =>
              LeadStageModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

class FixtureLeadService extends LeadService {
  @override
  Future<List<LeadStageModel>> getStages() async => fixtureStages();
  @override
  Future<LeadModel> getLeadById(String id) async => LeadModel(
    id: id,
    companyName: 'Gold Gym Aundh',
    source: 'DATA_CAPTURE',
    createdFrom: 'ADMIN_PANEL',
    status: 'NEW',
    stageId: 1,
    stage: fixtureStages().first,
  );
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  group('CRM 11 Pipeline Stages Contract Tests', () {
    test('backend stage fixture contains the configured labels and order', () {
      final stages = fixtureStages();
      expect(stages.length, 11);

      final expectedOrder = [
        {'sortOrder': 1, 'name': 'New', 'key': 'NEW'},
        {'sortOrder': 2, 'name': 'Contacted', 'key': 'CONTACTED'},
        {'sortOrder': 3, 'name': 'Details send', 'key': 'DETAILS_SEND'},
        {'sortOrder': 4, 'name': 'Follow-up', 'key': 'FOLLOW_UP'},
        {'sortOrder': 5, 'name': 'Visit Scheduled', 'key': 'VISIT_SCHEDULED'},
        {'sortOrder': 6, 'name': 'Visit Done', 'key': 'VISIT_DONE'},
        {'sortOrder': 7, 'name': 'Proposal Sent', 'key': 'PROPOSAL_SENT'},
        {'sortOrder': 8, 'name': 'Negotiation', 'key': 'NEGOTIATION'},
        {'sortOrder': 9, 'name': 'Final Call', 'key': 'FINAL_CALL'},
        {'sortOrder': 10, 'name': 'Won', 'key': 'WON'},
        {'sortOrder': 11, 'name': 'Lost', 'key': 'LOST'},
      ];

      for (int i = 0; i < 11; i++) {
        expect(stages[i].sortOrder, expectedOrder[i]['sortOrder']);
        expect(stages[i].name, expectedOrder[i]['name']);
        expect(stages[i].key, expectedOrder[i]['key']);
        expect(stages[i].isActive, isTrue);
        expect(stages[i].stageColor, isNotNull);
        expect(stages[i].stageBgColor, isNotNull);
        expect(stages[i].stageBorderColor, isNotNull);
      }
    });

    test('LeadStageModel parses JSON correctly', () {
      final json = {
        'id': 3,
        'key': 'DETAILS_SEND',
        'name': 'Details send',
        'sortOrder': 3,
        'isActive': true,
        'color': '#4F46E5',
        'bgColor': '#EEF2FF',
        'borderColor': '#C7D2FE',
      };

      final stage = LeadStageModel.fromJson(json);
      expect(stage.id, 3);
      expect(stage.key, 'DETAILS_SEND');
      expect(stage.name, 'Details send');
      expect(stage.sortOrder, 3);
      expect(stage.stageColor, const Color(0xFF4F46E5));
      expect(stage.stageBgColor, const Color(0xFFEEF2FF));
    });

    test(
      'LeadModel parses lead with nested stage and provides correct fallbacks',
      () {
        final leadJson = {
          'id': '101',
          'companyName': 'Acme Fitness Corp',
          'firstName': 'John',
          'lastName': 'Doe',
          'phone': '+919876543210',
          'source': 'GOOGLE_MAPS',
          'createdFrom': 'DATA_CAPTURE',
          'status': 'NEW',
          'stageId': 1,
          'stage': {
            'id': 1,
            'key': 'NEW',
            'name': 'New',
            'sortOrder': 1,
            'color': '#0284C7',
            'bgColor': '#E0F2FE',
            'borderColor': '#BAE6FD',
          },
        };

        final lead = LeadModel.fromJson(leadJson);
        expect(lead.id, '101');
        expect(lead.displayName, 'Acme Fitness Corp');
        expect(lead.fullName, 'John Doe');
        expect(lead.stageName, 'New');
        expect(lead.stageColor, const Color(0xFF0284C7));
        expect(lead.stageBgColor, const Color(0xFFE0F2FE));
      },
    );

    test(
      'LeadStagesNotifier resolves API stages and nextStage correctly',
      () async {
        final container = ProviderContainer(
          overrides: [
            leadServiceProvider.overrideWithValue(FixtureLeadService()),
          ],
        );
        addTearDown(container.dispose);

        await container.read(leadStagesProvider.future);
        final notifier = container.read(leadStagesProvider.notifier);

        // Alias resolution
        final resolvedDetails = notifier.resolveLeadStage(null, 'DETAILS_SENT');
        expect(resolvedDetails, isNotNull);
        expect(resolvedDetails!.key, 'DETAILS_SEND');
        expect(resolvedDetails.sortOrder, 3);

        final resolvedVisit = notifier.resolveLeadStage(null, 'VISIT');
        expect(resolvedVisit, isNotNull);
        expect(resolvedVisit!.key, 'VISIT_SCHEDULED');

        // Next stage progression
        final nextAfterNew = notifier.nextStage(1, 'NEW');
        expect(nextAfterNew, isNotNull);
        expect(nextAfterNew!.key, 'CONTACTED');
        expect(nextAfterNew.sortOrder, 2);

        final nextAfterWon = notifier.nextStage(10, 'WON');
        expect(nextAfterWon, isNotNull);
        expect(nextAfterWon!.key, 'LOST');

        final nextAfterLost = notifier.nextStage(11, 'LOST');
        expect(nextAfterLost, isNull); // Terminal stage
      },
    );
  });

  group('LeadDetailsView Widget Tests', () {
    testWidgets('Renders LeadDetailsView with New stage highlighted', (
      tester,
    ) async {
      const testLead = LeadModel(
        id: '99',
        companyName: 'Gold Gym Aundh',
        firstName: 'Avinash',
        lastName: 'Magar',
        phone: '+917447485011',
        email: 'customer.care@goldsgym.in',
        city: 'Pune',
        source: 'GOOGLE_PLACES',
        createdFrom: 'DATA_CAPTURE',
        status: 'NEW',
        stageId: 1,
        stage: LeadStageModel(
          id: 1,
          key: 'NEW',
          name: 'New',
          sortOrder: 1,
          color: '#0284C7',
          bgColor: '#E0F2FE',
          borderColor: '#BAE6FD',
        ),
      );

      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            leadServiceProvider.overrideWithValue(FixtureLeadService()),
          ],
          child: const MaterialApp(
            home: LeadDetailsView(leadId: '99', initialLead: testLead),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify business name and stage display
      expect(find.text('Gold Gym Aundh'), findsWidgets);
      expect(find.text('Pipeline Stage'), findsOneWidget);
      expect(find.text('Advance to Contacted'), findsOneWidget);

      // Tap on stage selector button to open bottom sheet
      final stageButton = find.text('Tap to change pipeline stage');
      expect(stageButton, findsOneWidget);
      await tester.tap(stageButton);
      await tester.pumpAndSettle();

      // Bottom sheet should now be open
      expect(find.text('Select Pipeline Stage'), findsOneWidget);
      expect(
        find.text('Move this lead to any configured CRM stage'),
        findsOneWidget,
      );

      // Verify all 11 stages exist in the bottom sheet
      expect(find.text('New'), findsWidgets);
      expect(find.text('Contacted'), findsWidgets);
      expect(find.text('Details send'), findsWidgets);
      expect(find.text('Follow-up'), findsWidgets);
      expect(find.text('Visit Scheduled'), findsWidgets);
      expect(find.text('Visit Done'), findsWidgets);
      expect(find.text('Proposal Sent'), findsWidgets);
      expect(find.text('Negotiation'), findsWidgets);
      expect(find.text('Final Call'), findsWidgets);
      expect(find.text('Won'), findsWidgets);
      expect(find.text('Lost'), findsWidgets);

      // Verify 'Current' badge is shown for New
      expect(find.text('Current'), findsOneWidget);
    });
  });
}
