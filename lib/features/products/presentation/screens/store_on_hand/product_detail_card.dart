import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../providers/store_on_hand_provider.dart';
import '../../widget/base_product_detail_card.dart';
import 'memory_products.dart';

class ProductDetailCard extends ConsumerWidget {
  final IdempiereProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onPrintTap;


  const ProductDetailCard({
    required this.product,
    this.onTap,
    this.onPrintTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color bg = Colors.cyan[800]!;
    Color border = Colors.blue;

    final hasMovement = (MemoryProducts.movementAndLines.id != null &&
        (MemoryProducts.movementAndLines.id ?? 0) > 0);

    if (!hasMovement) {
      // same behavior you had
      if (product.mOLIConfigurableSKU == null || product.mOLIConfigurableSKU == '') {
        bg = Colors.amber[800]!;
        border = bg;
      }

      if (ref.watch(searchByMOLIConfigurableSKUProvider)) {
        bg = Colors.amber[800]!;
        border = bg;
      } else {
        bg = themeColorPrimary;
        border = bg;
      }
    } else {
      // when has movement, keep your original look
      bg = Colors.cyan[800]!;
      border = Colors.blue;
    }

    return BaseProductDetailCard(
      product: product,
      backgroundColor: bg,
      borderColor: hasMovement ? border : bg, // mimic original
      categoryWithPrefix: false,
      onTap: onTap,
      onPrintTap:onPrintTap
    );
  }
}
