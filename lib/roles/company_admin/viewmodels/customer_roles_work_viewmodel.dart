import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/roles/company_admin/models/customer_roles_work_models.dart';

class CustomerRolesWorkState {
  final List<CustomerRoleItem> roles;
  final List<CustomerWorkTypeItem> workTypes;
  final List<CustomerTeamMemberItem> teamMembers;
  final List<CustomerTodayWorkItem> todayWorkItems;

  const CustomerRolesWorkState({
    required this.roles,
    required this.workTypes,
    required this.teamMembers,
    required this.todayWorkItems,
  });

  CustomerRolesWorkState copyWith({
    List<CustomerRoleItem>? roles,
    List<CustomerWorkTypeItem>? workTypes,
    List<CustomerTeamMemberItem>? teamMembers,
    List<CustomerTodayWorkItem>? todayWorkItems,
  }) {
    return CustomerRolesWorkState(
      roles: roles ?? this.roles,
      workTypes: workTypes ?? this.workTypes,
      teamMembers: teamMembers ?? this.teamMembers,
      todayWorkItems: todayWorkItems ?? this.todayWorkItems,
    );
  }
}

class CustomerRolesWorkNotifier extends StateNotifier<CustomerRolesWorkState> {
  CustomerRolesWorkNotifier() : super(_initialState);

  static const CustomerRolesWorkState _initialState = CustomerRolesWorkState(
    roles: [
      CustomerRoleItem(
        id: 'role_1',
        roleName: 'Photographer',
        workTypes: ['Reels Shoot'],
        icon: Remix.camera_3_line,
        color: Color(0xFF0284C7),
        bgColor: Color(0xFFE0F2FE),
        description: 'Handles on-location photo and reels video shoots.',
      ),
      CustomerRoleItem(
        id: 'role_2',
        roleName: 'Video Editor',
        workTypes: ['Video Editing'],
        icon: Remix.film_line,
        color: Color(0xFF0D9488),
        bgColor: Color(0xFFCCFBF1),
        description: 'Cuts, colors, and renders dynamic social media reels.',
      ),
      CustomerRoleItem(
        id: 'role_3',
        roleName: 'Graphic Designer',
        workTypes: ['Post Design', 'Story Design'],
        icon: Remix.palette_line,
        color: Color(0xFF9333EA),
        bgColor: Color(0xFFF3E8FF),
        description:
            'Creates daily carousel posts and engaging story creatives.',
      ),
      CustomerRoleItem(
        id: 'role_4',
        roleName: 'Social Media Manager',
        workTypes: ['Uploading'],
        icon: Remix.share_forward_box_line,
        color: Color(0xFFEA580C),
        bgColor: Color(0xFFFFEDD5),
        description:
            'Manages scheduling, hashtags, and social platform publishing.',
      ),
      CustomerRoleItem(
        id: 'role_5',
        roleName: 'Telecaller',
        workTypes: ['Customer Calling / Follow-up'],
        icon: Remix.customer_service_2_line,
        color: Color(0xFF16A34A),
        bgColor: Color(0xFFDCFCE7),
        description:
            'Outbound sales follow-ups, renewal calls, and customer coordination.',
      ),
    ],
    workTypes: [
      CustomerWorkTypeItem(
        id: 'work_1',
        workName: 'Reels Shoot',
        assignedRole: 'Photographer',
        icon: Remix.video_line,
        color: Color(0xFF0284C7),
        bgColor: Color(0xFFE0F2FE),
        description: 'Shooting short-form vertical video content on site.',
      ),
      CustomerWorkTypeItem(
        id: 'work_2',
        workName: 'Video Editing',
        assignedRole: 'Video Editor',
        icon: Remix.scissors_cut_line,
        color: Color(0xFF0D9488),
        bgColor: Color(0xFFCCFBF1),
        description: 'Editing raw footage into final polished reel format.',
      ),
      CustomerWorkTypeItem(
        id: 'work_3',
        workName: 'Post Design',
        assignedRole: 'Graphic Designer',
        icon: Remix.image_line,
        color: Color(0xFF9333EA),
        bgColor: Color(0xFFF3E8FF),
        description: 'Designing brand static/carousel social media posts.',
      ),
      CustomerWorkTypeItem(
        id: 'work_4',
        workName: 'Story Design',
        assignedRole: 'Graphic Designer',
        icon: Remix.artboard_line,
        color: Color(0xFF7C3AED),
        bgColor: Color(0xFFEDE9FE),
        description:
            'Creating interactive 24h stories and promotional banners.',
      ),
      CustomerWorkTypeItem(
        id: 'work_5',
        workName: 'Uploading',
        assignedRole: 'Social Media Manager',
        icon: Remix.upload_cloud_2_line,
        color: Color(0xFFEA580C),
        bgColor: Color(0xFFFFEDD5),
        description:
            'Scheduling and publishing approved creatives to accounts.',
      ),
    ],
    teamMembers: [
      CustomerTeamMemberItem(
        id: 'tm_1',
        name: 'Avinash',
        role: 'Photographer',
        assignedWork: 'Reels Shoot',
        team: 'SSM Team A',
        status: 'ACTIVE',
        email: 'avinash@quickboom.com',
        phone: '+91 98765 43210',
      ),
      CustomerTeamMemberItem(
        id: 'tm_2',
        name: 'Rahul',
        role: 'Video Editor',
        assignedWork: 'Video Editing',
        team: 'SSM Team A',
        status: 'ACTIVE',
        email: 'rahul@quickboom.com',
        phone: '+91 98765 43211',
      ),
      CustomerTeamMemberItem(
        id: 'tm_3',
        name: 'Priya',
        role: 'Graphic Designer',
        assignedWork: 'Post Design, Story Design',
        team: 'SSM Team B',
        status: 'ACTIVE',
        email: 'priya@quickboom.com',
        phone: '+91 98765 43212',
      ),
      CustomerTeamMemberItem(
        id: 'tm_4',
        name: 'Sneha',
        role: 'Social Media Manager',
        assignedWork: 'Uploading',
        team: 'SSM Team A',
        status: 'ACTIVE',
        email: 'sneha@quickboom.com',
        phone: '+91 98765 43213',
      ),
      CustomerTeamMemberItem(
        id: 'tm_5',
        name: 'Amit',
        role: 'Telecaller',
        assignedWork: 'Customer Calling / Follow-up',
        team: 'Outreach Team',
        status: 'ACTIVE',
        email: 'amit@quickboom.com',
        phone: '+91 98765 43214',
      ),
    ],
    todayWorkItems: [
      CustomerTodayWorkItem(
        id: 'tw_1',
        time: '10:00 AM',
        customerName: 'Care Fitness Gym',
        workType: 'Reels Shoot',
        assignedPerson: 'Avinash',
        role: 'Photographer',
        team: 'SSM Team A',
        icon: Remix.video_line,
        color: Color(0xFF0284C7),
        bgColor: Color(0xFFE0F2FE),
      ),
      CustomerTodayWorkItem(
        id: 'tw_2',
        time: '12:00 PM',
        customerName: 'IB Gym',
        workType: 'Video Editing',
        assignedPerson: 'Rahul',
        role: 'Video Editor',
        team: 'SSM Team A',
        icon: Remix.scissors_cut_line,
        color: Color(0xFF0D9488),
        bgColor: Color(0xFFCCFBF1),
      ),
      CustomerTodayWorkItem(
        id: 'tw_3',
        time: '03:00 PM',
        customerName: 'Young India Fitness',
        workType: 'Post Design',
        assignedPerson: 'Priya',
        role: 'Graphic Designer',
        team: 'SSM Team B',
        icon: Remix.palette_line,
        color: Color(0xFF9333EA),
        bgColor: Color(0xFFF3E8FF),
      ),
    ],
  );

  void addRole(CustomerRoleItem role) {
    state = state.copyWith(roles: [...state.roles, role]);
  }

  void updateRole(CustomerRoleItem updatedRole) {
    state = state.copyWith(
      roles: state.roles
          .map((r) => r.id == updatedRole.id ? updatedRole : r)
          .toList(),
    );
  }

  void deleteRole(String roleId) {
    state = state.copyWith(
      roles: state.roles.where((r) => r.id != roleId).toList(),
    );
  }

  void addWorkType(CustomerWorkTypeItem workType) {
    state = state.copyWith(workTypes: [...state.workTypes, workType]);
  }

  void updateWorkType(CustomerWorkTypeItem updatedWorkType) {
    state = state.copyWith(
      workTypes: state.workTypes
          .map((w) => w.id == updatedWorkType.id ? updatedWorkType : w)
          .toList(),
    );
  }

  void deleteWorkType(String workTypeId) {
    state = state.copyWith(
      workTypes: state.workTypes.where((w) => w.id != workTypeId).toList(),
    );
  }

  void addTeamMember(CustomerTeamMemberItem member) {
    state = state.copyWith(teamMembers: [...state.teamMembers, member]);
  }

  void updateTeamMember(CustomerTeamMemberItem updatedMember) {
    state = state.copyWith(
      teamMembers: state.teamMembers
          .map((m) => m.id == updatedMember.id ? updatedMember : m)
          .toList(),
    );
  }

  void deleteTeamMember(String memberId) {
    state = state.copyWith(
      teamMembers: state.teamMembers.where((m) => m.id != memberId).toList(),
    );
  }
}

final customerRolesWorkProvider =
    StateNotifierProvider<CustomerRolesWorkNotifier, CustomerRolesWorkState>(
      (ref) => CustomerRolesWorkNotifier(),
    );
