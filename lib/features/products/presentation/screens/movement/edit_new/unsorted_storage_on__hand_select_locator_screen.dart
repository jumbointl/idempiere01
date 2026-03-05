import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../config/constants/roles_app.dart';
import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../common/scan_button_by_action_fixed_short.dart';
import '../../../../domain/idempiere/idempiere_locator.dart';
import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../../domain/sql/sql_data_movement_line.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/locator_provider.dart';
import '../../../providers/products_providers.dart';
import '../../../providers/store_on_hand/action_notifier.dart';
import '../../common/base_unsorted_storage_on_hand_state.dart';
import '../create/auto_complete_movement_helper.dart';
import '../create/storage_on_hand_selectable_card.dart';
import '../provider/new_movement_provider.dart';
import '../../store_on_hand/memory_products.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../config/constants/roles_app.dart';
import '../../../../../../config/router/app_router.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../common/scan_button_by_action_fixed_short.dart';
import '../../../../domain/idempiere/idempiere_locator.dart';
import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../../domain/sql/sql_data_movement_line.dart';
import '../../../providers/actions/find_locator_to_action_provider.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/locator_provider.dart';
import '../../../providers/products_providers.dart';
import '../provider/new_movement_provider.dart';
import '../../locator/search_locator_dialog.dart';
import '../../store_on_hand/memory_products.dart';

class UnsortedStorageOnHandSelectLocatorScreen extends ConsumerStatefulWidget {
  final IdempiereStorageOnHande storage;
  final int index;
  final double width;
  final int actionScanType;
  final MovementAndLines movementAndLines;

  const UnsortedStorageOnHandSelectLocatorScreen({
    required this.index,
    required this.movementAndLines,
    required this.storage,
    required this.width,
    this.actionScanType = Memory.ACTION_GET_LOCATOR_TO_VALUE,
    super.key,
  });

  @override
  ConsumerState<UnsortedStorageOnHandSelectLocatorScreen> createState() =>
      UnsortedStorageOnHandSelectLocatorScreenState();
}

class UnsortedStorageOnHandSelectLocatorScreenState
    extends BaseUnsortedStorageOnHandState<
        UnsortedStorageOnHandSelectLocatorScreen> {
  late MovementAndLines movementAndLines;
  late double quantityToMove;
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
  String get screenTitle => 'Select Locator';

  @override
  String get sliderText => Messages.CREATE;

  @override
  void initState() {
    super.initState();

    movementAndLines = widget.movementAndLines;

    locatorFrom = widget.storage.mLocatorID;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(actionScanProvider.notifier).state = widget.actionScanType;
      ref.read(isScanningProvider.notifier).state = false;
      ref.read(quantityToMoveProvider.notifier).state = 0;
      ref.read(isDialogShowedProvider.notifier).state = false;

      if (movementAndLines.hasMovement && movementAndLines.lastLocatorTo != null) {
        ref.read(selectedLocatorToProvider.notifier).state =
        movementAndLines.lastLocatorTo!;
      } else {
        ref.invalidate(selectedLocatorToProvider);
      }
    });
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

  @override
  List<IdempiereStorageOnHande> buildVisibleStorageList(
      List<IdempiereStorageOnHande> all,
      ) {
    return all
        .where(
          (element) =>
      element.mLocatorID?.mWarehouseID?.id ==
          widget.storage.mLocatorID?.mWarehouseID?.id &&
          element.mProductID?.id == widget.storage.mProductID?.id &&
          element.mLocatorID?.id == widget.storage.mLocatorID?.id,
    )
        .toList();
  }

  @override
  bool onStorageSelected(
      WidgetRef ref,
      IdempiereStorageOnHande storage,
      int index,
      ) {
    final qtyOnHand = storage.qtyOnHand ?? 0;
    final quantity = Memory.numberFormatter0Digit.format(qtyOnHand);

    if (qtyOnHand <= 0) {
      errorMessage = '${Messages.ERROR_QUANTITY} $quantity';
      return false;
    }

    locatorFrom = storage.mLocatorID;
    errorMessage = '';
    return true;
  }

  @override
  Future<void> onPrimarySliderConfirmed() async {
    await createMovementLineOnly();
  }

  @override
  Widget build(BuildContext context) {
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
              onOk: handleInputString,
            ),
          if (showScan && canCreate)
            IconButton(
              icon: const Icon(Icons.keyboard, color: Colors.purple),
              onPressed: () {
                openInputDialogWithAction(
                  ref: ref,
                  history: false,
                  actionScan: widget.actionScanType,
                  onOk: handleInputString,
                );
              },
            ),
        ],
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
                  SliverToBoxAdapter(
                    child: buildProductHeaderCard(
                      widget.storage.mProductID?.identifier ?? '--',
                    ),
                  ),
                if (canCreate)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: buildLocatorCard(
                        label: Messages.FROM,
                        locator: locatorFrom,
                      ),
                    ),
                  ),
                if (canCreate)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: buildLocatorCard(
                        label: Messages.TO,
                        locator: ref.watch(selectedLocatorToProvider),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => SearchLocatorDialog(
                              readOnly: false,
                              forCreateLine: false,
                            ),
                          );
                        },
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
                            if (!context.mounted) return;
                            showErrorMessage(context, ref, Messages.ERROR_LINES);
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

  Future<void> createMovementLineOnly() async {
    final movementId = movementAndLines.id ?? -1;
    if (movementId <= 0) {
      showErrorMessage(context, ref, Messages.MOVEMENT_ID);
      return;
    }

    final lines = ref.read(movementLinesProvider(movementAndLines));
    final locatorFromId = widget.storage.mLocatorID?.id ?? -1;
    if (locatorFromId <= 0) {
      showErrorMessage(
        context,
        ref,
        Messages.ERROR_LOCATOR_FROM,
        durationSeconds: 3,
      );
      return;
    }

    final locatorTo = ref.read(selectedLocatorToProvider);
    if ((locatorTo.id ?? -1) <= 0) {
      showErrorMessage(
        context,
        ref,
        Messages.ERROR_LOCATOR_TO,
        durationSeconds: 3,
      );
      return;
    }

    final movementQty = ref.read(quantityToMoveProvider);
    if (movementQty <= 0) {
      showErrorMessage(
        context,
        ref,
        Messages.ERROR_QUANTITY,
        durationSeconds: 3,
      );
      return;
    }

    final movementLine = SqlDataMovementLine();
    Memory.sqlUsersData.copyToSqlData(movementLine);

    movementLine.mMovementID = IdempiereMovement(id: movementId);
    movementLine.mLocatorID = widget.storage.mLocatorID;
    movementLine.mProductID = widget.storage.mProductID;
    movementLine.mLocatorToID = locatorTo;
    movementLine.movementQty = movementQty;
    movementLine.mAttributeSetInstanceID = widget.storage.mAttributeSetInstanceID;
    movementLine.productName =
        widget.storage.mProductID?.name ?? widget.storage.mProductID?.identifier;
    movementLine.line = lines;

    if (movementLine.mMovementID?.id == null) {
      showErrorMessage(context, ref, Messages.ERROR_MOVEMENT);
      return;
    }

    if (movementLine.mLocatorID?.id == null) {
      showErrorMessage(context, ref, Messages.ERROR_LOCATOR_FROM);
      return;
    }

    if (movementLine.mProductID?.id == null) {
      showErrorMessage(context, ref, Messages.ERROR_PRODUCT);
      return;
    }

    if (movementLine.mLocatorToID?.id == null) {
      showErrorMessage(context, ref, Messages.ERROR_LOCATOR_TO);
      return;
    }

    MemoryProducts.newSqlDataMovementLineToCreate = movementLine;
    movementAndLines.movementLineToCreate = movementLine;
    MemoryProducts.movementAndLines = movementAndLines;

    if (!context.mounted) return;
    context.go(AppRouter.PAGE_CREATE_MOVEMENT_LINE, extra: movementAndLines);
  }

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) {
    FocusScope.of(context).unfocus();
    ref.read(isScanningProvider.notifier).state = false;
    ref.read(quantityToMoveProvider.notifier).state = 0;
    ref.read(isDialogShowedProvider.notifier).state = false;
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

    Navigator.pop(context);
  }

  @override
  double getWidth() => MediaQuery.of(context).size.width;
}
