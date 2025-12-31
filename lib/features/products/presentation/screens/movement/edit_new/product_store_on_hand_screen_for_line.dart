import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Async base
import 'package:monalisa_app_001/features/products/common/async_value_consumer_screen_state.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';

// Domain
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value_ui_model.dart';

// Providers
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier_for_line.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/store_on_hand_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';

// Widgets/UI
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/no_storage_on_hand_records_card.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/storage_on__hand_card_for_line.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/product_resume_card.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_records_card.dart';

// Local
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/product_with_stock.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/store_on_hand_for_put_away_movement.dart';
import '../../../widget/response_async_value_messages_card.dart';
import '../provider/products_home_provider.dart';
import 'custom_app_bar.dart';
import 'product_detail_card_for_line.dart';

class ProductStoreOnHandScreenForLine extends ConsumerStatefulWidget
    implements InputDataProcessor {
  final String productId;
  final String argument;
  final MovementAndLines movementAndLines;

  /// English: Scan action used by this screen
  final int actionTypeInt = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

  ProductStoreOnHandScreenForLine({
    required this.productId,
    required this.argument,
    required this.movementAndLines,
    super.key,
  });

  /// English: Notifier will be assigned in State.build via provider
  late ProductsScanNotifierForLine productsNotifier;

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

    productsNotifier.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionTypeInt,
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
    return ref.watch(findProductByUPCOrSKUForStoreOnHandProvider);
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
    widget.productsNotifier =
        ref.watch(scanStateNotifierForLineProvider.notifier);

    showResultCard = ref.watch(showResultCardProvider);
  }

  @override
  void executeAfterShown() {
    _resetFlags(ref);

    // English: Auto search when productId is passed
    if (widget.productId.isNotEmpty && widget.productId != '-1') {
      Future.microtask(() async {
        await widget.handleInputString(
          ref: ref,
          inputData: widget.productId,
          actionScan: widget.actionTypeInt,
        );
      });
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
          productsNotifier: widget.productsNotifier,
          product: product,
        ),
        if (product.hasListStorageOnHande)
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
          widget.productsNotifier,
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
    ref.read(productsHomeCurrentIndexProvider.notifier).state =
        Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN;

    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_MOVEMENT_BY_ID;
    ref.invalidate(productStoreOnHandCacheProvider);
    // English: Defer navigation to avoid Router rebuild during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      //context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$movementId/1');
      Navigator.pop(context);

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

    // English: Reset movement temporary data (same behavior)
    MemoryProducts.movementAndLines.clearData();
  }

  @override
  double getWidth() {
    return MediaQuery.of(context).size.width;
  }
}



/*
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/async_value_consumer_screen_state.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_records_card.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/no_storage_on_hand_records_card.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/storage_on__hand_card_for_line.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/products_scan_notifier_for_line.dart';
import '../../../providers/store_on_hand_provider.dart';
import '../../../widget/message_card.dart';
import '../../store_on_hand/product_resume_card.dart';
import '../provider/products_home_provider.dart';
import 'custom_app_bar.dart';
import 'product_detail_card_for_line.dart';

class ProductStoreOnHandScreenForLine extends ConsumerStatefulWidget
    implements InputDataProcessor {
  final String productId;
  final String argument;
  final MovementAndLines movementAndLines;

  /// English: Scan action used by this screen
  final int actionTypeInt = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

  ProductStoreOnHandScreenForLine({
    required this.productId,
    required this.argument,
    required this.movementAndLines,
    super.key,
  });

  /// English: Notifier is injected from state (watch provider)
  late ProductsScanNotifierForLine productsNotifier;

  @override
  ConsumerState<ProductStoreOnHandScreenForLine> createState() =>
      ProductStoreOnHandScreenForLineState();

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    if (inputData.isEmpty) return;

    // English: Let the notifier handle scan logic
    productsNotifier.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionTypeInt,
    );
  }
}

class ProductStoreOnHandScreenForLineState
    extends AsyncValueConsumerState<ProductStoreOnHandScreenForLine> {
  // ---------- UI colors ----------
  final Color colorBackgroundHasMovementId = Colors.yellow.shade200;
  final Color colorBackgroundNoMovementId = Colors.white;

  // ---------- Screen state ----------
  late MovementAndLines _movement;
  late int _movementId;

  // English: Cache these to avoid recomputing in builders
  late bool _showResultCard;

  @override
  bool get showLeading => true;

  @override
  int get actionScanTypeInt => widget.actionTypeInt;

  /// English: The async data for this screen
  @override
  AsyncValue<ResponseAsyncValue> get mainDataAsync =>
      ref.watch(findProductByUPCOrSKUForStoreOnHandProvider);

  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return _movement.hasMovement
        ? colorBackgroundHasMovementId
        : colorBackgroundNoMovementId;
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    return movementAppBarTitle(
      movementAndLines: _movement,
      onBack: () => popScopeAction(context, ref),
      showBackButton: false,
      subtitle: '${Messages.LINES} : (${_movement.movementLines?.length ?? 0})',
    );
  }

  @override
  Future<void> setDefaultValuesOnInitState(
      BuildContext context,
      WidgetRef ref,
      ) async {
    // English: Resolve MovementAndLines once (argument has priority)
    if (widget.argument.isNotEmpty && widget.argument != '-1') {
      _movement = MovementAndLines.fromJson(jsonDecode(widget.argument));
    } else {
      _movement = widget.movementAndLines;
    }

    _movementId = _movement.id ?? -1;
  }

  @override
  void initialSettingAtBuild(BuildContext context, WidgetRef ref) {
    // English: Bind notifier from provider each build (Riverpod)
    widget.productsNotifier = ref.watch(scanStateNotifierForLineProvider.notifier);

    _showResultCard = ref.watch(showResultCardProvider);
  }

  @override
  Future<void> executeAfterShown() async {
    await _resetFlags(ref);

    // English: Auto-search if productId was passed
    if (widget.productId.isNotEmpty && widget.productId != '-1') {
      await widget.handleInputString(
        ref: ref,
        inputData: widget.productId,
        actionScan: widget.actionTypeInt,
      );
    }
  }

  // ---------- AsyncValue UI (Error/Success) ----------

  @override
  Widget asyncValueErrorHandle(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    // English: Minimal error UI
    return MessageCard(
      title: Messages.ERROR,
      message: Messages.NO_DATA_FOUND,
      subtitle: '${result.message ?? ''}',
    );
  }

  @override
  Widget asyncValueSuccessPanel(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    final product = result.data;

    // English: When provider returns invalid product, show "continue" message
    if (product == null || product.id == null || product.id == -1) {
      return MessageCard(
        title: Messages.CONTINUE_TO_ADD_LINE,
        message: Messages.BACK_BUTTON_TO_SEE_MOVEMENT,
        subtitle: Messages.SCAN_PRODUCT_TO_CREATE_LINE,
      );
    }

    // English: Keep the selected product globally (same behavior as before)
    MemoryProducts.productWithStock = product;

    final double width = MediaQuery.of(context).size.width - 30;

    return Column(
      spacing: 10,
      children: [
        ProductDetailCardForLine(
          productsNotifier: widget.productsNotifier,
          product: product,
        ),
        if (product.hasListStorageOnHande)
          _buildStoragesOnHand(product.sortedStorageOnHande!, width),
      ],
    );
  }

  @override
  void afterAsyncValueAction(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    // English: No-op (kept intentionally)
  }

  // ---------- Storages UI ----------

  Widget _buildStoragesOnHand(List<IdempiereStorageOnHande> storages, double width) {
    if (!_showResultCard) {
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
        child: _movement.hasMovement
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
          widget.productsNotifier,
          storage,
          index, // line index visual (same as before)
          storages.length,
          width: width - 10,
          argument: widget.argument,
          movementAndLines: _movement,
          allowedWarehouseFrom: _movement.lastLocatorFrom?.mWarehouseID,
        );
      },
    );
  }

  // ---------- Input handling ----------

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

  // ---------- Back / Pop navigation ----------

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) {
    // English: Restore Home navigation configuration
    ref.read(productsHomeCurrentIndexProvider.notifier).state =
        Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN;

    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_MOVEMENT_BY_ID;

    // English: Defer navigation to avoid Router rebuild during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$_movementId/1');
    });
  }

  // ---------- Helpers ----------

  Future<void> _resetFlags(WidgetRef ref) async {
    // English: Reset scanning/dialog flags
    ref.read(isScanningFromDialogProvider.notifier).update((_) => false);
    ref.read(isScanningProvider.notifier).update((_) => false);
    ref.read(isScanningForLineProvider.notifier).update((_) => false);
    ref.read(isDialogShowedProvider.notifier).update((_) => false);

    // English: Reset movement temporary data (same behavior)
    MemoryProducts.movementAndLines.clearData();
  }

  @override
  double getWidth() {
    return MediaQuery.of(context).size.width;
  }
}
*/


/*
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/storage_on__hand_card_for_line.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_records_card.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/no_storage_on_hand_records_card.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/scan_button_by_action_fixed_short.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/products_scan_notifier_for_line.dart';
import '../../../widget/message_card.dart';
import 'custom_app_bar.dart';
import 'product_detail_card_for_line.dart';
import '../provider/products_home_provider.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/store_on_hand_provider.dart';
import '../../store_on_hand/product_resume_card.dart';


class ProductStoreOnHandScreenForLine extends ConsumerStatefulWidget implements InputDataProcessor{


  int countScannedCamera =0;
  late ProductsScanNotifierForLine productsNotifier ;
  final int actionTypeInt = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND ;
  final int pageIndex = Memory.PAGE_INDEX_STORE_ON_HAND;
  String argument;
  bool isMovementSearchedShowed = false;
  String productId;
  MovementAndLines movementAndLines;
  bool asyncResultHandled = false ;
  ProductStoreOnHandScreenForLine({
    required this.productId,
    required this.argument,
    required this.movementAndLines,
    super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => ProductStoreOnHandScreenForLineState();


  @override
  Future<void> handleInputString({required WidgetRef ref,required  String inputData,required int actionScan}) async {
    asyncResultHandled = false ;
    print('handleInputString result scan: $inputData');
    productsNotifier.handleInputString(ref: ref, inputData: inputData,
        actionScan: actionTypeInt);
  }

}

class ProductStoreOnHandScreenForLineState
    extends ConsumerState<ProductStoreOnHandScreenForLine> {
  Color colorBackgroundHasMovementId = Colors.yellow[200]!;
  Color colorBackgroundNoMovementId = Colors.white;

  double goToPosition =0.0;
  late var isDialogShowed;
  late var isScanning;
  late var showResultCard;
  int movementId =-1;


  MovementAndLines get movementAndLines {

    if(widget.argument.isNotEmpty && widget.argument!='-1') {
      return MovementAndLines.fromJson(jsonDecode(widget.argument));
    } else {
      return widget.movementAndLines;
    }
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await setDefaultValues(context, ref);
      print('----------product Id ${widget.productId}');
      if(widget.productId.isNotEmpty && widget.productId!='-1'){
        widget.handleInputString(ref: ref, inputData: widget.productId,
            actionScan: widget.actionTypeInt);
      }

    });

  }

  @override
  Widget build(BuildContext context){
    widget.productsNotifier = ref.watch(scanStateNotifierForLineProvider.notifier);
    isScanning = ref.watch(isScanningForLineProvider);
    showResultCard = ref.watch(showResultCardProvider);
    movementId = movementAndLines.id ?? -1;
    isDialogShowed = ref.watch(isDialogShowedProvider);
    final productAsync = ref.watch(findProductByUPCOrSKUForStoreOnHandProvider);

    final showScan = ref.watch(showScanFixedButtonProvider(widget.actionTypeInt));

    return Scaffold(

      appBar: AppBar(
        backgroundColor: movementAndLines.hasMovement
            ? colorBackgroundHasMovementId : colorBackgroundNoMovementId,
        automaticallyImplyLeading: true,
        leading:IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async =>
            {
              popScopeAction(context, ref),
            }
        ),

        title: movementAppBarTitle(movementAndLines: movementAndLines,
            onBack: ()=> popScopeAction,
            showBackButton: false,
            subtitle: '${Messages.LINES} : (${movementAndLines.movementLines?.length ?? 0})'
        ),
        actions: [
          if(showScan) ScanButtonByActionFixedShort(
            actionTypeInt: widget.actionTypeInt,
            onOk: widget.handleInputString,),
          IconButton(
            icon: const Icon(Icons.keyboard,color: Colors.purple),
            onPressed: () => {
              openInputDialogWithAction(ref: ref, history: false,
                  onOk: widget.handleInputString, actionScan:  widget.actionTypeInt)
            },
          ),

        ],

      ),
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) {
              return;
            }
            popScopeAction(context, ref);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
            child: SingleChildScrollView(
              child: productAsync.when(
                data: (result) {
                  if(result.id==null || result.id! ==-1){
                    return MessageCard(
                      title: Messages.CONTINUE_TO_ADD_LINE,
                      message: Messages.BACK_BUTTON_TO_SEE_MOVEMENT,
                      subtitle: Messages.SCAN_PRODUCT_TO_CREATE_LINE,
                    );
                  }
                  final double width = MediaQuery.of(context).size.width - 30;

                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if(!widget.asyncResultHandled) {
                        widget.asyncResultHandled = true;
                        print('result from search ----------');
                      }
                    });

                  MemoryProducts.productWithStock = result;
                  return Column(
                    spacing: 10,
                    children: [
                      ProductDetailCardForLine(
                          productsNotifier: widget.productsNotifier, product: result),
                      if(result.hasListStorageOnHande) getStoragesOnHand(result.sortedStorageOnHande!, width),
                    ],
                  );
                },error: (error, stackTrace) => Text('Error: $error'),
                loading: () {
                  final p = ref.watch(storeOnHandProgressProvider);
                  return LinearProgressIndicator(
                    minHeight: 36,
                    value: (p > 0 && p < 1) ? p : null,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getStoragesOnHand(List<IdempiereStorageOnHande> storages, double width) {

    if(!showResultCard){
      return Text(Messages.NO_DATA_FOUND);
    }

    if(storages.isEmpty){
      return isScanning ? Text(Messages.PLEASE_WAIT)
          : Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[600],
          borderRadius: BorderRadius.circular(10),
        ),
        //child: ProductResumeCard(storages,width-10)
        child: movementAndLines.hasMovement ? NoStorageOnHandRecordsCard(width: width)
            : NoRecordsCard(width: width),
      );
    }
    int length = storages.length;
    int add =1 ;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: length+add,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return showResultCard
              ? Container(
              width: width,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: ProductResumeCard(storages, width))
              : Text(Messages.NO_RESUME_SHOWED);
        }

        return StorageOnHandCardForLine(
          widget.productsNotifier,
          storages[index - add],
          index + 1 - add,
          storages.length,
          width: width - 10,
          argument: widget.argument,
          movementAndLines: MovementAndLines.fromJson(jsonDecode(widget.argument)),
          allowedWarehouseFrom: movementAndLines.lastLocatorFrom?.mWarehouseID,
        );
      },
    );
  }



  void popScopeAction(BuildContext context, WidgetRef ref) {

    // Restaurar configuración de navegación del Home
    ref.read(productsHomeCurrentIndexProvider.notifier).state =
        Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN;

    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_MOVEMENT_BY_ID;

    // Redirigir
    context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$movementId/1');
  }

  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) async {

    ref.read(isScanningFromDialogProvider.notifier).update((state) => false);
    ref.read(isScanningProvider.notifier).update((state) => false);
    ref.read(isScanningForLineProvider.notifier).update((state) => false);
    ref.read(isDialogShowedProvider.notifier).update((state) => false);

    MemoryProducts.movementAndLines.clearData() ;

  }

}
*/
