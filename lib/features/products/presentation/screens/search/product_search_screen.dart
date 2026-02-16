import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/actions/find_product_by_sku_name_action_provider.dart';

import 'package:monalisa_app_001/features/products/presentation/screens/search/product_detail_with_photo_card.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/actions/product_search_actions.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/search/update_product_upc_view.dart';

import '../../../../../config/router/app_router.dart';
import '../../../common/barcode_utils.dart';
import '../../../common/common_consumer_with_tab_bar_state.dart';
import '../../../common/input_dialog.dart';
import '../../../common/messages_dialog.dart';
import '../../../common/scan_button_by_action_fixed_short.dart';

import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';

import '../../../domain/idempiere/idempiere_product.dart';
import '../../providers/common_provider.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/product_search_provider.dart';
import '../../widget/no_data_card.dart';
import '../../widget/no_records_card.dart';
import '../../widget/product_search_mode_button.dart';
import '../store_on_hand/product_detail_card.dart';


class ProductSearchScreen extends ConsumerStatefulWidget  {
  int countScannedCamera = 0;

  final int actionScanType = Memory.ACTION_FIND_BY_UPC_SKU;
  late int pageIndex = Memory.PAGE_INDEX_SEARCH;

  ProductSearchScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ProductSearchScreenState();




}

class _ProductSearchScreenState
    extends CommonConsumerWithTabBarState<ProductSearchScreen> {

  @override
  int get tabLength => 2;
  @override
  EdgeInsets get tabPadding => const EdgeInsets.symmetric(horizontal: 8, vertical: 6);
  @override
  bool get tabSafeArea => true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_FIND_BY_UPC_SKU);
    });

  }

  @override
  List<Widget> buildTabs() => [
    Tab(text: Messages.FIND),
    Tab(text: Messages.IMAGE),
  ];

  @override
  List<Widget> buildAppBarActions() {
    final showScan = ref.watch(showScanFixedButtonProvider(widget.actionScanType));
     final productsNotifier = ref.read(scanHandleProvider.notifier);

    return [
      if (showScan)
        ScanButtonByActionFixedShort(
          actionTypeInt: widget.actionScanType,
          onOk: handleInputString,
        ),
      IconButton(
        icon: const Icon(Icons.keyboard, color: Colors.purple),
        onPressed: () {
          openInputDialogWithAction(
            ref: ref,
            history: false,
            onOk: handleInputString,
            actionScan: widget.actionScanType,
          );
        },
      ),
    ];
  }

  @override
  List<Widget> buildTabViews() => [
    _buildFindTab(),
    UpdateProductUpcView(),
  ];

  @override
  void onBackPressed() {
    // English: Keep original behavior to return home
    unfocus();
    context.go(AppRouter.PAGE_HOME);
  }

  @override
  Widget build(BuildContext context) {
    // English: Keep original behavior for home index tracking

    return GestureDetector(
      onTap: unfocus,
      child: buildTabScaffold(),
    );
  }

  Widget _buildFindTab() {
    final productAsync = ref.watch(findProductByUPCOrSKUProvider);
    List<IdempiereProduct> resultProducts =[];

    final double width = MediaQuery.of(context).size.width - 30;
    final double bodyHeight = MediaQuery.of(context).size.height - 200;

    widget.countScannedCamera =
        ref.watch(scannedCodeTimesProvider);

    final imageUrl = widget.countScannedCamera.isEven
        ? Memory.IMAGE_HTTP_SAMPLE_2
        : Memory.IMAGE_HTTP_SAMPLE_1;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 10),
              getSearchModeButton(
                largeButton: true,
                context: context,
                onModeChanged: (mode) async {
                  debugPrint('modeChange: $mode');
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await openInputDialogWithAction(
                      ref: ref,
                      history: false,
                      onOk: handleInputString,
                      actionScan: widget.actionScanType,
                    );
                  });
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),

        SliverToBoxAdapter(
          child: Container(
            width: width,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: productAsync.when(
              data: (products) {
                WidgetsBinding.instance.addPostFrameCallback((_) => stopScanning());
                resultProducts = products;

                if (products.isEmpty) return NoDataCard();

                if (products.length == 1) {
                  final p = products[0];
                  return (p.id != null && p.id! > 0)
                      ? ProductDetailWithPhotoCard(
                    product: p.copyWith(imageURL: imageUrl, uPC: null),
                    actionTypeInt: widget.actionScanType,
                  )
                      : NoDataCard();
                }

                // ✅ When more than one, we render list below (as sliver), so return a placeholder here
                return const SizedBox.shrink();
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
          ),
        ),

        // ✅ Multi product list (sliver)
        productAsync.maybeWhen(
          data: (products) => products.length > 1
              ? SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ProductDetailCard(
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
                      onPrintTap: (){
                        context.push(AppRouter.PAGE_LABEL_PRINTER_SELECT_PAGE,extra: product);
                      },
                    ),
                  );
                },
                childCount: products.length,
              ),
            ),
          )
              : const SliverToBoxAdapter(child: SizedBox.shrink()),
          orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
        ),

        // ✅ Update button at bottom
        SliverToBoxAdapter(
          child: (isCanEditUPC() && resultProducts.length == 1)
              ? Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final ok = await confirmAction(
                    title: Messages.CONFIRM,
                    message: Messages.UPDATE_UPC,
                  );
                  if (!ok || !context.mounted) return;
                  context.push(AppRouter.PAGE_UPDATE_PRODUCT_UPC);
                },
                child: Text(Messages.UPDATE_UPC),
              ),
            ),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );

  }

  bool isCanEditUPC() {
    final product = ref.read(productForUpcUpdateProvider);

    if (product.id == null || product.id == 0) return false;
    if (product.uPC == null || product.uPC!.isEmpty) return true;

    return false;
  }
  String normalizeUPC(String value) {
    if (value.length == 12) {
      final aux = '0$value';
      if (isValidEAN13(aux)) return aux;
    }
    return value;
  }
  @override
  Future<void> handleInputString({required WidgetRef ref, required String inputData, required int actionScan}) async {

    await ref.read(searchByUpcOrSkuActionProvider).handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND, // o el que uses
    );

  }
  Widget _buildProducts(List<IdempiereProduct>? products, double width) {
    debugPrint('_buildProducts 1 ${products?.length ?? 0}');
    if (products == null || products.isEmpty) {
      return NoRecordsCard(width: width);
    }
    debugPrint('_buildProducts 2 ${products.length}');
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        debugPrint('product index $index');
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
            context.go(AppRouter.PAGE_LABEL_PRINTER_SELECT_PAGE,extra: products[index]);
          },
        );
      },
    );
  }
  Future<void> goToUpcSearch(String upc) async {
    ref.read(productSearchModeProvider.notifier).state = ProductSearchMode.upc;
    if (upc.trim().isEmpty) return;

    await handleInputString(
      ref: ref,
      inputData: upc,
      actionScan: widget.actionScanType,
    );
  }
}
