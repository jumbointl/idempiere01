import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/idempiere_product.dart';
import '../../store_on_hand/memory_products.dart';
class ProductDetailCardForLine extends ConsumerStatefulWidget {
  final IdempiereProduct product;

  const ProductDetailCardForLine({required this.product, super.key});


  @override
  ConsumerState<ProductDetailCardForLine> createState() => ProductDetailCardForLineState();
}

class ProductDetailCardForLineState extends ConsumerState<ProductDetailCardForLine> {
  TextStyle textStyle = const TextStyle(fontWeight: FontWeight.bold,
      fontSize: themeFontSizeNormal
    ,color: Colors.white);

  @override
  Widget build(BuildContext context) {
    String att = widget.product.mAttributeSetInstanceID?.identifier  ?? '';
    if(att==''){
      att = '${Messages.ATTRIBUET_INSTANCE}: ${widget.product.mAttributeSetInstanceID?.identifier  ?? '--'}';
    }
    String category = '${Messages.CATEGORY}: ${widget.product.mProductCategoryID?.identifier  ?? '--'}';

    Color backGroundColor = themeColorPrimary;
    if(MemoryProducts.movementAndLines.id ==null || MemoryProducts.movementAndLines.id! <= 0){
      if(widget.product.mOLIConfigurableSKU == null || widget.product.mOLIConfigurableSKU == '') {
        backGroundColor = Colors.amber[800]!;

      }

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backGroundColor,
          border: Border.all(color:backGroundColor, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            Text(widget.product.name ?? '${Messages.NAME}--',style: textStyle,),
            Text('UPC: ${widget.product.uPC ?? 'UPC--'}',style: textStyle,),
            Text('SKU: ${widget.product.sKU ?? 'SKU--'}',style: textStyle,),
            Text('M_SKU: ${widget.product.mOLIConfigurableSKU ?? 'M_SKU--'}',style: textStyle,),
            Text(att,style: textStyle),
            Text(category,style: textStyle)

          ],
        ),
      );

    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backGroundColor,
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5,
        children: [
          Text(widget.product.name ?? '${Messages.NAME}--',style: textStyle,),
          Text('UPC: ${widget.product.uPC ?? 'UPC--'}',style: textStyle,),
          Text('SKU: ${widget.product.sKU ?? 'SKU--'}',style: textStyle,),
          Text('M_SKU: ${widget.product.mOLIConfigurableSKU ?? 'M_SKU--'}',style: textStyle,),
          Text(att,style: textStyle),
          Text(category,style: textStyle)


        ],
      ),
    );
  }
}