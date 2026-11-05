import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickboom_app/core/services/secure_storage_service.dart';
import 'package:quickboom_app/shared/services/lead_service.dart';
import 'package:quickboom_app/shared/viewmodels/lead_stages_viewmodel.dart';
import 'package:quickboom_app/shared/viewmodels/leads_viewmodel.dart';
import 'package:quickboom_app/shared/views/leads/leads_view.dart';
import 'lead_sync_and_auth_test.dart' as http;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final stages = (jsonDecode(File('test/fixtures/lead_stages.json').readAsStringSync()) as List).cast<Map<String,dynamic>>();
  final rows = stages.map((stage) => <String,dynamic>{
    'id': stage['id'], 'companyName': 'Record ${stage['key']}', 'source':'MANUAL',
    'status': stage['key'], 'stageId': stage['id'], 'stage':stage,
  }).toList();
  setUp(() => SecureStorageService.setMockInitialValues({'access_token':http.jwt(http.future),'refresh_token':'fixture-refresh','user_id':'7'}));
  tearDown(() => SecureStorageService.clearMockValues());

  for (final stage in stages) {
    test('${stage['name']} sends the configured ID on every page and preserves visit fields separately', () async {
      final requests = <Map<String,dynamic>>[];
      final api = http.client((request) {
        requests.add(Map<String,dynamic>.from(request.queryParameters));
        expect(request.path,'/leads');
        expect(request.queryParameters['stageId'],stage['id']);
        expect(request.queryParameters.containsKey('status'),false);
        expect(request.queryParameters['search'],'Fixture');
        final page=request.queryParameters['page'] as int;
        return http.jsonResponse({'data':[{
          ...rows.firstWhere((lead) => lead['stageId']==stage['id']),
          'id':page,'visitStatus':'SCHEDULED','assignedVisitorId':77,'visitScheduledAt':'2026-11-01',
        }], 'meta':{'totalPages':2,'total':2,'page':page}});
      }, (_) => throw StateError('Unexpected refresh'));
      final result=await LeadService(api).getLeads(status:'Display label must not be sent',stageId:stage['id'] as int,search:' Fixture ');
      expect(result.length,2);
      expect(requests.map((q)=>q['page']),[1,2]);
      expect(result.every((lead)=>lead.stageId==stage['id']),true);
      expect(result.first.visitStatus,'SCHEDULED');
      expect(result.first.assignedVisitorId,77);
      expect(result.first.status,stage['key']);
    });
  }
  test('All omits status and stage; scheduling submits Visitor ID/date/time to the existing API', () async {
    final api=http.client((request) {
      if(request.method=='GET') {
        expect(request.queryParameters.containsKey('stageId'),false);
        expect(request.queryParameters.containsKey('status'),false);
        return http.jsonResponse({'data':rows,'meta':{'totalPages':1}});
      }
      expect(request.path,'/leads/1/visits');
      expect(request.data['employeeId'],77);
      expect(request.data['date'],'2026-11-01');
      expect(request.data['time'],'10:30 AM');
      return http.jsonResponse({'data':{...rows.first,'visitStatus':'SCHEDULED','assignedVisitorId':77}});
    }, (_) => throw StateError('Unexpected refresh'));
    final service=LeadService(api);
    expect((await service.getLeads()).length,stages.length);
    final saved=await service.manageVisit('1',action:'SCHEDULE',employeeId:77,date:'2026-11-01',time:'10:30 AM');
    expect(saved.assignedVisitorId,77);
  });
  testWidgets('Visit Scheduled renders only matching API records; search and refresh preserve the stage and global badge count', (tester) async {
    final requests=<Map<String,dynamic>>[];
    final api=http.client((request) {
      if(request.path=='/leads/stages')return http.jsonResponse({'data':stages});
      requests.add(Map<String,dynamic>.from(request.queryParameters));
      final id=request.queryParameters['stageId'];
      final search=request.queryParameters['search'];
      final filtered=rows.where((row)=>(id==null||row['stageId']==id)&&(search==null||row['companyName'].toString().contains(search))).toList();
      return http.jsonResponse({'data':filtered,'meta':{'totalPages':1,'total':filtered.length}});
    }, (_) => throw StateError('Unexpected refresh'));
    final container=ProviderContainer(overrides:[leadServiceProvider.overrideWithValue(LeadService(api))]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container:container,child:const MaterialApp(home:LeadsView())));
    await tester.pumpAndSettle();
    final scheduled=stages.firstWhere((stage)=>stage['key']=='VISIT_SCHEDULED');
    final chip=find.text('Visit Scheduled').first;
    await tester.ensureVisible(chip);await tester.tap(chip);await tester.pumpAndSettle();
    expect(requests.last['stageId'],scheduled['id']);
    expect(find.text('Record VISIT_SCHEDULED'),findsOneWidget);
    expect(find.text('Record NEW'),findsNothing);
    await tester.enterText(find.byType(TextField),'no-match');
    await tester.testTextInput.receiveAction(TextInputAction.done);await tester.pumpAndSettle();
    expect(find.text('No leads found'),findsOneWidget);
    expect(container.read(leadsStageCountsProvider)['VISIT_SCHEDULED'],1);
    expect(requests.last['stageId'],scheduled['id']);
    expect(requests.last['search'],'no-match');
    final refresh = container.read(leadsProvider.notifier).refreshLeads();
    await tester.pumpAndSettle();
    await refresh;
    expect(requests.where((q)=>q['stageId']==scheduled['id']).last['search'],'no-match');
    expect(container.read(leadsProvider).requireValue,isEmpty);
  });

  testWidgets('Leads with stage NEW (even if legacy status is VISIT_SCHEDULED) never appear in Visit Scheduled tab', (tester) async {
    final conflictingRows = [
      {
        'id': 101,
        'companyName': 'Townhouse Godavari',
        'status': 'VISIT_SCHEDULED',
        'stageId': 5, // VISIT_SCHEDULED stage
        'stage': stages.firstWhere((s) => s['id'] == 5),
      },
      {
        'id': 102,
        'companyName': 'Ginger Nashik',
        'status': 'VISIT_SCHEDULED', // Conflicting legacy status!
        'stageId': 1, // NEW stage is authoritative!
        'stage': stages.firstWhere((s) => s['id'] == 1),
      },
      {
        'id': 103,
        'companyName': 'Hotel Yatrik',
        'status': 'NEW',
        'stageId': 1,
        'stage': stages.firstWhere((s) => s['id'] == 1),
      },
    ];

    final api = http.client((request) {
      if (request.path == '/leads/stages') return http.jsonResponse({'data': stages});
      // Return all leads even if query had stageId (simulating an un-filtered backend response)
      return http.jsonResponse({'data': conflictingRows, 'meta': {'totalPages': 1, 'total': conflictingRows.length}});
    }, (_) => throw StateError('Unexpected refresh'));

    final container = ProviderContainer(overrides: [leadServiceProvider.overrideWithValue(LeadService(api))]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MaterialApp(home: LeadsView())));
    await tester.pumpAndSettle();

    // Select Visit Scheduled tab
    final chip = find.text('Visit Scheduled').first;
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    // Townhouse Godavari must be present
    expect(find.text('Townhouse Godavari'), findsOneWidget);

    // Ginger Nashik and Hotel Yatrik MUST NOT appear in Visit Scheduled tab
    expect(find.text('Ginger Nashik'), findsNothing);
    expect(find.text('Hotel Yatrik'), findsNothing);
  });
}
