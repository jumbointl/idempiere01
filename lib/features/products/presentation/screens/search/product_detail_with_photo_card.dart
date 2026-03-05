import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../providers/ai/gallery_provider.dart';
import '../../providers/product_provider_common.dart';
class ProductDetailWithPhotoCard extends ConsumerStatefulWidget {
  final IdempiereProduct product;

  final int actionTypeInt;

  bool testMode = true;

  ProductDetailWithPhotoCard(
      {required this.product,
        required this.actionTypeInt, super.key});


  @override
  ConsumerState<ProductDetailWithPhotoCard> createState() =>
      _ProductDetailWithPhotoCardState();
}

class _ProductDetailWithPhotoCardState extends ConsumerState<ProductDetailWithPhotoCard> {

  @override
  Widget build(BuildContext context) {
    final productId = widget.product.id?.toString() ?? '';
    ref.listen(productGalleryProvider(productId), (prev, next) {
      if (next.isNotEmpty) {
        ref.read(selectedImageIndexProvider.notifier).state = 0;
      }
    });
    String att = widget.product.mAttributeSetInstanceID?.identifier  ?? '';
    if(att==''){
      att = '${Messages.ATTRIBUET_INSTANCE}: ${widget.product.mAttributeSetInstanceID?.identifier  ?? '--'}';
    }
    final images = ref.watch(productGalleryProvider(productId));
    final selectedIndex = ref.watch(selectedImageIndexProvider);

    String imageUrl = widget.product.imageURL ?? '';
    final rawCategory = widget.product.mProductCategoryID?.identifier ?? '--';
    final category =  '${Messages.CATEGORY}: $rawCategory' ;


    if (Memory.isTestMode) {
      imageUrl = Memory.IMAGE_HTTP_SAMPLE_1;
      int countScannedCamera = ref.watch(scannedCodeTimesProvider);
      imageUrl = countScannedCamera.isEven
          ? Memory.IMAGE_HTTP_SAMPLE_2
          : Memory.IMAGE_HTTP_SAMPLE_1;
    }

    Widget imageWidget;

    if (images.isEmpty) {
      // 🔹 Modo actual (Network)
      imageWidget = FadeInImage(
        placeholder: AssetImage(Memory.IMAGE_LOADING),
        image: NetworkImage(imageUrl),
        fit: BoxFit.contain,
        imageErrorBuilder: (_, _, _) =>
            Image.asset(Memory.IMAGE_NO_IMAGE, fit: BoxFit.cover),
      );
    } else {
      // 🔹 Modo galería local (FTP/S3)
      final safeIndex =
      selectedIndex < images.length ? selectedIndex : 0;

      final selectedImage = images[safeIndex];

      imageWidget = Image.memory(
        selectedImage.bytes,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Image.asset(Memory.IMAGE_NO_IMAGE, fit: BoxFit.contain),
      );
    }

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: widget.product.id != null && widget.product.id! > 0
              ? Colors.white
              : Colors.red[200]!,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            Container(
              // Importante: El color se mueve dentro del BoxDecoration
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20), // Ajusta el radio del borde aquí
                border: Border.all(color: Colors.grey[400]!), // Opcional: añade un borde sutil
              ),
              child: Center(
                child: SizedBox(
                  width: Memory.SIZE_PRODUCT_IMAGE_WIDTH,
                  height: Memory.SIZE_PRODUCT_IMAGE_HEIGHT,
                  child: ClipRRect(
                    // Aplicamos el mismo redondeo a la imagen para que no sobresalga en las esquinas
                    borderRadius: BorderRadius.circular(15),
                    child: imageWidget,
                  ),
                ),
              ),
            ),

            Text(
              widget.product.name ?? '${Messages.NAME}--',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('UPC: ${widget.product.uPC ?? 'UPC--'}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'SKU: ${widget.product.sKU ?? 'SKU--'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'M_SKU: ${widget.product.mOLIConfigurableSKU ?? 'M_SKU--'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              att,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              category,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }







}