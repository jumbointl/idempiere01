import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_product.dart';
class ProductDetailCardWithoutController extends ConsumerStatefulWidget {
  final IdempiereProduct product;
  const ProductDetailCardWithoutController({required this.product, super.key});


  @override
  ConsumerState<ProductDetailCardWithoutController> createState() => ProductDetailCardWithoutControllerState();
}

class ProductDetailCardWithoutControllerState extends ConsumerState<ProductDetailCardWithoutController> {
  TextStyle textStyle = const TextStyle(fontWeight: FontWeight.bold,fontSize: themeFontSizeNormal
    ,color: Colors.white);

  @override
  Widget build(BuildContext context) {
    String att = widget.product.mAttributeSetInstanceID?.identifier  ?? '';
    if(att==''){
      att = '${Messages.ATTRIBUET_INSTANCE}: ${widget.product.mAttributeSetInstanceID?.identifier  ?? '--'}';
    }
    Color backGroundColor = themeColorPrimary;

    return Container(
      decoration: BoxDecoration(
        color: backGroundColor,
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
          Text(att,style: textStyle,),

        ],
      ),
    );
  }
}