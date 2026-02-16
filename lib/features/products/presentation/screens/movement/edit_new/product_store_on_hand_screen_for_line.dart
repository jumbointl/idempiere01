import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';

// Domain
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value_ui_model.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/actions/find_product_by_sku_name_action_provider.dart';

// Providers
import 'package:monalisa_app_001/features/products/presentation/providers/store_on_hand_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';

// Widgets/UI
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/no_storage_on_hand_records_card.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/storage_on__hand_card_for_line.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/product_resume_card.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_records_card.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/product_search_mode_button.dart';

// Local
import '../../../../../../config/router/app_router.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/widget/async_value_consumer_product_state.dart';
import '../../../../domain/idempiere/idempiere_product.dart';
import '../../../../domain/idempiere/product_with_stock.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/store_on_hand_for_put_away_movement.dart';
import '../../../widget/response_async_value_messages_card.dart';
import '../provider/new_movement_provider.dart';
import 'custom_app_bar.dart';
import 'product_detail_card_for_line.dart';

class ProductStoreOnHandScreenForLine extends ConsumerStatefulWidget
     {
  final String productId;
  final String argument;
  final MovementAndLines movementAndLines;

  final int actionTypeInt = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

  const ProductStoreOnHandScreenForLine({
    required this.productId,
    required this.argument,
    required this.movementAndLines,
    super.key,
  });

  @override
  ConsumerState<ProductStoreOnHandScreenForLine> createState() =>
      ProductStoreOnHandScreenForLineState();




}

class ProductStoreOnHandScreenForLineState
    extends AsyncValueConsumerProductState<ProductStoreOnHandScreenForLine> {
  final Color colorBackgroundHasMovementId = Colors.yellow.shade200;
  final Color colorBackgroundNoMovementId = Colors.white;

  late MovementAndLines movement;
  late int movementId;
  @override
  bool get showLeading => true;

  @override
  int get actionScanTypeInt => widget.actionTypeInt;

  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return movement.hasMovement
        ? colorBackgroundHasMovementId
        : colorBackgroundNoMovementId;
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    return movementAppBarTitle(
      movementAndLines: movement,
      onBack: () => popScopeAction(context, ref),
      showBackButton: false,
      subtitle: '${Messages.LINES} : (${movement.movementLines?.length ?? 0})',
      button: getSearchModeButton(
          context: context,
        onModeChanged: (mode) {
          openInputDialogWithAction(
            ref: ref,
            history: false,
            onOk: handleInputString,
            actionScan: actionScanTypeInt,
          );
        },
      ),
    );
  }

  @override
  Future<void> setDefaultValuesOnInitState(
      BuildContext context,
      WidgetRef ref,
      ) async {
    if (widget.argument.isNotEmpty && widget.argument != '-1') {
      movement = MovementAndLines.fromJson(jsonDecode(widget.argument));
    } else {
      movement = widget.movementAndLines;
    }

    movementId = movement.id ?? -1;
  }



  @override
  Future<void> executeAfterShown() async {
    _resetFlags(ref);

    if (widget.productId.isNotEmpty && widget.productId != '-1') {
      await handleInputString(
        ref: ref,
        inputData: widget.productId,
        actionScan: widget.actionTypeInt,
      );
    }
  }

  @override
  Widget asyncValueErrorHandle(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    final uiModel = mapResponseAsyncValueToUi(
      result: result,
      title: Messages.PRODUCT,
      subtitle: Messages.FIND_PRODUCT_BY_UPC_SKU,
    );

    return ResponseAsyncValueMessagesCardAnimated(ui: uiModel);
  }

  @override
  Widget asyncValueSuccessPanel(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    if (!result.isInitiated ||
        (result.success == true && result.data == null) ||
        (result.success != true)) {
      final ui = mapResponseAsyncValueToUi(
        result: result,
        title: Messages.STORE_ON_HAND,
        subtitle: Messages.SCAN_PRODUCT,
      );

      return ResponseAsyncValueMessagesCardAnimated(ui: ui);
    }

    final dynamic raw = result.data;

    if (raw is ProductWithStock && raw.hasProduct) {
      final product = raw;
      MemoryProducts.productWithStock = product;
      final double width = MediaQuery.of(context).size.width - 30;

      return Column(
        spacing: 10,
        children: [
          ProductDetailCardForLine(product: product,
            onPrintTap: (){
              context.push(AppRouter.PAGE_LABEL_PRINTER_SELECT_PAGE,extra: product);
            },
          ),
          if (product.hasListStorageOnHande && product.hasSortedStorageOnHande)
            _buildStoragesOnHand(product.sortedStorageOnHande!, width),
        ],
      );
    }

    if (raw is List<IdempiereProduct>) {
      final double width = MediaQuery.of(context).size.width - 30;
      return _buildProducts(raw, width);
    }

    final ui = ResponseAsyncValueUiModel(
      state: ResponseUiState.error,
      title: Messages.ERROR,
      subtitle: Messages.NO_DATA_FOUND,
      message: result.message ?? Messages.ERROR,
      backgroundColor: Colors.red[200]!,
      borderColor: Colors.red,
      icon: Icons.error,
    );
    return ResponseAsyncValueMessagesCardAnimated(ui: ui);
  }

  Widget _buildStoragesOnHand(List<IdempiereStorageOnHande> storages, double width) {
    final showResultCard = ref.watch(showResultCardProvider);
    if (!showResultCard) {
      return Text(Messages.NO_DATA_FOUND);
    }
    final isScanning = ref.watch(isScanningForLineProvider);

    if (storages.isEmpty) {
      return isScanning
          ? Text(Messages.PLEASE_WAIT)
          : Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[600],
          borderRadius: BorderRadius.circular(10),
        ),
        child: movement.hasMovement
            ? NoStorageOnHandRecordsCard(width: width)
            : NoRecordsCard(width: width),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: storages.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            width: width,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: ProductResumeCard(storages, width),
          );
        }

        final storage = storages[index - 1];
        return StorageOnHandCardForLine(
          storage,
          index,
          storages.length,
          width: width - 10,
          argument: widget.argument,
          movementAndLines: movement,
          allowedWarehouseFrom: movement.mWarehouseID,
        );
      },
    );
  }

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    if (inputData.trim().isEmpty) return;
    ref.invalidate(productStoreOnHandCacheProvider);
    await Future.delayed(const Duration(milliseconds: 100));
    mainNotifier.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
    );
  }

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      ref.read(actionScanProvider.notifier).state = Memory.ACTION_FIND_MOVEMENT_BY_ID;
      ref.invalidate(productStoreOnHandCacheProvider);

      final counter = ref.read(movementLineDeletedCounterProvider);
      final route = '${AppRouter.PAGE_MOVEMENT_REPAINT}${counter % 2}/$movementId';
      ref.read(movementLineDeletedCounterProvider.notifier).state++;

      context.go(route);
    });
  }

  void _resetFlags(WidgetRef ref) {
    ref.read(isScanningFromDialogProvider.notifier).update((_) => false);
    ref.read(isScanningProvider.notifier).update((_) => false);
    ref.read(isScanningForLineProvider.notifier).update((_) => false);
    ref.read(isDialogShowedProvider.notifier).update((_) => false);
    ref.invalidate(allowedMovementDocumentTypeProvider);
    ref.read(actionScanProvider.notifier).update((_) => actionScanTypeInt);

    MemoryProducts.movementAndLines.clearData();
  }

  @override
  double getWidth() {
    return MediaQuery.of(context).size.width;
  }

  Widget _buildProducts(List<IdempiereProduct> products, double width) {
    if (products.isEmpty) return NoRecordsCard(width: width);

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = products[index];
        return ProductDetailCardForLine(
          product: p,
          onTap: () {

            final upc = (p.uPC ?? '').trim();
            if (upc.isEmpty) {
              String message = Messages.ERROR_UPC;
              showErrorCenterToast(context, message);
              return;
            }
            goToUpcSearch(upc);
          },
          onPrintTap: () {
            onPrintTap(context,ref,p);
          }

        );
      },
    );
  }


}
