import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Async base
import 'package:monalisa_app_001/features/products/common/async_value_consumer_screen_state.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';

// Domain
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value_ui_model.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/store_on_hand/action_notifier.dart';

// Providers
import 'package:monalisa_app_001/features/products/presentation/providers/store_on_hand_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';

// Widgets/UI
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/no_storage_on_hand_records_card.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/storage_on__hand_card_for_line.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/product_resume_card.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_records_card.dart';

// Local
import '../../../../../../config/router/app_router.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/product_with_stock.dart';
import '../../../providers/actions/find_store_on_hand_by_upc_sku_action_provider.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/store_on_hand_for_put_away_movement.dart';
import '../../../widget/response_async_value_messages_card.dart';
import '../provider/new_movement_provider.dart';
import 'custom_app_bar.dart';
import 'product_detail_card_for_line.dart';

class ProductStoreOnHandScreenForLine extends ConsumerStatefulWidget
    implements InputDataProcessor {
  final String productId;
  final String argument;
  final MovementAndLines movementAndLines;

  /// English: Scan action used by this screen
  final int actionTypeInt = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

  const ProductStoreOnHandScreenForLine({
    required this.productId,
    required this.argument,
    required this.movementAndLines,
    super.key,
  });

  /// English: Notifier will be assigned in State.build via provider

  @override
  ConsumerState<ProductStoreOnHandScreenForLine> createState() =>
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
    extends AsyncValueConsumerState<ProductStoreOnHandScreenForLine> {
  // ---------- UI colors ----------
  final Color colorBackgroundHasMovementId = Colors.yellow.shade200;
  final Color colorBackgroundNoMovementId = Colors.white;

  // ---------- Screen state ----------
  late MovementAndLines movement;
  late int movementId;

  late bool showResultCard;

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
    final notifier = ref.read(actionFindStoreOnHandByUpcSkuProvider);
    return  ref.watch(notifier.responseAsyncValueProvider);
  }

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
    );
  }

  @override
  Future<void> setDefaultValuesOnInitState(
      BuildContext context,
      WidgetRef ref,
      ) async {
    // English: Resolve movement from argument (priority) or injected object
    if (widget.argument.isNotEmpty && widget.argument != '-1') {
      movement = MovementAndLines.fromJson(jsonDecode(widget.argument));
    } else {
      movement = widget.movementAndLines;
    }

    movementId = movement.id ?? -1;
  }

  @override
  void initialSettingAtBuild(BuildContext context, WidgetRef ref) {
    // English: Bind notifier from provider each build

    showResultCard = ref.watch(showResultCardProvider);
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
        ),
        if (product.hasListStorageOnHande && product.hasSortedStorageOnHande)
          _buildStoragesOnHand(product.sortedStorageOnHande!, width),
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

    // English: +1 item for resume header
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

    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_MOVEMENT_BY_ID;
    ref.invalidate(productStoreOnHandCacheProvider);
    // English: Defer navigation to avoid Router rebuild during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final counter = ref.read(movementLineDeletedCounterProvider);
      final route = '${AppRouter.PAGE_MOVEMENT_REPAINT}${counter%2}/$movementId';
      ref.read(movementLineDeletedCounterProvider.notifier).state++;

      context.go(route);
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _resetFlags(WidgetRef ref) {
    // English: Reset scanning/dialog flags
    ref.read(isScanningFromDialogProvider.notifier).update((_) => false);
    ref.read(isScanningProvider.notifier).update((_) => false);
    ref.read(isScanningForLineProvider.notifier).update((_) => false);
    ref.read(isDialogShowedProvider.notifier).update((_) => false);
    ref.invalidate(allowedMovementDocumentTypeProvider);
    ref.read(actionScanProvider.notifier).update((state) =>actionScanTypeInt );

    // English: Reset movement temporary data (same behavior)
    MemoryProducts.movementAndLines.clearData();
  }

  @override
  double getWidth() {
    return MediaQuery.of(context).size.width;
  }
}


