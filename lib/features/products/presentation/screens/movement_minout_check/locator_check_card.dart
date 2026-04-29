import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/movement_minout_check.dart';
import '../../providers/product_provider_common.dart';

/// Locator-level card for [MovementMInOutCheckScreen].
///
/// Card background colour:
///   - green-light  if every assigned product has enough stock
///   - pink-light   if at least one product is partial or missing
///
/// Tapping the header expands a per-product breakdown where each product is:
///   - green-light  ok (`available >= required`)
///   - pink-light   partial (`0 < available < required`)
///   - red-light    missing (`available <= 0`) with the note
///                  "No hay en este locator"
///
/// Long-press on a product line opens the system share sheet with a
/// descriptive text + a `monalisa002://run?action=4&value=...` deep link
/// that, when tapped on a device with monalisa_app_002 installed, opens
/// the same product on its `ProductStoreOnHand` screen.
class LocatorCheckCard extends ConsumerStatefulWidget {
  const LocatorCheckCard({
    super.key,
    required this.group,
    required this.source,
    required this.documentNo,
  });

  final MovementMInOutCheckLocatorGroup group;
  final MovementMInOutCheckSource source;
  final String documentNo;

  @override
  ConsumerState<LocatorCheckCard> createState() => _LocatorCheckCardState();
}

class _LocatorCheckCardState extends ConsumerState<LocatorCheckCard> {
  bool _expanded = false;

  String _fmt(double v) => Memory.numberFormatter0Digit.format(v);

  /// Navigates to [ProductStoreOnHandScreen] with the line's UPC. The
  /// destination screen seeds [productCodeInputProvider] and auto-fires
  /// the search via its inherited `executeAfterShown` flow.
  ///
  /// Pre-sets `actionScanProvider` to the destination's action so the
  /// scan button doesn't flicker between the source and destination
  /// values during the navigation transition. Restored in `finally` when
  /// the destination is popped — that's our equivalent of "popscope on
  /// the source screen".
  Future<void> _onLineTap(String upc) async {
    if (upc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Messages.ERROR_UPC_EMPTY)),
      );
      return;
    }
    final oldAction = ref.read(actionScanProvider);
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;
    try {
      await context.push('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/$upc');
    } finally {
      ref.read(actionScanProvider.notifier).state = oldAction;
    }
  }

  /// Build the cross-app deep link for a product UPC. Receivers (currently
  /// only monalisa_app_002) parse this and route to `ProductStoreOnHand`
  /// with the UPC pre-filled. Action int is the same `Memory.ACTION_*`
  /// value the receiver expects.
  String _buildShareUrl(String upc) {
    final uri = Uri(
      scheme: 'monalisa002',
      host: 'run',
      queryParameters: <String, String>{
        'action': Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND.toString(),
        'value': jsonEncode(<String, String>{'upc': upc}),
      },
    );
    return uri.toString();
  }

  String _buildShareText({
    required String upc,
    required String name,
    required String locatorValue,
    required double required,
    required double available,
  }) {
    final tipo = widget.source == MovementMInOutCheckSource.movement
        ? 'Movement'
        : 'Shipment';
    final url = _buildShareUrl(upc);
    return <String>[
      'Tipo: $tipo',
      'Doc N°: ${widget.documentNo}',
      'Producto: ${name.isEmpty ? '(sin nombre)' : name}',
      'UPC: $upc',
      'Locator: $locatorValue',
      'Req: ${_fmt(required)} / Stock: ${_fmt(available)}',
      url,
    ].join('\n');
  }

  /// Long-press handler — opens a bottom sheet with two actions:
  ///   - "Compartir": opens the system share sheet with the descriptive
  ///     text + deep link (for sending to a colleague over WhatsApp /
  ///     email / etc.).
  ///   - "Abrir en monalisa 002": launches the `monalisa002://` URL
  ///     directly via `url_launcher`. On a device that has the app
  ///     installed, Android opens it via the registered ACTION_VIEW
  ///     intent-filter — that's the local-testing path that the share
  ///     sheet alone can't cover (the share sheet only lists ACTION_SEND
  ///     receivers).
  Future<void> _onLineLongPress({
    required String upc,
    required String name,
    required String locatorValue,
    required double required,
    required double available,
  }) async {
    if (upc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto sin UPC — nada para compartir')),
      );
      return;
    }
    final url = _buildShareUrl(upc);
    final text = _buildShareText(
      upc: upc,
      name: name,
      locatorValue: locatorValue,
      required: required,
      available: available,
    );

    if (!mounted) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.share, color: Colors.purple),
              title: const Text('Compartir'),
              subtitle: const Text('WhatsApp, email, etc.'),
              onTap: () => Navigator.of(ctx).pop('share'),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new, color: Colors.purple),
              title: const Text('Abrir en monalisa 002'),
              subtitle: const Text('Abre el link aquí mismo'),
              onTap: () => Navigator.of(ctx).pop('open'),
            ),
          ],
        ),
      ),
    );

    if (action == 'share') {
      await SharePlus.instance.share(ShareParams(text: text));
    } else if (action == 'open') {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir el link — ¿está instalada monalisa 002?',
            ),
          ),
        );
      }
    }
  }

  Color _bgForLine(LocatorCheckLineStatus s) {
    switch (s) {
      case LocatorCheckLineStatus.ok:
        return Colors.green.shade50;
      case LocatorCheckLineStatus.partial:
        return Colors.pink.shade50;
      case LocatorCheckLineStatus.missing:
        return Colors.red.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final loc = group.locator;
    final cardColor =
        group.allOk ? Colors.green.shade100 : Colors.pink.shade100;

    final headerSubtitle = group.allOk
        ? '${group.countAssigned} producto(s) asignado(s)'
        : '${group.countAssigned} asignado(s)  •  ${group.countMissing} faltante(s)';

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: <Widget>[
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            title: Text(
              loc.value ?? loc.name ?? '(no value)',
              style: const TextStyle(
                fontSize: themeFontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              headerSubtitle,
              style: const TextStyle(fontSize: themeFontSizeSmall),
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
            ),
          ),
          if (_expanded) _buildBreakdown(group),
        ],
      ),
    );
  }

  Widget _buildBreakdown(MovementMInOutCheckLocatorGroup group) {
    final entries = group.totalRequiredByProduct.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: <Widget>[
        const Divider(height: 1),
        ...entries.map((entry) {
          final productId = entry.key;
          final required = entry.value;
          final available = group.totalAvailableByProduct[productId] ?? 0;
          final status = group.statusForProduct(productId, required);

          final line = group.linesAssigned.firstWhere(
            (l) => l.product.id == productId,
          );
          final product = line.product;
          final upc = (product.uPC ?? '').trim();
          final name = (product.name ?? '').trim();

          return Material(
            color: _bgForLine(status),
            child: InkWell(
              onTap: () => _onLineTap(upc),
              onLongPress: () => _onLineLongPress(
                upc: upc,
                name: name,
                locatorValue: group.locator.value ??
                    group.locator.name ??
                    '(sin valor)',
                required: required,
                available: available,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            name.isEmpty ? '(no name)' : name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (upc.isNotEmpty)
                            Text(
                              'UPC: $upc',
                              style: const TextStyle(
                                fontSize: themeFontSizeSmall,
                              ),
                            ),
                          if (status == LocatorCheckLineStatus.missing)
                            const Text(
                              'No hay en este locator',
                              style: TextStyle(
                                fontSize: themeFontSizeSmall,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          'Req: ${_fmt(required)}',
                          style: const TextStyle(
                            fontSize: themeFontSizeSmall,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          'Stock: ${_fmt(available)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
