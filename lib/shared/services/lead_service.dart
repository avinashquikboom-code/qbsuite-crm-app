import 'package:quickboom_app/core/network/api_client.dart';
import 'package:flutter/foundation.dart';
import '../models/lead_model.dart';
import '../models/lead_stage_model.dart';

class LeadService {
  final ApiClient? _apiClient;

  LeadService([this._apiClient]);

  /// Fetch all configured pipeline stages from backend GET /leads/stages.
  Future<List<LeadStageModel>> getStages() async {
    if (_apiClient == null) throw StateError('API Client unavailable');
    final res = await _apiClient.get('/leads/stages');
    final raw = res.data;
    final items = raw is List
        ? raw
        : raw is Map
        ? (raw['data'] ?? raw['items'])
        : null;
    if (items is! List) {
      throw const FormatException('Invalid pipeline stages response');
    }
    final stages =
        items
            .map(
              (item) => LeadStageModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (stages.any(
          (stage) => stage.id <= 0 || stage.key.isEmpty || stage.name.isEmpty,
        ) ||
        stages.map((stage) => stage.id).toSet().length != stages.length ||
        stages.map((stage) => stage.key).toSet().length != stages.length) {
      throw const FormatException('Invalid or duplicate pipeline stages');
    }
    return stages;
  }

  /// Fetch paginated leads from GET /leads.
  Future<List<LeadModel>> getLeads({
    String? status,
    int? stageId,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    if (_apiClient == null) throw StateError('API Client unavailable');
    final leads = <LeadModel>[];
    final seen = <String>{};
    var currentPage = page;
    var totalPages = page;
    do {
      final res = await _apiClient.get(
        '/leads',
        queryParameters: {
          'page': currentPage,
          'limit': limit,
          if (stageId != null) 'stageId': stageId,
          if (stageId == null && status != null && status.isNotEmpty && status != 'ALL')
            'status': status,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );
      final raw = res.data;
      final payload = raw is Map && raw['data'] is Map ? raw['data'] : raw;
      final dynamic items = payload is List
          ? payload
          : payload is Map
          ? payload['data'] ?? payload['items']
          : null;
      if (items is! List) {
        throw const FormatException('Invalid lead list response');
      }
      if (kDebugMode) {
        debugPrint(
          '[LEADS_RESPONSE] endpoint=/leads page=$currentPage '
          'limit=$limit status=${status ?? 'ALL'} '
          'hasSearch=${search?.trim().isNotEmpty == true} '
          'httpStatus=${res.statusCode} returned=${items.length} '
          'total=${payload is Map ? payload['total'] : null} '
          'records=${items.whereType<Map>().map((item) => {'id': item['id'], 'assignedToId': item['assignedToId'], 'status': item['status'], 'stageId': item['stageId']}).toList()}',
        );
      }
      for (final item in items) {
        final lead = LeadModel.fromJson(Map<String, dynamic>.from(item as Map));
        if (lead.id.isEmpty) throw const FormatException('Lead ID is missing');
        if (seen.add(lead.id)) leads.add(lead);
      }
      final dynamic pagination = payload is Map
          ? payload['pagination'] ??
                payload['meta'] ??
                (raw is Map ? raw['pagination'] ?? raw['meta'] : null)
          : raw is Map
          ? raw['pagination'] ?? raw['meta']
          : null;
      final dynamic pages = pagination is Map
          ? pagination['totalPages']
          : payload is Map
          ? payload['totalPages']
          : null;
      if (pages != null) {
        if (pages is! num ||
            !pages.isFinite ||
            pages.toInt() != pages ||
            pages < 0) {
          throw const FormatException('Invalid lead pagination');
        }
        totalPages = pages.toInt();
      }
      currentPage++;
    } while (currentPage <= totalPages);
    return leads;
  }

  /// Get lead details by ID from GET /leads/$id.
  Future<LeadModel> getLeadById(String id) async {
    if (_apiClient != null) {
      final res = await _apiClient.get('/leads/$id');
      final raw = res.data;
      final map = (raw is Map && raw['data'] is Map)
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
      return LeadModel.fromJson(map);
    }
    throw Exception('API Client unavailable');
  }

  /// Update lead stage / status with the registered PATCH /leads/$id/status.
  Future<LeadModel> updateStatus(
    String id, {
    required String status,
    int? stageId,
    String? notes,
  }) async {
    if (_apiClient != null) {
      final payload = <String, dynamic>{
        'status': status,
        if (stageId != null) 'stageId': stageId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final res = await _apiClient.patch('/leads/$id/status', data: payload);
      final raw = res.data;
      final map = (raw is Map && raw['data'] is Map)
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
      final updated = LeadModel.fromJson(map);
      if (updated.id != id || updated.status != status) {
        throw const FormatException(
          'Stage update response does not match the saved Lead',
        );
      }
      return updated;
    }
    throw Exception('API Client unavailable');
  }

  /// Create lead with POST /leads.
  Future<LeadModel> createLead(Map<String, dynamic> data) async {
    if (_apiClient != null) {
      final res = await _apiClient.post('/leads', data: data);
      final raw = res.data;
      final map = (raw is Map && raw['data'] is Map)
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
      return LeadModel.fromJson(map);
    }
    throw Exception('API Client unavailable');
  }

  /// Add a note to lead with POST /leads/:id/notes.
  Future<Map<String, dynamic>> addNote(String id, String content) async {
    if (_apiClient != null) {
      final res = await _apiClient.post(
        '/leads/$id/notes',
        data: {'content': content.trim()},
      );
      final raw = res.data;
      return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    }
    throw StateError('API Client unavailable');
  }

  /// Get notes for lead with GET /leads/:id/notes.
  Future<List<Map<String, dynamic>>> getNotes(String id) async {
    if (_apiClient != null) {
      final res = await _apiClient.get('/leads/$id/notes');
      final raw = res.data;
      final payload = raw is Map && raw['data'] is Map ? raw['data'] : raw;
      final dynamic items = payload is List
          ? payload
          : payload is Map
          ? payload['data'] ?? payload['notes']
          : null;
      if (items is List) {
        return items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    }
    throw StateError('API Client unavailable');
  }

  /// Manage field visit: schedule, start, or complete via POST /leads/:id/visits
  Future<LeadModel> manageVisit(
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
    if (_apiClient != null) {
      final payload = <String, dynamic>{
        'action': action,
        if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
        if (date != null && date.isNotEmpty) 'date': date,
        if (time != null && time.isNotEmpty) 'time': time,
        if (location != null && location.isNotEmpty) 'location': location,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (employeeId != null) 'employeeId': employeeId,
      };

      final res = await _apiClient.post('/leads/$id/visits', data: payload);
      final raw = res.data;
      final map = (raw is Map && raw['data'] is Map)
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
      return LeadModel.fromJson(map);
    }
    throw StateError('API Client unavailable');
  }
}
