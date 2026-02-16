import 'package:flutter/material.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_product.dart';

class BaseProductDetailCard extends StatelessWidget {
  final IdempiereProduct product;

  final Color backgroundColor;
  final Color borderColor;

  final bool categoryWithPrefix;

  final VoidCallback? onTap;

  /// NEW: printer icon callback
  final VoidCallback? onPrintTap;

  final TextStyle? textStyle;

  const BaseProductDetailCard({
    super.key,
    required this.product,
    required this.backgroundColor,
    required this.borderColor,
    this.categoryWithPrefix = false,
    this.onTap,
    this.onPrintTap,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final style = textStyle ??
        const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: themeFontSizeNormal,
          color: Colors.white,
        );

    String att = product.mAttributeSetInstanceID?.identifier ?? '';
    if (att == '') {
      att =
      '${Messages.ATTRIBUET_INSTANCE}: ${product.mAttributeSetInstanceID?.identifier ?? '--'}';
    }

    final rawCategory = product.mProductCategoryID?.identifier ?? '--';
    final category = categoryWithPrefix
        ? '${Messages.CATEGORY}: $rawCategory'
        : rawCategory;

    final content = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              Text(product.name ?? '${Messages.NAME}--', style: style),
              Text('UPC: ${product.uPC ?? 'UPC--'}', style: style),
              Text('SKU: ${product.sKU ?? 'SKU--'}', style: style),
              Text('M_SKU: ${product.mOLIConfigurableSKU ?? 'M_SKU--'}',
                  style: style),
              Text(att, style: style),
              Text(category, style: style),
            ],
          ),

          // Printer icon (top right) - floating badge style
          if (onPrintTap != null)
            Positioned(
              bottom: 25,
              right: 6,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPrintTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(46, 0, 0, 0),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color.fromARGB(64, 255, 255, 255),
                        width: 0.8,
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.print,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
