import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../domain/idempiere/idempiere_locator.dart';
import '../../../domain/idempiere/locator_ip_line.dart';
import '../../../domain/idempiere/locator_product_stock.dart';
import '../../providers/locator_stock/locator_stock_extract_providers.dart';

class LocatorIpLinesBottomSheet extends ConsumerStatefulWidget {
  const LocatorIpLinesBottomSheet({
    super.key,
    required this.locator,
    required this.productStock,
  });

  final IdempiereLocator locator;
  final LocatorProductStock productStock;

  static Future<void> show(
    BuildContext context, {
    required WidgetRef ref,
    required IdempiereLocator locator,
    required LocatorProductStock productStock,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LocatorIpLinesBottomSheet(
        locator: locator,
        productStock: productStock,
      ),
    );
  }

  @override
  ConsumerState<LocatorIpLinesBottomSheet> createState() =>
      _LocatorIpLinesBottomSheetState();
}

class _LocatorIpLinesBottomSheetState
    extends ConsumerState<LocatorIpLinesBottomSheet> {
  late Future<List<LocatorIpLine>> _future;

  @override
  void initState() {
    super.initState();
    _future = extractIpLinesForProduct(
      ref,
      ExtractIpLinesArgs(
        locator: widget.locator,
        productStock: widget.productStock,
      ),
    );
  }

  String _fmtQty(double v) => Memory.numberFormatter0Digit.format(v);

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final p = widget.productStock.product;
    final loc = widget.locator;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'IP lines — ${p.uPC ?? p.sKU ?? "(product)"}',
                          style: const TextStyle(
                            fontSize: themeFontSizeLarge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Locator ${loc.value ?? loc.name ?? loc.id}',
                          style: const TextStyle(
                            fontSize: themeFontSizeSmall,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: FutureBuilder<List<LocatorIpLine>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error: ${snap.error}'),
                    );
                  }
                  final lines = snap.data ?? const <LocatorIpLine>[];
                  if (lines.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No IP lines in range.')),
                    );
                  }

                  final total =
                      lines.fold<double>(0, (a, l) => a + l.qty);

                  return Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('${lines.length} line(s)'),
                            Text(
                              'Total: ${_fmtQty(total)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: lines.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final l = lines[i];
                            return ListTile(
                              dense: true,
                              leading: _SourceTag(tag: l.sourceTag),
                              title: Text(
                                l.documentNo.isEmpty
                                    ? '(no doc)'
                                    : l.documentNo,
                              ),
                              subtitle: Text(
                                <String>[
                                  _fmtDate(l.movementDate),
                                  if (l.lineNo != null) 'Line ${l.lineNo}',
                                  if ((l.description ?? '').isNotEmpty)
                                    l.description!,
                                ].join('  •  '),
                              ),
                              trailing: Text(
                                _fmtQty(l.qty),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTag extends StatelessWidget {
  const _SourceTag({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final color = tag == 'MOV' ? Colors.indigo : Colors.deepOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: themeFontSizeSmall,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
