import 'package:monalisa_app_001/features/auth/domain/domain.dart';
import 'package:monalisa_app_001/features/auth/domain/dtos/auth_data_dto.dart';
import 'package:monalisa_app_001/features/auth/domain/dtos/login_dto.dart';
import 'package:monalisa_app_001/features/auth/domain/dtos/organization_dto.dart';
import 'package:monalisa_app_001/features/auth/domain/dtos/role_dto.dart';
import 'package:monalisa_app_001/features/auth/domain/dtos/warehouse_dto.dart';
import '../infrastructure.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;

  AuthRepositoryImpl({AuthDataSource? dataSource})
      : dataSource = dataSource ?? AuthDataSourceImpl();

  @override
  Future<LoginDto> login(String userName, String password) {
    return dataSource.login(userName, password);
  }

  @override
  Future<RoleDto> getRoles(int clientId) {
    return dataSource.getRoles(clientId);
  }

  @override
  Future<OrganizationDto> getOrganizations(
      int clientId, int roleId) {
    return dataSource.getOrganizations(clientId, roleId);
  }

  @override
  Future<WarehouseDto> getWarehouses(
      int clientId, int roleId, int organizationId) {
    return dataSource.getWarehouses(clientId, roleId, organizationId);
  }

  @override
  Future<AuthDataDto> getAuthData(int clientId, int roleId,
      int organizationId, int warehouseId) {
    return dataSource.getAuthData(
        clientId, roleId, organizationId, warehouseId);
  }
  
  @override
  Future<bool> validateUrl(String url) {
    return dataSource.validateUrl(url);
  }
  
  @override
  Future<RoleDto> getRolesIncluded(int roleId) {
    return dataSource.getRolesIncluded(roleId);
  }
}
