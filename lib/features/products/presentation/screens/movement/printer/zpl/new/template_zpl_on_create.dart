import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/new_movement_provider.dart';
import '../../printer_scan_notifier.dart';
import 'template_zpl_models.dart';
import 'template_zpl_utils.dart';
import 'template_zpl_preview_screen.dart';
import 'template_zpl_store.dart';
import 'template_zpl_on_create_editor.dart'; // (opcional) si separas editor

Future<void> showCreateZplTemplateDialog({
  required BuildContext context,
  required WidgetRef ref,
  required ZplTemplateStore store,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ManageTemplatesDialog(ref: ref, store: store),
  );
}

class _ManageTemplatesDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final ZplTemplateStore store;

  const _ManageTemplatesDialog({required this.ref, required this.store});

  @override
  ConsumerState<_ManageTemplatesDialog> createState() => _ManageTemplatesDialogState();
}

class _ManageTemplatesDialogState extends ConsumerState<_ManageTemplatesDialog> {
  late List<ZplTemplate> items;

  @override
  void initState() {
    super.initState();
    items = widget.store.loadAll();
  }

  Future<void> reload() async => setState(() => items = widget.store.loadAll());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Templates ZPL (Administrar)'),
      content: SizedBox(
        width: 920,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final created = await showZplTemplateEditorDialogMode(
                      context: context,
                      store: widget.store,
                      ref: ref,
                      initial: null,
                    );
                    if (created != null) await reload();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar nuevo'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    items.isEmpty ? 'No hay templates.' : 'Preview / Enviar DF / Imprimir Reference / Editar / Borrar.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final t = items[i];

                  return ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(t.templateFileName),
                    subtitle: Text(
                      t.mode == ZplTemplateMode.product ? 'Modo: Producto (8)' : 'Modo: Categoría (6)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          tooltip: 'Preview',
                          onPressed: () async {
                            final movementAndLines = ref.read(movementAndLinesProvider);
                            final filled = buildFilledPreviewFirstPage(template: t, movementAndLines: movementAndLines);
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
                                  filledPreviewFirstPage: filled,
                                  filledPreviewAllPages: filledAll,
                                  missingTokens: missing,
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility),
                        ),
                        IconButton(
                          tooltip: 'Enviar DF a impresora',
                          onPressed: () async {
                            final printerState = ref.read(printerScanProvider);
                            final ip = printerState.ipController.text.trim();
                            final port = int.tryParse(printerState.portController.text.trim()) ?? 9100;
                            if (ip.isEmpty) return;

                            await sendZplBySocket(ip: ip, port: port, zpl: t.zplTemplateDf);
                          },
                          icon: const Icon(Icons.upload),
                        ),
                        IconButton(
                          tooltip: 'Imprimir (Reference)',
                          onPressed: () async {
                            final printerState = ref.read(printerScanProvider);
                            final ip = printerState.ipController.text.trim();
                            final port = int.tryParse(printerState.portController.text.trim()) ?? 9100;
                            if (ip.isEmpty) return;

                            final movementAndLines = ref.read(movementAndLinesProvider);
                            await printReferenceBySocket(ip: ip, port: port, template: t, movementAndLines: movementAndLines);
                          },
                          icon: const Icon(Icons.print),
                        ),
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () async {
                            final edited = await showZplTemplateEditorDialogMode(
                              context: context,
                              store: widget.store,
                              ref: ref,
                              initial: t,
                            );
                            if (edited != null) await reload();
                          },
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          tooltip: 'Borrar',
                          onPressed: () async {
                            await widget.store.deleteById(t.id);
                            await reload();
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final edited = await showZplTemplateEditorDialogMode(
                        context: context,
                        store: widget.store,
                        initial: t,
                        ref: ref,
                      );
                      if (edited != null) await reload();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }
}
