import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/shared/presentation/widgets/container_action_buttons.dart';

import '../../../../config/config.dart';
import '../../../shared/presentation/widgets/custom_drop_down.dart';
import '../../../shared/shared.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/role.dart';
import '../../domain/entities/warehouse.dart';
import '../providers/auth_provider.dart';

class AuthDataScreen extends StatelessWidget {
  const AuthDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seleccionar Rol'),
        ),
        body: const RoleView(),
      ),
    );
  }
}

class RoleView extends ConsumerWidget {
  const RoleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authDataState = ref.watch(authProvider);
    final authDataNotifier = ref.read(authProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        children: [
          CustomDropDown<Client>(
            label: 'Grupo Empresarial',
            value: authDataState.selectedClient,
            options: authDataState.clients,
            onChanged: (client) => authDataNotifier.updateClient(client!),
          ),
          const SizedBox(height: 4),
          CustomDropDown<Role>(
            label: 'Rol',
            value: authDataState.selectedRole,
            options: authDataState.roles,
            onChanged: (role) => authDataNotifier.updateRole(role!),
          ),
          const SizedBox(height: 4),
          CustomDropDown<Organization>(
            label: 'Organización',
            value: authDataState.selectedOrganization,
            options: authDataState.organizations,
            onChanged: (organization) =>
                authDataNotifier.updateOrganization(organization!),
          ),
          const SizedBox(height: 4),
          CustomDropDown<Warehouse>(
            label: 'Almacén',
            value: authDataState.selectedWarehouse,
            options: authDataState.warehouses,
            onChanged: (warehouse) =>
                authDataNotifier.updateWarehouse(warehouse!),
          ),
          const SizedBox(height: 16),
          ContainerActionButtons(
            children: [
              CustomFilledButton(
                onPressed: authDataState.isLoading
                    ? null
                    : () {
                        authDataNotifier.submitAuthData();
                      },
                label: 'Confirmar',
                icon: const Icon(Icons.check),
                isPosting: authDataState.isLoading,
              ),
              CustomFilledButton(
                onPressed: () {
                  authDataNotifier.authDataCancelar(context);
                },
                label: 'Cancelar',
                icon: const Icon(Icons.close),
                labelColor: Colors.white,
                buttonColor: themeColorGray,
              )
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
