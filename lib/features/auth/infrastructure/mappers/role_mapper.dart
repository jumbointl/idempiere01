import 'package:monalisa_app_001/features/auth/domain/dtos/role_dto.dart';

import '../../domain/entities/role.dart';

class RoleMapper {
  static RoleDto roleDtoJsonToEntity(Map<String, dynamic> json) =>
      RoleDto(
        roles: List<Role>.from(
          json['roles'].map(
              (roleJson) => Role.fromJson(roleJson as Map<String, dynamic>)),
        ),
      );
}
