import 'package:dio/dio.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/auth/domain/domain.dart';
import 'package:monalisa_app_001/features/auth/domain/dtos/auth_data_dto.dart';
import 'package:monalisa_app_001/features/auth/domain/dtos/login_dto.dart';
import 'package:monalisa_app_001/features/auth/domain/dtos/organization_dto.dart';
import 'package:monalisa_app_001/features/auth/domain/dtos/role_dto.dart';
import 'package:monalisa_app_001/features/auth/domain/dtos/warehouse_dto.dart';
import 'package:monalisa_app_001/features/auth/infrastructure/mappers/auth_data_mapper.dart';
import 'package:monalisa_app_001/features/auth/infrastructure/mappers/login_mapper.dart';
import 'package:monalisa_app_001/features/auth/infrastructure/mappers/organization_mapper.dart';
import 'package:monalisa_app_001/features/auth/infrastructure/mappers/role_mapper.dart';
import 'package:monalisa_app_001/features/shared/shared.dart';

import '../../../shared/data/memory.dart';
import '../../../shared/domain/entities/response_api.dart';
import '../../domain/entities/ad_role_included.dart';
import '../../domain/entities/role.dart';
import '../mappers/warehouse_mapper.dart';

class AuthDataSourceImpl implements AuthDataSource {
  late final Dio dio;

  AuthDataSourceImpl() {
    _initDio();
  }

  Future<void> _initDio() async {
    dio = await DioClient.create();
  }

  @override
  Future<LoginDto> login(String userName, String password) async {
    Memory.userName = userName;
    try {
      final response = await dio.post('/api/v1/auth/tokens',
          data: {'userName': userName, 'password': password});

      final loginResponse = LoginMapper.loginDtoJsonToEntity(response.data);

      return loginResponse;
    } on DioException catch (e) {
      print(e);
      throw CustomErrorDioException(e, null);
    } catch (e) {
      throw Exception('ERROR: ${e.toString()}');
    }
  }

  @override
  Future<RoleDto> getRoles(int clientId) async {
    try {
      final response = await dio.get('/api/v1/auth/roles?client=$clientId');

      final rolesResponse = RoleMapper.roleDtoJsonToEntity(response.data);
      return rolesResponse;
    } on DioException catch (e) {
      print(e);
      throw CustomErrorDioException(e, null);
    } catch (e) {
      throw Exception('ERROR: ${e.toString()}');
    }
  }

  @override
  Future<OrganizationDto> getOrganizations(int clientId, int roleId) async {
    try {
      final response = await dio
          .get('/api/v1/auth/organizations?client=$clientId&role=$roleId');

      final organizationsResponse =
          OrganizationMapper.organizationDtoJsonToEntity(response.data);
      return organizationsResponse;
    } on DioException catch (e) {
      print(e);
      throw CustomErrorDioException(e, null);
    } catch (e) {
      throw Exception('ERROR: ${e.toString()}');
    }
  }

  @override
  Future<WarehouseDto> getWarehouses(
      int clientId, int roleId, int organizationId) async {
    try {
      final response = await dio.get(
          '/api/v1/auth/warehouses?client=$clientId&role=$roleId&organization=$organizationId');

      final warehousesResponse =
          WarehouseMapper.warehouseDtoJsonToEntity(response.data);
      return warehousesResponse;
    } on DioException catch (e) {
      print(e);
      throw CustomErrorDioException(e, null);
    } catch (e) {
      throw Exception('ERROR: ${e.toString()}');
    }
  }

  @override
  Future<AuthDataDto> getAuthData(
      int clientId, int roleId, int organizationId, int warehouseId) async {

    try {
      final response = await dio.put(
        '/api/v1/auth/tokens',
        data: {
          "clientId": clientId,
          "roleId": roleId,
          "organizationId": organizationId,
          "warehouseId": warehouseId,
          "language": "es_PY",
        },
      );

      final authDataResponse =
          AuthDataMapper.authDataDtoJsonToEntity(response.data);
      if(authDataResponse.token!=null){
        Memory.sqlUsersData.setIdempiereClient(clientId);
        Memory.sqlUsersData.setIdempiereOrganization(organizationId);
        Memory.sqlUsersData.setIdempiereWarehouse(warehouseId: warehouseId,organizationId: organizationId);
        if(authDataResponse.userId!=null) Memory.sqlUsersData.setIdempiereCreateBy(authDataResponse.userId!);

      }

      return authDataResponse;
    } on DioException catch (e) {
      print(e);
      throw CustomErrorDioException(e, null);
    } catch (e) {
      throw Exception('ERROR: ${e.toString()}');
    }
  }

  @override
  Future<bool> validateUrl(String url) async {
    try {
      Environment.apiUrl = url;
      final response = await dio.get(url);
      Environment.apiUrl = '';
      return response.statusCode == 200;
    } catch (e) {
      print('Error validating URL: $e');
      return false;
    }
  }

  @override
  Future<RoleDto> getRolesIncluded(int roleId) async {
    try {
      final response = await dio.get(
          '/api/v1/models/ad_role_included?\$filter=AD_Role_ID%20eq%20$roleId');

      if (response.statusCode == 200) {
        final responseApi = ResponseApi<AdRoleIncluded>.fromJson(
            response.data, AdRoleIncluded.fromJson);

        final roles = responseApi.records?.map((role) {
          return Role(
            id: int.parse(role.includedRoleId.id?.toString() ?? '0'),
            name: role.includedRoleId.identifier ?? '',
          );
        }).toList() ?? [];

        return RoleDto(roles: roles);
      } else {
        throw Exception(
            'Error al obtener la lista de roles: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print(e);
      throw CustomErrorDioException(e, null);
    } catch (e) {
      throw Exception('ERROR: ${e.toString()}');
    }
  }
}
