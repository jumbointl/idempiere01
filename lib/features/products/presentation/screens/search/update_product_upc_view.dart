import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../../common/common_consumer_state.dart';

import '../../providers/product_provider_common.dart';
import '../../providers/product_search_provider.dart';
import '../../providers/products_scan_notifier.dart';
import '../../widget/no_data_card.dart';

class UpdateProductUpcView extends ConsumerStatefulWidget {
  int countScannedCamera = 0;
  late ProductsScanNotifier productsNotifier;
  final int actionTypeInt = Memory.ACTION_UPDATE_UPC;

  UpdateProductUpcView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      UpdateProductUpcViewState();
}

class UpdateProductUpcViewState
    extends CommonConsumerState<UpdateProductUpcView> {

  @override
  Widget build(BuildContext context) {
    widget.productsNotifier = ref.watch(scanHandleNotifierProvider.notifier);

    final double width = MediaQuery.of(context).size.width - 30;
    final double bodyHeight = MediaQuery.of(context).size.height - 200;

    final isScanning = ref.watch(isScanningProvider);
    final product = ref.watch(productForUpcUpdateProvider);

    // English: Keep image sizes proportional to view height
    Memory.SIZE_PRODUCT_IMAGE_WIDTH = bodyHeight / 4;
    Memory.SIZE_PRODUCT_IMAGE_HEIGHT = bodyHeight / 4;

    widget.countScannedCamera = ref.watch(scannedCodeTimesProvider);

    final imageUrl = widget.countScannedCamera.isEven
        ? Memory.IMAGE_HTTP_SAMPLE_2
        : Memory.IMAGE_HTTP_SAMPLE_1;

    final Color foreGroundProgressBar = Colors.amber[600]!;

    // English: This widget is used inside a TabBarView, so DO NOT return a Scaffold here.
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        if (isScanning)
          LinearProgressIndicator(
            backgroundColor: Colors.cyan,
            color: foreGroundProgressBar,
            minHeight: 36,
          )
        else
          Center(child: Text(Messages.UPDATE_IMAGE)),

        const SizedBox(height: 5),

        Container(
          width: width,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: (product.id != null && product.id! > 0)
              ? _getUpdateUPCCard(
            product.copyWith(imageURL: imageUrl, uPC: null),
          )
              : NoDataCard(),
        ),
      ],
    );
  }

  Widget _getUpdateUPCCard(IdempiereProduct product) {
    // English: Build attribute instance line safely
    String att = product.mAttributeSetInstanceID?.identifier ?? '';
    if (att.isEmpty) {
      att =
      '${Messages.ATTRIBUET_INSTANCE}: ${product.mAttributeSetInstanceID?.identifier ?? '--'}';
    }

    // English: Use the provided imageURL; fallback to sample image if needed
    String imageUrl = product.imageURL ?? '';
    if (imageUrl.isEmpty) {
      imageUrl = Memory.IMAGE_HTTP_SAMPLE_1;
    }

    // English: Optional demo mode - keep as in your original logic
    const bool testMode = true;
    if (testMode) {
      final countScannedCamera = ref.watch(scannedCodeTimesProvider);
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
            Text(
              att,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> handleInputString({required WidgetRef ref,
    required String inputData, required int actionScan}) {
    // TODO: implement handleInputString
    throw UnimplementedError();
  }
}
