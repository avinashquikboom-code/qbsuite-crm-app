import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/shared/models/data_capture_model.dart';
import 'package:quickboom_app/shared/services/data_capture_service.dart';

void main() {
  group('DataCaptureService Freshness & Caching Tests', () {
    late DataCaptureService service;

    setUp(() {
      service = DataCaptureService();
    });

    test(
      'extractPlaces generates fresh category-specific and location-specific records',
      () async {
        final job = await service.extractPlaces(
          keyword: 'Dental Clinic',
          location: 'Pune',
          maxResults: 5,
        );

        expect(job.keyword, 'Dental Clinic');
        expect(job.location, 'Pune');
        expect(job.places.length, 5);

        // Verify that places are NOT generic gym names
        for (final place in job.places) {
          expect(place.businessName.toLowerCase(), isNot(contains('gym')));
          expect(place.category, 'Dental Clinic');
          expect(place.address, contains('Pune'));
          expect(place.phone, isNotEmpty);
        }
      },
    );

    test(
      'ExtractionJobRecord.fromJson unwraps nested backend data object properly',
      () {
        final wrappedBackendJson = {
          'statusCode': 201,
          'success': true,
          'message': 'Operation successful',
          'data': {
            'jobId': 'job_live_999',
            'keyword': 'Organic Bakery',
            'location': 'Mumbai',
            'requested': 10,
            'captured': 1,
            'places': [
              {
                'googlePlaceId': 'ChIJ_live_bakery_0',
                'businessName': 'Artisan Crust Bakery',
                'category': 'Bakery',
                'address': 'Plot 4, Bandra West, Mumbai',
                'phone': '+91 98200 11223',
                'rating': 4.8,
                'reviewCount': 120,
                'status': 'CAPTURED',
              },
            ],
          },
        };

        final record = ExtractionJobRecord.fromJson(wrappedBackendJson);
        expect(record.jobId, 'job_live_999');
        expect(record.keyword, 'Organic Bakery');
        expect(record.location, 'Mumbai');
        expect(record.places.length, 1);
        expect(record.places.first.businessName, 'Artisan Crust Bakery');
        expect(record.places.first.googlePlaceId, 'ChIJ_live_bakery_0');
        expect(record.places.first.rating, 4.8);
      },
    );

    test(
      'CapturedBusiness.fromJson correctly parses status and isImported',
      () {
        final importedJson = {
          'id': 42,
          'businessName': 'Sunrise Cafe',
          'category': 'Restaurant',
          'status': 'LEAD_CREATED',
        };

        final business = CapturedBusiness.fromJson(importedJson);
        expect(business.businessName, 'Sunrise Cafe');
        expect(business.isImported, isTrue);
      },
    );
  });
}
