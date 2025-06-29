import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/auth/infrastructure/infrastructure.dart';
import 'package:monalisa_app_001/features/shared/infrastructure/errors/custom_error.dart';
import 'package:monalisa_app_001/features/shared/infrastructure/services/services.dart';

import '../../../../config/constants/roles_app.dart';
import '../../domain/domain.dart';
import '../../domain/dtos/auth_data_dto.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/role.dart';
import '../../domain/entities/warehouse.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    authRepository: AuthRepositoryImpl(),
    keyValueStorageService: KeyValueStorageServiceImpl(),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository authRepository;
  final KeyValueStorageService keyValueStorageService;
  AuthDataDto authDataDto = AuthDataDto(language: 'es_PY');

  AuthNotifier({
    required this.authRepository,
    required this.keyValueStorageService,
  }) : super(AuthState(
          clients: [],
          roles: [],
          organizations: [],
          warehouses: [],
        )) {
    _initialize();
  }

  void _initialize() async {
    state = state.copyWith(
      showUrlApi: false,
    );
    try {
      bool urlApi = await loadUrlApi();
      if (urlApi) {
        await checkAuthStatus();
      } else {
        logout();
      }
    } catch (e) {
      logout(CustomErrorClean(e).clean);
    }
  }

  void setShowUrlApi() {
    state = state.copyWith(
      showUrlApi: true,
    );
  }

  void onUrlApiChanged(String value) {
    final url = value.trim();
    state = state.copyWith(
      urlApi: url,
      errorMessage: '',
    );
  }

  Future<bool> setUrlApi() async {
    bool isValid = await validateUrl(state.urlApi);
    if (!isValid) {
      state = state.copyWith(
        urlApiError: 'La URL ingresada no responde.',
      );
      return false;
    }
    state = state.copyWith(
      urlApiError: null,
    );
    await keyValueStorageService.setKeyValue('urlApi', state.urlApi);
    Environment.apiUrl = state.urlApi;
    return true;
  }

  Future<bool> validateUrl(String url) async {
    final validateResponse = await authRepository.validateUrl(url);
    return validateResponse;
  }

  Future<String> getUrlApi() async {
    try {
      final urlApi = await keyValueStorageService.getValue<String>('urlApi');
      if (urlApi == null || urlApi.isEmpty) {
        return '';
      }
      state = state.copyWith(
        urlApi: urlApi.trim(),
      );
      return urlApi;
    } catch (e) {
      log('Error al obtener la url del API: $e');
      return '';
    }
  }

  Future<void> login(
      String userName, String password, bool preferLocalData) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: '',
    );

    try {
      bool urlApi = await setUrlApi();

      if (!urlApi) {
        String message = state.urlApiError.isNotEmpty ? state.urlApiError : '';
        throw Exception(message);
      }

      final loginResponse = await authRepository.login(userName, password);

      if (loginResponse.clients.isEmpty) {
        throw Exception("No se encontraron clientes asociados a este usuario.");
      }

      state = state.copyWith(
        clients: loginResponse.clients,
        token: loginResponse.token,
        userName: userName,
        password: password,
        showUrlApi: false,
      );
      Environment.token = loginResponse.token;

      await updateClient(loginResponse.clients.first,
          preferLocalData: preferLocalData);

      if (state.authStatus != AuthStatus.checking) {
        state = state.copyWith(authStatus: AuthStatus.login, errorMessage: '');
      }
    } catch (e, stackTrace) {
      log("Error en login: $e\n$stackTrace");
      logout(CustomErrorClean(e).clean);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> submitAuthData() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final authDataResponse = await authRepository.getAuthData(
        state.selectedClient!.id,
        state.selectedRole!.id,
        state.selectedOrganization?.id ?? 0,
        state.selectedWarehouse?.id ?? 0,
      );

      if (authDataResponse.userId == null ||
          authDataResponse.token == null ||
          authDataResponse.refreshToken == null) {
        throw Exception("Faltan datos en la respuesta del login final.");
      }

      authDataDto.client = state.selectedClient;
      authDataDto.role = state.selectedRole;
      authDataDto.organization = state.selectedOrganization;
      authDataDto.warehouse = state.selectedWarehouse;
      authDataDto.userId = authDataResponse.userId;
      authDataDto.token = authDataResponse.token;
      authDataDto.refreshToken = authDataResponse.refreshToken;
      authDataDto.userName = state.userName;
      authDataDto.password = state.password;

      _setAuthData(authDataDto);

      final user = state.userName;
      final client = state.selectedClient?.name ?? '';
      final role = state.selectedRole?.name ?? '';
      final organization = state.selectedOrganization?.name ?? '';
      final warehouse = state.selectedWarehouse?.name ?? '';
      final authInfo = '$user@$client/$organization/$warehouse/$role';

      Environment.token = authDataResponse.token!;

      final rolesResponse =
          await authRepository.getRolesIncluded(state.selectedRole!.id);
      final rolesApp = rolesResponse.roles
          .where((role) => role.name.startsWith('APP_'))
          .toList();
      if (rolesApp.isNotEmpty) {
        RolesApp.set(rolesApp);
        // print('RolesApp: ${RolesApp.getString()}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: '',
          token: authDataResponse.token,
          authStatus: AuthStatus.authenticated,
          authInfo: authInfo,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No se encontraron roles APP asociados a este usuario.',
          authStatus: AuthStatus.notAuthenticated,
        );
        throw Exception(
            "No se encontraron roles APP asociados a este usuario.");
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: CustomErrorClean(e).clean,
        authStatus: AuthStatus.notAuthenticated,
      );
      throw Exception(CustomErrorClean(e).clean);
    }
  }

  Future<void> loadAuthData() async {
    state = state.copyWith(isLoading: true);
    try {
      final authDataResponse = await _getAuthData();

      if (authDataResponse == null) {
        logout();
        return;
      }

      authDataDto = authDataResponse;

      final hasValidCredentials = authDataDto.userName?.isNotEmpty == true &&
          authDataDto.password?.isNotEmpty == true;

      if (hasValidCredentials) {
        await login(authDataDto.userName!, authDataDto.password!, true);
      } else {
        logout();
      }
    } catch (e) {
      logout(CustomErrorClean(e).clean);
    }
  }

  void authDataCancelar(BuildContext context) {
    if (authDataDto.userId != null &&
        state.token != null &&
        authDataDto.refreshToken != null) {
      state = state.copyWith(
        authStatus: AuthStatus.authenticated,
      );
    } else {
      logout();
    }
  }

  Future<void> logout([String? errorMessage]) async {
    authDataDto = AuthDataDto();
    await keyValueStorageService.removeKey('authData');
    state = state.copyWith(
      authStatus: AuthStatus.notAuthenticated,
      errorMessage: errorMessage,
    );
  }

  Future<bool> loadUrlApi() async {
    final urlApi = await keyValueStorageService.getValue<String>('urlApi');
    if (urlApi != null && urlApi.isNotEmpty) {
      state = state.copyWith(urlApi: urlApi);
      Environment.apiUrl = urlApi;
      return true;
    }
    return false;
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(authStatus: AuthStatus.checking);
    try {
      final authDataResponse = await _getAuthData();
      if (authDataResponse != null) {
        authDataDto = authDataResponse;
        if (authDataDto.userName != null && authDataDto.password != null) {
          await login(authDataDto.userName!, authDataDto.password!, true);
          await submitAuthData();
        } else {
          logout();
        }
      } else {
        logout();
      }
    } catch (e) {
      logout(CustomErrorClean(e).clean);
    }
  }

  Future<void> _setAuthData(AuthDataDto authDataDto) async {
    final jsonString = jsonEncode(authDataDto);
    await keyValueStorageService.setKeyValue('authData', jsonString);
  }

  Future<AuthDataDto?> _getAuthData() async {
    try {
      final authDataString =
          await keyValueStorageService.getValue<String>('authData');

      if (authDataString == null || authDataString.isEmpty) {
        return null;
      }

      final authDataMap = jsonDecode(authDataString) as Map<String, dynamic>;
      return AuthDataDto.fromJson(authDataMap);
    } catch (e) {
      log('Error al obtener authData: $e');
      return null;
    }
  }

  Future<void> updateClient(Client client, {bool? preferLocalData}) async {
    final selected = preferLocalData == true && authDataDto.client != null
        ? state.clients.firstWhere((c) => c.id == authDataDto.client!.id,
            orElse: () => authDataDto.client!)
        : client;

    state = state.copyWith(
      selectedClient: selected,
      isLoading: true,
    );

    final rolesResponse =
        await authRepository.getRoles(state.selectedClient!.id);
    if (rolesResponse.roles.isEmpty) {
      throw Exception("No se encontraron roles disponibles para este cliente.");
    }
    // final filteredRoles = rolesResponse.roles
    //     .where((role) => !role.name.startsWith('APP_'))
    //     .toList();
    state = state.copyWith(roles: rolesResponse.roles, isLoading: false);
    await updateRole(rolesResponse.roles.first, preferLocalData: preferLocalData);
  }

  Future<void> updateRole(Role role, {bool? preferLocalData}) async {
    final selected = preferLocalData == true && authDataDto.role != null
        ? state.roles.firstWhere((r) => r.id == authDataDto.role!.id,
            orElse: () => authDataDto.role!)
        : role;

    state = state.copyWith(
      selectedRole: selected,
      isLoading: true,
    );

    final organizationsResponse = await authRepository.getOrganizations(
      state.selectedClient!.id,
      state.selectedRole!.id,
    );

    state = state.copyWith(
        organizations: organizationsResponse.organizations, isLoading: false);

    if (organizationsResponse.organizations.isNotEmpty) {
      await updateOrganization(organizationsResponse.organizations.first,
          preferLocalData: preferLocalData);
    }
  }

  Future<void> updateOrganization(Organization organization,
      {bool? preferLocalData = false}) async {
    final selected = preferLocalData == true && authDataDto.organization != null
        ? state.organizations.firstWhere(
            (o) => o.id == authDataDto.organization!.id,
            orElse: () => authDataDto.organization!)
        : organization;

    state = state.copyWith(
      selectedOrganization: selected,
      isLoading: true,
    );

    if (state.selectedOrganization != null) {
      final warehousesResponse = await authRepository.getWarehouses(
        state.selectedClient!.id,
        state.selectedRole!.id,
        state.selectedOrganization!.id,
      );

      state = state.copyWith(
          warehouses: warehousesResponse.warehouses, isLoading: false);

      if (warehousesResponse.warehouses.isNotEmpty) {
        updateWarehouse(warehousesResponse.warehouses.first,
            preferLocalData: preferLocalData);
      }
    }
  }

  void updateWarehouse(Warehouse warehouse, {bool? preferLocalData = false}) {
    final selected = preferLocalData == true && authDataDto.warehouse != null
        ? state.warehouses.firstWhere((w) => w.id == authDataDto.warehouse!.id,
            orElse: () => authDataDto.warehouse!)
        : warehouse;

    state = state.copyWith(
      selectedWarehouse: selected,
      isLoading: false,
    );
  }
}

enum AuthStatus { checking, login, authenticated, notAuthenticated }

class AuthState {
  final String? token;
  final String? userName;
  final String? password;
  final Client? selectedClient;
  final Role? selectedRole;
  final Organization? selectedOrganization;
  final Warehouse? selectedWarehouse;
  final String? authInfo;
  final List<Client> clients;
  final List<Role> roles;
  final List<Organization> organizations;
  final List<Warehouse> warehouses;
  final AuthStatus authStatus;
  final bool isLoading;
  final bool isSaving;
  final String errorMessage;
  final bool showUrlApi;
  final String urlApi;
  final String urlApiError;

  AuthState({
    this.token,
    this.userName,
    this.password,
    this.selectedClient,
    this.selectedRole,
    this.selectedOrganization,
    this.selectedWarehouse,
    this.authInfo,
    required this.clients,
    required this.roles,
    required this.organizations,
    required this.warehouses,
    this.authStatus = AuthStatus.checking,
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage = '',
    this.showUrlApi = false,
    this.urlApi = '',
    this.urlApiError = '',
  });

  AuthState copyWith({
    String? token,
    String? userName,
    String? password,
    Client? selectedClient,
    Role? selectedRole,
    Organization? selectedOrganization,
    Warehouse? selectedWarehouse,
    String? authInfo,
    List<Client>? clients,
    List<Role>? roles,
    List<Organization>? organizations,
    List<Warehouse>? warehouses,
    AuthStatus? authStatus,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? showUrlApi,
    String? urlApi,
    String? urlApiError,
  }) =>
      AuthState(
        token: token ?? this.token,
        userName: userName ?? this.userName,
        password: password ?? this.password,
        selectedClient: selectedClient ?? this.selectedClient,
        selectedRole: selectedRole ?? this.selectedRole,
        selectedOrganization: selectedOrganization ?? this.selectedOrganization,
        selectedWarehouse: selectedWarehouse ?? this.selectedWarehouse,
        authInfo: authInfo ?? this.authInfo,
        clients: clients ?? this.clients,
        roles: roles ?? this.roles,
        organizations: organizations ?? this.organizations,
        warehouses: warehouses ?? this.warehouses,
        authStatus: authStatus ?? this.authStatus,
        errorMessage: errorMessage ?? this.errorMessage,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        showUrlApi: showUrlApi ?? this.showUrlApi,
        urlApi: urlApi ?? this.urlApi,
        urlApiError: urlApiError ?? this.urlApiError,
      );
}
