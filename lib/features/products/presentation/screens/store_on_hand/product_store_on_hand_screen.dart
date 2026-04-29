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
import '../../providers/store_on_hand/store_on_hand_input_providers.dart';
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

  /// Mirrors the input into [productCodeInputProvider] so a scan, manual
  /// dialog or URL launcher all converge on the same source before firing
  /// the search. Then delegates to the parent which routes through the
  /// active mode notifier (UPC vs SKU/NAME).
  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    ref.read(productCodeInputProvider.notifier).state = inputData.trim();
    await super.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
    );
  }

  /// Re-fires the search with whatever is currently in
  /// [productCodeInputProvider]. Bound to the search button next to the
  /// code TextField.
  Future<void> _runSearchFromInput() async {
    final code = ref.read(productCodeInputProvider).trim();
    if (code.isEmpty) return;
    await handleInputString(
      ref: ref,
      inputData: code,
      actionScan: actionScanTypeInt,
    );
  }

  Future<void> _openProductCodeInputDialog() async {
    final current = ref.read(productCodeInputProvider);
    final controller = TextEditingController(text: current);
    // Suppress scan dispatch while the dialog is open so a stray scan
    // doesn't re-fire the screen's search handler. Restored on dialog
    // close via finally (covers OK, Cancel, dismiss, and exceptions).
    final oldAction = ref.read(actionScanProvider);
    ref.read(actionScanProvider.notifier).state = 0;
    String? result;
    try {
      result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('UPC / SKU'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Scan or type'),
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(Messages.CANCEL),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: Text(Messages.OK),
            ),
          ],
        ),
      );
    } finally {
      ref.read(actionScanProvider.notifier).state = oldAction;
    }
    if (result == null) return;
    final code = result.trim();
    if (code.isEmpty) return;
    await handleInputString(
      ref: ref,
      inputData: code,
      actionScan: actionScanTypeInt,
    );
  }

  @override
  Widget getMainDataCard(BuildContext context, WidgetRef ref) {
    final code = ref.watch(productCodeInputProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // UPC/SKU input row — read-only TextField mirroring the provider;
        // tap opens manual dialog; search button re-fires.
        Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: _openProductCodeInputDialog,
                child: AbsorbPointer(
                  child: TextField(
                    readOnly: true,
                    controller: TextEditingController(text: code),
                    decoration: const InputDecoration(
                      labelText: 'UPC / SKU',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.purple),
              tooltip: 'BUSCAR',
              onPressed: _runSearchFromInput,
            ),
          ],
        ),
        const SizedBox(height: 8),
        super.getMainDataCard(context, ref),
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