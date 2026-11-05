import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/roles/company_admin/models/team_model.dart';
import 'package:quickboom_app/roles/company_admin/services/team_service.dart';
import 'package:quickboom_app/roles/company_admin/viewmodels/team_viewmodel.dart';
import 'package:quickboom_app/core/network/api_client.dart';

class MockTeamService extends TeamService {
  List<TeamItem> mockTeams;

  MockTeamService(List<TeamItem> initialTeams)
    : mockTeams = List.from(initialTeams),
      super(ApiClient());

  @override
  Future<List<TeamItem>> fetchTeams({
    String? search,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    var list = mockTeams;
    if ((search ?? '').isNotEmpty) {
      list = list
          .where((t) => t.name.toLowerCase().contains(search!.toLowerCase()))
          .toList();
    }
    if ((status ?? '').isNotEmpty && status != 'ALL') {
      list = list.where((t) => t.status == status).toList();
    }
    return list;
  }

  @override
  Future<TeamItem> createTeam({
    required String name,
    String? description,
    int? leaderId,
    List<int>? memberIds,
    bool isActive = true,
  }) async {
    final newTeam = TeamItem(
      id: mockTeams.length + 1,
      customerId: 101,
      name: name,
      description: description,
      leaderId: leaderId,
      isActive: isActive,
      status: isActive ? 'ACTIVE' : 'INACTIVE',
      members: (memberIds ?? [])
          .map(
            (id) => TeamMemberItem(
              id: id,
              teamId: mockTeams.length + 1,
              employeeId: id,
              role: 'MEMBER',
            ),
          )
          .toList(),
      memberCount: memberIds?.length ?? 0,
    );
    mockTeams.insert(0, newTeam);
    return newTeam;
  }

  @override
  Future<TeamItem> updateTeam(
    int id, {
    String? name,
    String? description,
    int? leaderId,
    List<int>? memberIds,
    bool? isActive,
  }) async {
    final idx = mockTeams.indexWhere((t) => t.id == id);
    if (idx == -1) throw Exception('Not found');
    final old = mockTeams[idx];
    final updated = TeamItem(
      id: old.id,
      customerId: old.customerId,
      name: name ?? old.name,
      description: description ?? old.description,
      leaderId: leaderId ?? old.leaderId,
      isActive: isActive ?? old.isActive,
      status: (isActive ?? old.isActive) ? 'ACTIVE' : 'INACTIVE',
      members: memberIds != null
          ? memberIds
                .map(
                  (mId) => TeamMemberItem(
                    id: mId,
                    teamId: id,
                    employeeId: mId,
                    role: 'MEMBER',
                  ),
                )
                .toList()
          : old.members,
      memberCount: memberIds?.length ?? old.memberCount,
    );
    mockTeams[idx] = updated;
    return updated;
  }

  @override
  Future<bool> deleteTeam(int id, {bool permanent = false}) async {
    mockTeams.removeWhere((t) => t.id == id);
    return true;
  }
}

void main() {
  group('Team Management Unit Tests (Flutter)', () {
    test('1. TeamItem and TeamMemberItem parse JSON correctly', () {
      final json = {
        'id': 1,
        'customerId': 101,
        'name': 'SSM Creative Squad',
        'description': 'Handles photography and post production',
        'leaderId': 12,
        'isActive': true,
        'status': 'ACTIVE',
        'leader': {
          'id': 12,
          'employeeCode': 'EMP-012',
          'firstName': 'Alex',
          'lastName': 'Rivers',
          'email': 'alex@quickboom.com',
          'phone': '+91 9876543210',
          'designation': {'name': 'Senior Lead'},
        },
        'members': [
          {
            'id': 101,
            'teamId': 1,
            'employeeId': 12,
            'role': 'LEADER',
            'employee': {
              'id': 12,
              'employeeCode': 'EMP-012',
              'firstName': 'Alex',
              'lastName': 'Rivers',
            },
          },
          {
            'id': 102,
            'teamId': 1,
            'employeeId': 15,
            'role': 'MEMBER',
            'employee': {
              'id': 15,
              'employeeCode': 'EMP-015',
              'firstName': 'Maya',
              'lastName': 'Lin',
            },
          },
        ],
        'memberCount': 2,
        'createdAt': '2026-09-04T12:00:00.000Z',
      };

      final team = TeamItem.fromJson(json);

      expect(team.id, 1);
      expect(team.name, 'SSM Creative Squad');
      expect(team.leader?.displayName, 'Alex Rivers');
      expect(team.leader?.designation, 'Senior Lead');
      expect(team.members.length, 2);
      expect(team.members[1].employee?.displayName, 'Maya Lin');
      expect(team.status, 'ACTIVE');
      expect(team.isActive, true);
    });

    test('2. TeamsViewModel loads and filters teams', () async {
      final sampleTeams = [
        const TeamItem(
          id: 1,
          customerId: 101,
          name: 'Video Crew A',
          isActive: true,
          status: 'ACTIVE',
        ),
        const TeamItem(
          id: 2,
          customerId: 101,
          name: 'Design Squad B',
          isActive: false,
          status: 'INACTIVE',
        ),
      ];

      final mockService = MockTeamService(sampleTeams);
      final vm = TeamsViewModel(mockService);

      await vm.loadTeams();
      expect(vm.state.teams.length, 2);

      vm.setSearchQuery('Video');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(vm.state.teams.length, 1);
      expect(vm.state.teams.first.name, 'Video Crew A');

      vm.setSearchQuery('');
      vm.setStatusFilter('INACTIVE');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(vm.state.teams.length, 1);
      expect(vm.state.teams.first.name, 'Design Squad B');
    });

    test('3. TeamsViewModel creates, updates, and deletes team', () async {
      final sampleTeams = <TeamItem>[
        const TeamItem(
          id: 1,
          customerId: 101,
          name: 'Initial Team',
          isActive: true,
        ),
      ];

      final mockService = MockTeamService(sampleTeams);
      final vm = TeamsViewModel(mockService);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(vm.state.teams.length, 1);

      final created = await vm.createTeam(
        name: 'New Marketing Team',
        description: 'Outreach and social',
        leaderId: 10,
        memberIds: [10, 20],
      );
      expect(created, true);
      expect(vm.state.teams.length, 2);
      expect(vm.state.teams.first.name, 'New Marketing Team');

      final updated = await vm.updateTeam(1, name: 'Renamed Initial Team');
      expect(updated, true);
      expect(vm.state.teams.any((t) => t.name == 'Renamed Initial Team'), true);

      final deleted = await vm.deleteTeam(1);
      expect(deleted, true);
      expect(vm.state.teams.any((t) => t.id == 1), false);
    });
  });
}
