import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:quickboom_app/roles/company_admin/models/team_model.dart';
import 'package:quickboom_app/roles/company_admin/services/team_service.dart';

class TeamsState {
  final List<TeamItem> teams;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String statusFilter;

  const TeamsState({
    this.teams = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter = 'ALL',
  });

  TeamsState copyWith({
    List<TeamItem>? teams,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    String? statusFilter,
  }) {
    return TeamsState(
      teams: teams ?? this.teams,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

final teamsNotifierProvider = StateNotifierProvider<TeamsViewModel, TeamsState>(
  (ref) {
    final teamService = ref.watch(teamServiceProvider);
    return TeamsViewModel(teamService);
  },
);

class TeamsViewModel extends StateNotifier<TeamsState> {
  final TeamService _teamService;

  TeamsViewModel(this._teamService) : super(const TeamsState()) {
    loadTeams();
  }

  Future<void> loadTeams() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final teams = await _teamService.fetchTeams(
        search: state.searchQuery,
        status: state.statusFilter,
      );
      state = state.copyWith(teams: teams, isLoading: false);
    } catch (e) {
      debugPrint('[TeamsViewModel.loadTeams] Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load teams from server. Please try again.',
      );
    }
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
    loadTeams();
  }

  void setStatusFilter(String status) {
    if (state.statusFilter == status) return;
    state = state.copyWith(statusFilter: status);
    loadTeams();
  }

  Future<bool> createTeam({
    required String name,
    String? description,
    int? leaderId,
    List<int>? memberIds,
    bool isActive = true,
  }) async {
    try {
      await _teamService.createTeam(
        name: name,
        description: description,
        leaderId: leaderId,
        memberIds: memberIds,
        isActive: isActive,
      );
      await loadTeams();
      return true;
    } catch (e) {
      debugPrint('[TeamsViewModel.createTeam] Error: $e');
      return false;
    }
  }

  Future<bool> updateTeam(
    int id, {
    String? name,
    String? description,
    int? leaderId,
    List<int>? memberIds,
    bool? isActive,
  }) async {
    try {
      await _teamService.updateTeam(
        id,
        name: name,
        description: description,
        leaderId: leaderId,
        memberIds: memberIds,
        isActive: isActive,
      );
      await loadTeams();
      return true;
    } catch (e) {
      debugPrint('[TeamsViewModel.updateTeam] Error: $e');
      return false;
    }
  }

  Future<bool> deleteTeam(int id) async {
    try {
      await _teamService.deleteTeam(id);
      await loadTeams();
      return true;
    } catch (e) {
      debugPrint('[TeamsViewModel.deleteTeam] Error: $e');
      return false;
    }
  }

  Future<bool> addMember(
    int teamId,
    int employeeId, {
    String role = 'MEMBER',
  }) async {
    try {
      await _teamService.addMember(teamId, employeeId: employeeId, role: role);
      await loadTeams();
      return true;
    } catch (e) {
      debugPrint('[TeamsViewModel.addMember] Error: $e');
      return false;
    }
  }

  Future<bool> removeMember(int teamId, int employeeId) async {
    try {
      await _teamService.removeMember(teamId, employeeId);
      await loadTeams();
      return true;
    } catch (e) {
      debugPrint('[TeamsViewModel.removeMember] Error: $e');
      return false;
    }
  }
}
