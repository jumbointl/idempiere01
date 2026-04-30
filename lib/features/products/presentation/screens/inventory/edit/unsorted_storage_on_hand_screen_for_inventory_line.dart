
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisapy_core/monalisapy_core.dart' show SafeBottomBar;

import '../../../../../../config/constants/roles_app.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/inventory_and_lines.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../../common/base_unsorted_storage_on_hand_state.dart';
import '../../movement/provider/new_movement_provider.dart';



import 'inventory_line_creation_helper.dart';

class UnsortedStorageOnHandScreenForInventoryLine extends ConsumerStatefulWidget {
  final IdempiereStorageOnHande storage;
  final int index;
  final bool isInventory;
  double width;
  int pageIndex = Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND;
  InventoryAndLines inventoryAndLines;

  UnsortedStorageOnHandScreenForInventoryLine({
    required this.index,
    required this.inventoryAndLines,
    required this.storage,
    required this.width,
    this.isInventory = true,
    super.key,
  });

  @override
  ConsumerState<UnsortedStorageOnHandScreenForInventoryLine> createState() =>
      UnsortedStorageOnHandScreenForInventoryLineState();
}

class UnsortedStorageOnHandScreenForInventoryLineState
    extends BaseUnsortedStorageOnHandState<
        UnsortedStorageOnHandScreenForInventoryLine>
    with InventoryLineCreationHelper<UnsortedStorageOnHandScreenForInventoryLine> {
  late InventoryAndLines inventoryAndLines;
  late double quantityToCount;
  @override



  @override
  double get screenWidth => widget.width;

  @override
  bool get isInventory => true;

  @override
  IdempiereStorageOnHande get sourceStorage => widget.storage;

  @override
  double get minSelectableQtyOnTap => 0;

  @override
  String get screenTitle => 'Inventory Line';

  @override
  String get sliderText => 'Slide to create inventory line';

  @override
  void initState() {
    super.initState();
    inventoryAndLines = widget.inventoryAndLines;


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(isScanningProvider.notifier).state = false;
      ref.read(quantityToMoveProvider.notifier).state = 0;
    });
  }


  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {}

  @override
  List<IdempiereStorageOnHande> buildVisibleStorageList(
      List<IdempiereStorageOnHande> all,
      ) {
    return all
        .where((element) =>
    element.mLocatorID?.mWarehouseID?.id ==
        widget.storage.mLocatorID?.mWarehouseID?.id &&
        element.mProductID?.id == widget.storage.mProductID?.id &&
        element.mLocatorID?.id == widget.storage.mLocatorID?.id)
        .toList();
  }
  @override
  String get messageNotStorageAvailable => errorMessage;
  @override
  @override
  bool onStorageSelected(
      WidgetRef ref,
      IdempiereStorageOnHande storage,
      int index,
      ) {
    final int locatorId = storage.mLocatorID?.id ?? -1;
    final int attributeSetInstanceId =
        storage.mAttributeSetInstanceID?.id ?? Memory.INITIAL_STATE_ID;
    final int productId = storage.mProductID?.id ?? -1;

    final List<dynamic> lines = inventoryAndLines.inventoryLines ?? [];

    final bool exists = lines.any((line) {
      final int lineLocatorId = line.mLocatorID?.id ?? -1;
      final int lineAttributeSetInstanceId =
          line.mAttributeSetInstanceID?.id ?? Memory.INITIAL_STATE_ID;
      final int lineProductId = line.mProductID?.id ?? -1;

      return lineLocatorId == locatorId &&
          lineAttributeSetInstanceId == attributeSetInstanceId &&
          lineProductId == productId;
    });

    if (exists) {
      errorMessage = Messages.REPEATED;

      /*WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showErrorMessage(context, ref, errorMessage);
      });*/

      return false;
    }

    errorMessage = '';
    return true;
  }

  @override
  Future<void> onPrimarySliderConfirmed() async {
    await createInventoryLineOnly(
      context: context,
      ref: ref,
      inventoryAndLines: inventoryAndLines,
      sourceStorage: widget.storage,
      width: widget.width,
    );
  }

  @override
  Widget build(BuildContext context) {
    widget.width = MediaQuery.of(context).size.width;
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
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) return;
            popScopeAction(context, ref);
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                if (canCreate)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
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
                      child: buildLinesCard(
                        lines: ref.watch(inventoryLinesProvider(inventoryAndLines)),
                        onEdit: () async {
                          final lines =
                          ref.read(inventoryLinesProvider(inventoryAndLines));

                          final result = await openInputDialogWithResult(
                            context,
                            ref,
                            false,
                            value: lines.toInt().toString(),
                            title: Messages.LINES,
                            numberOnly: true,
                          );

                          final aux = double.tryParse(result ?? '') ?? 0;
                          if (aux > 0) {
                            ref
                                .read(inventoryLinesProvider(inventoryAndLines).notifier)
                                .state = aux;
                            inventoryAndLines.inventoryLineToCreate!.line = aux ;
                          } else {
                            if (!context.mounted) return;
                            showErrorMessage(context, ref, Messages.ERROR_LINES);
                          }
                        },
                      ),
                    ),
                  ),
                if (canCreate)
                  SliverToBoxAdapter(
                    child: buildSimpleValueRow(
                      label: 'Qty Count',
                      value: Memory.numberFormatter0Digit.format(quantityToCount),
                      backgroundColor: Colors.green[50],
                    ),
                  ),
                buildStockList(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) {
    FocusScope.of(context).unfocus();
    ref.read(isScanningProvider.notifier).state = false;
    ref.read(quantityToMoveProvider.notifier).state = 0;
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;
    Navigator.pop(context);
  }
}