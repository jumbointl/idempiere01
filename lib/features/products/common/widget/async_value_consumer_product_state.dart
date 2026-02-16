import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';

import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_product.dart';
import '../../domain/idempiere/product_with_stock.dart';
import '../../domain/idempiere/response_async_value.dart';
import '../../presentation/providers/actions/find_product_by_sku_name_action_provider.dart';
import '../../presentation/providers/common/code_and_fire_action_notifier.dart';
import '../../presentation/providers/store_on_hand/action_notifier.dart';
import '../../presentation/providers/store_on_hand_for_put_away_movement.dart';
import '../async_value_consumer_screen_state.dart';

/// Common AsyncValue state for product search (UPC / SKU / NAME)
abstract class AsyncValueConsumerProductState<T extends ConsumerStatefulWidget>
    extends AsyncValueConsumerState<T> {
  /// If false, screen will always use UPC notifier (no SKU/NAME mode).
  bool get enableSearchMode => true;

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
    debugPrint('mainNotifier $mode Notifier ${mode == ProductSearchMode.upc ? 'upcNotifier' : 'skuNameNotifier'}');
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
  void initialSettingAtBuild(BuildContext context, WidgetRef ref) {

  }


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

      ref.invalidate(productStoreOnHandCacheProvider);
      goToUpcSearch(upc);
    }
  }
  void onPrintTap(BuildContext context, WidgetRef ref, IdempiereProduct product) {
    String message = Messages.NOT_IMPLEMENTED_YET;
    showWarningCenterToast(context, message);

  }
  bool isUpcSuccess(ResponseAsyncValue result) => result.data is ProductWithStock;
  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    if (inputData.isEmpty) return;
    ref.invalidate(productStoreOnHandCacheProvider);
    await Future.delayed(const Duration(milliseconds: 100));
    await mainNotifier.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
    );
    //
  }

}
