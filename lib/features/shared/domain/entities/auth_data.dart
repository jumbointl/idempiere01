import '../../../auth/domain/entities/client.dart';
import '../../../auth/domain/entities/organization.dart';
import '../../../auth/domain/entities/role.dart';
import '../../../auth/domain/entities/warehouse.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AuthData {
  final String userName;
  final String password;
  final Client selectedClient;
  final Role selectedRole;
  final Organization selectedOrganization;
  final Warehouse selectedWarehouse;

  AuthData({
    required this.userName,
    required this.password,
    required this.selectedClient,
    required this.selectedRole,
    required this.selectedOrganization,
    required this.selectedWarehouse,
  });
}

extension AuthStateMapper on AuthState {
  AuthData toAuthData() {
    if (userName == null ||
        password == null ||
        selectedClient == null ||
        selectedRole == null ||
        selectedOrganization == null ||
        selectedWarehouse == null) {
      throw Exception('AuthState incompleto para run process');
    }

    return AuthData(
      userName: userName!,
      password: password!,
      selectedClient: selectedClient!,
      selectedRole: selectedRole!,
      selectedOrganization: selectedOrganization!,
      selectedWarehouse: selectedWarehouse!,
    );
  }
}
