import 'package:monalisa_app_001/features/auth/domain/dtos/auth_data_dto.dart';
import 'package:monalisa_app_001/features/auth/domain/dtos/login_dto.dart';

import '../dtos/organization_dto.dart';
import '../dtos/role_dto.dart';
import '../dtos/warehouse_dto.dart';

abstract class AuthRepository {
  Future<bool> validateUrl(String url);
  Future<LoginDto> login(String userName, String password);
  // Future<String> checkAuthStatus();
  Future<RoleDto> getRoles(int clientId);
  Future<OrganizationDto> getOrganizations(int clientId, int roleId);
  Future<WarehouseDto> getWarehouses(
      int clientId, int roleId, int organizationId);
  Future<AuthDataDto> getAuthData(
      int clientId, int roleId, int organizationId, int warehouseId);
  Future<RoleDto> getRolesIncluded(int roleId);
}
