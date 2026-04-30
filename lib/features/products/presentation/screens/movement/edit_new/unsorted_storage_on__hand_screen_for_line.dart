import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisapy_core/monalisapy_core.dart' show SafeBottomBar;
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';

import '../../../../../../config/constants/roles_app.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../common/scan_button_by_action_fixed_short.dart';
import '../../../../domain/idempiere/idempiere_locator.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/locator_provider.dart';
import '../../common/base_unsorted_storage_on_hand_state.dart';
import '../provider/new_movement_provider.dart';


import 'movement_line_creation_helper.dart';

class UnsortedStorageOnHandScreenForLine extends ConsumerStatefulWidget
    implements InputDataProcessor {
  final IdempiereStorageOnHande storage;
  final int index;
  double width;
  int pageIndex = Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND;
  final int actionScanType = Memory.ACTION_GET_LOCATOR_TO_VALUE;
  MovementAndLines movementAndLines;
  String argument;

  UnsortedStorageOnHandScreenForLine({
    required this.index,
    required this.movementAndLines,
    required this.storage,
    required this.width,
    super.key,
    required this.argument,
  });

  @override
  ConsumerState<UnsortedStorageOnHandScreenForLine> createState() =>
      UnsortedStorageOnHandScreenForLineState();

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    final scanHandleNotifier = ref.read(scanHandleProvider.notifier);
    scanHandleNotifier.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
    );
  }
}

class UnsortedStorageOnHandScreenForLineState
    extends BaseUnsortedStorageOnHandState<UnsortedStorageOnHandScreenForLine>
    with MovementLineCreationHelper<UnsortedStorageOnHandScreenForLine> {
  late MovementAndLines movementAndLines;
  late double quantityToMove;
  late IdempiereLocator? locatorTo;

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
    final documentId = movementAndLines.cDocTypeID?.id ?? -1;
    final docType = Memory.getDocumentTypeById(documentId);
    return docType?.identifier ?? Messages.UNEXPECTED_ERROR;
  }

  @override
  String get sliderText => Messages.SLIDE_TO_CREATE_LINE;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    movementAndLines =
    (widget.argument.isNotEmpty && widget.argument != '-1')
        ? MovementAndLines.fromJson(jsonDecode(widget.argument))
        : widget.movementAndLines;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(actionScanProvider.notifier).update(
            (state) => Memory.ACTION_NO_SCAN_ACTION,
      );
      await setDefaultValues(context, ref);
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) async {
    ref.read(isScanningProvider.notifier).update((state) => false);
    ref.read(quantityToMoveProvider.notifier).update((state) => 0);
    if (movementAndLines.hasMovement && movementAndLines.lastLocatorTo != null) {
      locatorTo = movementAndLines.lastLocatorTo;
      ref.read(selectedLocatorToProvider.notifier).state =
      movementAndLines.lastLocatorTo!;
    }
  }

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
  bool onStorageSelected(
      WidgetRef ref,
      IdempiereStorageOnHande storage,
      int index,
      ) {
      var qty  = storage.qtyOnHand ?? 0;
      if(qty <= 0){
        errorMessage = '${Messages.QUANTITY} <=0';
        return false;
      }
      errorMessage = '';
      return true;
  }

  @override
  Future<void> onPrimarySliderConfirmed() async {
    final lines = ref.watch(movementLinesProvider(movementAndLines));
    await createMovementLineOnly(
      context: context,
      ref: ref,
      movementAndLines: movementAndLines,
      sourceStorage: widget.storage,
      argument: widget.argument,
      lines: lines,
    );
  }

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) {
    return widget.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
    );
  }

  @override
  Widget build(BuildContext context) {
    widget.width = MediaQuery.of(context).size.width;
    quantityToMove = ref.watch(quantityToMoveProvider);

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
                  SliverToBoxAdapter(
                    child: buildLocatorCard(
                      label: Messages.FROM,
                      locator: widget.storage.mLocatorID,
                    ),
                  ),
                if (canCreate)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: buildLocatorCard(
                        label: Messages.TO,
                        locator: ref.read(selectedLocatorToProvider),
                      ),
                    ),
                  ),
                if (canCreate)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: buildLinesCard(
                        lines: ref.watch(movementLinesProvider(movementAndLines)),
                        onEdit: () async {
                          final lines =
                          ref.read(movementLinesProvider(movementAndLines));
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
                                .read(movementLinesProvider(movementAndLines).notifier)
                                .state = aux;
                          } else {
                            if (context.mounted) {
                              showErrorMessage(context, ref, Messages.ERROR_LINES);
                            }
                          }
                        },
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
                        backgroundColor:
                        quantityToMove > 0 ? Colors.green[50] : Colors.grey[200],
                      ),
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
    ref.read(isScanningProvider.notifier).update((state) => false);
    ref.read(quantityToMoveProvider.notifier).update((state) => 0);
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;
    Navigator.pop(context);
  }
}