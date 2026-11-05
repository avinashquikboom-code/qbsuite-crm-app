import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/shared/models/lead_model.dart';
import 'package:quickboom_app/shared/services/lead_service.dart';
import 'package:quickboom_app/shared/viewmodels/lead_stages_viewmodel.dart';
import 'package:quickboom_app/shared/viewmodels/leads_viewmodel.dart';

class _Service extends LeadService {
  final requests = <Completer<List<LeadModel>>>[];
  final filters = <Map<String, String?>>[];
  @override
  Future<List<LeadModel>> getLeads({
    String? status,
    int? stageId,
    String? search,
    int page = 1,
    int limit = 50,
  }) {
    filters.add({'status': status, 'search': search});
    final request = Completer<List<LeadModel>>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  for (final oldFails in [false, true]) {
    test(
      'older ${oldFails ? 'failed' : 'empty'} fetch cannot replace refreshed assigned leads',
      () async {
        final service = _Service();
        final container = ProviderContainer(
          overrides: [leadServiceProvider.overrideWithValue(service)],
        );
        addTearDown(container.dispose);
        container.read(leadsProvider);
        await Future<void>.delayed(Duration.zero);
        final notifier = container.read(leadsProvider.notifier);
        final refresh = notifier.fetchLeads(status: 'NEW', search: 'Capture');
        service.requests[1].complete([
          LeadModel.fromJson({
            'id': 55,
            'companyName': 'Capture fixture',
            'phone': '123',
            'email': 'fixture@example.test',
            'assignedToId': 7,
            'status': 'NEW',
            'source': 'Google Places',
            'stageId': 1,
          }),
        ]);
        await refresh;
        if (oldFails) {
          service.requests[0].completeError(StateError('Older failed request'));
        } else {
          service.requests[0].complete([]);
        }
        await Future<void>.delayed(Duration.zero);
        final visible = container.read(leadsProvider).requireValue;
        expect(visible.single.id, '55');
        expect(visible.single.assignedToId, 7);
        expect(visible.single.status, 'NEW');
        final nextRefresh = notifier.refreshLeads();
        expect(service.filters.last, {'status': 'NEW', 'search': 'Capture'});
        service.requests.last.complete(visible);
        await nextRefresh;
      },
    );
  }
}
