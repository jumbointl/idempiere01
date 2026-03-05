import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/idempiere_locator.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/put_away_movement.dart';
import '../../../providers/product_provider_common.dart';
import '../../movement/provider/new_auto_complete_movement_provider.dart';
import '../provider/new_movement_provider.dart';

mixin AutoCompleteMovementHelper<T extends ConsumerStatefulWidget>
on ConsumerState<T> {
  List<IdempiereStorageOnHande> buildAutoCompleteMovementDestinationList({
    required List<IdempiereStorageOnHande> all,
    required IdempiereStorageOnHande fromStorage,
  }) {
    final int fromWarehouseId = fromStorage.mLocatorID?.mWarehouseID?.id ?? -1;
    final int fromLocatorId = fromStorage.mLocatorID?.id ?? -1;
    final int fromProductId = fromStorage.mProductID?.id ?? -1;
    final int fromAttributeSetId =
        fromStorage.mAttributeSetInstanceID?.id ?? Memory.INITIAL_STATE_ID;

    return all.where((e) {
      final int warehouseId = e.mLocatorID?.mWarehouseID?.id ?? -1;
      final int locatorId = e.mLocatorID?.id ?? -1;
      final int productId = e.mProductID?.id ?? -1;
      final int attributeSetId =
          e.mAttributeSetInstanceID?.id ?? Memory.INITIAL_STATE_ID;

      final bool sameWarehouse = warehouseId == fromWarehouseId;
      final bool sameProduct = productId == fromProductId;

      if (!sameWarehouse || !sameProduct) return false;

      final bool sameObject =
          e.id != null && fromStorage.id != null && e.id == fromStorage.id;
      if (sameObject) return false;

      final bool sameLocator = locatorId == fromLocatorId;
      final bool sameAttributeSet = attributeSetId == fromAttributeSetId;

      if (sameLocator && sameAttributeSet) {
        return false;
      }

      return true;
    }).toList();
  }

  PutAwayMovement createPutAwayMovementForAutoComplete({
    required IdempiereStorageOnHande fromStorage,
    required IdempiereStorageOnHande toStorage,
    required double qty,
  }) {
    final movement = PutAwayMovement();
    movement.setUser(Memory.sqlUsersData);

    movement.movementLineToCreate!.mProductID = fromStorage.mProductID;
    movement.movementLineToCreate!.mLocatorID = fromStorage.mLocatorID;
    movement.movementLineToCreate!.mLocatorToID = toStorage.mLocatorID;
    movement.movementLineToCreate!.movementQty = qty;
    movement.movementLineToCreate!.productName =
        fromStorage.mProductID?.name ?? fromStorage.mProductID?.identifier;

    movement.movementToCreate!.locatorFromId = fromStorage.mLocatorID?.id;
    movement.movementToCreate!.mWarehouseID =
        fromStorage.mLocatorID?.mWarehouseID;
    movement.movementToCreate!.mWarehouseToID =
        toStorage.mLocatorID?.mWarehouseID;

    return movement;
  }

  bool verifyLocator({
    required IdempiereLocator? locatorFrom,
    required IdempiereLocator? locatorTo,
  }) {
    return true;
  }

  Widget buildAutoMovementDestinationCard({
    required IdempiereStorageOnHande item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[200] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade400,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.mLocatorID?.value ?? item.mLocatorID?.identifier ?? '--'),
            Text(item.mAttributeSetInstanceID?.identifier ?? '--'),
            Text(
              Memory.numberFormatter0Digit.format(item.qtyOnHand ?? 0),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> createAutoCompleteMovement({
    required BuildContext context,
    required WidgetRef ref,
    required List<IdempiereStorageOnHande> sourceList,
    required IdempiereStorageOnHande fromStorage,
  }) async {
    ref.read(quantityToMoveProvider.notifier).state = 0;
    ref.invalidate(newAutoCompleteMovementProvider);

    final destinationList = buildAutoCompleteMovementDestinationList(
      all: sourceList,
      fromStorage: fromStorage,
    );

    if (destinationList.isEmpty) {
      showErrorMessage(
        context,
        ref,
        'No hay destinos disponibles para corregir stock',
      );
      return;
    }

    int selectedIndex = -1;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Consumer(
              builder: (context, ref, _) {
                final qty = ref.watch(quantityToMoveProvider);
                final createMovementAsync =
                ref.watch(newAutoCompleteMovementProvider);

                final selectedTo =
                selectedIndex >= 0 ? destinationList[selectedIndex] : null;

                return SafeArea(
                  child: SizedBox(
                    height: MediaQuery.of(sheetContext).size.height * 0.92,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Create Auto Complete Movement',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.separated(
                              itemCount: destinationList.length,
                              separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final item = destinationList[i];
                                final isSelected = i == selectedIndex;

                                return buildAutoMovementDestinationCard(
                                  item: item,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setModalState(() {
                                      selectedIndex = i;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () async {
                              final maxQty = fromStorage.qtyOnHand ?? 0;
                              await getDoubleDialog(
                                ref: ref,
                                maxValue: maxQty,
                                minValue: 1,
                                quantity: maxQty,
                                targetProvider: quantityToMoveProvider,
                              );

                              ref.read(isDialogShowedProvider.notifier).state =
                              false;
                              ref.read(isScanningProvider.notifier).state =
                              false;
                            },
                            child: Text(
                              'Cantidad: ${Memory.numberFormatter0Digit.format(qty)}',
                            ),
                          ),
                          const SizedBox(height: 8),
                          createMovementAsync.when(
                            data: (movement) {
                              if (movement == null) {
                                return const SizedBox.shrink();
                              }

                              if (movement.id != null && movement.id! > 0) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!sheetContext.mounted) return;
                                  Navigator.of(sheetContext).pop();
                                  showSuccessMessage(
                                    context,
                                    ref,
                                    'Movement created: ${movement.id}',
                                  );
                                });

                                return Text(
                                  'Movement created: ${movement.id}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }

                              return Text(
                                movement.description ??
                                    movement.name ??
                                    Messages.ERROR,
                              );
                            },
                            error: (error, stackTrace) =>
                                Text('Error: $error'),
                            loading: () => const LinearProgressIndicator(),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () {
                              if (qty <= 0) {
                                showErrorMessage(
                                  context,
                                  ref,
                                  Messages.ERROR_QUANTITY,
                                );
                                return;
                              }

                              if (selectedTo == null) {
                                showErrorMessage(
                                  context,
                                  ref,
                                  Messages.ERROR_LOCATOR_TO,
                                );
                                return;
                              }

                              final locatorOk = verifyLocator(
                                locatorFrom: fromStorage.mLocatorID,
                                locatorTo: selectedTo.mLocatorID,
                              );

                              if (!locatorOk) {
                                showErrorMessage(
                                  context,
                                  ref,
                                  Messages.ERROR_LOCATOR_TO,
                                );
                                return;
                              }

                              final movement =
                              createPutAwayMovementForAutoComplete(
                                fromStorage: fromStorage,
                                toStorage: selectedTo,
                                qty: qty,
                              );

                              ref
                                  .read(autoCompleteMovementDraftProvider.notifier)
                                  .state = movement;

                              ref
                                  .read(fireAutoCompleteMovementProvider.notifier)
                                  .update((state) => state + 1);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Crear'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}