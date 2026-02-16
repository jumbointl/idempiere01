
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/m_inout/presentation/providers/m_in_out_providers.dart';
import 'package:monalisa_app_001/features/m_inout/presentation/screens/storage_on__hand_card_for_minout_line.dart';

// Async base
import 'package:monalisa_app_001/features/products/common/async_value_consumer_screen_state.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';

// Domain
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value_ui_model.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common/code_and_fire_action_notifier.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/store_on_hand/action_notifier.dart';

// Providers
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';

// Widgets/UI
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/no_storage_on_hand_records_card.dart';

// Local
import '../../../../config/router/app_router.dart';
import '../../../products/domain/idempiere/product_with_stock.dart';
import '../../../products/presentation/providers/product_provider_common.dart';
import '../../../products/presentation/providers/store_on_hand_for_put_away_movement.dart';
import '../../../products/presentation/screens/movement/edit_new/custom_app_bar.dart';
import '../../../products/presentation/screens/movement/edit_new/product_detail_card_for_line.dart';
import '../../../products/presentation/widget/response_async_value_messages_card.dart';
import '../../../shared/data/messages.dart';
import '../../../shared/data/memory.dart';
import '../../domain/entities/line.dart';

class ProductStoreOnHandScreenForMInOutLine extends ConsumerStatefulWidget
    implements InputDataProcessor {
  final String productId;
  final Line movementLine;

  /// English: Scan action used by this screen
  final int actionTypeInt = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

  const ProductStoreOnHandScreenForMInOutLine({
    required this.productId,
    required this.movementLine,
    super.key,
  });

  /// English: Notifier will be assigned in State.build via provider

  @override
  ConsumerState<ProductStoreOnHandScreenForMInOutLine> createState() =>
      ProductStoreOnHandScreenForLineState();

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    if (inputData.trim().isEmpty) return;
    ref.invalidate(productStoreOnHandCacheProvider);
    await Future.delayed(const Duration(milliseconds: 100));
    ref.read(actionFindStoreOnHandByUpcSkuProvider).handleInputString(
        ref: ref,
        inputData: inputData,
        actionScan: actionScan
    );
  }
}

class ProductStoreOnHandScreenForLineState
    extends AsyncValueConsumerState<ProductStoreOnHandScreenForMInOutLine> {
  // ---------- UI colors ----------
  final Color colorBackgroundHasMovementId = Colors.yellow.shade200;
  final Color colorBackgroundNoMovementId = Colors.white;

  // ---------- Screen state ----------

  @override
  bool get showLeading => true;

  @override
  int get actionScanTypeInt => widget.actionTypeInt;

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

    return  ref.watch(mainNotifier.responseAsyncValueProvider);
  }

  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return colorBackgroundHasMovementId;
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    return lineAppBarTitle(
      line: widget.movementLine,
      onBack: () => popScopeAction(context, ref),
      showBackButton: false,
      subtitle: '${Messages.LINE} : (${widget.movementLine.line ?? 0})',
    );
  }

  @override
  Future<void> setDefaultValuesOnInitState(
      BuildContext context,
      WidgetRef ref,
      ) async {
  }

  @override
  void initialSettingAtBuild(BuildContext context, WidgetRef ref) {
    // English: Bind notifier from provider each build
  }

  @override
  Future<void> executeAfterShown() async {
    debugPrint('ProductStoreOnHandScreenForLineState.executeAfterShown ${widget.productId}');

    if (widget.productId.isNotEmpty && widget.productId != '-1') {
      await handleInputString(
        ref: ref,
        inputData: widget.productId,
        actionScan: widget.actionTypeInt,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // AsyncValue UI
  // ---------------------------------------------------------------------------

  /// English:
  /// With the new provider style, most "errors" come through AsyncValue.data
  /// (result.success == false). This handler is kept as a safety net.
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
    // English: Show consistent message card for idle/empty/error states
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



    // English: At this point -> initiated == true, success == true, data != null
    final dynamic raw = result.data;


    // Defensive: unexpected data type
    if (raw is! ProductWithStock || !raw.hasProduct) {
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

    final product = raw;

    // English: Keep global selection (same behavior as before)
    MemoryProducts.productWithStock = product;
    final double width = MediaQuery.of(context).size.width - 30;

    return Column(
      spacing: 10,
      children: [
        ProductDetailCardForLine(
          product: product,
          onPrintTap: (){
            context.push(AppRouter.PAGE_LABEL_PRINTER_SELECT_PAGE,extra: product);
          },
        ),
        if (product.hasListStorageOnHande)
          _buildStoragesOnHand(product.listStorageOnHande!, width),
      ],
    );
  }

  @override
  void afterAsyncValueAction(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    // English: No-op
  }

  // ---------------------------------------------------------------------------
  // Storages UI
  // ---------------------------------------------------------------------------

  Widget _buildStoragesOnHand(List<IdempiereStorageOnHande> storages, double width) {

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
        child: NoStorageOnHandRecordsCard(width: width),
      );
    }
    final movement = ref.read(mInOutProvider);
    // English: +1 item for resume header
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: storages.length ,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final storage = storages[index];
        return StorageOnHandCardForMInOutLine(
          width: width - 10,
          allowedWarehouseFrom: movement.mInOut?.mWarehouseId.id ?? '-1',
          allowedAttSet: widget.movementLine.mAttributeSetInstanceID,
          storage: storage,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Input handling
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Back / Pop navigation
  // ---------------------------------------------------------------------------

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) {


    // English: Defer navigation to avoid Router rebuild during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.pop();
    });
  }


  @override
  double getWidth() {
    return MediaQuery.of(context).size.width;
  }

  @override
  CodeAndFireActionNotifier get mainNotifier => ref.read(actionFindStoreOnHandByUpcSkuProvider);
}


