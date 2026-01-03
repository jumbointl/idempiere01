import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../providers/store_on_hand_provider.dart';
import 'memory_products.dart';
class ProductDetailCard extends ConsumerStatefulWidget {
  final IdempiereProduct product;
  const ProductDetailCard({required this.product, super.key});


  @override
  ConsumerState<ProductDetailCard> createState() => ProductDetailCardState();
}

class ProductDetailCardState extends ConsumerState<ProductDetailCard> {
  TextStyle textStyle = const TextStyle(fontWeight: FontWeight.bold,
      fontSize: themeFontSizeNormal
    ,color: Colors.white);

  @override
  Widget build(BuildContext context) {
    String att = widget.product.mAttributeSetInstanceID?.identifier  ?? '';
    if(att==''){
      att = '${Messages.ATTRIBUET_INSTANCE}: ${widget.product.mAttributeSetInstanceID?.identifier  ?? '--'}';
    }
    String category = widget.product.mProductCategoryID?.identifier  ?? '--';
    Color backGroundColor = Colors.cyan[800]!;
    bool canSearch = true ;
    if(MemoryProducts.movementAndLines.id ==null || MemoryProducts.movementAndLines.id! <= 0){
      if(widget.product.mOLIConfigurableSKU == null || widget.product.mOLIConfigurableSKU == '') {
        canSearch = false;
        backGroundColor = Colors.amber[800]!;

      }
      if(ref.watch(searchByMOLIConfigurableSKUProvider)){
        backGroundColor = Colors.amber[800]!;
      } else {
        backGroundColor = themeColorPrimary;
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
            Text(category,style: textStyle),

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(att,style: textStyle),
              const SizedBox(width: 8,),
              Text(category,style: textStyle),
            ],)

        ],
      ),
    );
  }
}