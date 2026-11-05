class TeamLeaderItem {
  final int id;
  final String? employeeCode;
  final String? firstName;
  final String? lastName;
  final String? name;
  final String? email;
  final String? phone;
  final String? designation;

  const TeamLeaderItem({
    required this.id,
    this.employeeCode,
    this.firstName,
    this.lastName,
    this.name,
    this.email,
    this.phone,
    this.designation,
  });

  String get displayName {
    final full = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (full.isNotEmpty) return full;
    if ((name ?? '').isNotEmpty) return name!;
    return 'Leader #$id';
  }

  factory TeamLeaderItem.fromJson(Map<String, dynamic> json) {
    String? desigName;
    if (json['designation'] is Map) {
      desigName = json['designation']['name']?.toString();
    } else if (json['designation'] != null) {
      desigName = json['designation']?.toString();
    }

    return TeamLeaderItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      employeeCode: json['employeeCode']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      designation: desigName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeCode': employeeCode,
      'firstName': firstName,
      'lastName': lastName,
      'name': name,
      'email': email,
      'phone': phone,
      'designation': designation,
    };
  }
}

class TeamMemberItem {
  final int id;
  final int teamId;
  final int employeeId;
  final String role;
  final DateTime? joinedAt;
  final TeamLeaderItem? employee;

  const TeamMemberItem({
    required this.id,
    required this.teamId,
    required this.employeeId,
    required this.role,
    this.joinedAt,
    this.employee,
  });

  factory TeamMemberItem.fromJson(Map<String, dynamic> json) {
    return TeamMemberItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      teamId: json['teamId'] is int
          ? json['teamId']
          : int.tryParse(json['teamId']?.toString() ?? '0') ?? 0,
      employeeId: json['employeeId'] is int
          ? json['employeeId']
          : int.tryParse(json['employeeId']?.toString() ?? '0') ?? 0,
      role: json['role']?.toString() ?? 'MEMBER',
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString())
          : null,
      employee: json['employee'] is Map<String, dynamic>
          ? TeamLeaderItem.fromJson(json['employee'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'employeeId': employeeId,
      'role': role,
      'joinedAt': joinedAt?.toIso8601String(),
      'employee': employee?.toJson(),
    };
  }
}

class TeamItem {
  final int id;
  final int customerId;
  final String name;
  final String? description;
  final int? leaderId;
  final bool isActive;
  final String status;
  final TeamLeaderItem? leader;
  final List<TeamMemberItem> members;
  final int memberCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TeamItem({
    required this.id,
    required this.customerId,
    required this.name,
    this.description,
    this.leaderId,
    this.isActive = true,
    this.status = 'ACTIVE',
    this.leader,
    this.members = const [],
    this.memberCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory TeamItem.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List? ?? [];
    final parsedMembers = rawMembers
        .whereType<Map<String, dynamic>>()
        .map((m) => TeamMemberItem.fromJson(m))
        .toList();

    return TeamItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      customerId: json['customerId'] is int
          ? json['customerId']
          : int.tryParse(json['customerId']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      leaderId: json['leaderId'] != null
          ? (json['leaderId'] is int
                ? json['leaderId']
                : int.tryParse(json['leaderId']?.toString() ?? ''))
          : null,
      isActive: json['isActive'] is bool
          ? json['isActive']
          : (json['isActive']?.toString() == 'true'),
      status:
          json['status']?.toString() ??
          ((json['isActive'] == false) ? 'INACTIVE' : 'ACTIVE'),
      leader: json['leader'] is Map<String, dynamic>
          ? TeamLeaderItem.fromJson(json['leader'])
          : null,
      members: parsedMembers,
      memberCount: json['memberCount'] is int
          ? json['memberCount']
          : (int.tryParse(json['memberCount']?.toString() ?? '') ??
                parsedMembers.length),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'name': name,
      'description': description,
      'leaderId': leaderId,
      'isActive': isActive,
      'status': status,
      'leader': leader?.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'memberCount': memberCount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
