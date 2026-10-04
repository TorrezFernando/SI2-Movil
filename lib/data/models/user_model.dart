class RoleModel {
  const RoleModel({
    required this.id,
    required this.name,
    required this.permissions,
  });

  final int id;
  final String name;
  final List<String> permissions;

  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        permissions: (json['permissions'] as List<dynamic>? ?? [])
            .whereType<String>()
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'permissions': permissions,
      };
}

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
    required this.roles,
  });

  final int id;
  final String email;
  final String fullName;
  final bool isActive;
  final List<RoleModel> roles;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        email: json['email'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? false,
        roles: (json['roles'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(RoleModel.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'is_active': isActive,
        'roles': roles.map((role) => role.toJson()).toList(),
      };
}