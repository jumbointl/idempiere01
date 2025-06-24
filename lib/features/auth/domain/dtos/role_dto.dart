import '../entities/role.dart';

class RoleDto {
  final List<Role> roles;

  RoleDto({
    required this.roles,
  });

  factory RoleDto.fromJson(Map<String, dynamic> json) {
    return RoleDto(
      roles: (json['roles'] as List<dynamic>)
          .map((role) => Role.fromJson(role as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roles': roles.map((role) => role.toJson()).toList(),
    };
  }
}
