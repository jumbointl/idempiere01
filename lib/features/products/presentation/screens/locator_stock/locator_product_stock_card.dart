import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../domain/idempiere/idempiere_locator.dart';
import '../../../domain/idempiere/locator_product_stock.dart';
import 'locator_ip_lines_bottom_sheet.dart';

/// Single product row inside [LocatorStockDetailScreen].
///
/// Shows UPC + name + 3 metrics (`Show` / `In Progress` / `Expected`)
/// and an "Extraer" button that opens [LocatorIpLinesBottomSheet].
class LocatorProductStockCard extends ConsumerStatefulWidget {
  const LocatorProductStockCard({
    super.key,
    required this.locator,
    required this.productStock,
    required this.width,
    this.highlight = false,
  });

  final IdempiereLocator locator;
  final LocatorProductStock productStock;
  final double width;

  /// When true (the product matches the user's `M_Product_ID` filter) the
  /// card renders with a cyan-100 background to stand out from the rest
  /// of the locator's products.
  final bool highlight;

  @override
  ConsumerState<LocatorProductStockCard> createState() =>
      _LocatorProductStockCardState();
}

class _LocatorProductStockCardState
    extends ConsumerState<LocatorProductStockCard> {
  bool _extracting = false;

  String _fmt(double? v) {
    if (v == null) return '—';
    return Memory.numberFormatter0Digit.format(v);
  }

  Future<void> _onExtract() async {
    if (_extracting) return;
    setState(() => _extracting = true);
    try {
      await LocatorIpLinesBottomSheet.show(
        context,
        ref: ref,
        locator: widget.locator,
        productStock: widget.productStock,
      );
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.productStock.product;
    final upc = (p.uPC ?? '').trim();
    final name = (p.name ?? '').trim();
    final sku = (p.sKU ?? '').trim();

    final show = widget.productStock.totalShow;
    final inProgress = widget.productStock.totalInProgress;
    final expected = widget.productStock.expected;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              name.isEmpty ? '(no name)' : name,
              style: const TextStyle(
                fontSize: themeFontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Wrap(
              spacing: 12,
              children: <Widget>[
                if (upc.isNotEmpty)
                  Text('UPC: $upc',
                      style: const TextStyle(fontSize: themeFontSizeSmall)),
                if (sku.isNotEmpty)
                  Text('SKU: $sku',
                      style: const TextStyle(fontSize: themeFontSizeSmall)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                _Metric(label: 'Show', value: _fmt(show)),
                _Metric(label: 'In Progress', value: _fmt(inProgress)),
                _Metric(label: 'Expected', value: _fmt(expected)),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _extracting ? null : _onExtract,
                icon: _extracting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: const Text('Extraer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: themeFontSizeSmall,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: themeFontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
