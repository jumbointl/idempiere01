
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisapy_core/monalisapy_core.dart' show SafeBottomBar;

import '../../../../../../config/constants/roles_app.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../common/scan_button_by_action_fixed_short.dart';
import '../../../../domain/idempiere/idempiere_locator.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/put_away_movement.dart';
import '../../../../domain/idempiere/response_async_value.dart';
import '../../../providers/actions/find_locator_to_action_provider.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/locator_provider.dart';
import '../../../providers/products_providers.dart';
import '../../../providers/store_on_hand/action_notifier.dart';
import '../../common/base_unsorted_storage_on_hand_state.dart';
import '../provider/new_movement_provider.dart';
import '../../locator/search_locator_dialog.dart';
import '../../store_on_hand/memory_products.dart';
import 'movement_create_validation_result.dart';
import 'movements_create_screen.dart';
import 'storage_on_hand_selectable_card.dart';

class UnsortedStorageOnHandScreenForMovement extends ConsumerStatefulWidget
    implements InputDataProcessor {
  final IdempiereStorageOnHande storage;
  final int index;
  final double width;
  final int actionScanType;

  const UnsortedStorageOnHandScreenForMovement({
    required this.index,
    required this.storage,
    required this.width,
    this.actionScanType = Memory.ACTION_GET_LOCATOR_TO_VALUE,
    super.key,
  });

  @override
  ConsumerState<UnsortedStorageOnHandScreenForMovement> createState() =>
      UnsortedStorageOnHandScreenForMovementState();

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

class UnsortedStorageOnHandScreenForMovementState
    extends BaseUnsortedStorageOnHandState<
        UnsortedStorageOnHandScreenForMovement> {
  late PutAwayMovement putAwayMovement;
  late double quantityToMove;
  late AsyncValue findLocatorTo;
  IdempiereLocator? locatorFrom;

  @override
  bool get showLeading => true;

  @override
  int get actionScanTypeInt => widget.actionScanType;

  @override
  AsyncValue get mainDataAsync => const AsyncLoading();

  @override
  double get screenWidth => widget.width;

  @override
  bool get isInventory => false;

  @override
  IdempiereStorageOnHande get sourceStorage => widget.storage;

  @override
  double get minSelectableQtyOnTap => 1;

  @override
  String get screenTitle {
    return ref.read(movementCreateScreenTitleProvider);

  }

  @override
  String get sliderText => Messages.SLIDE_TO_CREATE_LINE;

  @override
  void initState() {
    super.initState();
    putAwayMovement= MemoryProducts.putAwayMovement;
    putAwayMovement.setUser(Memory.sqlUsersData);


    // English: Ensure org link is consistent (some models need org propagation)
    final org = widget.storage.mLocatorID!.aDOrgID!;
    widget.storage.mLocatorID!.mWarehouseID!.aDOrgID = org;

    locatorFrom = widget.storage.mLocatorID;

    putAwayMovement.movementLineToCreate!.mProductID = widget.storage.mProductID;
    putAwayMovement.movementLineToCreate!.mLocatorID = locatorFrom;

    putAwayMovement.movementToCreate!.locatorFromId = locatorFrom!.id;
    putAwayMovement.movementToCreate!.mWarehouseID = locatorFrom!.mWarehouseID;


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      locatorFrom = widget.storage.mLocatorID;
      ref.read(actualLocatorFromProvider.notifier).state = locatorFrom?.id ?? -1;
      ref.read(actionScanProvider.notifier).state = widget.actionScanType;
      ref.invalidate(selectedLocatorToProvider);
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
          e.mProductID?.id == widget.storage.mProductID?.id &&
          e.mLocatorID?.id == widget.storage.mLocatorID?.id,
    )
        .toList();
  }

  @override
  bool onStorageSelected(
      WidgetRef ref,
      IdempiereStorageOnHande storage,
      int index,
      ) {

    putAwayMovement.movementLineToCreate!.mAttributeSetInstanceID =
        storage.mAttributeSetInstanceID;

    return true;
  }

  @override
  Future<void> onPrimarySliderConfirmed() async {

    var locatorTo = ref.read(selectedLocatorToProvider);

    if ( putAwayMovement.movementLineToCreate != null) {
      putAwayMovement.movementLineToCreate!.movementQty = quantityToMove;
      putAwayMovement.movementLineToCreate!.mLocatorToID = locatorTo;
      putAwayMovement.movementToCreate!.mWarehouseToID = locatorTo.mWarehouseID;
      putAwayMovement.movementToCreate!.mWarehouseID =  locatorFrom?.mWarehouseID;

      final check = putAwayMovement.canCreatePutAwayMovement();
      final ui = mapPutAwayCheckToUi(check);

      if (!ui.ok) {
        showErrorMessage(context, ref, ui.message);
        return;
      }

      await openMovementCreateBottomSheet(
        context: ref.context,
        putAwayMovement: putAwayMovement,
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    quantityToMove = ref.watch(quantityToMoveProvider);
    findLocatorTo = ref.watch(findLocatorToProvider);

    prepareCommonBuild(context: context, ref: ref);

    final canCreate =
        RolesApp.appMovementComplete || RolesApp.appMovementconfirmComplete;
    final canShowBottomBar = ref.watch(canShowCreateLineBottomBarProvider);
    final showScan = ref.watch(
      showScanFixedButtonProvider(widget.actionScanType),
    );

    return Scaffold(
      appBar: buildCommonAppBar(
        context: context,
        ref: ref,
        title: screenTitle,
        actions: [
          if (showScan && canCreate)
            ScanButtonByActionFixedShort(
              actionTypeInt: widget.actionScanType,
              onOk: widget.handleInputString,
            ),
          if (showScan && canCreate)
            IconButton(
              icon: const Icon(Icons.keyboard, color: Colors.purple),
              onPressed: () {
                openInputDialogWithAction(
                  ref: ref,
                  history: false,
                  actionScan: widget.actionScanType,
                  onOk: widget.handleInputString,
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: canShowBottomBar
          ? SafeBottomBar(
              child: buildCommonBottomSlider(
                context: context,
                ref: ref,
                text: sliderText,
                onConfirmation: onPrimarySliderConfirmed,
              ),
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
                    child: _buildMovementCard(context, ref),
                  ),
                if (canCreate)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: buildProductHeaderCard(
                        widget.storage.mProductID?.identifier ?? '--',
                      ),
                    ),
                  ),
                if (canCreate)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: buildSimpleValueRow(
                        label: Messages.QUANTITY_SHORT,
                        value: Memory.numberFormatter0Digit.format(quantityToMove),
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 5),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final storage = storageList[index];
                      final background = themeColorSuccessfulLight;

                      return StorageOnHandSelectableCard(
                        ref: ref,
                        storage: storage,
                        width: widget.width,
                        isSelected: isCardsSelected[index],
                        isInventory: false,
                        selectedColor: background,
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
                            maxValue: storage.qtyOnHand ?? 0,
                            minValue: 1,
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

  Widget _buildMovementCard(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: ref.watch(movementColorProvider(locatorFrom)),
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          ListTile(
            leading: SizedBox(
              width: 60,
              child: Text(
                '${Messages.FROM} ${Messages.LOCATOR}',
                style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                ),
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
              color: locatorFrom != null ? Colors.green : Colors.red,
            ),
          ),
          _buildLocatorTo(context, ref),
        ],
      ),
    );
  }

  Widget _buildLocatorTo(BuildContext context, WidgetRef ref) {
    return findLocatorTo.when(
      data: (result) {
        ResponseAsyncValue response = result;
        final locator = ref.read(selectedLocatorToProvider);

        if (!response.isInitiated || !response.success || response.data == null) {
          final title = result.message ?? Messages.NO_DATA_FOUND;
          return ListTile(
            leading: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => SearchLocatorDialog(
                    readOnly: false,
                    forCreateLine: false,
                  ),
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

        return ListTile(
          leading: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => SearchLocatorDialog(
                  readOnly: false,
                  forCreateLine: false,
                ),
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
              ),
            ),
          ),
          title: Text(
            locator.value ?? locator.identifier ?? '',
            style: TextStyle(
              fontSize: fontSizeMedium,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          trailing: (locator.id ?? -1) > 0
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.error, color: Colors.red),
        );
      },
      error: (error, stackTrace) => Text(
        Messages.ERROR,
        style: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
      loading: () => const LinearProgressIndicator(minHeight: 16),
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
    await widget.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
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

}