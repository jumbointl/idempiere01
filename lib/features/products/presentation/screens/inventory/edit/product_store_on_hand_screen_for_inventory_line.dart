import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value_ui_model.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/store_on_hand_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/inventory/edit/product_detail_card_for_inventory_line.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/inventory/edit/storage_on_hand_card_for_inventory_line.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_records_card.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/product_search_mode_button.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../providers/common_provider.dart';
import '../../common/async_value_consumer_product_state.dart';
import '../../../../domain/idempiere/idempiere_product.dart';
import '../../../../domain/idempiere/inventory_and_lines.dart';
import '../../../../domain/idempiere/product_with_stock.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/store_on_hand_for_put_away_movement.dart';
import '../../../widget/response_async_value_messages_card.dart';
import '../../movement/edit_new/custom_app_bar.dart';
import '../../movement/edit_new/product_detail_card_for_line.dart';
import '../../movement/edit_new/storage_on__hand_card_for_line.dart';
import '../../store_on_hand/product_resume_card.dart';


class ProductStoreOnHandScreenForInventoryLine extends ConsumerStatefulWidget {
  final String productId;
  final String argument;
  final InventoryAndLines inventoryAndLines;
  final bool isInventory;

  final int actionTypeInt = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

  const ProductStoreOnHandScreenForInventoryLine({
    required this.productId,
    required this.argument,
    required this.inventoryAndLines,
    this.isInventory = true,
    super.key,
  });

  @override
  ConsumerState<ProductStoreOnHandScreenForInventoryLine> createState() =>
      ProductStoreOnHandScreenForInventoryLineState();
}

class ProductStoreOnHandScreenForInventoryLineState
    extends AsyncValueConsumerProductState<
        ProductStoreOnHandScreenForInventoryLine> {
  late InventoryAndLines inventory;
  late int inventoryId;

  @override
  bool get showLeading => false;

  @override
  int get actionScanTypeInt => widget.actionTypeInt;

  @override
  String get initialProductId => widget.productId;

  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return inventory.hasInventory ? Colors.yellow.shade200 : Colors.white;
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    return inventoryAppBarTitle(
        inventoryAndLines: inventory,
        subtitle: '${Messages.LINES}: ${inventory.inventoryLines?.length ?? 0}',
        onBack: () {
          popScopeAction(context, ref);
        },
        button: getSearchModeButton(
          context: context,
          onModeChanged: (mode) async {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await openInputDialogWithAction(
                ref: ref,
                history: false,
                onOk: handleInputString,
                actionScan: actionScanTypeInt,
              );
            });
          },
        ));
  }

  @override
  Future<void> setDefaultValuesOnInitState(
      BuildContext context,
      WidgetRef ref,
      ) async {
    if (widget.argument.isNotEmpty && widget.argument != '-1') {
      inventory = InventoryAndLines.fromJson(jsonDecode(widget.argument));
    } else {
      inventory = widget.inventoryAndLines;
    }

    inventoryId = inventory.id ?? -1;
  }

  @override
  Future<void> resetScreenFlags(WidgetRef ref) async {
    resetCommonSearchFlags(ref);
  }

  @override
  Widget asyncValueErrorHandle(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    return buildDefaultAsyncErrorCard(result);
  }

  @override
  Widget asyncValueSuccessPanel(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    final width = MediaQuery.of(context).size.width - 30;
    return buildDefaultSuccessPanel(
      result: result,
      width: width,
    );
  }

  @override
  Widget buildProductResumeCard(
      List<IdempiereStorageOnHande> storages,
      double width,
      ) {
    return ProductResumeCard(storages, width);
  }

  @override
  Widget buildProductItem(
      IdempiereProduct product,
      double width,
      ) {
    return ProductDetailCardForInventoryLine(
      product: product,
      onTap: () {
        final upc = (product.uPC ?? '').trim();
        if (upc.isEmpty) {
          showErrorCenterToast(context, Messages.ERROR_UPC);
          return;
        }
        goToUpcSearch(upc);
      },
      onPrintTap: () {
        onPrintTap(context, ref, product);
      },
    );
  }

  @override
  Widget buildStorageItem(
      IdempiereStorageOnHande storage,
      int index,
      int total,
      double width,
      ) {
    return StorageOnHandCardForInventoryLine(
      storage,
      index,
      total,
      width: width,
      argument: widget.argument,
      inventoryAndLines: inventory,
      isInventory: widget.isInventory,
    );
  }

  @override
  Widget buildEmptyStoragesWidget(double width) {
    return NoRecordsCard(width: width);
  }

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      ref.read(actionScanProvider.notifier).state =
          Memory.ACTION_FIND_INVENTORY_BY_ID;
      ref.invalidate(productStoreOnHandCacheProvider);

      context.go('${AppRouter.PAGE_INVENTORY_EDIT}/$inventoryId/1');
    });
  }

  @override
  double getWidth() {
    return MediaQuery.of(context).size.width;
  }
}