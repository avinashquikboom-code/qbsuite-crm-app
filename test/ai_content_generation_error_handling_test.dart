import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/network/api_exception.dart';

void main() {
  group('AI Content Generation Error Handling Tests', () {
    test('1. Insufficient credits parsing and format', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
          statusCode: 400,
          data: {
            'statusCode': 400,
            'message':
                'Insufficient AI credits. This action requires 10 credits, but your balance is 5. Please top up your wallet.',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.statusCode, 400);
      expect(apiException.isInsufficientCredits, isTrue);
      expect(apiException.requiredCredits, 10);
      expect(apiException.availableCredits, 5);
      expect(
        apiException.userMessage,
        'Insufficient AI credits. You need 10 credits, but you have 5.',
      );
    });

    test('2. Validation error with errors array', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
          statusCode: 400,
          data: {
            'statusCode': 400,
            'message': 'Prompt is required and cannot be empty.',
            'errors': ['prompt must be longer than or equal to 3 characters'],
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.statusCode, 400);
      expect(apiException.isInsufficientCredits, isFalse);
      expect(
        apiException.userMessage,
        'Prompt is required and cannot be empty.',
      );
      expect(
        apiException.errors,
        contains('prompt must be longer than or equal to 3 characters'),
      );
    });

    test('3. Network unavailable / connection error', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
        type: DioExceptionType.connectionError,
        message: 'Failed to connect to host',
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(
        apiException.userMessage,
        'Cannot reach server. Please check your internet connection and try again.',
      );
      expect(apiException.userMessage.contains('DioException'), isFalse);
    });

    test('4. 401 Session expired', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
          statusCode: 401,
          data: {'statusCode': 401, 'message': 'Unauthorized'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.statusCode, 401);
      expect(
        apiException.userMessage,
        'Your session has expired. Please log in again.',
      );
    });

    test('5. 403 Permission / access denied', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
          statusCode: 403,
          data: {'statusCode': 403, 'message': 'Forbidden resource'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.statusCode, 403);
      expect(
        apiException.userMessage,
        'Access denied. You do not have permission for this action.',
      );
    });

    test('6. 404 Resource not found', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
          statusCode: 404,
          data: {'statusCode': 404, 'message': 'Not Found'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.statusCode, 404);
      expect(apiException.userMessage, 'Requested resource was not found.');
    });

    test('7. 409 Conflict', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
          statusCode: 409,
          data: {
            'statusCode': 409,
            'message': 'A generation request is already in progress.',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.statusCode, 409);
      expect(
        apiException.userMessage,
        'A generation request is already in progress.',
      );
    });

    test('8. 422 Unprocessable Entity', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
          statusCode: 422,
          data: {
            'statusCode': 422,
            'message': 'Invalid aspect ratio specified.',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.statusCode, 422);
      expect(apiException.userMessage, 'Invalid aspect ratio specified.');
    });

    test('9. 429 Rate Limit', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
          statusCode: 429,
          data: {'statusCode': 429, 'message': 'Too many requests'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.statusCode, 429);
      expect(
        apiException.userMessage,
        'Too many requests. Please wait a moment before trying again.',
      );
    });

    test('10. 500 Backend error', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
          statusCode: 500,
          data: {'statusCode': 500, 'message': 'Internal server error'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.statusCode, 500);
      expect(
        apiException.userMessage,
        'Something went wrong on our end. Please try again later.',
      );
    });

    test('11. 502/503/504 Service temporarily unavailable', () {
      for (final code in [502, 503, 504]) {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
          response: Response(
            requestOptions: RequestOptions(
              path: '/api/v1/customer/ai/generate',
            ),
            statusCode: code,
          ),
          type: DioExceptionType.badResponse,
        );

        final apiException = ApiException.fromDioException(dioException);

        expect(apiException.statusCode, code);
        expect(
          apiException.userMessage,
          'Service temporarily unavailable. Please try again shortly.',
        );
      }
    });

    test(
      '12. AI provider failure returns safe message and no raw stack/URLs',
      () {
        final dioException = DioException(
          requestOptions: RequestOptions(
            path: '/api/v1/customer/ai/generate',
            baseUrl: 'https://internal-api-cluster.internal:3000',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/api/v1/customer/ai/generate',
            ),
            statusCode: 500,
            data: {
              'statusCode': 500,
              'message':
                  'Content generation is temporarily unavailable. Please try again.',
              'errorDetails': 'AI Engine timeout at socket 10.0.0.1:8080',
            },
          ),
          type: DioExceptionType.badResponse,
        );

        final apiException = ApiException.fromDioException(dioException);

        expect(apiException.statusCode, 500);
        expect(
          apiException.userMessage,
          'Content generation is temporarily unavailable. Please try again.',
        );
        // Verify no leak of internal URLs or technical details
        expect(apiException.userMessage.contains('10.0.0.1'), isFalse);
        expect(apiException.userMessage.contains('timeout at socket'), isFalse);
        expect(
          apiException.userMessage.contains('internal-api-cluster'),
          isFalse,
        );
      },
    );

    test('13. Technical raw messages are scrubbed', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/customer/ai/generate'),
          statusCode: 500,
          data: {
            'statusCode': 500,
            'message':
                'DioException [bad response]: RequestOptions.validateStatus error at dio_mixin.dart:404',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.userMessage.contains('DioException'), isFalse);
      expect(apiException.userMessage.contains('RequestOptions'), isFalse);
      expect(apiException.userMessage.contains('dio_mixin.dart'), isFalse);
      expect(
        apiException.userMessage,
        'Something went wrong on our end. Please try again later.',
      );
    });
  });
}
