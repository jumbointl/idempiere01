import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/product_with_stock.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_records_card.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../common/input_dialog.dart';
import '../../providers/product_provider_common.dart';
import '../common/async_value_consumer_product_state.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../../domain/idempiere/response_async_value.dart';
import '../../providers/common_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/locator_provider.dart';
import '../../widget/product_search_mode_button.dart';
import 'memory_products.dart';
import 'new_storage_on_hand_card.dart';
import 'product_detail_card.dart';
import 'product_resume_card.dart';



class ProductStoreOnHandScreen extends ConsumerStatefulWidget {
  String? productId;

  static const String MOVEMENT_DELIVERY_NOTE = 'remittance';
  static const String READ_STOCK_ONLY = 'read_stock_only';
  static const String MOVEMENT_OTHER = 'other';
  static const String MOVEMENT_IN_SAME_WAREHOUSE = 'movementInSameWarehouse';
  static const String PHYSICAL_INVENTORY = 'physical_inventory';

  ProductStoreOnHandScreen({
    super.key,
    this.productId,
  });

  @override
  ConsumerState<ProductStoreOnHandScreen> createState() =>
      _ProductStoreOnHandScreenState();
}

class _ProductStoreOnHandScreenState
    extends AsyncValueConsumerProductState<ProductStoreOnHandScreen> {
  bool readStockOnly = false;
  late String movementType;
  late String title;
  bool isInventory = false;

  @override
  bool get showLeading => true;

  @override
  int get actionScanTypeInt => Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

  @override
  String get initialProductId => canStartSearchAtInit ? (widget.productId ?? '') : '';

  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return Colors.white;
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: themeFontSizeLarge),
        ),
        const SizedBox(width: 4),
        getSearchModeButton(
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
        ),
      ],
    );
  }

  @override
  Future<void> setDefaultValuesOnInitState(
      BuildContext context,
      WidgetRef ref,
      ) async {
    title = Messages.PRODUCT;
    movementType = ProductStoreOnHandScreen.MOVEMENT_OTHER;
    isInventory = widget.productId == ProductStoreOnHandScreen.PHYSICAL_INVENTORY;

    if (widget.productId == ProductStoreOnHandScreen.MOVEMENT_DELIVERY_NOTE) {
      widget.productId = '-1';
      movementType = ProductStoreOnHandScreen.MOVEMENT_DELIVERY_NOTE;
      title = Messages.DELIVELY_NOTE;
    } else if (widget.productId == ProductStoreOnHandScreen.READ_STOCK_ONLY) {
      widget.productId = '-1';
      movementType = ProductStoreOnHandScreen.READ_STOCK_ONLY;
      title = Messages.STOCK;
      readStockOnly = true;
    } else if (widget.productId == ProductStoreOnHandScreen.PHYSICAL_INVENTORY) {
      title = Messages.PRODUCT;
    }
  }

  @override
  Future<void> resetScreenFlags(WidgetRef ref) async {
    resetCommonSearchFlags(ref);

    final userWarehouse = ref.read(authProvider).selectedWarehouse?.id ?? 0;

    switch (widget.productId) {
      case ProductStoreOnHandScreen.MOVEMENT_IN_SAME_WAREHOUSE:
      case ProductStoreOnHandScreen.PHYSICAL_INVENTORY:
        ref.read(allowedWarehouseToProvider.notifier).state = userWarehouse;
        ref.read(excludedWarehouseToProvider.notifier).state = 0;
        break;

      default:
        ref.read(allowedWarehouseToProvider.notifier).state = 0;
        ref.read(excludedWarehouseToProvider.notifier).state = userWarehouse;
        break;
    }

    if (movementType == ProductStoreOnHandScreen.MOVEMENT_DELIVERY_NOTE) {
      ref.read(allowedMovementDocumentTypeProvider.notifier).state =
          Memory.MM_ELECTRONIC_DELIVERY_NOTE_ID;
    } else {
      ref.read(allowedMovementDocumentTypeProvider.notifier).state =
          Memory.NO_MM_ELECTRONIC_DELIVERY_NOTE_ID;
    }
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
    return ProductDetailCard(
      product: product,
      onTap: () {
        final productUPC = (product.uPC ?? '').trim();
        if (productUPC.isEmpty) {
          final message = '${Messages.ERROR_UPC}: $productUPC';
          showErrorCenterToast(context, message);
          return;
        }
        goToUpcSearch(productUPC);
      },
      onPrintTap: () async {
        final oldAction = ref.read(actionScanProvider);
        await context.push(
          AppRouter.PAGE_PRODUCT_LABEL_PRINTER_SELECT_PAGE,
          extra: product,
        );
        ref.read(actionScanProvider.notifier).state = oldAction;
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
    return NewStorageOnHandCard(
      storage,
      index,
      total,
      width: width,
      readStockOnly: readStockOnly,
      isInventory: isInventory,
    );
  }

  @override
  Widget buildEmptyStoragesWidget(double width) {
    return NoRecordsCard(width: width);
  }

  @override
  Widget buildDefaultSuccessPanel({
    required ResponseAsyncValue result,
    required double width,
  }) {
    if (!result.isInitiated ||
        (result.success == true && result.data == null) ||
        (result.success != true)) {
      return buildInvalidResultCard(result);
    }

    final raw = result.data;

    if (raw is ProductWithStock && raw.hasProduct) {
      final product = raw;
      MemoryProducts.productWithStock = product;

      return Column(
        spacing: 10,
        children: [
          buildProductItem(product, width),
          if (product.hasListStorageOnHande)
            buildStorageSection(
              storages: product.sortedStorageOnHande ?? const [],
              width: width,
              emptyWidget: buildEmptyStoragesWidget(width),
              storageItemBuilder: (storage, index, total) =>
                  buildStorageItem(storage, index, total, width - 10),
            ),
        ],
      );
    }

    if (raw is List<IdempiereProduct>) {
      return buildProductsList(
        products: raw,
        width: width,
        itemBuilder: (p) => buildProductItem(p, width),
      );
    }

    return buildFallbackNoDataCard(result);
  }

  bool get canStartSearchAtInit {
    if (widget.productId == null ||
        widget.productId!.isEmpty ||
        widget.productId == '-1' ||
        widget.productId == ProductStoreOnHandScreen.MOVEMENT_DELIVERY_NOTE ||
        widget.productId == ProductStoreOnHandScreen.READ_STOCK_ONLY ||
        widget.productId == ProductStoreOnHandScreen.MOVEMENT_IN_SAME_WAREHOUSE ||
        widget.productId == ProductStoreOnHandScreen.MOVEMENT_OTHER ||
        widget.productId == ProductStoreOnHandScreen.PHYSICAL_INVENTORY) {
      return false;
    }
    return true;
  }

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) async {
    clearProductCache();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.go(AppRouter.PAGE_HOME);
    });
  }

  @override
  double getWidth() {
    return MediaQuery.of(context).size.width;
  }
}