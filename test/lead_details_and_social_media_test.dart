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
import 'package:quickboom_app/shared/models/data_capture_record.dart';
import 'package:quickboom_app/shared/models/lead_model.dart';
import 'package:quickboom_app/shared/models/social_media_model.dart';
import 'package:quickboom_app/shared/views/data_capture/data_capture_records_screen.dart';
import 'package:quickboom_app/shared/views/leads/lead_details_view.dart';
import 'package:quickboom_app/shared/widgets/contact_information_card.dart';
import 'package:quickboom_app/shared/widgets/social_media_profiles_card.dart';

class _CaptureAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions) handler;
  _CaptureAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Object data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SecureStorageService.setMockInitialValues({});
    PermissionManager.instance.setPermissions([
      const UserPermission(module: 'LEADS', action: 'VIEW'),
      const UserPermission(module: 'LEADS', action: 'EDIT'),
      const UserPermission(module: 'DATA_CAPTURE', action: 'VIEW'),
      const UserPermission(module: 'DATA_CAPTURE', action: 'EDIT'),
    ], role: 'BPO');
  });

  tearDown(() {
    SecureStorageService.clearMockValues();
    PermissionManager.instance.clear();
  });

  group('ContactInformationCard Tests', () {
    testWidgets('Renders all available contact details with actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ContactInformationCard(
                businessName: 'Acme Corporation',
                contactPerson: 'Jane Doe',
                phone: '+919876543210',
                email: 'jane@acme.test',
                website: 'acme.test',
                address: '123 Market Street',
                city: 'Pune',
                state: 'Maharashtra',
                pincode: '411001',
                country: 'India',
                category: 'Technology',
                googlePlaceId: 'ChIJ12345',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contact Information'), findsOneWidget);
      expect(find.text('Acme Corporation'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('+919876543210'), findsOneWidget);
      expect(find.text('jane@acme.test'), findsOneWidget);
      expect(find.text('acme.test'), findsOneWidget);
      expect(
        find.text('123 Market Street, Pune, Maharashtra, 411001, India'),
        findsOneWidget,
      );
      expect(find.text('Technology'), findsOneWidget);

      // Action tooltips
      expect(find.byTooltip('Call Mobile Number'), findsOneWidget);
      expect(find.byTooltip('Send Email'), findsOneWidget);
      expect(find.byTooltip('Open Website'), findsOneWidget);
      expect(find.byTooltip('Open in Google Maps'), findsOneWidget);
    });

    testWidgets('Hides empty and missing fields gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ContactInformationCard(
                businessName: 'Sole Traders',
                // phone, email, website, address missing
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contact Information'), findsOneWidget);
      expect(find.text('Sole Traders'), findsOneWidget);

      expect(find.text('Mobile Number'), findsNothing);
      expect(find.text('Email Address'), findsNothing);
      expect(find.text('Website'), findsNothing);
      expect(find.text('Business Address'), findsNothing);
    });

    testWidgets('Returns SizedBox.shrink() when all fields are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContactInformationCard())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contact Information'), findsNothing);
    });
  });

  group('SocialMediaProfilesCard Tests', () {
    testWidgets('Renders multiple platform profiles with icons and handles', (
      tester,
    ) async {
      final social = {
        'instagram': 'https://instagram.com/acme_biz',
        'facebook': 'https://facebook.com/acme.biz',
        'linkedin': 'acme-inc',
        'twitter': '@acme_tweets',
        'youtube': 'https://youtube.com/@acme_channel',
        'threads': '@acme_threads',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SocialMediaProfilesCard(socialMedia: social),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Social Media Profiles'), findsOneWidget);
      expect(find.text('6 profiles'), findsOneWidget);

      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('@acme_biz'), findsOneWidget);

      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('acme.biz'), findsOneWidget);

      expect(find.text('LinkedIn'), findsOneWidget);
      expect(find.text('@acme-inc'), findsOneWidget);

      expect(find.text('X (Twitter)'), findsOneWidget);
      expect(find.text('@acme_tweets'), findsOneWidget);

      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Threads'), findsOneWidget);
    });

    testWidgets('Ignores empty and whitespace social media entries', (
      tester,
    ) async {
      final social = {
        'instagram': '',
        'facebook': '   ',
        'linkedin': 'valid_handle',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SocialMediaProfilesCard(socialMedia: social),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Social Media Profiles'), findsOneWidget);
      expect(find.text('1 profile'), findsOneWidget);
      expect(find.text('LinkedIn'), findsOneWidget);
      expect(find.text('Instagram'), findsNothing);
      expect(find.text('Facebook'), findsNothing);
    });

    testWidgets('Returns SizedBox.shrink() when socialMedia is null or empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SocialMediaProfilesCard(socialMedia: null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Social Media Profiles'), findsNothing);
    });
  });

  group('LeadDetailsView Contact & Social Media Integration Tests', () {
    testWidgets(
      'Displays ContactInformationCard and SocialMediaProfilesCard for Lead',
      (tester) async {
        final lead = LeadModel(
          id: '101',
          companyName: 'Apex Logistics',
          firstName: 'Robert',
          lastName: 'Taylor',
          phone: '+919876500000',
          email: 'robert@apex.test',
          website: 'apex.test',
          address: '45 Harbour Road',
          city: 'Mumbai',
          state: 'Maharashtra',
          pincode: '400001',
          country: 'India',
          category: 'Freight & Logistics',
          source: 'MANUAL',
          createdFrom: 'ADMIN_PANEL',
          status: 'NEW',
          socialMedia: const SocialMediaModel(
            instagram: 'apex_logistics',
            linkedin: 'https://linkedin.com/in/robert-taylor',
          ),
        );

        ApiClient().dio.httpClientAdapter = _CaptureAdapter((options) {
          if (options.path.startsWith('/leads/stages')) {
            return _jsonBody({'data': []});
          }
          if (options.path == '/leads') {
            return _jsonBody({
              'data': [lead.toJson()],
            });
          }
          if (options.path == '/leads/101') {
            return _jsonBody({'data': lead.toJson()});
          }
          return _jsonBody({'data': null});
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: LeadDetailsView(leadId: '101', initialLead: lead),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Contact Information'), findsOneWidget);
        expect(find.text('Apex Logistics'), findsWidgets);
        expect(find.text('Robert Taylor'), findsWidgets);
        expect(find.text('+919876500000'), findsOneWidget);
        expect(find.text('robert@apex.test'), findsOneWidget);
        expect(find.text('apex.test'), findsOneWidget);
        expect(
          find.text('45 Harbour Road, Mumbai, Maharashtra, 400001, India'),
          findsOneWidget,
        );

        expect(find.text('Social Media Profiles'), findsOneWidget);
        expect(find.text('Instagram'), findsOneWidget);
        expect(find.text('LinkedIn'), findsOneWidget);
      },
    );

    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      testWidgets(
        'Renders LeadDetailsView cleanly without RenderFlex overflow at width ${width.toInt()}px',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final lead = LeadModel(
            id: '202',
            companyName: 'Evergreen Enterprises',
            firstName: 'Alexander',
            lastName: 'Montgomery-Smith',
            phone: '+919876543210',
            email: 'alexander.montgomery@evergreen.test',
            website: 'evergreenenterprises.test',
            address: '789 Commerce Way, Suite 400',
            city: 'Bengaluru',
            state: 'Karnataka',
            pincode: '560001',
            country: 'India',
            category: 'Enterprise Solutions',
            source: 'GOOGLE_ADS_SEARCH_CAMPAIGN',
            createdFrom: 'MOBILE_APPLICATION_CRM',
            status: 'IN_PROGRESS',
          );

          ApiClient().dio.httpClientAdapter = _CaptureAdapter((options) {
            if (options.path.startsWith('/leads/stages')) {
              return _jsonBody({'data': []});
            }
            if (options.path == '/leads') {
              return _jsonBody({
                'data': [lead.toJson()],
              });
            }
            if (options.path == '/leads/202') {
              return _jsonBody({'data': lead.toJson()});
            }
            return _jsonBody({'data': null});
          });

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: LeadDetailsView(leadId: '202', initialLead: lead),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.text('SOURCE: GOOGLE_ADS_SEARCH_CAMPAIGN'),
            findsOneWidget,
          );
          expect(find.text('FROM: MOBILE_APPLICATION_CRM'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('DataCaptureRecordScreen Social Media and Email Action Tests', () {
    testWidgets('Displays SocialMediaProfilesCard and Send Email action', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final captureRecord = DataCaptureRecord.fromJson({
        'id': 55,
        'businessName': 'Starlight Cafe',
        'status': 'VALIDATED',
        'address': 'MG Road, Bengaluru',
        'phone': '+918023456789',
        'email': 'contact@starlight.test',
        'website': 'starlightcafe.test',
        'isImported': false,
        'socialMedia': {
          'instagram': 'starlight_cafe',
          'facebook': 'starlightcafeofficial',
        },
      });

      ApiClient().dio.httpClientAdapter = _CaptureAdapter((options) {
        return _jsonBody({'data': captureRecord.fields});
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DataCaptureRecordScreen(record: captureRecord),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Starlight Cafe'), findsOneWidget);
      expect(find.text('Send Email'), findsOneWidget);
      expect(find.text('Social Media Profiles'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('Import to Leads'), findsOneWidget);
    });
  });
}
