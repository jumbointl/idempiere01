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
import '../../../common/widget/async_value_consumer_product_state.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../../domain/idempiere/response_async_value.dart';
import '../../../domain/idempiere/response_async_value_ui_model.dart';
import '../../providers/actions/find_product_by_sku_name_action_provider.dart';
import '../../providers/common_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/locator_provider.dart';
import '../../providers/product_provider_common.dart';
import '../../widget/product_search_mode_button.dart';
import '../../widget/response_async_value_messages_card.dart';
import 'new_storage_on_hand_card.dart';
import 'product_detail_card.dart';
import 'product_resume_card.dart';

class ProductStoreOnHandScreen extends ConsumerStatefulWidget {
  String? productId;
  static const String MOVEMENT_DELIVERY_NOTE = 'remittance';
  static const String READ_STOCK_ONLY = 'read_stock_only';
  static const String MOVEMENT_OTHER = 'other';
  static const String MOVEMENT_IN_SAME_WAREHOUSE = 'movementInSameWarehouse';

  ProductStoreOnHandScreen({super.key, this.productId});

  int get actionScanTypeInt => Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

  @override
  ConsumerState<ProductStoreOnHandScreen> createState() =>
      _ProductStoreOnHandScreenState();

}

class _ProductStoreOnHandScreenState
    extends AsyncValueConsumerProductState<ProductStoreOnHandScreen> {
  bool readStockOnly = false;
  late String movementType = ProductStoreOnHandScreen.MOVEMENT_OTHER;
  late String title;
  bool _didInit = false;

  @override
  int get actionScanTypeInt => Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return Colors.white;
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Text(
          Messages.PRODUCT,
          style: TextStyle(fontSize: themeFontSizeLarge),
        ),
        const SizedBox(width: 4),
        getSearchModeButton(
          context: context,
          onModeChanged: (mode) async {
            // If switched to SKU/NAME, open input dialog (optional UX)
            debugPrint('modeChange: $mode');
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
  Future<void> executeAfterShown() async {
    if (!mounted || _didInit) return;
    _didInit = true;

    ref.read(isDialogShowedProvider.notifier).state = false;
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

    switch (widget.productId) {
      case ProductStoreOnHandScreen.MOVEMENT_IN_SAME_WAREHOUSE:
        final userWarehouse = ref.read(authProvider).selectedWarehouse?.id ?? 0;
        ref
            .read(allowedWarehouseToProvider.notifier)
            .update((state) => userWarehouse);
        ref.read(excludedWarehouseToProvider.notifier).update((state) => 0);
        break;

      default:
        final userWarehouse = ref.read(authProvider).selectedWarehouse?.id ?? 0;
        ref.read(allowedWarehouseToProvider.notifier).state = 0;
        ref.read(excludedWarehouseToProvider.notifier).state = userWarehouse;
        break;
    }

    if (movementType == ProductStoreOnHandScreen.MOVEMENT_DELIVERY_NOTE) {
      ref
          .read(allowedMovementDocumentTypeProvider.notifier)
          .update((state) => Memory.MM_ELECTRONIC_DELIVERY_NOTE_ID);
    } else {
      ref
          .read(allowedMovementDocumentTypeProvider.notifier)
          .update((state) => Memory.NO_MM_ELECTRONIC_DELIVERY_NOTE_ID);
    }

    if (canStartSearchAtInit) {
      handleInputString(
        ref: ref,
        inputData: widget.productId!,
        actionScan: actionScanTypeInt,
      );
    } else {
      widget.productId = '-1';
    }
  }

  @override
  Widget asyncValueErrorHandle(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    final searchMode = ref.watch(productSearchModeProvider);
    String message = '';
    Color? borderColor;

    switch (searchMode) {
      case ProductSearchMode.upc:
        message = Messages.FIND_PRODUCT_BY_UPC_SKU;
        break;
      case ProductSearchMode.sku:
        message = Messages.FIND_PRODUCT_BY_SKU;
        borderColor = Colors.cyan.shade800;
        break;
      case ProductSearchMode.name:
        message = Messages.FIND_PRODUCT_BY_NAME;
        borderColor = Colors.blue.shade800;
        break;
    }

    final uiModel = mapResponseAsyncValueToUi(
      result: result,
      title: Messages.PRODUCT,
      subtitle: message,
      borderColor: borderColor,
    );

    return ResponseAsyncValueMessagesCardAnimated(ui: uiModel);
  }

  @override
  Widget asyncValueSuccessPanel(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    final isProductWithStock = result.data is ProductWithStock;
    if (isProductWithStock) {
      return asyncValueSuccessPanelUPC(ref, result: result);
    } else {
      return asyncValueSuccessPanelSkuOrName(ref, result: result);
    }
  }

  Widget asyncValueSuccessPanelUPC(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    final product = result.data;

    if (product == null) return const SizedBox.shrink();

    final width = MediaQuery.of(context).size.width - 30;

    return Column(
      spacing: 10,
      children: [
        ProductDetailCard(
           product: product,
           onPrintTap: (){
              context.push(AppRouter.PAGE_PRODUCT_LABEL_PRINTER_SELECT_PAGE,extra: product);
           },
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
      separatorBuilder: (_, _) => const SizedBox(height: 10),
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
  Future<void> setDefaultValuesOnInitState(
      BuildContext context, WidgetRef ref) async {
    title = Messages.PRODUCT;
    if (widget.productId == ProductStoreOnHandScreen.MOVEMENT_DELIVERY_NOTE) {
      widget.productId = '-1';
      movementType = ProductStoreOnHandScreen.MOVEMENT_DELIVERY_NOTE;
      title = Messages.DELIVELY_NOTE;
    } else if (widget.productId == ProductStoreOnHandScreen.READ_STOCK_ONLY) {
      widget.productId = '-1';
      movementType = ProductStoreOnHandScreen.READ_STOCK_ONLY;
      title = Messages.STOCK;
      widget.productId = '-1';
      readStockOnly = true;
    }
  }

  @override
  double getWidth() {
    throw UnimplementedError();
  }

  @override
  bool get showLeading => true;

  bool get canStartSearchAtInit {
    if (widget.productId == null ||
        widget.productId!.isEmpty ||
        widget.productId == '-1' ||
        widget.productId == ProductStoreOnHandScreen.MOVEMENT_DELIVERY_NOTE ||
        widget.productId == ProductStoreOnHandScreen.READ_STOCK_ONLY ||
        widget.productId == ProductStoreOnHandScreen.MOVEMENT_IN_SAME_WAREHOUSE ||
        widget.productId == ProductStoreOnHandScreen.MOVEMENT_OTHER) {
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

  Widget asyncValueSuccessPanelSkuOrName(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    final products = result.data;
    if (products == null) return const SizedBox.shrink();

    final width = MediaQuery.of(context).size.width - 30;
    return _buildProducts(products, width);
  }

  Widget _buildProducts(List<IdempiereProduct>? products, double width) {
    if (products == null || products.isEmpty) {
      return NoRecordsCard(width: width);
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return ProductDetailCard(
          product: products[index],
          onTap: () {
            final productUPC = (products[index].uPC ?? '').trim();
            if (productUPC.isEmpty) {
              final message = '${Messages.ERROR_UPC}: $productUPC';
              showErrorCenterToast(context, message);
              return;
            }
            goToUpcSearch(productUPC);
          },
          onPrintTap: (){
            context.go(AppRouter.PAGE_PRODUCT_LABEL_PRINTER_SELECT_PAGE,extra: products[index]);
          },
        );
      },
    );
  }
}
