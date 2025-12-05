import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_product.dart';
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
    Color backGroundColor = widget.product.id !=null && widget.product.id! >0 ? Colors.white : Colors.red[200]!;
    Memory.setImageSize(context);
    String att = widget.product.mAttributeSetInstanceID?.identifier  ?? '';
    if(att==''){
      att = '${Messages.ATTRIBUET_INSTANCE}: ${widget.product.mAttributeSetInstanceID?.identifier  ?? '--'}';
    }
    String category = widget.product.mProductCategoryID?.identifier  ?? '--';
    String imageUrl = widget.product.imageURL ?? '' ;
    if(Memory.isTestMode){
      imageUrl = Memory.IMAGE_HTTP_SAMPLE_1; // Example image URL
      int countScannedCamera = ref.watch(scannedCodeTimesProvider);
      if(countScannedCamera.isEven){
        imageUrl = Memory.IMAGE_HTTP_SAMPLE_2;
      } else {
        imageUrl = Memory.IMAGE_HTTP_SAMPLE_1;
      }
    }
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: backGroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
      
            Center(
              child: SizedBox(
                width: Memory.SIZE_PRODUCT_IMAGE_WIDTH,
                height: Memory.SIZE_PRODUCT_IMAGE_HEIGHT,
                child: FadeInImage(
                  placeholder: AssetImage(Memory.IMAGE_LOADING), // Placeholder for loading
                  image:NetworkImage(imageUrl),
      
                  fit: BoxFit.cover, // Adjust as needed
                  imageErrorBuilder: (context, error, stackTrace) {
                    return Image.asset(Memory.IMAGE_NO_IMAGE, fit: BoxFit.cover); // Display on error
                  },
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