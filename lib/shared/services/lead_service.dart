import 'package:quickboom_app/core/constants/app_config.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:flutter/foundation.dart';
import '../models/lead_model.dart';
import '../models/lead_stage_model.dart';

class LeadService {
  final ApiClient? _apiClient;

  LeadService([this._apiClient]);

  /// Fetch all configured pipeline stages from backend GET /leads/stages.
  Future<List<LeadStageModel>> getStages() async {
    if (AppConfig.uiOnlyMode) {
      return List<LeadStageModel>.from(_UiOnlyLeadStore.stages);
    }
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
    if (AppConfig.uiOnlyMode) {
      return _UiOnlyLeadStore.filterLeads(
        status: status,
        stageId: stageId,
        search: search,
      );
    }
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
          if (stageId == null &&
              status != null &&
              status.isNotEmpty &&
              status != 'ALL')
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
    if (AppConfig.uiOnlyMode) {
      return _UiOnlyLeadStore.leadById(id);
    }
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
    if (AppConfig.uiOnlyMode) {
      return _UiOnlyLeadStore.updateStatus(
        id,
        status: status,
        stageId: stageId,
        notes: notes,
      );
    }
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
    if (AppConfig.uiOnlyMode) {
      return _UiOnlyLeadStore.createLead(data);
    }
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
    if (AppConfig.uiOnlyMode) {
      return _UiOnlyLeadStore.addNote(id, content);
    }
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
    if (AppConfig.uiOnlyMode) {
      return _UiOnlyLeadStore.getNotes(id);
    }
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
    if (AppConfig.uiOnlyMode) {
      return _UiOnlyLeadStore.leadById(id);
    }
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

class _UiOnlyLeadStore {
  static const stages = <LeadStageModel>[
    LeadStageModel(
      id: 1,
      key: 'NEW',
      name: 'New',
      sortOrder: 1,
      color: '#0284C7',
      bgColor: '#E0F2FE',
      borderColor: '#BAE6FD',
    ),
    LeadStageModel(
      id: 2,
      key: 'CONTACTED',
      name: 'Contacted',
      sortOrder: 2,
      color: '#D97706',
      bgColor: '#FEF3C7',
      borderColor: '#FDE68A',
    ),
    LeadStageModel(
      id: 3,
      key: 'CALL_BACK',
      name: 'Call Back',
      sortOrder: 3,
      color: '#8B5CF6',
      bgColor: '#F3E8FF',
      borderColor: '#E9D5FF',
    ),
    LeadStageModel(
      id: 4,
      key: 'DETAILS_SENT',
      name: 'Details Sent',
      sortOrder: 4,
      color: '#4F46E5',
      bgColor: '#EEF2FF',
      borderColor: '#E0E7FF',
    ),
    LeadStageModel(
      id: 5,
      key: 'FOLLOW_UP',
      name: 'Follow-Up',
      sortOrder: 5,
      color: '#06B6D4',
      bgColor: '#CFFAFE',
      borderColor: '#A5F3FC',
    ),
    LeadStageModel(
      id: 6,
      key: 'VISIT_SCHEDULED',
      name: 'Visit Scheduled',
      sortOrder: 6,
      color: '#EA580C',
      bgColor: '#FFEDD5',
      borderColor: '#FED7AA',
    ),
    LeadStageModel(
      id: 7,
      key: 'VISIT_DONE',
      name: 'Visit Done',
      sortOrder: 7,
      color: '#0891B2',
      bgColor: '#E0F7FA',
      borderColor: '#B2EBF2',
    ),
    LeadStageModel(
      id: 8,
      key: 'PROPOSAL_SENT',
      name: 'Proposal Sent',
      sortOrder: 8,
      color: '#7C3AED',
      bgColor: '#EDE9FE',
      borderColor: '#DDD6FE',
    ),
    LeadStageModel(
      id: 9,
      key: 'NEGOTIATION',
      name: 'Negotiation',
      sortOrder: 9,
      color: '#CA8A04',
      bgColor: '#FEF9C3',
      borderColor: '#FDE68A',
    ),
    LeadStageModel(
      id: 10,
      key: 'WON',
      name: 'Won',
      sortOrder: 10,
      color: '#16A34A',
      bgColor: '#DCFCE7',
      borderColor: '#BBF7D0',
    ),
    LeadStageModel(
      id: 11,
      key: 'LOST',
      name: 'Lost',
      sortOrder: 11,
      color: '#DC2626',
      bgColor: '#FEE2E2',
      borderColor: '#FECACA',
    ),
  ];

  static final List<LeadModel> leads = [
    _lead(
      id: 'lead_101',
      company: 'Urban Bites Cafe',
      first: 'Rohan',
      last: 'Deshmukh',
      phone: '9876543210',
      email: 'rohan@urbanbites.in',
      city: 'Pune',
      category: 'Restaurant',
      stageId: 1,
      notes: 'New enquiry from Google listing.',
      createdAt: '2026-11-05T09:20:00.000Z',
    ),
    _lead(
      id: 'lead_102',
      company: 'Glow Skin Clinic',
      first: 'Neha',
      last: 'Kulkarni',
      phone: '9823456710',
      email: 'neha@glowskin.clinic',
      city: 'Pune',
      category: 'Clinic',
      stageId: 2,
      notes: 'Spoke with receptionist. Owner available after 4 PM.',
      createdAt: '2026-11-04T11:10:00.000Z',
    ),
    _lead(
      id: 'lead_103',
      company: 'FitCore Gym',
      first: 'Amit',
      last: 'Patil',
      phone: '9812345678',
      email: 'amit@fitcore.gym',
      city: 'Pune',
      category: 'Gym',
      stageId: 3,
      notes: 'Requested callback tomorrow morning.',
      createdAt: '2026-11-04T08:45:00.000Z',
    ),
    _lead(
      id: 'lead_104',
      company: 'Luxe Interiors',
      first: 'Sneha',
      last: 'Joshi',
      phone: '9765432109',
      email: 'sneha@luxeinteriors.in',
      city: 'Mumbai',
      category: 'Interior Design',
      stageId: 4,
      notes: 'Brochure and pricing sheet sent on WhatsApp.',
      createdAt: '2026-11-03T16:30:00.000Z',
    ),
    _lead(
      id: 'lead_105',
      company: 'Bluewave Academy',
      first: 'Karan',
      last: 'Shah',
      phone: '9898765432',
      email: 'karan@bluewave.academy',
      city: 'Pune',
      category: 'Education',
      stageId: 5,
      notes: 'Follow-up scheduled for Friday.',
      createdAt: '2026-11-03T10:05:00.000Z',
    ),
    _lead(
      id: 'lead_106',
      company: 'Sunrise Dental Care',
      first: 'Meera',
      last: 'Iyer',
      phone: '9900112233',
      email: 'meera@sunrisedental.com',
      city: 'Pune',
      category: 'Dental',
      stageId: 6,
      notes: 'Visit booked at FC Road clinic.',
      createdAt: '2026-11-02T14:15:00.000Z',
    ),
    _lead(
      id: 'lead_107',
      company: 'PixelForge Studio',
      first: 'Arjun',
      last: 'Mehta',
      phone: '9876501234',
      email: 'arjun@pixelforge.studio',
      city: 'Pune',
      category: 'Creative Agency',
      stageId: 8,
      notes: 'Proposal shared for 3-month social package.',
      createdAt: '2026-11-01T12:00:00.000Z',
    ),
    _lead(
      id: 'lead_108',
      company: 'GreenLeaf Organics',
      first: 'Pooja',
      last: 'Nair',
      phone: '9845012398',
      email: 'pooja@greenleaf.org',
      city: 'Nashik',
      category: 'Retail',
      stageId: 10,
      notes: 'Converted to annual plan.',
      createdAt: '2026-10-28T09:40:00.000Z',
    ),
  ];

  static final Map<String, List<Map<String, dynamic>>> notes = {
    'lead_102': [
      {
        'id': 'note_1',
        'content': 'First call completed. Interested in Instagram ads.',
        'createdAt': '2026-11-04T11:20:00.000Z',
      },
    ],
  };

  static LeadStageModel _stageById(int id) =>
      stages.firstWhere((stage) => stage.id == id, orElse: () => stages.first);

  static LeadModel _lead({
    required String id,
    required String company,
    required String first,
    required String last,
    required String phone,
    required String email,
    required String city,
    required String category,
    required int stageId,
    required String notes,
    required String createdAt,
  }) {
    final stage = _stageById(stageId);
    return LeadModel(
      id: id,
      companyName: company,
      firstName: first,
      lastName: last,
      phone: phone,
      email: email,
      city: city,
      state: 'Maharashtra',
      country: 'India',
      category: category,
      source: 'DATA_CAPTURE',
      createdFrom: 'MOBILE',
      status: stage.key,
      stageId: stage.id,
      stage: stage,
      notes: notes,
      assignedToId: 1,
      assignedToName: 'Priya Sharma',
      createdAt: createdAt,
    );
  }

  static List<LeadModel> filterLeads({
    String? status,
    int? stageId,
    String? search,
  }) {
    Iterable<LeadModel> result = leads;
    if (stageId != null) {
      result = result.where((lead) => lead.stageId == stageId);
    } else if (status != null && status.isNotEmpty && status != 'ALL') {
      final key = status.toUpperCase();
      result = result.where((lead) => lead.status.toUpperCase() == key);
    }
    final query = search?.trim().toLowerCase() ?? '';
    if (query.isNotEmpty) {
      result = result.where((lead) {
        return lead.companyName.toLowerCase().contains(query) ||
            lead.fullName.toLowerCase().contains(query) ||
            (lead.phone ?? '').toLowerCase().contains(query) ||
            (lead.email ?? '').toLowerCase().contains(query) ||
            (lead.city ?? '').toLowerCase().contains(query);
      });
    }
    return result.toList();
  }

  static LeadModel leadById(String id) {
    return leads.firstWhere(
      (lead) => lead.id == id,
      orElse: () => throw Exception('Lead not found'),
    );
  }

  static LeadModel updateStatus(
    String id, {
    required String status,
    int? stageId,
    String? notes,
  }) {
    final index = leads.indexWhere((lead) => lead.id == id);
    if (index < 0) throw Exception('Lead not found');
    final stage = stageId != null
        ? _stageById(stageId)
        : stages.firstWhere(
            (item) => item.key.toUpperCase() == status.toUpperCase(),
            orElse: () => leads[index].stage ?? stages.first,
          );
    final updated = leads[index].copyWith(
      status: stage.key,
      stageId: stage.id,
      stage: stage,
      notes: notes ?? leads[index].notes,
    );
    leads[index] = updated;
    return updated;
  }

  static LeadModel createLead(Map<String, dynamic> data) {
    final stage = stages.first;
    final lead = LeadModel(
      id: 'lead_${DateTime.now().millisecondsSinceEpoch}',
      companyName:
          data['companyName']?.toString() ??
          data['businessName']?.toString() ??
          'New Business',
      firstName: data['firstName']?.toString(),
      lastName: data['lastName']?.toString(),
      phone: data['phone']?.toString(),
      email: data['email']?.toString(),
      city: data['city']?.toString(),
      category: data['category']?.toString(),
      source: 'MANUAL',
      createdFrom: 'MOBILE',
      status: stage.key,
      stageId: stage.id,
      stage: stage,
      assignedToId: 1,
      assignedToName: 'Priya Sharma',
      createdAt: DateTime.now().toIso8601String(),
    );
    leads.insert(0, lead);
    return lead;
  }

  static Map<String, dynamic> addNote(String id, String content) {
    final note = {
      'id': 'note_${DateTime.now().millisecondsSinceEpoch}',
      'content': content.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    notes.putIfAbsent(id, () => []).insert(0, note);
    return note;
  }

  static List<Map<String, dynamic>> getNotes(String id) =>
      List<Map<String, dynamic>>.from(notes[id] ?? const []);
}
