import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_product.dart';
class ProductDetailCard extends ConsumerStatefulWidget {
  final IdempiereProduct product;

  const ProductDetailCard(this.product, {super.key});


  @override
  ConsumerState<ProductDetailCard> createState() => ProductDetailCardState();
}

class ProductDetailCardState extends ConsumerState<ProductDetailCard> {

  @override
  Widget build(BuildContext context) {
    String att = widget.product.mAttributeSetInstanceID?.identifier  ?? '';
    if(att==''){
      att = '${Messages.ATTRIBUET_INSTANCE}: ${widget.product.mAttributeSetInstanceID?.identifier  ?? '--'}';
    }

    return Container(
      decoration: BoxDecoration(
        color: themeColorPrimaryLight2,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5,
        children: [
          Text(widget.product.name ?? '${Messages.NAME}--'),
          Text('UPC:${widget.product.uPC ?? 'UPC--'}'),
          Text('SKU:${widget.product.sKU ?? 'SKU--'}'),
          Text(att),

        ],
      ),
    );
  }
}