import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:monalisa_app_001/features/products/presentation/screens/search/product_detail_with_photo_card.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/actions/product_search_actions.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/search/update_product_upc_view.dart';

import '../../../../../config/router/app_router.dart';
import '../../../common/barcode_utils.dart';
import '../../../common/common_consumer_with_tab_bar_state.dart';
import '../../../common/input_dialog.dart';
import '../../../common/scan_button_by_action_fixed_short.dart';

import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';

import '../../providers/common_provider.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/product_search_provider.dart';
import '../../widget/no_data_card.dart';


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
    // TODO: implement initState
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

    final double width = MediaQuery.of(context).size.width - 30;
    final double bodyHeight = MediaQuery.of(context).size.height - 200;

    widget.countScannedCamera =
        ref.watch(scannedCodeTimesProvider);

    final imageUrl = widget.countScannedCamera.isEven
        ? Memory.IMAGE_HTTP_SAMPLE_2
        : Memory.IMAGE_HTTP_SAMPLE_1;

    return SizedBox(
      height: bodyHeight,
      child: Column(
        spacing: 10,
        children: [
          Container(
            width: width,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: productAsync.when(
              data: (product) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  stopScanning();
                });

                return (product.id != null && product.id! > 0)
                    ? ProductDetailWithPhotoCard(
                  product: product.copyWith(imageURL: imageUrl, uPC: null),
                  actionTypeInt: widget.actionScanType,
                )
                    : NoDataCard();
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
          ),
          if (isCanEditUPC())
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // English: Confirmation via bottom sheet
                    final ok = await confirmAction(
                      title: Messages.CONFIRM,
                      message: Messages.UPDATE_UPC,
                    );
                    if (!ok || !context.mounted) return;
                    if(context.mounted)context.push(AppRouter.PAGE_UPDATE_PRODUCT_UPC);
                  },
                  child: Text(Messages.UPDATE_UPC),
                ),
              ),
            ),
        ],
      ),
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
}
