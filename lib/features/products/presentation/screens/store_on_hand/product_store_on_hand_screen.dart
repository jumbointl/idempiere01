import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common/code_and_fire_action_notifier.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_records_card.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../common/async_value_consumer_screen_state.dart';
import '../../../domain/idempiere/response_async_value.dart';
import '../../../domain/idempiere/response_async_value_ui_model.dart';
import '../../providers/common_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/locator_provider.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/store_on_hand/action_notifier.dart';
import '../../providers/store_on_hand_for_put_away_movement.dart';
import '../../widget/response_async_value_messages_card.dart';
import '../movement/widget/base_product_store_on_hand_screen.dart';
import 'new_storage_on_hand_card.dart';
import 'product_detail_card.dart';
import 'product_resume_card.dart';

class ProductStoreOnHandScreen extends BaseProductStoreOnHandScreen {
  String? productId;
  static const String MOVEMENT_DELIVERY_NOTE = 'remittance';
  static const String READ_STOCK_ONLY = 'read_stock_only';
  static const String MOVEMENT_OTHER ='other';
  static const String MOVEMENT_IN_SAME_WAREHOUSE = 'movementInSameWarehouse';

  ProductStoreOnHandScreen({super.key, this.productId});


  @override
  int get actionScanTypeInt =>
      Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

  @override
  ConsumerState<ProductStoreOnHandScreen> createState() =>
      _ProductStoreOnHandScreenState();

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) {
    ref.invalidate(productStoreOnHandCacheProvider);

    // ⚠️ diferir navegación para evitar crash Router
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.go(AppRouter.PAGE_HOME);
    });
  }
}

class _ProductStoreOnHandScreenState
    extends AsyncValueConsumerState<ProductStoreOnHandScreen> {

  bool readStockOnly = false;
  late String movementType = ProductStoreOnHandScreen.MOVEMENT_OTHER;
  late String title;
  String productUPC ='-1';
  bool _didInit = false;

  @override
  int get actionScanTypeInt =>
      Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

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
    return Colors.white;
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    return Text(
      Messages.PRODUCT,
      style: TextStyle(fontSize: themeFontSizeLarge),
    );
  }

  @override
  void initialSettingAtBuild(BuildContext context, WidgetRef ref) {
    // English: Reset flags and providers once per screen lifecycle

  }

  @override
  Future<void> executeAfterShown() async {

    if (!mounted || _didInit) return;
    _didInit = true;
    ref.read(isDialogShowedProvider.notifier).state = false;
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

    ref.read(isDialogShowedProvider.notifier).state = false;
    switch(widget.productId){
      case ProductStoreOnHandScreen.MOVEMENT_IN_SAME_WAREHOUSE:

        final userWarehouse = ref.read(authProvider).selectedWarehouse?.id ?? 0;
        ref.read(allowedWarehouseToProvider.notifier).update((state) => userWarehouse);
        ref.read(excludedWarehouseToProvider.notifier).update((state) => 0);

        break ;

      default:
        final userWarehouse =
            ref.read(authProvider).selectedWarehouse?.id ?? 0;

        ref.read(allowedWarehouseToProvider.notifier).state = 0;
        ref.read(excludedWarehouseToProvider.notifier).state = userWarehouse;


        break;
    }



    if(movementType==ProductStoreOnHandScreen.MOVEMENT_DELIVERY_NOTE){
      ref.read(allowedMovementDocumentTypeProvider.notifier).update((state) => Memory.MM_ELECTRONIC_DELIVERY_NOTE_ID);
    } else {
      ref.read(allowedMovementDocumentTypeProvider.notifier).update((state) => Memory.NO_MM_ELECTRONIC_DELIVERY_NOTE_ID);
    }
    if(canStartSearchAtInit){
      handleInputString(
          ref: ref,
          inputData: widget.productId!,
          actionScan: actionScanTypeInt
          );
    } else {
      widget.productId ='-1';
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

  // ---------------- SUCCESS WITH DATA ----------------

  @override
  Widget asyncValueSuccessPanel(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    final product = result.data;

    if (product == null) {
      // English: Safety fallback, should normally not happen
      return const SizedBox.shrink();
    }

    final width = MediaQuery.of(context).size.width - 30;

    return Column(
      spacing: 10,
      children: [
        ProductDetailCard(

          product: product,
        ),
        if (product.hasListStorageOnHande)
          _buildStorages(product.sortedStorageOnHande, width),
      ],
    );
  }

  Widget _buildStorages(
      List<IdempiereStorageOnHande>? storages,
      double width,
      ) {
    if (storages == null || storages.isEmpty) {
      return NoRecordsCard(width: width);
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: storages.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return ProductResumeCard(storages, width);
        }
        return NewStorageOnHandCard(

          storages[index - 1],
          index,
          storages.length,
          width: width - 10,
          readStockOnly: readStockOnly,
        );
      },
    );
  }

  @override
  void afterAsyncValueAction(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    // English: No-op for now
  }

  @override
  Future<void> setDefaultValuesOnInitState(BuildContext context, WidgetRef ref) async {
    title = Messages.PRODUCT ;
    if(widget.productId==ProductStoreOnHandScreen.MOVEMENT_DELIVERY_NOTE){
      widget.productId = '-1';
      movementType = ProductStoreOnHandScreen.MOVEMENT_DELIVERY_NOTE;
      title = Messages.DELIVELY_NOTE ;
    } else if(widget.productId==ProductStoreOnHandScreen.READ_STOCK_ONLY){
      widget.productId = '-1';
      movementType = ProductStoreOnHandScreen.READ_STOCK_ONLY;
      title = Messages.STOCK ;
      widget.productId = '-1';
      readStockOnly = true;
    }
  }

  @override
  double getWidth() {
    // TODO: implement getWidth
    throw UnimplementedError();
  }
  @override
  bool get showLeading => true;

  bool get canStartSearchAtInit {
    if(widget.productId==null || widget.productId!.isEmpty || widget.productId=='-1'
    || widget.productId==ProductStoreOnHandScreen.MOVEMENT_DELIVERY_NOTE ||
    widget.productId==ProductStoreOnHandScreen.READ_STOCK_ONLY ||
    widget.productId==ProductStoreOnHandScreen.MOVEMENT_IN_SAME_WAREHOUSE
    || widget.productId==ProductStoreOnHandScreen.MOVEMENT_OTHER
    ) {
      return false;
    }
    return true ;
  }
  @override
  Future<void> handleInputString({required WidgetRef ref, required String inputData, required int actionScan}) async {
    if(inputData.isEmpty) return ;
    ref.invalidate(productStoreOnHandCacheProvider);
    await Future.delayed(const Duration(milliseconds: 100));
    mainNotifier.handleInputString(
        ref: ref,
        inputData: inputData,
        actionScan: actionScan,
    );
  }
  @override
  void popScopeAction(BuildContext context, WidgetRef ref) async {
    //ref.invalidate(productStoreOnHandCacheProvider);
    ref.read(productStoreOnHandCacheProvider.notifier).state = null ;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.go(AppRouter.PAGE_HOME);
    });


  }

  @override
  // TODO: implement mainNotifier
  CodeAndFireActionNotifier get mainNotifier => ref.read(actionFindStoreOnHandByUpcSkuProvider);
}


