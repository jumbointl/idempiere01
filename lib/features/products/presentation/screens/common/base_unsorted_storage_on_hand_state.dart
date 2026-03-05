import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

import '../../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../common/common_consumer_state.dart';
import '../../../common/input_dialog.dart';
import '../../../common/messages_dialog.dart';
import '../../../domain/idempiere/idempiere_locator.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/idempiere/put_away_movement.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/store_on_hand_provider.dart';
import '../movement/create/storage_on_hand_selectable_card.dart';
import '../movement/provider/new_auto_complete_movement_provider.dart';
import '../movement/provider/new_movement_provider.dart';

abstract class BaseUnsortedStorageOnHandState<T extends ConsumerStatefulWidget>
    extends CommonConsumerState<T> {
  late ScrollController scrollController;

  List<IdempiereStorageOnHande> unsortedStorageList = [];
  List<IdempiereStorageOnHande> storageList = [];
  List<bool> isCardsSelected = [];

  double widthLarge = 0;
  double widthSmall = 0;
  double dialogHeight = 0;
  double dialogWidth = 0;

  String errorMessage = '';

  @override
  double fontSizeMedium = 16;

  @override
  double fontSizeLarge = 22;

  double get screenWidth;
  bool get isInventory;
  IdempiereStorageOnHande get sourceStorage;
  double get minSelectableQtyOnTap;

  String get screenTitle;
  String get sliderText;

  String get messageNotStorageAvailable =>
      errorMessage.isNotEmpty ? errorMessage : Messages.NO_DATA_FOUND;

  Color get selectedStorageCardColor => Colors.green[100]!;
  Color get unselectedStorageCardColor => Colors.grey[200]!;

  List<IdempiereStorageOnHande> buildVisibleStorageList(
      List<IdempiereStorageOnHande> all,
      );

  /// English: Return false to stop quantity dialog / selection flow.
  bool onStorageSelected(
      WidgetRef ref,
      IdempiereStorageOnHande storage,
      int index,
      );

  Future<void> onPrimarySliderConfirmed();

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void prepareCommonBuild({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    widthLarge = screenWidth / 3 * 2;
    widthSmall = screenWidth / 3;

    dialogHeight = MediaQuery.of(context).size.height;
    dialogWidth = MediaQuery.of(context).size.width;

    unsortedStorageList = ref.read(unsortedStoreOnHandListProvider);
    storageList = buildVisibleStorageList(unsortedStorageList);

    if (isCardsSelected.length != storageList.length) {
      isCardsSelected = List<bool>.filled(storageList.length, false);
    }
  }

  AppBar buildCommonAppBar({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    List<Widget>? actions,
  }) {
    return AppBar(
      centerTitle: false,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => popScopeAction(context, ref),
      ),
      actions: actions,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget buildCommonBottomSlider({
    required BuildContext context,
    required WidgetRef ref,
    required String text,
    required Future<void> Function() onConfirmation,
  }) {
    return BottomAppBar(
      height: 70,
      color: themeColorPrimary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ConfirmationSlider(
          height: 45,
          backgroundColor: Colors.green[100]!,
          backgroundColorEnd: Colors.green[800]!,
          foregroundColor: Colors.green,
          text: text,
          textStyle: const TextStyle(
            fontSize: themeFontSizeLarge,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
          onConfirmation: onConfirmation,
        ),
      ),
    );
  }

  Widget sectionCard({required Color? color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
  }

  Widget buildProductHeaderCard(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget buildSimpleValueRow({
    required String label,
    required String value,
    Color? backgroundColor,
    Color valueColor = Colors.purple,
  }) {
    return sectionCard(
      color: backgroundColor ?? Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLocatorCard({
    required String label,
    required IdempiereLocator? locator,
    VoidCallback? onTap,
  }) {
    final valid = locator != null && locator.id != null && locator.id! > 0;

    final content = Row(
      children: [
        Icon(
          Icons.location_on,
          color: valid ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: ${locator?.value ?? locator?.identifier ?? '--'}',
            style: TextStyle(
              fontSize: fontSizeMedium,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );

    return sectionCard(
      color: valid ? Colors.green[50] : Colors.amber[50],
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }

  Widget buildLinesCard({
    required double lines,
    required VoidCallback onEdit,
  }) {
    return sectionCard(
      color: Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              Messages.LINES,
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextButton(
              style: TextButton.styleFrom(
                side: const BorderSide(color: Colors.black, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
              ),
              onPressed: onEdit,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  Memory.numberFormatter0Digit.format(lines),
                  style: TextStyle(
                    fontSize: fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget storageOnHandCard({
    required WidgetRef ref,
    required IdempiereStorageOnHande storage,
    required int index,
    bool enableSend = true,
  }) {
    final qtyOnHand = storage.qtyOnHand ?? 0;

    return StorageOnHandSelectableCard(
      ref: ref,
      storage: storage,
      width: screenWidth,
      isSelected: isCardsSelected[index],
      isInventory: isInventory,
      selectedColor: selectedStorageCardColor,
      unselectedColor: unselectedStorageCardColor,
      onTap: () async {
        setState(() {
          isCardsSelected = List<bool>.filled(storageList.length, false);
          isCardsSelected[index] = true;
        });

        final ok = onStorageSelected(ref, storage, index);
        if (!ok) {
          if (messageNotStorageAvailable.isNotEmpty) {
            showWarningCenterToast(context, messageNotStorageAvailable);
          }
          return;
        }

        unfocus();

        await getDoubleDialog(
          ref: ref,
          minValue: minSelectableQtyOnTap,
          maxValue: qtyOnHand,
          quantity: qtyOnHand,
          targetProvider: quantityToMoveProvider,
        );

        ref.read(isDialogShowedProvider.notifier).state = false;
      },
      onSendTap: enableSend && qtyOnHand > 0
          ? () async {
        await onSendStorage(storage, index);
      }
          : null,
    );
  }

  Future<void> onSendStorage(
      IdempiereStorageOnHande storage,
      int index,
      ) async {
    await createAutoCompleteMovement(storage, index);
  }

  Widget buildStockList(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 5),
      sliver: SliverList.separated(
        itemBuilder: (BuildContext context, int index) {
          return storageOnHandCard(
            ref: ref,
            storage: storageList[index],
            index: index,
          );
        },
        itemCount: storageList.length,
        separatorBuilder: (BuildContext context, int index) =>
        const SizedBox(height: 5),
      ),
    );
  }

  Future<void> createAutoCompleteMovement(
      IdempiereStorageOnHande fromStorage,
      int index,
      ) async {
    ref.read(quantityToMoveProvider.notifier).state = 0;
    ref.invalidate(newAutoCompleteMovementProvider);

    final destinationList =
    buildAutoCompleteMovementDestinationList(fromStorage);

    if (destinationList.isEmpty) {
      showErrorMessage(context, ref, messageNotStorageAvailable);
      return;
    }

    int selectedIndex = -1;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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

                final locatorFromName = fromStorage.mLocatorID?.value ??
                    fromStorage.mLocatorID?.identifier ??
                    '--';

                final locatorToName = selectedTo?.mLocatorID?.value ??
                    selectedTo?.mLocatorID?.identifier ??
                    '--';

                return SafeArea(
                  child: SizedBox(
                    height: MediaQuery.of(sheetContext).size.height * 0.92,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          buildProductCard(fromStorage),
                          const SizedBox(height: 8),
                          buildFromCard(fromStorage),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
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
                            child: buildQuantityCard(qty),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'TO:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: ListView.separated(
                              itemCount: destinationList.length,
                              separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final item = destinationList[i];
                                final isSelected = i == selectedIndex;

                                return buildDestinationCard(
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
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('LocatorFrom: $locatorFromName'),
                                Text('LocatorTo: $locatorToName'),
                                Text(
                                  'Cantidad: ${Memory.numberFormatter0Digit.format(qty)}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
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
                                  'MOVEMENT CREATED ID : ${movement.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                );
                              }

                              if (movement.id == null) {
                                return Text(
                                  'MOVEMENT ID : ${Messages.ERROR_DOCUMENT_NOT_CREATED}',
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if ((movement.description ?? '').isNotEmpty)
                                    Text(movement.description ?? ''),
                                  Text(
                                    'MOVEMENT ID : ${movement.name ?? movement.id}',
                                  ),
                                ],
                              );
                            },
                            error: (error, stackTrace) =>
                                Text('Error: $error'),
                            loading: () => const LinearProgressIndicator(),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    if (qty <= 0) {
                                      showErrorMessage(
                                        context,
                                        ref,
                                        Messages.ERROR_QUANTITY,
                                      );
                                      return;
                                    }

                                    if (selectedTo == null ||
                                        selectedTo.mLocatorID?.id == null ||
                                        selectedTo.mLocatorID!.id! <= 0) {
                                      showErrorMessage(
                                        context,
                                        ref,
                                        Messages.ERROR_LOCATOR_TO,
                                      );
                                      return;
                                    }

                                    if (qty > (fromStorage.qtyOnHand ?? 0)) {
                                      showErrorMessage(
                                        context,
                                        ref,
                                        Messages.ERROR_QUANTITY,
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

                                    if (movement == null) {
                                      showErrorMessage(
                                        context,
                                        ref,
                                        Messages.ERROR,
                                      );
                                      return;
                                    }

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
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () =>
                                      Navigator.of(sheetContext).pop(),
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text('Cancelar'),
                                ),
                              ),
                            ],
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

  List<IdempiereStorageOnHande> buildAutoCompleteMovementDestinationList(
      IdempiereStorageOnHande fromStorage,
      ) {
    final fromWarehouseId = fromStorage.mLocatorID?.mWarehouseID?.id ?? -1;
    final fromLocatorId = fromStorage.mLocatorID?.id ?? -1;
    final fromProductId = fromStorage.mProductID?.id ?? -1;
    final fromAttributeSetId =
        fromStorage.mAttributeSetInstanceID?.id ?? Memory.INITIAL_STATE_ID;

    return unsortedStorageList.where((e) {
      final warehouseId = e.mLocatorID?.mWarehouseID?.id ?? -1;
      final locatorId = e.mLocatorID?.id ?? -1;
      final productId = e.mProductID?.id ?? -1;
      final attributeSetId =
          e.mAttributeSetInstanceID?.id ?? Memory.INITIAL_STATE_ID;

      final sameWarehouse = warehouseId == fromWarehouseId;
      final sameProduct = productId == fromProductId;

      if (!sameWarehouse || !sameProduct) return false;

      final sameObject =
          e.id != null && fromStorage.id != null && e.id == fromStorage.id;
      if (sameObject) return false;

      final sameLocator = locatorId == fromLocatorId;
      final sameAttributeSet = attributeSetId == fromAttributeSetId;

      if (sameLocator && sameAttributeSet) {
        return false;
      }

      return true;
    }).toList();
  }

  PutAwayMovement? createPutAwayMovementForAutoComplete({
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

  Widget buildProductCard(IdempiereStorageOnHande storage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        storage.mProductID?.identifier ?? '--',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildFromCard(IdempiereStorageOnHande storage) {
    final warehouse = storage.mLocatorID?.mWarehouseID?.identifier ?? '--';
    final locator =
        storage.mLocatorID?.value ?? storage.mLocatorID?.identifier ?? '--';
    final qty = Memory.numberFormatter0Digit.format(storage.qtyOnHand ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.cyan[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FROM:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Warehouse: $warehouse'),
          Text('Locator: $locator'),
          Text('Qty: $qty'),
        ],
      ),
    );
  }

  Widget buildQuantityCard(double qty) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade800),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Cantidad',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            Memory.numberFormatter0Digit.format(qty),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDestinationCard({
    required IdempiereStorageOnHande item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final warehouse = item.mLocatorID?.mWarehouseID?.identifier ?? '--';
    final locator =
        item.mLocatorID?.value ?? item.mLocatorID?.identifier ?? '--';
    final qty = Memory.numberFormatter0Digit.format(item.qtyOnHand ?? 0);
    final attribute = item.mAttributeSetInstanceID?.identifier ?? '--';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[200] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade800 : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Warehouse: $warehouse'),
            Text('Locator: $locator'),
            Text('Qty: $qty'),
            Text('Att Set: $attribute'),
          ],
        ),
      ),
    );
  }

  void popScopeAction(BuildContext context, WidgetRef ref);
}