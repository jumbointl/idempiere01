import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/create/auto_complete_movement_ui.dart';

import '../../../../../../config/constants/roles_app.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/put_away_inventory.dart';
import '../../../../domain/sql/sql_data_inventory_line.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/store_on_hand/action_notifier.dart';
import '../../common/base_unsorted_storage_on_hand_state.dart';
import '../../movement/create/storage_on_hand_selectable_card.dart';
import '../../movement/provider/new_movement_provider.dart';

class UnsortedStorageOnHandScreenForInventory extends ConsumerStatefulWidget {
  final IdempiereStorageOnHande storage;
  final int index;
  final double width;

  const UnsortedStorageOnHandScreenForInventory({
    required this.index,
    required this.storage,
    required this.width,
    super.key,
  });


  @override
  ConsumerState<UnsortedStorageOnHandScreenForInventory> createState() =>
      UnsortedStorageOnHandScreenForInventoryState();
}

class UnsortedStorageOnHandScreenForInventoryState
    extends BaseUnsortedStorageOnHandState<
        UnsortedStorageOnHandScreenForInventory> {
  late double quantityToCount;
  PutAwayInventory? putAwayInventory;
  String repeatedErrorMessage = '';

  @override
  bool get showLeading => true;

  @override
  int get actionScanTypeInt => Memory.ACTION_GET_LOCATOR_TO_VALUE;

  @override
  AsyncValue get mainDataAsync => const AsyncLoading();

  @override
  double get screenWidth => widget.width;

  @override
  bool get isInventory => true;

  @override
  IdempiereStorageOnHande get sourceStorage => widget.storage;

  @override
  double get minSelectableQtyOnTap => 0;

  @override
  String get screenTitle => 'Physical Inventory';

  @override
  String get sliderText => Messages.SLIDE_TO_CREATE;

  @override
  String get messageNotStorageAvailable =>
      repeatedErrorMessage.isNotEmpty ? repeatedErrorMessage : Messages.NO_DATA_FOUND;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final org = widget.storage.mLocatorID?.aDOrgID;
      final locatorFrom = widget.storage.mLocatorID;

      putAwayInventory = PutAwayInventory();
      putAwayInventory!.setUser(Memory.sqlUsersData);

      putAwayInventory!.inventoryToCreate!.aDOrgID = org;
      putAwayInventory!.inventoryToCreate!.mWarehouseID = locatorFrom?.mWarehouseID;
      putAwayInventory!.inventoryToCreate!.description =
          Memory.getDescriptionFromApp();

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

      ref.read(isScanningProvider.notifier).state = false;
      ref.read(quantityToMoveProvider.notifier).state = 0;
    });
  }

  @override
  List<IdempiereStorageOnHande> buildVisibleStorageList(
      List<IdempiereStorageOnHande> all,
      ) {
    return all
        .where(
          (e) =>
      e.mLocatorID?.mWarehouseID?.id ==
          widget.storage.mLocatorID?.mWarehouseID?.id &&
          e.mProductID?.id == widget.storage.mProductID?.id,
    )
        .toList();
  }

  @override
  bool onStorageSelected(
      WidgetRef ref,
      IdempiereStorageOnHande storage,
      int index,
      ) {


    repeatedErrorMessage = '';

    if (putAwayInventory != null) {
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

    return true;
  }

  @override
  Future<void> onPrimarySliderConfirmed() async {
    final qty = ref.read(quantityToMoveProvider);

    if (putAwayInventory == null ||
        putAwayInventory!.inventoryLineToCreate == null ||
        putAwayInventory!.inventoryToCreate == null) {
      showErrorMessage(context, ref, 'Inventory data is null');
      return;
    }
    final warehouse = widget.storage.mLocatorID?.mWarehouseID;


    putAwayInventory!.inventoryLineToCreate!.qtyCount = qty;
    debugPrint('qtyCount ${qty.toString()}');
    putAwayInventory!.inventoryLineToCreate!.qtyBook =
        putAwayInventory!.inventoryLineToCreate!.qtyBook ??
            widget.storage.qtyOnHand ??
            0;
    putAwayInventory!.inventoryLineToCreate!.mProductID =
        widget.storage.mProductID;
    putAwayInventory!.inventoryLineToCreate!.mAttributeSetInstanceID =
        widget.storage.mAttributeSetInstanceID;
    putAwayInventory!.inventoryLineToCreate!.productName =
        widget.storage.mProductID?.name ?? widget.storage.mProductID?.identifier;
    putAwayInventory!.inventoryToCreate!.mWarehouseID = warehouse ;



    final check = putAwayInventory!.canCreatePutAwayInventory();
    debugPrint('check ${check.toString()}');
    if (check != PutAwayInventory.SUCCESS) {
      showErrorMessage(context, ref, Messages.ERROR);
      return;
    }

    await openInventoryCreateBottomSheet(
      context: ref.context,
      putAwayInventory: putAwayInventory!,
    );
    return;
  }

  @override
  Widget build(BuildContext context) {
    quantityToCount = ref.watch(quantityToMoveProvider);

    prepareCommonBuild(context: context, ref: ref);

    final canCreate = RolesApp.appInventoryComplete;
    final canShowBottomBar =
    ref.watch(canShowCreateLineBottomBarForInventoryProvider);

    return Scaffold(
      appBar: buildCommonAppBar(
        context: context,
        ref: ref,
        title: screenTitle,
      ),
      bottomNavigationBar: canShowBottomBar
          ? buildCommonBottomSlider(
        context: context,
        ref: ref,
        text: sliderText,
        onConfirmation: onPrimarySliderConfirmed,
      )
          : null,
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            popScopeAction(context, ref);
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                if (canCreate)
                  SliverToBoxAdapter(
                    child: buildProductHeaderCard(
                      widget.storage.mProductID?.identifier ?? '--',
                    ),
                  ),
                if (canCreate)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: buildSimpleValueRow(
                        label: 'Qty Count',
                        value: Memory.numberFormatter0Digit.format(quantityToCount),
                        backgroundColor: Colors.green[50],
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 5),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final storage = storageList[index];
                      return StorageOnHandSelectableCard(
                        ref: ref,
                        storage: storage,
                        width: widget.width,
                        isSelected: isCardsSelected[index],
                        isInventory: true,
                        selectedColor: themeColorSuccessfulLight,
                        onTap: () async {
                          final ok = onStorageSelected(ref, storage, index);
                          if (!ok) return;

                          setState(() {
                            isCardsSelected =
                            List<bool>.filled(storageList.length, false);
                            isCardsSelected[index] = true;
                          });

                          await getDoubleDialog(
                            ref: ref,
                            maxValue: null, //storage.qtyOnHand ?? 0,
                            minValue: 0,
                            quantity: storage.qtyOnHand ?? 0,
                            targetProvider: quantityToMoveProvider,
                          );

                          ref.read(isDialogShowedProvider.notifier).state = false;
                        },
                        onSendTap: () async {
                          await createAutoCompleteMovement(storage, index);
                        },
                      );
                    },
                    itemCount: storageList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) {
    unfocus();
    ref.read(isScanningProvider.notifier).state = false;
    ref.read(quantityToMoveProvider.notifier).state = 0;
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;
    Navigator.pop(context);
  }

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