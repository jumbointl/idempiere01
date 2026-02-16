import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../config/theme/app_theme.dart';
import '../../../../domain/idempiere/idempiere_product.dart';
import '../../../widget/base_product_detail_card.dart';
import '../../store_on_hand/memory_products.dart';

class ProductDetailCardForLine extends ConsumerWidget {
  final IdempiereProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onPrintTap;

  const ProductDetailCardForLine({
    required this.product,
    this.onTap,
    this.onPrintTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMovement = (MemoryProducts.movementAndLines.id != null &&
        (MemoryProducts.movementAndLines.id ?? 0) > 0);

    Color bg = themeColorPrimary;
    Color border = Colors.blue;

    if (!hasMovement) {
      if (product.mOLIConfigurableSKU == null || product.mOLIConfigurableSKU == '') {
        bg = Colors.amber[800]!;
        border = bg;
      } else {
        border = bg;
      }
    }

    return BaseProductDetailCard(
      product: product,
      backgroundColor: bg,
      borderColor: hasMovement ? border : border,
      categoryWithPrefix: true, // ForLine wants "CATEGORY: xxx"
      onTap: onTap,
      onPrintTap: onPrintTap,
    );
  }
}
