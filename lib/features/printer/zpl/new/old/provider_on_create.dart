import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../products/presentation/providers/common_provider.dart';
import '../../../../products/presentation/providers/product_provider_common.dart';
import '../models/category_agg.dart';
import '../models/zpl_template.dart';
import '../provider/template_zpl_utils.dart';

/// BottomSheet con búsqueda.
/// Devuelve el token seleccionado o null si canceló.
Future<String?> showZplTokenPickerSheet({
  required WidgetRef ref,
  required BuildContext context,
  required ZplTemplateMode mode,
  required int rowsPerLabel,
}) async {
  final all = buildTokenCatalog(mode: mode, rowsPerLabel: rowsPerLabel);
  ref.read(enableScannerKeyboardProvider.notifier).state = false;
  ref.read(isDialogShowedProvider.notifier).state = true;
  return showModalBottomSheet<String>(
    isDismissible: false,
    enableDrag: false,
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {

      return StatefulBuilder(
        builder: (ctx, setState) {
          String q = '';
          final query = q.trim().toUpperCase();

          final filtered = (query.isEmpty)
              ? all
              : all.where((t) {
            final hay = '${t.section} ${t.token}'.toUpperCase();
            return hay.contains(query);
          }).toList();

          // Agrupar por sección (manteniendo orden)
          final sections = <String, List<TokenItem>>{};
          for (final item in filtered) {
            sections.putIfAbsent(item.section, () => []).add(item);
          }

          final height = MediaQuery.of(ctx).size.height * 0.85;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              if (didPop) {
                return;
              }
              ref.read(enableScannerKeyboardProvider.notifier).state = true;
              ref.read(isDialogShowedProvider.notifier).state = false;
              Navigator.pop(context, null);
            },
            child: SizedBox(
              height: height,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Buscar token',
                        hintText: 'Ej: PRODUCT_NAME, TOTAL, PAGE, CATEGORY_QTY…',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: (q.isEmpty)
                            ? null
                            : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => q = ''),
                        ),
                      ),
                      onChanged: (v) => setState(() => q = v),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      children: [
                        for (final entry in sections.entries) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          ...entry.value.map(
                                (it) => Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Colors.black12),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  it.token,
                                  style: const TextStyle(fontFamily: 'monospace'),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                onTap: () {
                                  ref.read(enableScannerKeyboardProvider.notifier).state = true;
                                  ref.read(isDialogShowedProvider.notifier).state = false;
                                  Navigator.pop(ctx, it.token);
                                },
                              ),
                            ),
                          ),
                        ],
                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No hay resultados.'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
List<TokenItem> buildTokenCatalog({
  required ZplTemplateMode mode,
  required int rowsPerLabel,
}) {
  final rows = rowsPerLabel.clamp(1, 50);
  final list = <TokenItem>[];

  // HEADER
  const header = 'HEADER';
  list.addAll([
    const TokenItem(header, DOCUMENT_NUMBER__),
    const TokenItem(header, DATE__),
    const TokenItem(header, STATUS__),
    const TokenItem(header, COMPANY__),
    const TokenItem(header, TITLE__),
    const TokenItem(header, ADDRESS__),
    const TokenItem(header, WAREHOUSE_FROM__),
    const TokenItem(header, WAREHOUSE_TO__),
  ]);

  // CATEGORY
  if (mode == ZplTemplateMode.movement) {
    const sec = 'LINE (por fila)';
    for (int i = 0; i < rows; i++) {
      list.add(TokenItem(sec, CATEGORY_SEQUENCE__(i)));
      list.add(TokenItem(sec, CATEGORY_NAME__(i)));
      list.add(TokenItem(sec, CATEGORY_QTY__(i)));
      list.add(TokenItem(sec, MOVEMENT_LINE_LINE__(i)));
      list.add(TokenItem(sec, MOVEMENT_LINE_MOVEMENT_QTY__(i)));
      list.add(TokenItem(sec, PRODUCT_SQCUENCE__(i)));
      list.add(TokenItem(sec, PRODUCT_NAME__(i)));
      list.add(TokenItem(sec, PRODUCT_UPC__(i)));
      list.add(TokenItem(sec, PRODUCT_SKU__(i)));
      list.add(TokenItem(sec, PRODUCT_ATT__(i)));
    }
  }

  // FOOTER
  const footer = 'FOOTER';
  list.addAll([
    const TokenItem(footer, TOTAL_QUANTITY__),
    const TokenItem(footer, PAGE_NUMBER_OVER_TOTAL_PAGE__),
    const TokenItem(footer, GENERATED_BY__),
  ]);

  return list;
}