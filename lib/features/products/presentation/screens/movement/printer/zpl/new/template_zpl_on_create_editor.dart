import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/new/template_zpl_preview_screen.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/new/template_zpl_store.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/new/template_zpl_utils.dart';

import '../../../../../../common/messages_dialog.dart';
import '../../../provider/new_movement_provider.dart';
import '../../printer_scan_notifier.dart';
import 'template_zpl_models.dart';
Future<ZplTemplate?> showZplTemplateEditorDialogMode({
  required BuildContext context,
  required ZplTemplateStore store,
  ZplTemplate? initial,
  required WidgetRef ref,
}) async {
  // ======================
  // Estado inicial
  // ======================
  late ZplTemplateMode mode;

  // ✅ inicializar una sola vez
  mode = initial?.mode ?? ZplTemplateMode.category;

  final nameCtrl = TextEditingController(
    text: initial?.templateFileName ??
        (mode == ZplTemplateMode.category
            ? 'E:TEMPLATE_CATEGORY.ZPL'
            : 'E:TEMPLATE_PRODUCT.ZPL'),
  );

  final dfCtrl = TextEditingController(text: initial?.zplTemplateDf ?? '');
  final refCtrl = TextEditingController(text: initial?.zplReferenceTxt ?? '');

  int rowsPerLabel(ZplTemplateMode m) => m == ZplTemplateMode.category ? 6 : 8;

  String stripDrive(String file) {
    final idx = file.indexOf(':');
    return (idx >= 0 && idx < file.length - 1) ? file.substring(idx + 1) : file;
  }

  // ======================
  // Cargar ejemplos
  // ======================
  void loadExampleForMode() {
    final file = nameCtrl.text.trim().isEmpty
        ? (mode == ZplTemplateMode.category
        ? 'E:TEMPLATE_CATEGORY.ZPL'
        : 'E:TEMPLATE_PRODUCT.ZPL')
        : nameCtrl.text.trim();

    if (nameCtrl.text.trim().isEmpty) {
      nameCtrl.text = file;
    }

    // DF solo si es nuevo y está vacío
    if (initial == null && dfCtrl.text.trim().isEmpty) {
      if (mode == ZplTemplateMode.category) {
        dfCtrl.text = buildTemplateZpl100x150ByCategoryDf(
          printerFile: file,
          rowsPerLabel: 6,
        );
      } else {
        // DF de producto puede ser reemplazado luego por el layout real
        dfCtrl.text = '''
^XA
^DF$file^FS
^XZ
'''.trim();
      }
    }

    // Reference siempre se puede regenerar como ejemplo
    if (mode == ZplTemplateMode.category) {
      refCtrl.text = buildReferenceTxtByCategory(
        templateFileNameNoDrive: stripDrive(file),
      );
    } else {
      refCtrl.text = buildReferenceProductExample(
        templateFileNoDrive: stripDrive(file),
      );
    }
  }

  if (initial == null) {
    loadExampleForMode();
  }

  // ======================
  // Insertar token en cursor
  // ======================
  void insertAtCursor(TextEditingController c, String text) {
    final sel = c.selection;
    final start = sel.start < 0 ? c.text.length : sel.start;
    final end = sel.end < 0 ? c.text.length : sel.end;

    c.text = c.text.replaceRange(start, end, text);
    c.selection = TextSelection.collapsed(offset: start + text.length);
  }

  // ======================
  // Dialog
  // ======================
  return showDialog<ZplTemplate>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final rows = rowsPerLabel(mode);

        return AlertDialog(
          title: Text(initial == null ? 'Nuevo template ZPL' : 'Editar template ZPL'),
          content: SizedBox(
            width: 880,
            child: SingleChildScrollView(
              child: Column(
                children: [

                  // ======================
                  // Barra superior
                  // ======================
                  // ===== Botones acciones rápidas: Preview / Enviar DF / Imprimir Reference =====
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Preview (DF / REF / Filled 1ra pág)
                          final movementAndLines = ref.read(movementAndLinesProvider);
                          final temp = (initial ??
                              ZplTemplate(
                                id: 'TEMP',
                                templateFileName: nameCtrl.text.trim(),
                                zplTemplateDf: dfCtrl.text,
                                zplReferenceTxt: refCtrl.text,
                                mode: mode,
                                createdAt: DateTime.now(),
                              ))
                              .copyWith(
                            templateFileName: nameCtrl.text.trim(),
                            zplTemplateDf: dfCtrl.text,
                            zplReferenceTxt: refCtrl.text,
                            mode: mode,
                          );

                          final filled = buildFilledPreviewFirstPage(
                            template: temp,
                            movementAndLines: movementAndLines,
                          );
                          final filledAll = buildFilledPreviewAllPages(
                            template: temp,
                            movementAndLines: movementAndLines,
                          );

                          final missing = validateMissingTokens(
                            template: temp,
                            referenceTxt: temp.zplReferenceTxt,
                          );

                          await showDialog(
                            context: context,
                            builder: (_) => ZplPreviewDialog(
                              template: temp,
                              filledPreviewFirstPage: filled,
                              filledPreviewAllPages: filledAll,
                              missingTokens: missing,
                              // ✅ callbacks para acciones desde preview
                              onSendDf: () async {
                                final printerState = ref.read(printerScanProvider);
                                final ip = printerState.ipController.text.trim();
                                final port = int.tryParse(printerState.portController.text.trim()) ?? 0;
                                if (ip.isEmpty || port == 0) {
                                  showWarningMessage(ref.context, ref, 'IP/PORT inválido');
                                  return;
                                }
                                await sendZplBySocket(ip: ip, port: port, zpl: temp.zplTemplateDf);
                              },
                              onPrintReference: () async {
                                final printerState = ref.read(printerScanProvider);
                                final ip = printerState.ipController.text.trim();
                                final port = int.tryParse(printerState.portController.text.trim()) ?? 0;
                                if (ip.isEmpty || port == 0) {
                                  showWarningMessage(ref.context, ref, 'IP/PORT inválido');
                                  return;
                                }
                                await printReferenceBySocket(
                                  ip: ip,
                                  port: port,
                                  template: temp,
                                  movementAndLines: movementAndLines,
                                );
                              },
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Preview'),
                      ),
                      const SizedBox(width: 8),

                      ElevatedButton.icon(
                        onPressed: () async {
                          // ✅ 1) Enviar DF (instalar template)
                          final printerState = ref.read(printerScanProvider);
                          final ip = printerState.ipController.text.trim();
                          final port = int.tryParse(printerState.portController.text.trim()) ?? 0;

                          if (ip.isEmpty || port == 0) {
                            showWarningMessage(ref.context, ref, 'IP/PORT inválido');
                            return;
                          }

                          await sendZplBySocket(ip: ip, port: port, zpl: dfCtrl.text);
                        },
                        icon: const Icon(Icons.upload),
                        label: const Text('Enviar DF'),
                      ),
                      const SizedBox(width: 8),

                      ElevatedButton.icon(
                        onPressed: () async {
                          // ✅ 2) Imprimir Reference (rellenar + paginar + socket)
                          final printerState = ref.read(printerScanProvider);
                          final ip = printerState.ipController.text.trim();
                          final port = int.tryParse(printerState.portController.text.trim()) ?? 0;

                          if (ip.isEmpty || port == 0) {
                            showWarningMessage(ref.context, ref, 'IP/PORT inválido');
                            return;
                          }

                          final movementAndLines = ref.read(movementAndLinesProvider);

                          final temp = (initial ??
                              ZplTemplate(
                                id: 'TEMP',
                                templateFileName: nameCtrl.text.trim(),
                                zplTemplateDf: dfCtrl.text,
                                zplReferenceTxt: refCtrl.text,
                                mode: mode,
                                createdAt: DateTime.now(),
                              ))
                              .copyWith(
                            templateFileName: nameCtrl.text.trim(),
                            zplTemplateDf: dfCtrl.text,
                            zplReferenceTxt: refCtrl.text,
                            mode: mode,
                          );

                          await printReferenceBySocket(
                            ip: ip,
                            port: port,
                            template: temp,
                            movementAndLines: movementAndLines,
                          );
                        },
                        icon: const Icon(Icons.print),
                        label: const Text('Imprimir Reference'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ZplTemplateMode>(
                          value: mode,
                          decoration: const InputDecoration(
                            labelText: 'Modo del template',
                            border: OutlineInputBorder(),
                          ),
                          items: ZplTemplateMode.values
                              .map(
                                (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m == ZplTemplateMode.category
                                    ? 'Categoría (6 filas)'
                                    : 'Producto (8 filas)',
                              ),
                            ),
                          )
                              .toList(),
                          onChanged: initial != null
                              ? null
                              : (Enum? m) {
                            if (m == null) return;
                            setState(() {
                              mode = m as ZplTemplateMode; // ✅ cast explícito
                              loadExampleForMode();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => setState(loadExampleForMode),
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('Cargar ejemplo'),
                      ),
                      const SizedBox(width: 10),
                      PopupMenuButton<String>(
                        tooltip: 'Insertar token',
                        itemBuilder: (_) =>
                            tokenMenuItemsByMode(mode: mode, rowsPerLabel: rows),
                        onSelected: (token) =>
                            setState(() => insertAtCursor(refCtrl, token)),
                        child: ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.control_point_duplicate),
                          label: const Text('Insertar token'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ======================
                  // Nombre template
                  // ======================
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del template en impresora',
                      hintText:
                      'Ej: E:TEMPLATE_CATEGORY.ZPL / E:TEMPLATE_PRODUCT.ZPL',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ======================
                  // DF
                  // ======================
                  TextField(
                    controller: dfCtrl,
                    minLines: 10,
                    maxLines: 18,
                    decoration: const InputDecoration(
                      labelText: 'TEMPLATE.ZPL (DF – crear plantilla)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ======================
                  // Reference
                  // ======================
                  TextField(
                    controller: refCtrl,
                    minLines: 14,
                    maxLines: 22,
                    decoration: InputDecoration(
                      labelText:
                      'REFERENCE.TXT (XF + FN + TOKENS) — ${stripDrive(nameCtrl.text)}',
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Desistir'),
            ),
            ElevatedButton(
              onPressed: () async {
                final file = nameCtrl.text.trim();
                if (file.isEmpty) return;

                final result = (initial ??
                    ZplTemplate(
                      id: DateTime.now()
                          .millisecondsSinceEpoch
                          .toString(),
                      templateFileName: file,
                      zplTemplateDf: dfCtrl.text,
                      zplReferenceTxt: refCtrl.text,
                      mode: mode,
                      createdAt: DateTime.now(),
                    ))
                    .copyWith(
                  templateFileName: file,
                  zplTemplateDf: dfCtrl.text,
                  zplReferenceTxt: refCtrl.text,
                  mode: mode,
                );

                await store.upsert(result);
                if (ctx.mounted) Navigator.pop(ctx, result);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ),
  );
}
