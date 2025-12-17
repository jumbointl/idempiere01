import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/new_movement_provider.dart';
import '../../printer_scan_notifier.dart';
import 'template_zpl_models.dart';
import 'template_zpl_utils.dart';
import 'template_zpl_preview_screen.dart';
import 'template_zpl_store.dart'; // recomendado

Future<ZplTemplate?> showUseZplTemplateDialog({
  required BuildContext context,
  required WidgetRef ref,
  required ZplTemplateStore store,
}) {
  return showDialog<ZplTemplate>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UseZplTemplateDialog(ref: ref, store: store),
  );
}

class _UseZplTemplateDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final ZplTemplateStore store;

  const _UseZplTemplateDialog({required this.ref, required this.store});

  @override
  ConsumerState<_UseZplTemplateDialog> createState() => _UseZplTemplateDialogState();
}

class _UseZplTemplateDialogState extends ConsumerState<_UseZplTemplateDialog> {
  late List<ZplTemplate> items;
  String? selectedId;

  @override
  void initState() {
    super.initState();
    items = widget.store.loadAll();
    if (items.isNotEmpty) selectedId = items.first.id;
  }

  ZplTemplate? get selected => (selectedId == null)
      ? null
      : items.where((e) => e.id == selectedId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final t = selected;

    return AlertDialog(
      title: const Text('Usar template ZPL'),
      content: SizedBox(
        width: 820,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final x = items[i];
                  return ListTile(
                    leading: Radio<String>(
                      value: x.id,
                      groupValue: selectedId,
                      onChanged: (v) => setState(() => selectedId = v),
                    ),
                    title: Text(x.templateFileName),
                    subtitle: Text(
                      x.mode == ZplTemplateMode.product ? 'Modo: Producto (8)' : 'Modo: Categoría (6)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () => setState(() => selectedId = x.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: (t == null)
                      ? null
                      : () async {
                    final movementAndLines = ref.read(movementAndLinesProvider);
                    final filled = buildFilledPreviewFirstPage(
                      template: t,
                      movementAndLines: movementAndLines,
                    );
                    final filledAll = buildFilledPreviewAllPages(
                      template: t,
                      movementAndLines: movementAndLines,
                    );

                    final missing = validateMissingTokens(
                      template: t,
                      referenceTxt: t.zplReferenceTxt,
                    );
                    await showDialog(
                      context: context,
                      builder: (_) => ZplPreviewDialog(
                          template: t,
                          missingTokens: missing,
                          filledPreviewFirstPage: filled ,
                          filledPreviewAllPages: filledAll,
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Preview'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: (t == null)
                      ? null
                      : () async {
                    final printerState = ref.read(printerScanProvider);
                    final ip = printerState.ipController.text.trim();
                    final port = int.tryParse(printerState.portController.text.trim()) ?? 9100;
                    if (ip.isEmpty) return;

                    final movementAndLines = ref.read(movementAndLinesProvider);
                    await printReferenceBySocket(
                      ip: ip,
                      port: port,
                      template: t,
                      movementAndLines: movementAndLines,
                    );
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimir (Reference)'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cerrar')),
        ElevatedButton(
          onPressed: (t == null) ? null : () => Navigator.pop(context, t),
          child: const Text('Usar'),
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
