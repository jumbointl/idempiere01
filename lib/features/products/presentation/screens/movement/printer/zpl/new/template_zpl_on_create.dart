import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/new/template_zpl_on_create_editor_sheet.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

import '../../../../../../../shared/data/memory.dart';
import '../../../../../../common/messages_dialog.dart';
import '../../../../../providers/common_provider.dart';
import '../../../provider/new_movement_provider.dart';
import '../../printer_scan_notifier.dart';
import 'template_zpl_models.dart';
import 'template_zpl_utils.dart';
import 'template_zpl_preview_screen.dart';
import 'template_zpl_store.dart';
// (opcional) si separas editor

Future<void> showCreateZplTemplateDialog({
  required BuildContext context,
  required WidgetRef ref,
  required ZplTemplateStore store,
}) async {
  await showManageZplTemplatesSheet(
    context: context,
    ref: ref,
    store: store,
  );
  
}
Future<void> showManageZplTemplatesSheet({
  required BuildContext context,
  required WidgetRef ref,
  required ZplTemplateStore store,
}) async {
  await showModalBottomSheet(
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
      final height = MediaQuery.of(ctx).size.height * 0.90;
      int actualAction = ref.read(actionScanProvider);
      ref.read(actionScanProvider.notifier).state = Memory.ACTION_NO_SCAN_ACTION;
      ref.read(isDialogShowedProvider.notifier).state = true;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;
          }
          ref.read(enableScannerKeyboardProvider.notifier).state = true;
          ref.read(isDialogShowedProvider.notifier).state = false;
          ref.read(actionScanProvider.notifier).state = actualAction;
          Navigator.pop(context, null);
        },
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: _ManageTemplatesSheet(ref: ref, store: store),
        ),
      );
    },
  );
}

class _ManageTemplatesSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final ZplTemplateStore store;

  const _ManageTemplatesSheet({required this.ref, required this.store});

  @override
  ConsumerState<_ManageTemplatesSheet> createState() => _ManageTemplatesSheetState();
}

class _ManageTemplatesSheetState extends ConsumerState<_ManageTemplatesSheet> {
  late List<ZplTemplate> items;


  late int actualAction;

  @override
  void initState() {
    super.initState();
    items = widget.store.loadAll();
    ref.read(isDialogShowedProvider.notifier).state = true;
    actualAction = ref.read(actionScanProvider);
    ref.read(actionScanProvider.notifier).state = Memory.ACTION_NO_SCAN_ACTION;
  }
  @override
  dispose() {
    ref.read(isDialogShowedProvider.notifier).state = false;
    ref.read(actionScanProvider.notifier).state = actualAction;
    ref.read(enableScannerKeyboardProvider.notifier).state = true;

    super.dispose();
  }


  Future<void> reload() async => setState(() => items = widget.store.loadAll());

  String modeText(ZplTemplate t) =>
      t.mode == ZplTemplateMode.movement
          ? 'Modo: Movement (${t.rowPerpage})'
          : 'Modo: N/A (${t.rowPerpage})';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ===== Header =====
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Templates ZPL (Administrar)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                icon: const Icon(Icons.close),
                onPressed: () {
                    ref.read(enableScannerKeyboardProvider.notifier).state = true;
                    ref.read(isDialogShowedProvider.notifier).state = false;
                    ref.read(actionScanProvider.notifier).state = actualAction;
                    Navigator.pop(context);
                } ,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ===== Actions top =====
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final created = await showZplTemplateEditorDialogMode(
                    context: context,
                    store: widget.store,
                    ref: widget.ref,
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
                  items.isEmpty
                      ? 'No hay templates.'
                      : 'Preview / Enviar DF / Imprimir Reference / Editar / Borrar',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // ===== List =====
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No hay templates guardados.'))
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final t = items[i];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.black12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final edited = await showZplTemplateEditorDialogMode(
                      context: context,
                      store: widget.store,
                      initial: t,
                      ref: widget.ref,
                    );
                    if (edited != null) await reload();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ===== Row 1: Filename (ancho completo) =====
                        Row(
                          children: [
                            const Icon(Icons.description, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t.templateFileName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // ===== Row 2: Info =====
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                modeText(t),
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ),
                            Text(
                              _formatDateShort(t.createdAt),
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // ===== Row 3: Actions =====
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _miniAction(
                              tooltip: 'Preview',
                              icon: Icons.visibility,
                              onTap: () async {
                                final movementAndLines =
                                widget.ref.read(movementAndLinesProvider);

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

                                await showZplPreviewSheet(
                                  template: t,
                                  filledPreviewFirstPage: filled,
                                  filledPreviewAllPages: filledAll,
                                  missingTokens: missing,
                                  context: context,
                                );
                              },
                            ),
                            _miniAction(
                              tooltip: 'Enviar DF a impresora',
                              icon: Icons.upload,
                              onTap: () async {
                                final printerState =
                                widget.ref.read(printerScanProvider);
                                final ip = printerState.ipController.text.trim();
                                final port = int.tryParse(
                                  printerState.portController.text.trim(),
                                ) ??
                                    9100;
                                final df = t.zplTemplateDf.trim();
                                final canSendDf = df.isNotEmpty;
                                if (!canSendDf) {
                                  showWarningMessage(widget.ref.context, widget.ref, Messages.ERROR_EMPTY_DF);
                                  return;
                                }

                                if (ip.isEmpty) {
                                  showWarningMessage(widget.ref.context, widget.ref, 'IP inválida');
                                  return;
                                }

                                await sendZplBySocket(
                                  ip: ip,
                                  port: port,
                                  zpl: t.zplTemplateDf,
                                );
                              },
                            ),
                            _miniAction(
                              tooltip: 'Imprimir (Reference)',
                              icon: Icons.print,
                              onTap: () async {
                                final printerState =
                                widget.ref.read(printerScanProvider);
                                final ip = printerState.ipController.text.trim();
                                final port = int.tryParse(
                                  printerState.portController.text.trim(),
                                ) ??
                                    9100;

                                if (ip.isEmpty) {
                                  showWarningMessage(widget.ref.context, widget.ref, 'IP inválida');
                                  return;
                                }

                                final movementAndLines =
                                widget.ref.read(movementAndLinesProvider);

                                final missing = validateMissingTokens(
                                  template: t,
                                  referenceTxt: t.zplReferenceTxt,
                                );
                                if (missing.isNotEmpty) {
                                  showWarningMessage(
                                    widget.ref.context,
                                    widget.ref,
                                    'Tokens no soportados: ${missing.join(', ')}',
                                  );
                                  return;
                                }

                                await printReferenceBySocket(
                                  ip: ip,
                                  port: port,
                                  template: t,
                                  movementAndLines: movementAndLines,
                                );
                              },
                            ),
                            _miniAction(
                              tooltip: 'Editar',
                              icon: Icons.edit,
                              onTap: () async {
                                final edited = await showZplTemplateEditorDialogMode(
                                  context: context,
                                  store: widget.store,
                                  ref: widget.ref,
                                  initial: t,
                                );
                                if (edited != null) await reload();
                              },
                            ),
                            _miniAction(
                              tooltip: 'Borrar',
                              icon: Icons.delete,
                              onTap: () async {
                                await widget.store.deleteById(t.id);
                                await reload();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ===== Footer =====
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  ref.read(enableScannerKeyboardProvider.notifier).state = true;
                  ref.read(isDialogShowedProvider.notifier).state = false;
                  ref.read(actionScanProvider.notifier).state = actualAction;
                  Navigator.pop(context);
                },
                child: const Text('Cerrar'),
              ),
              const Spacer(),
              Text(
                'Total: ${items.length}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _miniAction({
  required String tooltip,
  required IconData icon,
  required Future<void> Function() onTap,
}) {
  return Tooltip(
    message: tooltip,
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async => await onTap(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18),
      ),
    ),
  );
}

String _formatDateShort(DateTime d) {
  String two(int x) => x.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}


