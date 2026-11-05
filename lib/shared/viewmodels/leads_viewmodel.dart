import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lead_model.dart';
import '../services/lead_service.dart';
import 'lead_stages_viewmodel.dart';

final leadsProvider =
    NotifierProvider<LeadsViewModel, AsyncValue<List<LeadModel>>>(() {
      return LeadsViewModel();
    });

/// Provider exposing total and per-stage lead counts derived from full pipeline data.
final leadsStageCountsProvider = Provider<Map<String, int>>((ref) {
  ref.watch(leadsProvider);
  return ref.read(leadsProvider.notifier).stageCounts;
});

final sharedLeadNotesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, leadId) async {
      final service = ref.watch(leadServiceProvider);
      return service.getNotes(leadId);
    });

class LeadsViewModel extends Notifier<AsyncValue<List<LeadModel>>> {
  LeadService get _leadService => ref.read(leadServiceProvider);
  String? _lastStatus;
  int? _lastStageId;
  String? _lastSearch;
  int _fetchGeneration = 0;
  List<LeadModel> _allLeads = const [];
  Map<String, int> _stageCounts = const {};

  Map<String, int> get stageCounts => _stageCounts;

  @override
  AsyncValue<List<LeadModel>> build() {
    Future.microtask(() { if (ref.mounted && _fetchGeneration == 0) fetchLeads(); });
    return const AsyncValue.loading();
  }

  void _updateCounts(List<LeadModel> leads) {
    final stagesNotifier = ref.read(leadStagesProvider.notifier);
    final counts = <String, int>{'': leads.length, 'ALL': leads.length};
    for (final stage in ref.read(activeLeadStagesProvider)) { counts[stage.key.toUpperCase()] = 0; counts[stage.id.toString()] = 0; }
    for (final lead in leads) {
      final resolved = stagesNotifier.resolveLeadStage(
        lead.stageId,
        lead.status,
      );
      final key = (resolved?.key ?? lead.stage?.key ?? lead.status).toUpperCase();
      counts[key] = (counts[key] ?? 0) + 1;
      if (key == 'VISIT') counts['VISIT_SCHEDULED'] = (counts['VISIT_SCHEDULED'] ?? 0) + 1;
      if (key == 'VISIT_SCHEDULED') counts['VISIT'] = (counts['VISIT'] ?? 0) + 1;
      if (lead.stageId != null) {
        counts[lead.stageId.toString()] =
            (counts[lead.stageId.toString()] ?? 0) + 1;
      }
    }
    _stageCounts = counts;
  }

  Future<void> fetchLeads({String? status, String? search, int? stageId, bool refreshCounts = false}) async {
    final generation = ++_fetchGeneration;
    _lastStatus = status;
    _lastStageId = stageId;
    _lastSearch = search;
    state = const AsyncValue.loading();
    try {
      final reloadCounts = refreshCounts && (stageId != null || status?.isNotEmpty == true || search?.isNotEmpty == true);
      final countsRequest = reloadCounts ? _leadService.getLeads() : null;
      final filteredRequest = _leadService.getLeads(status: status, search: search, stageId: stageId);
      final results = await Future.wait([filteredRequest, if (countsRequest != null) countsRequest]);
      final serverLeads = results.first;
      if (!ref.mounted || generation != _fetchGeneration) return;
      debugPrint(
        '[LEADS_DISPLAY] parsed=${serverLeads.length} status=${status ?? 'ALL'}',
      );
      if (reloadCounts) {
        _allLeads = List<LeadModel>.unmodifiable(results.last);
        _updateCounts(_allLeads);
      } else if (stageId == null && (status == null || status.isEmpty) && (search == null || search.trim().isEmpty)) {
        _allLeads = List<LeadModel>.unmodifiable(serverLeads);
        _updateCounts(_allLeads);
      }
      state = AsyncValue.data(serverLeads);
    } catch (e, st) {
      if (!ref.mounted || generation != _fetchGeneration) return;
      debugPrint('[LeadsViewModel] fetchLeads error: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshLeads() async {
    await fetchLeads(status: _lastStatus, search: _lastSearch, stageId: _lastStageId, refreshCounts: _allLeads.isNotEmpty);
  }

  Future<LeadModel?> getLeadDetails(String id) async {
    try {
      final lead = await _leadService.getLeadById(id);
      _updateLocalLead(lead);
      return lead;
    } catch (e) {
      debugPrint('[LeadsViewModel] getLeadDetails error: $e');
      rethrow;
    }
  }

  Future<bool> addNote(String id, String content) async {
    try {
      await _leadService.addNote(id, content);
      ref.invalidate(sharedLeadNotesProvider(id));
      await getLeadDetails(id);
      return true;
    } catch (e) {
      debugPrint('[LeadsViewModel] addNote error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getNotes(String id) async {
    try {
      return await _leadService.getNotes(id);
    } catch (e) {
      debugPrint('[LeadsViewModel] getNotes error: $e');
      return [];
    }
  }

  Future<LeadModel?> updateStatus(
    String id, {
    required String status,
    int? stageId,
    String? notes,
  }) async {
    debugPrint(
      '[LeadsViewModel] updateStatus leadId: $id, status: $status, stageId: $stageId',
    );
    try {
      final updated = await _leadService.updateStatus(
        id,
        status: status,
        stageId: stageId,
        notes: notes,
      );
      await refreshLeads();
      return updated;
    } catch (e) {
      debugPrint('[LeadsViewModel] updateStatus FAILED: $e');
      rethrow;
    }
  }

  Future<LeadModel?> manageVisit(
    String id, {
    required String action,
    String? purpose,
    String? date,
    String? time,
    String? location,
    double? latitude,
    double? longitude,
    String? notes,
    dynamic employeeId,
  }) async {
    try {
      final updated = await _leadService.manageVisit(
        id,
        action: action,
        purpose: purpose,
        date: date,
        time: time,
        location: location,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
        employeeId: employeeId,
      );
      await refreshLeads();
      return updated;
    } catch (e) {
      debugPrint('[LeadsViewModel] manageVisit error: $e');
      rethrow;
    }
  }

  Future<LeadModel?> createLead(Map<String, dynamic> data) async {
    try {
      final created = await _leadService.createLead(data);
      await refreshLeads();
      return created;
    } catch (e) {
      debugPrint('[LeadsViewModel] createLead error: $e');
      rethrow;
    }
  }

  bool _matchesStage(LeadModel lead) {
    if (_lastStageId != null) {
      if (lead.stageId != null) return lead.stageId == _lastStageId;
      return ref.read(leadStagesProvider.notifier).resolveLeadStage(null, lead.status)?.id == _lastStageId;
    }
    if (_lastStatus == null || _lastStatus!.isEmpty) return true;
    final stage = ref.read(leadStagesProvider.notifier).resolveLeadStage(lead.stageId, lead.status);
    return (stage?.key ?? lead.status).toUpperCase() == _lastStatus!.toUpperCase();
  }

  void addOrUpdateLead(LeadModel lead) {
    if (_allLeads.isNotEmpty) {
      final allIndex = _allLeads.indexWhere((l) => l.id == lead.id);
      final updatedAll = List<LeadModel>.from(_allLeads);
      if (allIndex >= 0) {
        updatedAll[allIndex] = lead;
      } else {
        updatedAll.insert(0, lead);
      }
      _allLeads = List<LeadModel>.unmodifiable(updatedAll);
      _updateCounts(_allLeads);
    }
    final currentList = state.asData?.value;
    if (!_matchesStage(lead)) {
      if (currentList != null) state = AsyncValue.data(currentList.where((item) => item.id != lead.id).toList());
      return;
    }
    if (currentList == null) {
      state = AsyncValue.data([lead]);
      return;
    }
    final index = currentList.indexWhere((l) => l.id == lead.id);
    if (index >= 0) {
      final updatedList = List<LeadModel>.from(currentList);
      updatedList[index] = lead;
      state = AsyncValue.data(updatedList);
    } else {
      state = AsyncValue.data([lead, ...currentList]);
    }
  }

  void _updateLocalLead(LeadModel lead) {
    if (_allLeads.isNotEmpty) {
      final allIndex = _allLeads.indexWhere((l) => l.id == lead.id);
      if (allIndex >= 0) {
        final updatedAll = List<LeadModel>.from(_allLeads);
        updatedAll[allIndex] = lead;
        _allLeads = List<LeadModel>.unmodifiable(updatedAll);
        _updateCounts(_allLeads);
      }
    }
    final currentList = state.asData?.value;
    if (!_matchesStage(lead)) {
      if (currentList != null) state = AsyncValue.data(currentList.where((item) => item.id != lead.id).toList());
      return;
    }
    if (currentList == null) return;
    final index = currentList.indexWhere((l) => l.id == lead.id);
    if (index >= 0) {
      final updatedList = List<LeadModel>.from(currentList);
      updatedList[index] = lead;
      state = AsyncValue.data(updatedList);
    }
  }
}
