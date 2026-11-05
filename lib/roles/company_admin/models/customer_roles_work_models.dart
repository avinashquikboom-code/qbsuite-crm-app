import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

class CustomerRoleItem {
  final String id;
  final String roleName;
  final List<String> workTypes;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String? description;

  const CustomerRoleItem({
    required this.id,
    required this.roleName,
    required this.workTypes,
    this.icon = Remix.user_star_line,
    this.color = const Color(0xFF0284C7),
    this.bgColor = const Color(0xFFE0F2FE),
    this.description,
  });

  CustomerRoleItem copyWith({
    String? id,
    String? roleName,
    List<String>? workTypes,
    IconData? icon,
    Color? color,
    Color? bgColor,
    String? description,
  }) {
    return CustomerRoleItem(
      id: id ?? this.id,
      roleName: roleName ?? this.roleName,
      workTypes: workTypes ?? this.workTypes,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      bgColor: bgColor ?? this.bgColor,
      description: description ?? this.description,
    );
  }
}

class CustomerWorkTypeItem {
  final String id;
  final String workName;
  final String assignedRole;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String? description;

  const CustomerWorkTypeItem({
    required this.id,
    required this.workName,
    required this.assignedRole,
    this.icon = Remix.task_line,
    this.color = const Color(0xFF0D9488),
    this.bgColor = const Color(0xFFCCFBF1),
    this.description,
  });

  CustomerWorkTypeItem copyWith({
    String? id,
    String? workName,
    String? assignedRole,
    IconData? icon,
    Color? color,
    Color? bgColor,
    String? description,
  }) {
    return CustomerWorkTypeItem(
      id: id ?? this.id,
      workName: workName ?? this.workName,
      assignedRole: assignedRole ?? this.assignedRole,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      bgColor: bgColor ?? this.bgColor,
      description: description ?? this.description,
    );
  }
}

class CustomerTeamMemberItem {
  final String id;
  final String name;
  final String role;
  final String assignedWork;
  final String team;
  final String status;
  final Color statusColor;
  final Color statusBgColor;
  final String email;
  final String phone;

  const CustomerTeamMemberItem({
    required this.id,
    required this.name,
    required this.role,
    required this.assignedWork,
    required this.team,
    this.status = 'ACTIVE',
    this.statusColor = const Color(0xFF16A34A),
    this.statusBgColor = const Color(0xFFDCFCE7),
    this.email = '',
    this.phone = '',
  });

  CustomerTeamMemberItem copyWith({
    String? id,
    String? name,
    String? role,
    String? assignedWork,
    String? team,
    String? status,
    Color? statusColor,
    Color? statusBgColor,
    String? email,
    String? phone,
  }) {
    return CustomerTeamMemberItem(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      assignedWork: assignedWork ?? this.assignedWork,
      team: team ?? this.team,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
      statusBgColor: statusBgColor ?? this.statusBgColor,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}

class CustomerTodayWorkItem {
  final String id;
  final String time;
  final String customerName;
  final String workType;
  final String assignedPerson;
  final String role;
  final String team;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const CustomerTodayWorkItem({
    required this.id,
    required this.time,
    required this.customerName,
    required this.workType,
    required this.assignedPerson,
    required this.role,
    required this.team,
    this.icon = Remix.video_line,
    this.color = const Color(0xFF0D9488),
    this.bgColor = const Color(0xFFCCFBF1),
  });
}
