import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/roles/company_admin/models/team_model.dart';

final teamServiceProvider = Provider<TeamService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TeamService(apiClient);
});

class TeamService {
  final ApiClient _apiClient;

  TeamService(this._apiClient);

  /// Fetch list of teams with server-side filters & pagination
  Future<List<TeamItem>> fetchTeams({
    String? search,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if ((search ?? '').trim().isNotEmpty) {
        queryParams['search'] = search!.trim();
      }
      if ((status ?? '').isNotEmpty && status != 'ALL') {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get(
        '/teams',
        queryParameters: queryParams,
      );

      final data = response.data;
      final List rawItems;
      if (data is Map<String, dynamic>) {
        rawItems = data['data'] as List? ?? data['items'] as List? ?? [];
      } else if (data is List) {
        rawItems = data;
      } else {
        rawItems = [];
      }

      return rawItems
          .whereType<Map<String, dynamic>>()
          .map((json) => TeamItem.fromJson(json))
          .toList();
    } catch (e, stack) {
      debugPrint('[TeamService.fetchTeams] Error: $e\n$stack');
      rethrow;
    }
  }

  /// Get single team details with members and leader
  Future<TeamItem> fetchTeamById(int id) async {
    try {
      final response = await _apiClient.get('/teams/$id');
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return TeamItem.fromJson(data);
    } catch (e, stack) {
      debugPrint('[TeamService.fetchTeamById] Error: $e\n$stack');
      rethrow;
    }
  }

  /// Create a new team
  Future<TeamItem> createTeam({
    required String name,
    String? description,
    int? leaderId,
    List<int>? memberIds,
    bool isActive = true,
  }) async {
    try {
      final body = <String, dynamic>{'name': name.trim(), 'isActive': isActive};
      if (description != null && description.trim().isNotEmpty) {
        body['description'] = description.trim();
      }
      if (leaderId != null) {
        body['leaderId'] = leaderId;
      }
      if (memberIds != null && memberIds.isNotEmpty) {
        body['memberIds'] = memberIds;
      }

      final response = await _apiClient.post('/teams', data: body);
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return TeamItem.fromJson(data);
    } catch (e, stack) {
      debugPrint('[TeamService.createTeam] Error: $e\n$stack');
      rethrow;
    }
  }

  /// Update an existing team
  Future<TeamItem> updateTeam(
    int id, {
    String? name,
    String? description,
    int? leaderId,
    List<int>? memberIds,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name.trim();
      if (description != null) body['description'] = description.trim();
      if (leaderId != null) body['leaderId'] = leaderId;
      if (memberIds != null) body['memberIds'] = memberIds;
      if (isActive != null) body['isActive'] = isActive;

      final response = await _apiClient.put('/teams/$id', data: body);
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return TeamItem.fromJson(data);
    } catch (e, stack) {
      debugPrint('[TeamService.updateTeam] Error: $e\n$stack');
      rethrow;
    }
  }

  /// Deactivate or delete team
  Future<bool> deleteTeam(int id, {bool permanent = false}) async {
    try {
      await _apiClient.delete(
        '/teams/$id',
        queryParameters: {'permanent': permanent ? 'true' : 'false'},
      );
      return true;
    } catch (e, stack) {
      debugPrint('[TeamService.deleteTeam] Error: $e\n$stack');
      rethrow;
    }
  }

  /// Add a member to a team
  Future<TeamMemberItem> addMember(
    int teamId, {
    required int employeeId,
    String role = 'MEMBER',
  }) async {
    try {
      final response = await _apiClient.post(
        '/teams/$teamId/members',
        data: {'employeeId': employeeId, 'role': role},
      );
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return TeamMemberItem.fromJson(data);
    } catch (e, stack) {
      debugPrint('[TeamService.addMember] Error: $e\n$stack');
      rethrow;
    }
  }

  /// Remove a member from a team
  Future<bool> removeMember(int teamId, int employeeId) async {
    try {
      await _apiClient.delete('/teams/$teamId/members/$employeeId');
      return true;
    } catch (e, stack) {
      debugPrint('[TeamService.removeMember] Error: $e\n$stack');
      rethrow;
    }
  }
}
