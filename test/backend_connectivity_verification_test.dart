import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:quickboom_app/core/network/app_url.dart';

void main() {
  group('Production Backend Connectivity & Verification Suite', () {
    test('1. DNS Resolution: api.qbapp.online resolves to valid IP', () async {
      final addresses = await InternetAddress.lookup('api.qbapp.online');
      expect(addresses, isNotEmpty);
      expect(addresses.any((a) => a.type == InternetAddressType.IPv4), isTrue);
      final ipv4 = addresses.firstWhere(
        (a) => a.type == InternetAddressType.IPv4,
      );
      expect(ipv4.address, equals('13.202.136.71'));
    });

    test(
      '2. HTTPS & TLS: https://api.qbapp.online responds with valid SSL',
      () async {
        final client = HttpClient();
        final request = await client.getUrl(
          Uri.parse('https://api.qbapp.online/api/v1/marketplace/tools'),
        );
        final response = await request.close();
        expect(response.statusCode, equals(200));
        expect(response.certificate, isNotNull);
        expect(response.certificate!.subject, contains('api.qbapp.online'));
        client.close();
      },
    );

    test(
      '3. REST API: GET /api/v1/marketplace/tools returns real database tools',
      () async {
        final dio = Dio(BaseOptions(baseUrl: AppUrl.baseUrl));
        final response = await dio.get(AppUrl.marketplaceTools);

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<Map>());

        final dataMap = response.data as Map<String, dynamic>;
        expect(dataMap['success'], isTrue);
        final tools = dataMap['data'] as List;
        expect(tools.length, greaterThanOrEqualTo(6));

        // Verify real production tools from backend database
        final titles = tools.map((t) => t['title']).toList();
        expect(titles, contains('WhatsApp Marketing Tool'));
        expect(titles, contains('Social Media Scheduler'));
        expect(titles, contains('CRM & Lead Manager'));
      },
    );

    test(
      '4. WebSocket: wss://api.qbapp.online/ws/plan-schedule/ connects with 101 Switching Protocols',
      () async {
        final wsUrl = AppUrl.getWsUrl(
          AppUrl.planScheduleWs,
          queryParams: {'customerId': 'CUST-24'},
        );

        final socket = await WebSocket.connect(
          wsUrl,
          headers: {'Origin': 'https://api.qbapp.online'},
        ).timeout(const Duration(seconds: 10));

        expect(socket.readyState, equals(WebSocket.open));

        final completer = Completer<String>();
        final sub = socket.listen((data) {
          final str = data.toString();
          if (!completer.isCompleted) {
            completer.complete(str);
          }
        });

        final firstPacket = await completer.future.timeout(
          const Duration(seconds: 5),
        );
        expect(firstPacket.startsWith('0'), isTrue); // Engine.IO OPEN packet
        expect(firstPacket, contains('"sid"'));

        await sub.cancel();
        await socket.close();
      },
    );

    test(
      '5. WebSocket Auth & Namespace: joins /ws/plan-schedule namespace cleanly',
      () async {
        final wsUrl = AppUrl.getWsUrl(
          AppUrl.planScheduleWs,
          queryParams: {'customerId': 'CUST-24'},
        );

        final socket = await WebSocket.connect(
          wsUrl,
          headers: {'Origin': 'https://api.qbapp.online'},
        );

        final nsCompleter = Completer<String>();
        final sub = socket.listen((data) {
          final str = data.toString();
          if (str.startsWith('0')) {
            socket.add('40/ws/plan-schedule,');
          } else if (str.startsWith('40/ws/plan-schedule')) {
            if (!nsCompleter.isCompleted) {
              nsCompleter.complete(str);
            }
          }
        });

        final nsResponse = await nsCompleter.future.timeout(
          const Duration(seconds: 5),
        );
        expect(nsResponse.startsWith('40/ws/plan-schedule'), isTrue);
        expect(nsResponse, contains('"sid"'));

        await sub.cancel();
        await socket.close();
      },
    );
  });
}
