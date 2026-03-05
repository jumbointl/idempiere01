import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../config/theme/app_theme.dart';
import '../../../../domain/idempiere/idempiere_product.dart';
import '../../../widget/base_product_detail_card.dart';

class ProductDetailCardForInventoryLine extends ConsumerWidget {
  final IdempiereProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onPrintTap;

  const ProductDetailCardForInventoryLine({
    required this.product,
    this.onTap,
    this.onPrintTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseProductDetailCard(
      product: product,
      backgroundColor: themeColorPrimary,
      borderColor: Colors.blue,
      categoryWithPrefix: true,
      onTap: onTap,
      onPrintTap: onPrintTap,
    );
  }
}