import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

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
  final int actionTypeInt = Memory.ACTION_UPDATE_UPC;

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

  @override
  void initState() {
    super.initState();
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
              onOk: ref.read(productsUpdateNotifierProvider.notifier).handleInputString,
            ),
          IconButton(
            icon: const Icon(Icons.keyboard, color: Colors.purple),
            onPressed: () {
              openInputDialogWithAction(
                ref: ref,
                history: false,
                onOk: ref.read(productsUpdateNotifierProvider.notifier).handleInputString,
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
            isScanning
                ? LinearProgressIndicator(
              backgroundColor: Colors.cyan,
              color: Colors.amber[600],
              minHeight: 36,
            )
                : _getSearchBar(),

            Expanded(
              child: dataToUpdateUPC.state.length == 2
                  ? updateAsync.when(
                data: (product) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    stopScanning();
                  });

                  // English: Optional success feedback
                  // (If you already show success elsewhere, remove this)
                  // showSuccessSheet(Messages.SUCCESS);

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

  // -------------------------
  // UI widgets
  // -------------------------

  Widget _buttonScanWithPhone() {
    final isScanning = ref.watch(isScanningProvider);

    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: isScanning ? Colors.grey : Colors.cyan[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
      onPressed: isScanning
          ? null
          : () async {
        // English: Open camera scanner and store the result
        final result = await SimpleBarcodeScanner.scanBarcode(
          context,
          barcodeAppBar: BarcodeAppBar(
            appBarTitle: Messages.SCANNING,
            centerTitle: false,
            enableBackButton: true,
            backButtonIcon: const Icon(Icons.arrow_back_ios),
          ),
          isShowFlashIcon: true,
          delayMillis: 300,
          cameraFace: CameraFace.back,
        );

        if (result != null && result.isNotEmpty) {
          ref
              .read(scanHandleProvider.notifier)
              .addNewUPCCode(result);
        }
      },
      child: Text(Messages.OPEN_CAMERA),
    );
  }

  Widget _getSearchBar() {

    return SizedBox(
      width: MediaQuery.of(context).size.width - 30,
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              Messages.PLEASE_SCAN_NEW_UPC,
              textAlign: TextAlign.center,
              style: textStyleMediumBold,
            ),
          ),
        ],
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

            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor:
                  isCanEditUPC() ? Colors.purple : Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (!isCanEditUPC()) return;

                  final id = ref.read(productForUpcUpdateProvider).id?.toString() ?? '';
                  final newUPC = ref.read(newUPCToUpdateProvider.notifier).state;

                  // English: Validate inputs
                  final idOk = id.isNotEmpty && int.tryParse(id) != null && int.parse(id) > 0;
                  final upcOk = newUPC.isNotEmpty &&
                      int.tryParse(newUPC) != null &&
                      int.parse(newUPC) > 0;

                  if (!idOk || !upcOk) {
                    await showErrorSheet(
                      '${Messages.DATA_NOT_VALID}\nID: $id, UPC: $newUPC',
                    );
                    return;
                  }

                  // English: Ask confirmation using unified bottom sheet
                  final ok = await confirmAction(
                    title: Messages.CONFIRM,
                    message: 'ID: $id\nUPC: $newUPC',
                  );
                  if (!ok) return;

                  // English: Trigger update flow
                  final updateData = <String>[id, newUPC];
                  ref.read(dataToUpdateUPCProvider.notifier).update((_) => updateData);

                  // English: Mark scanning (optional UX)
                  startScanning();
                },
                child: Text(hinTextUpdateUPC),
              ),
            ),

            const SizedBox(height: 10),

            // English: Optional: Provide camera scan button in this card
            _buttonScanWithPhone(),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // Business rules
  // -------------------------

  bool isCanEditUPC() {
    final p = ref.read(productForUpcUpdateProvider);

    if (p.id == null || p.id == 0) return false;

    // English: If product has no UPC yet, allow updating when new UPC is valid
    if (p.uPC == null || p.uPC!.isEmpty) {
      final aux = ref.read(newUPCToUpdateProvider.notifier).state;
      if (aux == hinTextUpdateUPC) return false;
      if (int.tryParse(aux) == null) return false;
      if (int.parse(aux) == 0) return false;
      return true;
    }

    return false;
  }

  @override
  Future<void> handleInputString({required WidgetRef ref, required String inputData, required int actionScan}) {
    // TODO: implement handleInputString
    throw UnimplementedError();
  }
}
