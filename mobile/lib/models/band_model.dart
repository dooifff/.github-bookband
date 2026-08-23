class BandModel {
  final int id;
  final String name;
  final String? description;
  final String? genre;
  final String status;
  final BandMember? owner;
  final List<BandMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;

  BandModel({
    required this.id,
    required this.name,
    this.description,
    this.genre,
    required this.status,
    this.owner,
    this.members = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory BandModel.fromJson(Map<String, dynamic> json) {
    return BandModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      genre: json['genre'],
      status: json['status'] ?? 'active',
      owner: json['owner'] != null ? BandMember.fromJson(json['owner']) : null,
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => BandMember.fromJson(m))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'genre': genre,
      'status': status,
      'owner': owner?.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class BandMember {
  final int id;
  final MemberUser? user;
  final String role;
  final String status;
  final DateTime? joinedAt;

  BandMember({
    required this.id,
    this.user,
    required this.role,
    required this.status,
    this.joinedAt,
  });

  factory BandMember.fromJson(Map<String, dynamic> json) {
    return BandMember(
      id: json['id'],
      user: json['user'] != null ? MemberUser.fromJson(json['user']) : null,
      role: json['role'] ?? 'member',
      status: json['status'] ?? 'pending',
      joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'role': role,
      'status': status,
      'joined_at': joinedAt?.toIso8601String(),
    };
  }
}

class MemberUser {
  final int id;
  final String name;

  MemberUser({
    required this.id,
    required this.name,
  });

  factory MemberUser.fromJson(Map<String, dynamic> json) {
    return MemberUser(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
