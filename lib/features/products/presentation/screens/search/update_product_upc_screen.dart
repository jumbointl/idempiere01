import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../common/input_dialog.dart';
import '../../../common/scan_button_by_action_fixed_short.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../providers/common_provider.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/product_search_provider.dart';
import '../../providers/product_update_upc_provider.dart';
import '../search/product_result_with_photo_card.dart';

// English: Base state with unified bottom sheets + helpers
import '../../../common/common_consumer_state.dart';

class UpdateProductUpcScreen extends ConsumerStatefulWidget {
  final int actionTypeInt = Memory.ACTION_FILL_NEW_UPC_TO_UPDATE;

  const UpdateProductUpcScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      UpdateProductUpcScreenState();
}

class UpdateProductUpcScreenState
    extends CommonConsumerState<UpdateProductUpcScreen> {

  late IdempiereProduct product;
  late var newUPCProvider;
  late AsyncValue updateAsync;
  late var dataToUpdateUPC;

  final hinTextUpdateUPC = Messages.UPDATE_UPC;
  int get actionScanTypeInt => Memory.ACTION_FILL_NEW_UPC_TO_UPDATE ;

  @override
  void initState() {

    super.initState();
    debugPrint('widget.actionTypeInt ${widget.actionTypeInt}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(actionScanProvider.notifier).state = Memory.ACTION_FILL_NEW_UPC_TO_UPDATE;
    });

  }

  @override
  Widget build(BuildContext context) {
    dataToUpdateUPC = ref.watch(dataToUpdateUPCProvider.notifier);
    product = ref.watch(productForUpcUpdateProvider);
    updateAsync = ref.watch(updateProductUPCProvider);

    final double bodyHeight = MediaQuery.of(context).size.height - 100;
    final isScanning = ref.watch(isScanningProvider);

    newUPCProvider = ref.watch(newUPCToUpdateProvider);


    final showScan = ref.watch(showScanFixedButtonProvider(widget.actionTypeInt));

    return Scaffold(
      appBar: AppBar(
        title: Text(Messages.PRODUCT),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // English: Keep back behavior simple and safe
            unfocus();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (showScan)
            ScanButtonByActionFixedShort(
              actionTypeInt: widget.actionTypeInt,
              onOk: handleInputString,
            ),
          IconButton(
            icon: const Icon(Icons.keyboard, color: Colors.purple),
            onPressed: () {
              openInputDialogWithAction(
                ref: ref,
                history: false,
                onOk: handleInputString,
                actionScan: widget.actionTypeInt,
              );
            },
          ),
        ],
      ),
      body: SizedBox(
        height: bodyHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            (isScanning)
                ? LinearProgressIndicator(
              backgroundColor: Colors.cyan,
              color: Colors.amber[600],
              minHeight: 36,
            ) : SizedBox(height: 6,) ,

            Expanded(
              child: dataToUpdateUPC.state.length == 2
                  ? updateAsync.when(
                data: (product) {

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    stopScanning();

                  });

                  return _getProductDetailCard(product: product);
                },
                error: (error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    stopScanning();
                  });
                  return Center(child: Text('Error: $error'));
                },
                loading: () => const LinearProgressIndicator(),
              )
                  : _getUpdateUPCCard(product),
            ),
          ],
        ),
      ),
    );
  }


  Widget _getProductDetailCard({required IdempiereProduct product}) {
    return ProductResultWithPhotoCard(
      product: product,
      actionTypeInt: widget.actionTypeInt,
    );
  }

  Widget _getUpdateUPCCard(IdempiereProduct product) {
    var imageUrl = product.imageURL ?? '';
    final bool testMode = true;

    if (testMode) {
      // English: Demo image rotation based on scan counter
      imageUrl = Memory.IMAGE_HTTP_SAMPLE_1;
      final countScannedCamera =
          ref.watch(scannedCodeTimesProvider.notifier).state;

      imageUrl = countScannedCamera.isEven
          ? Memory.IMAGE_HTTP_SAMPLE_2
          : Memory.IMAGE_HTTP_SAMPLE_1;
    }

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                width: Memory.SIZE_PRODUCT_IMAGE_WIDTH,
                height: Memory.SIZE_PRODUCT_IMAGE_HEIGHT,
                child: FadeInImage(
                  placeholder: AssetImage(Memory.IMAGE_LOADING),
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      Memory.IMAGE_NO_IMAGE,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name ?? '${Messages.NAME}--',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'SKU: ${product.sKU ?? 'SKU--'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'M_SKU: ${product.mOLIConfigurableSKU ?? 'M_SKU--'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  newUPCProvider == '' ? Messages.SCAN_UPC : newUPCProvider,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }



  @override
  Future<void> handleInputString({required WidgetRef ref, required String inputData, required int actionScan}) async {
    ref.read(productsUpdateNotifierProvider.notifier).handleInputString(ref: ref,
        inputData: inputData,actionScan: widget.actionTypeInt) ;
  }

}
