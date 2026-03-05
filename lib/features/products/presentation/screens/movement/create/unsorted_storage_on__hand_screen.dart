import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/constants/roles_app.dart';
import 'package:monalisa_app_001/features/products/common/async_value_consumer_simple_state.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/common/input_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_document_type.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_inventory.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_inventory_line.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/create/movement_create_validation_result.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../common/messages_dialog.dart';
import '../../../providers/actions/find_locator_to_action_provider.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/locator_provider.dart';
import '../../../providers/store_on_hand/action_notifier.dart';
import '../../locator/search_locator_dialog.dart';
import '../provider/new_movement_provider.dart';
import 'auto_complete_movement_helper.dart';
import 'auto_complete_movement_ui.dart';
import 'movements_create_screen.dart';
import 'storage_on_hand_selectable_card.dart';

class UnsortedStorageOnHandScreen extends ConsumerStatefulWidget
    implements InputDataProcessor {
  final IdempiereStorageOnHande storage;
  final int index;

  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;

  double width;
  final int pageIndex = Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND;
  final int actionScanType = Memory.ACTION_GET_LOCATOR_TO_VALUE;
  final bool isInventory;

  String? productUPC;

  UnsortedStorageOnHandScreen({
    required this.index,
    required this.storage,
    required this.width,
    this.productUPC,
    super.key,
    required this.isInventory,
  });

  @override
  ConsumerState<UnsortedStorageOnHandScreen> createState() =>
      UnsortedStorageOnHandScreenState();

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    final notifier = ref.read(findLocatorToActionProvider);
    notifier.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
    );
  }
}

class UnsortedStorageOnHandScreenState
    extends AsyncValueConsumerSimpleState<UnsortedStorageOnHandScreen>
    with AutoCompleteMovementHelper<UnsortedStorageOnHandScreen> {
  List<IdempiereStorageOnHande> unsortedStorageList = [];
  List<IdempiereStorageOnHande> storageList = [];

  List<bool> isCardsSelected = [];

  @override
  double fontSizeMedium = 16;

  @override
  double fontSizeLarge = 22;

  double widthLarge = 0;
  double widthSmall = 0;

  double dialogHeight = 0;
  double dialogWidth = 0;

  PutAwayMovement? putAwayMovement;
  PutAwayInventory? putAwayInventory;
  IdempiereLocator? locatorFrom;

  late AsyncValue findLocatorTo;
  late double quantityToMove;

  @override
  bool get showLeading => true;

  @override
  bool get scrollMainDataCard => false;

  @override
  int get actionScanTypeInt => widget.actionScanType;

  @override
  AsyncValue<ResponseAsyncValue> get mainDataAsync => const AsyncLoading();

  @override
  double getWidth() => MediaQuery.of(context).size.width;

  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return Colors.white;
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    final title = widget.isInventory
        ? 'Physical Inventory'
        : ref.read(movementCreateScreenTitleProvider);

    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  @override
  Future<void> setDefaultValuesOnInitState(
      BuildContext context,
      WidgetRef ref,
      ) async {
    putAwayMovement = PutAwayMovement();
    putAwayMovement!.setUser(Memory.sqlUsersData);

    final org = widget.storage.mLocatorID!.aDOrgID!;
    widget.storage.mLocatorID!.mWarehouseID!.aDOrgID = org;

    locatorFrom = widget.storage.mLocatorID;

    putAwayMovement!.movementLineToCreate!.mProductID = widget.storage.mProductID;
    putAwayMovement!.movementLineToCreate!.mLocatorID = locatorFrom;
    putAwayMovement!.movementToCreate!.locatorFromId = locatorFrom!.id;
    putAwayMovement!.movementToCreate!.mWarehouseID = locatorFrom!.mWarehouseID;

    if (widget.isInventory) {
      putAwayInventory = PutAwayInventory();
      putAwayInventory!.setUser(Memory.sqlUsersData);

      putAwayInventory!.inventoryToCreate!.aDOrgID = org;
      putAwayInventory!.inventoryToCreate!.mWarehouseID = locatorFrom!.mWarehouseID;
      putAwayInventory!.inventoryToCreate!.description =
          Memory.getDescriptionFromApp();
      putAwayInventory!.inventoryToCreate!.cDocTypeID = IdempiereDocumentType(
        id: 1000023,
        identifier: 'Physical Inventory',
      );

      putAwayInventory!.inventoryLineToCreate = SqlDataInventoryLine(
        aDOrgID: org,
        mLocatorID: locatorFrom,
        mProductID: widget.storage.mProductID,
        mAttributeSetInstanceID: widget.storage.mAttributeSetInstanceID,
        qtyBook: widget.storage.qtyOnHand,
        qtyCount: 0,
        productName:
        widget.storage.mProductID?.name ?? widget.storage.mProductID?.identifier,
        line: 10,
      );

      Memory.sqlUsersData.copyToSqlData(putAwayInventory!.inventoryLineToCreate!);
      Memory.sqlUsersData.copyToSqlData(putAwayInventory!.inventoryToCreate!);
    }
  }

  @override
  void executeAfterShown() {
    final id = locatorFrom?.id ?? -1;
    ref.read(actualLocatorFromProvider.notifier).state = id;
    ref.read(isDialogShowedProvider.notifier).state = false;
    ref.read(actionScanProvider.notifier).state = actionScanTypeInt;
    ref.invalidate(selectedLocatorToProvider);
  }

  @override
  void initialSettingOnBuild(BuildContext context, WidgetRef ref) {
    widget.width = MediaQuery.of(context).size.width;

    dialogHeight = MediaQuery.of(context).size.height;
    dialogWidth = MediaQuery.of(context).size.width;

    widthLarge = widget.width / 3 * 2;
    widthSmall = widget.width / 3;

    quantityToMove = ref.watch(quantityToMoveProvider);
    unsortedStorageList = ref.read(unsortedStoreOnHandListProvider);

    if (widget.isInventory) {
      storageList = unsortedStorageList
          .where(
            (e) =>
        e.mLocatorID?.mWarehouseID?.id ==
            widget.storage.mLocatorID?.mWarehouseID?.id &&
            e.mProductID?.id == widget.storage.mProductID?.id,
      )
          .toList();
    } else {
      storageList = unsortedStorageList
          .where(
            (e) =>
        e.mLocatorID?.mWarehouseID?.id ==
            widget.storage.mLocatorID?.mWarehouseID?.id &&
            e.mProductID?.id == widget.storage.mProductID?.id &&
            e.mLocatorID?.id == widget.storage.mLocatorID?.id,
      )
          .toList();
    }

    if (isCardsSelected.length != storageList.length) {
      isCardsSelected = List<bool>.filled(storageList.length, false);
    }

    locatorFrom = widget.storage.mLocatorID;
    findLocatorTo = ref.watch(findLocatorToProvider);
  }

  @override
  BottomAppBar? getBottomAppBar(BuildContext context, WidgetRef ref) {
    final canShowBottomBar = widget.isInventory
        ? ref.watch(canShowCreateLineBottomBarForInventoryProvider)
        : ref.watch(canShowCreateLineBottomBarProvider);

    if (!canShowBottomBar) return null;

    return bottomAppBar(context, ref);
  }

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) {
    unfocus();
    ref.read(isScanningProvider.notifier).state = false;
    ref.read(isDialogShowedProvider.notifier).state = false;
    ref.read(quantityToMoveProvider.notifier).state = 0;
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      final router = GoRouter.of(context);

      if (router.canPop()) {
        router.pop();
        return;
      }

      final productId = widget.storage.mProductID?.id ?? -1;
      context.go('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/$productId');
    });
  }

  @override
  Widget getMainDataCard(BuildContext context, WidgetRef ref) {
    final canCreate = widget.isInventory
        ? RolesApp.appInventoryComplete
        : (RolesApp.appMovementComplete || RolesApp.appMovementconfirmComplete);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          if (canCreate && !widget.isInventory)
            SliverToBoxAdapter(child: getMovementCard(context, ref)),
          if (canCreate)
            SliverPadding(
              padding: const EdgeInsets.only(top: 5),
              sliver: SliverToBoxAdapter(
                child: _productHeaderCard(),
              ),
            ),
          if (canCreate)
            SliverPadding(
              padding: const EdgeInsets.only(top: 5),
              sliver: SliverToBoxAdapter(
                child: _quantityCard(),
              ),
            ),
          getStockList(context, ref),
        ],
      ),
    );
  }

  Widget _productHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        widget.storage.mProductID?.identifier ?? '--',
        style: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _quantityCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              widget.isInventory ? 'Qty Count' : Messages.QUANTITY_SHORT,
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
              Memory.numberFormatter0Digit.format(quantityToMove),
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BottomAppBar bottomAppBar(BuildContext context, WidgetRef ref) {
    return BottomAppBar(
      height: 70,
      color: themeColorPrimary,
      child: ConfirmationSlider(
        height: 45,
        backgroundColor: Colors.green[100]!,
        backgroundColorEnd: Colors.green[800]!,
        foregroundColor: Colors.green,
        text: Messages.SLIDE_TO_CREATE,
        textStyle: TextStyle(
          fontSize: themeFontSizeLarge,
          color: Colors.purple,
          fontWeight: FontWeight.bold,
        ),
        onConfirmation: () async {
          final qty = ref.read(quantityToMoveProvider);

          if (widget.isInventory) {
            if (putAwayInventory == null ||
                putAwayInventory!.inventoryLineToCreate == null ||
                putAwayInventory!.inventoryToCreate == null) {
              showErrorMessage(context, ref, 'Inventory data is null');
              return;
            }

            putAwayInventory!.inventoryLineToCreate!.qtyCount = qty;
            putAwayInventory!.inventoryLineToCreate!.qtyBook =
                putAwayInventory!.inventoryLineToCreate!.qtyBook ??
                    widget.storage.qtyOnHand ??
                    0;
            putAwayInventory!.inventoryLineToCreate!.mLocatorID = locatorFrom;
            putAwayInventory!.inventoryLineToCreate!.mProductID =
                widget.storage.mProductID;
            putAwayInventory!.inventoryLineToCreate!.mAttributeSetInstanceID =
                widget.storage.mAttributeSetInstanceID;
            putAwayInventory!.inventoryLineToCreate!.productName =
                widget.storage.mProductID?.name ??
                    widget.storage.mProductID?.identifier;

            putAwayInventory!.inventoryToCreate!.mWarehouseID =
                locatorFrom?.mWarehouseID;
            putAwayInventory!.inventoryToCreate!.aDOrgID =
                locatorFrom?.mWarehouseID?.aDOrgID;
            putAwayInventory!.inventoryToCreate!.description =
                Memory.getDescriptionFromApp();

            final check = putAwayInventory!.canCreatePutAwayInventory();
            final ui = mapPutAwayInventoryCheckToUi(check);

            if (!ui.ok) {
              showErrorMessage(context, ref, ui.message);
              return;
            }

            await openInventoryCreateBottomSheet(
              context: ref.context,
              putAwayInventory: putAwayInventory!,
            );
            return;
          }

          if (putAwayMovement != null &&
              putAwayMovement!.movementLineToCreate != null) {
            putAwayMovement!.movementLineToCreate!.movementQty = qty;
            putAwayMovement!.movementLineToCreate!.mLocatorID = locatorFrom;

            putAwayMovement!.movementLineToCreate!.mLocatorToID = ref.read(selectedLocatorToProvider);

            final check = putAwayMovement!.canCreatePutAwayMovement();
            final ui = mapPutAwayCheckToUi(check);

            if (!ui.ok) {
              showErrorMessage(context, ref, ui.message);
              return;
            }

            await openMovementCreateBottomSheet(
              context: ref.context,
              putAwayMovement: putAwayMovement!,
            );
            return;
          }

          showErrorMessage(context, ref, Messages.MOVEMENT_ALREADY_CREATED);
        },
      ),
    );
  }

  Future<void> openMovementCreateBottomSheet({
    required BuildContext context,
    required PutAwayMovement putAwayMovement,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: MovementsCreateScreen(
            putAwayMovement: putAwayMovement,
          ),
        );
      },
    );
  }

  Future<void> selectStorage(IdempiereStorageOnHande storage, int index) async {
    final qtyOnHand = storage.qtyOnHand ?? 0;
    final quantity = Memory.numberFormatter0Digit.format(qtyOnHand);

    if (qtyOnHand <= 0 && !widget.isInventory) {
      final message = '${Messages.ERROR_QUANTITY} $quantity';
      showErrorMessage(context, ref, message);
      return;
    }

    setState(() {
      isCardsSelected = List<bool>.filled(storageList.length, false);
      isCardsSelected[index] = true;
    });

    locatorFrom = storage.mLocatorID;

    if (widget.isInventory && putAwayInventory != null) {
      putAwayInventory!.inventoryLineToCreate?.mLocatorID = storage.mLocatorID;
      putAwayInventory!.inventoryLineToCreate?.mProductID = storage.mProductID;
      putAwayInventory!.inventoryLineToCreate?.mAttributeSetInstanceID =
          storage.mAttributeSetInstanceID;
      putAwayInventory!.inventoryLineToCreate?.qtyBook = storage.qtyOnHand;
      putAwayInventory!.inventoryLineToCreate?.productName =
          storage.mProductID?.name ?? storage.mProductID?.identifier;

      putAwayInventory!.inventoryToCreate?.mWarehouseID =
          storage.mLocatorID?.mWarehouseID;
      putAwayInventory!.inventoryToCreate?.aDOrgID =
          storage.mLocatorID?.mWarehouseID?.aDOrgID;
    }

    if (!widget.isInventory && putAwayMovement != null) {
      putAwayMovement!.movementLineToCreate!.mLocatorID = storage.mLocatorID;
      putAwayMovement!.movementLineToCreate!.mProductID = storage.mProductID;
      putAwayMovement!.movementLineToCreate!.mAttributeSetInstanceID =
          storage.mAttributeSetInstanceID;
      putAwayMovement!.movementToCreate!.locatorFromId = storage.mLocatorID?.id;
      putAwayMovement!.movementToCreate!.mWarehouseID =
          storage.mLocatorID?.mWarehouseID;
    }

    unfocus();

    await getDoubleDialog(
      ref: ref,
      maxValue: qtyOnHand,
      minValue: widget.isInventory ? 0 : 1,
      quantity: qtyOnHand,
      targetProvider: quantityToMoveProvider,
    );

    ref.read(isDialogShowedProvider.notifier).state = false;
  }

  Widget storageOnHandCard(IdempiereStorageOnHande storage, int index) {
    final warehouse = ref.read(authProvider).selectedWarehouse;
    final warehouseID = warehouse?.id ?? 0;

    final warehouseStorage = storage.mLocatorID?.mWarehouseID;
    final background = (warehouseStorage?.id == warehouseID)
        ? widget.colorSameWarehouse
        : widget.colorDifferentWarehouse;

    return StorageOnHandSelectableCard(
      ref: ref,
      storage: storage,
      width: widget.width,
      isSelected: isCardsSelected[index],
      isInventory: widget.isInventory,
      selectedColor: background,
      onTap: () async {
        await selectStorage(storage, index);
      },
      onSendTap: () async {
        await createAutoCompleteMovement(
          context: context,
          ref: ref,
          sourceList: unsortedStorageList,
          fromStorage: storage,
        );
      },
    );
  }

  Widget getMovementCard(BuildContext context, WidgetRef ref) {
    final color = ref.watch(movementColorProvider(locatorFrom));

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: SizedBox(
              width: 60,
              child: Text(
                '${Messages.FROM} ${Messages.LOCATOR}',
                style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            title: Text(
              locatorFrom?.value ?? Messages.LOCATOR_FROM,
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            trailing: Icon(
              Icons.check_circle,
              color: widget.storage.mLocatorID != null
                  ? Colors.green
                  : Colors.red,
            ),
          ),
          getLocatorTo(context, ref),
        ],
      ),
    );
  }

  Widget getLocatorTo(BuildContext context, WidgetRef ref) {
    return findLocatorTo.when(
      data: (result) {
        ResponseAsyncValue response = result;
        if (!response.isInitiated) {
          String title = Messages.WAIT_FOR_SEARCH;
          return ListTile(
            leading: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) {
                    return SearchLocatorDialog(
                      readOnly: false,
                      forCreateLine: false,
                    );
                  },
                );
              },
              child: SizedBox(
                width: 60,
                child: Text(
                  '${Messages.TO} ${Messages.LOCATOR}',
                  style: TextStyle(
                    fontSize: fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            trailing: const Icon(Icons.error, color: Colors.red),
          );
        } else if (!response.success) {
          String title = result.message ?? Messages.NO_DATA_FOUND;

          return ListTile(
            leading: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) {
                    return SearchLocatorDialog(
                      readOnly: false,
                      forCreateLine: false,
                    );
                  },
                );
              },
              child: SizedBox(
                width: 60,
                child: Text(
                  '${Messages.TO} ${Messages.LOCATOR}',
                  style: TextStyle(
                    fontSize: fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            trailing: const Icon(Icons.error, color: Colors.red),
          );
        } else if (response.data == null) {
          String title = result.message ?? Messages.NO_DATA_FOUND;

          return ListTile(
            leading: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) {
                    return SearchLocatorDialog(
                      readOnly: false,
                      forCreateLine: false,
                    );
                  },
                );
              },
              child: SizedBox(
                width: 60,
                child: Text(
                  '${Messages.TO} ${Messages.LOCATOR}',
                  style: TextStyle(
                    fontSize: fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            trailing: const Icon(Icons.error, color: Colors.red),
          );
        }

        final IdempiereLocator locator = ref.read(selectedLocatorToProvider);
        if (locator.id != null && locator.id! > 0) {
          putAwayMovement!.movementLineToCreate!.mLocatorToID = locator;
          putAwayMovement!.movementToCreate!.mWarehouseToID = locator.mWarehouseID;
        }

        return ListTile(
          leading: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) {
                  return SearchLocatorDialog(
                    readOnly: false,
                    forCreateLine: false,
                  );
                },
              );
            },
            child: SizedBox(
              width: 60,
              child: Text(
                '${Messages.TO} ${Messages.LOCATOR}',
                style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
                textAlign: TextAlign.start,
              ),
            ),
          ),
          title: Text(
            (locator.id != null) ? (locator.value ?? '') : (locator.identifier ?? ''),
            style: TextStyle(
              fontSize: fontSizeMedium,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          trailing: (locator.id != null && locator.id! > 0)
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.error, color: Colors.red),
        );
      },
      error: (error, stackTrace) {
        return Text(
          Messages.ERROR,
          style: TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        );
      },
      loading: () => const LinearProgressIndicator(minHeight: 16),
    );
  }

  Widget getStockList(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 5),
      sliver: SliverList.separated(
        itemBuilder: (context, index) {
          return storageOnHandCard(storageList[index], index);
        },
        itemCount: storageList.length,
        separatorBuilder: (_, _) => const SizedBox(height: 5),
      ),
    );
  }

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    widget.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
    );
  }
}