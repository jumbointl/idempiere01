import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../../domain/idempiere/product_with_stock.dart';
import '../../../domain/idempiere/response_async_value.dart';
import '../../providers/actions/find_product_by_sku_name_action_provider.dart';
import '../../providers/common/code_and_fire_action_notifier.dart';
import '../../providers/store_on_hand/action_notifier.dart';
import '../../providers/store_on_hand_for_put_away_movement.dart';
import '../../../common/async_value_consumer_screen_state.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/idempiere/response_async_value_ui_model.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/store_on_hand_provider.dart';
import '../../screens/store_on_hand/memory_products.dart';
import '../../widget/no_records_card.dart';
import '../../widget/response_async_value_messages_card.dart';

/// Common AsyncValue state for product search (UPC / SKU / NAME)
abstract class AsyncValueConsumerProductState<T extends ConsumerStatefulWidget>
    extends AsyncValueConsumerState<T> {
  /// If false, screen will always use UPC notifier (no SKU/NAME mode).
  bool get enableSearchMode => true;

  /// Optional initial product id/upc passed by route.
  String get initialProductId => '';

  CodeAndFireActionNotifier get upcNotifier =>
      ref.read(actionFindStoreOnHandByUpcSkuProvider);

  CodeAndFireActionNotifier get skuNameNotifier =>
      ref.read(actionFindProductBySkuNameProvider);

  ProductSearchMode get currentSearchMode =>
      ref.watch(productSearchModeProvider);

  @override
  CodeAndFireActionNotifier get mainNotifier {
    if (!enableSearchMode) return upcNotifier;
    final mode = currentSearchMode;
    return mode == ProductSearchMode.upc ? upcNotifier : skuNameNotifier;
  }

  @override
  AsyncValue<ResponseAsyncValue> get mainDataAsync {
    final cached = ref.watch(productStoreOnHandCacheProvider);
    if (cached != null) {
      return AsyncData(
        ResponseAsyncValue(
          isInitiated: true,
          success: true,
          data: cached,
        ),
      );
    }
    return ref.watch(mainNotifier.responseAsyncValueProvider);
  }

  void clearProductCache() {
    ref.read(productStoreOnHandCacheProvider.notifier).state = null;
  }

  @override
  void initialSettingAtBuild(BuildContext context, WidgetRef ref) {}

  Future<void> goToUpcSearch(String upc) async {
    if (upc.trim().isEmpty) return;

    ref.invalidate(fireSearchBySKUNameProvider);
    ref.invalidate(scannedCodeForSearchBySKUNameProvider);

    if (enableSearchMode) {
      ref.read(productSearchModeProvider.notifier).state =
          ProductSearchMode.upc;
    }

    await handleInputString(
      ref: ref,
      inputData: upc,
      actionScan: actionScanTypeInt,
    );
  }

  @override
  void afterAsyncValueAction(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    if (!enableSearchMode) return;
    if (!result.success || result.data == null) return;

    final mode = currentSearchMode;
    if (mode == ProductSearchMode.upc) return;

    final raw = result.data;
    if (raw is List<IdempiereProduct> && raw.length == 1) {
      final upc = (raw.first.uPC ?? '').trim();
      if (upc.isEmpty) return;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await goToUpcSearch(upc);
      });
    }
  }

  Future<void> onPrintTap(
      BuildContext context,
      WidgetRef ref,
      IdempiereProduct product,
      ) async {
    if (!context.mounted) return;
    context.push(
      '/products/label-printer-select',
      extra: product,
    );
  }

  void resetCommonSearchFlags(WidgetRef ref) {
    ref.read(isScanningFromDialogProvider.notifier).state = false;
    ref.read(isScanningProvider.notifier).state = false;
    ref.read(isScanningForLineProvider.notifier).state = false;
    ref.read(isDialogShowedProvider.notifier).state = false;
    ref.read(actionScanProvider.notifier).state = actionScanTypeInt;
  }

  /// Child can add custom resets.
  Future<void> resetScreenFlags(WidgetRef ref) async {
    resetCommonSearchFlags(ref);
  }

  @override
  Future<void> executeAfterShown() async {
    await resetScreenFlags(ref);

    if (initialProductId.isNotEmpty && initialProductId != '-1') {
      await handleInputString(
        ref: ref,
        inputData: initialProductId,
        actionScan: actionScanTypeInt,
      );
    }
  }

  Widget buildDefaultAsyncErrorCard(ResponseAsyncValue result) {
    final message = result.message ?? '';
    final uiModel = mapResponseAsyncValueToUi(
      result: result,
      title: Messages.PRODUCT,
      subtitle: message,
    );

    return ResponseAsyncValueMessagesCardAnimated(ui: uiModel);
  }

  Widget buildInvalidResultCard(
      ResponseAsyncValue result, {
        String title ='STORE ON HAND',
      }) {
    final message = result.message ?? Messages.ERROR;
    final ui = mapResponseAsyncValueToUi(
      result: result,
      title: title,
      subtitle: message,
    );

    return ResponseAsyncValueMessagesCardAnimated(ui: ui);
  }

  Widget buildFallbackNoDataCard(ResponseAsyncValue result) {
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

  Widget buildProductsList({
    required List<IdempiereProduct> products,
    required double width,
    required Widget Function(IdempiereProduct product) itemBuilder,
  }) {
    if (products.isEmpty) return NoRecordsCard(width: width);

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return itemBuilder(products[index]);
      },
    );
  }

  Widget buildStorageSection({
    required List<IdempiereStorageOnHande> storages,
    required double width,
    required Widget emptyWidget,
    required Widget Function(
        IdempiereStorageOnHande storage,
        int index,
        int total,
        ) storageItemBuilder,
  }) {
    final showResultCard = ref.watch(showResultCardProvider);
    if (!showResultCard) {
      return Text(Messages.NO_DATA_FOUND);
    }

    if (storages.isEmpty) {
      return emptyWidget;
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: storages.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            width: width,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: buildProductResumeCard(storages, width),
          );
        }

        final storage = storages[index - 1];
        return storageItemBuilder(storage, index, storages.length);
      },
    );
  }

  /// Child provides concrete ProductResumeCard if needed.
  Widget buildProductResumeCard(
      List<IdempiereStorageOnHande> storages,
      double width,
      );

  /// Child provides concrete product tile/card.
  Widget buildProductItem(
      IdempiereProduct product,
      double width,
      );

  /// Child provides concrete storage tile/card.
  Widget buildStorageItem(
      IdempiereStorageOnHande storage,
      int index,
      int total,
      double width,
      );

  /// Child provides empty widget for storages section.
  Widget buildEmptyStoragesWidget(double width);

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
          if (product.hasListStorageOnHande && product.hasSortedStorageOnHande)
            buildStorageSection(
              storages: product.sortedStorageOnHande!,
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
}