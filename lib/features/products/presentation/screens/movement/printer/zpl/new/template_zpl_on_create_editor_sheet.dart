import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/new/zpl_printer_setting.dart';

import '../../../../../../../../config/theme/app_theme.dart';
import '../../../../../../../shared/data/memory.dart';
import '../../../../../../common/messages_dialog.dart';
import '../../../../../../common/widget_utils.dart';
import '../../../provider/new_movement_provider.dart';
import '../../printer_scan_notifier.dart';

import 'template_zpl_models.dart';
import 'template_zpl_store.dart';
import 'template_zpl_utils.dart';
import 'template_zpl_preview_screen.dart';

Future<ZplTemplate?> showZplTemplateEditorDialogMode({
  required BuildContext context,
  required WidgetRef ref,
  required ZplTemplateStore store,
  ZplTemplate? initial,
}) async {
  ZplTemplateMode mode =
      initial?.mode ?? ZplTemplateMode.movement;
  final bool isAdmin = Memory.isAdmin == true;
  final nameCtrl = TextEditingController(
    text: initial?.templateFileName ??
        (mode == ZplTemplateMode.movement
            ? 'E:MOVEMENT_BY_LINE_TEMPLATE.ZPL'
            : 'E:TEMPLATE.ZPL'),
  );

  final dfCtrl =
  TextEditingController(text: initial?.zplTemplateDf ?? '');
  final refCtrl = TextEditingController(
      text: initial?.zplReferenceTxt ?? '');

  final rowPerpageCtrl = TextEditingController(
    text: (initial?.rowPerpage ??
        (mode == ZplTemplateMode.movement ? 8 : 8))
        .toString(),
  );

  int currentRows() {
    final v = int.tryParse(rowPerpageCtrl.text.trim());
    if (v == null || v <= 0) {
      return mode == ZplTemplateMode.movement ? 8 : 8;
    }
    return v.clamp(1, 80);
  }

  void loadExampleForMode() {
    final file = nameCtrl.text.trim().isEmpty
        ? (mode == ZplTemplateMode.movement
        ? 'E:MOVEMENT_BY_LINE_TEMPLATE.ZPL.ZPL'
        : 'E:TEMPLATE.ZPL')
        : nameCtrl.text.trim();

    if (nameCtrl.text.trim().isEmpty) {
      nameCtrl.text = file;
    }

    if (initial == null && dfCtrl.text.trim().isEmpty) {
      dfCtrl.text = '''
^XA
^DFE:MOVEMENT_BY_LINE_TEMPLATE.ZPL^FS
^CI28
^PW800
^LL1200
^LH0,0
^LS0
^PR3


^FO20,20
^BQN,2,8
^FN1^FS

^FO192,24^FB572,1,0,R^A0N,44,32^FN2^FS
^FO192,76^FB286,1,0,C^A0N,24,18^FN3^FS
^FO478,76^FB286,1,0,R^A0N,24,18^FN4^FS

^FO192,108^FB572,1,0,R^A0N,38,28^FN6^FS
^FO192,148^FB572,1,0,R^A0N,30,22^FN5^FS

^FO192,184^FB572,1,0,R^A0N,22,18^FN7^FS
^FO192,212^FB572,1,0,R^A0N,22,18^FN8^FS
^FO192,240^FB572,1,0,R^A0N,22,18^FN9^FS

^FO20,300^GB744,2,2^FS
^FO20,330^A0N,22,18^FDLINE^FS
^FO90,330^A0N,22,18^FDPRODUCT NAME^FS
^FO624,330^FB140,1,0,R^A0N,22,18^FDQTY^FS
^FO20,382^GB744,2,2^FS

^FO20,412^FB70,1,0,L^A0N,24,18^FN101^FS
^FO90,412^FB534,1,0,L^A0N,24,18^FN102^FS
^FO624,412^FB140,1,0,R^A0N,28,22^FN103^FS
^FO20,466^GB744,1,1^FS

^FO20,492^FB70,1,0,L^A0N,24,18^FN104^FS
^FO90,492^FB534,1,0,L^A0N,24,18^FN105^FS
^FO624,492^FB140,1,0,R^A0N,28,22^FN106^FS
^FO20,546^GB744,1,1^FS

^FO20,572^FB70,1,0,L^A0N,24,18^FN107^FS
^FO90,572^FB534,1,0,L^A0N,24,18^FN108^FS
^FO624,572^FB140,1,0,R^A0N,28,22^FN109^FS
^FO20,626^GB744,1,1^FS

^FO20,652^FB70,1,0,L^A0N,24,18^FN110^FS
^FO90,652^FB534,1,0,L^A0N,24,18^FN111^FS
^FO624,652^FB140,1,0,R^A0N,28,22^FN112^FS
^FO20,706^GB744,1,1^FS

^FO20,732^FB70,1,0,L^A0N,24,18^FN113^FS
^FO90,732^FB534,1,0,L^A0N,24,18^FN114^FS
^FO624,732^FB140,1,0,R^A0N,28,22^FN115^FS
^FO20,786^GB744,1,1^FS

^FO20,812^FB70,1,0,L^A0N,24,18^FN116^FS
^FO90,812^FB534,1,0,L^A0N,24,18^FN117^FS
^FO624,812^FB140,1,0,R^A0N,28,22^FN118^FS
^FO20,866^GB744,1,1^FS

^FO20,892^FB70,1,0,L^A0N,24,18^FN119^FS
^FO90,892^FB534,1,0,L^A0N,24,18^FN120^FS
^FO624,892^FB140,1,0,R^A0N,28,22^FN121^FS
^FO20,946^GB744,1,1^FS

^FO20,972^FB70,1,0,L^A0N,24,18^FN122^FS
^FO90,972^FB534,1,0,L^A0N,24,18^FN123^FS
^FO624,972^FB140,1,0,R^A0N,28,22^FN124^FS
^FO20,1026^GB744,1,1^FS

^FO20,1060^FB360,1,0,L^A0N,28,20^FDTOTAL QTY : ^FS
^FO380,1060^FB384,1,0,R^A0N,28,20^FN901^FS

^FO20,1090^GB744,2,2^FS
^FO644,1120^FB120,1,0,R^A0N,28,20^FN902^FS

^XZ
'''.trim();
    }

    if (initial == null && refCtrl.text.trim().isEmpty) {
      refCtrl.text =
"""
^XA
^CI28
^XFE:MOVEMENT_BY_LINE_TEMPLATE.ZPL^FS

^FN1^FDLA,__DOCUMENT_NUMBER^FS
^FN2^FD__DOCUMENT_NUMBER^FS
^FN3^FD__DATE^FS
^FN4^FD__STATUS^FS
^FN5^FD__TITLE^FS
^FN6^FD__COMPANY^FS

^FN7^FD__ADDRESS^FS
^FN8^FD__WAREHOUSE_FROM^FS
^FN9^FD__WAREHOUSE_TO^FS

^FN101^FD__MOVEMENT_LINE_LINE0^FS
^FN102^FD__PRODUCT_NAME0^FS
^FN103^FD__MOVEMENT_LINE_MOVEMENT_QTY0^FS

^FN104^FD__MOVEMENT_LINE_LINE1^FS
^FN105^FD__PRODUCT_NAME1^FS
^FN106^FD__MOVEMENT_LINE_MOVEMENT_QTY1^FS

^FN107^FD__MOVEMENT_LINE_LINE2^FS
^FN108^FD__PRODUCT_NAME2^FS
^FN109^FD__MOVEMENT_LINE_MOVEMENT_QTY2^FS

^FN110^FD__MOVEMENT_LINE_LINE3^FS
^FN111^FD__PRODUCT_NAME3^FS
^FN112^FD__MOVEMENT_LINE_MOVEMENT_QTY3^FS

^FN113^FD__MOVEMENT_LINE_LINE4^FS
^FN114^FD__PRODUCT_NAME4^FS
^FN115^FD__MOVEMENT_LINE_MOVEMENT_QTY4^FS

^FN116^FD__MOVEMENT_LINE_LINE5^FS
^FN117^FD__PRODUCT_NAME5^FS
^FN118^FD__MOVEMENT_LINE_MOVEMENT_QTY5^FS

^FN119^FD__MOVEMENT_LINE_LINE6^FS
^FN120^FD__PRODUCT_NAME6^FS
^FN121^FD__MOVEMENT_LINE_MOVEMENT_QTY6^FS

^FN122^FD__MOVEMENT_LINE_LINE7^FS
^FN123^FD__PRODUCT_NAME7^FS
^FN124^FD__MOVEMENT_LINE_MOVEMENT_QTY7^FS

^FN901^FD__TOTAL_QUANTITY^FS
^FN902^FD__PAGE_NUMBER_OVER_TOTAL_PAGE^FS

^PQ1
^XZ
""".trim();
      //'^XA\n^XFE:${stripDrive(file)}^FS\n^PQ1\n^XZ';
    }

    if (initial == null &&
        rowPerpageCtrl.text.trim().isEmpty) {
      rowPerpageCtrl.text =
          (mode == ZplTemplateMode.movement ? 8 : 8)
              .toString();
    }
  }

  void insertAtCursor(
      TextEditingController c, String text) {
    final sel = c.selection;
    final start =
    sel.start < 0 ? c.text.length : sel.start;
    final end = sel.end < 0 ? c.text.length : sel.end;
    c.text = c.text.replaceRange(start, end, text);
    c.selection =
        TextSelection.collapsed(offset: start + text.length);
  }

  Future<void> doSendDf() async {
    if (!Memory.isAdmin) {
      showWarningMessage(context, ref, 'Solo administradores pueden enviar DF');
      return;
    }

    final df = dfCtrl.text.trim();
    if (df.isEmpty) {
      showWarningMessage(context, ref, 'DF vacío');
      return;
    }

    final printerState = ref.read(printerScanProvider);
    final ip = printerState.ipController.text.trim();
    final port = int.tryParse(printerState.portController.text.trim()) ?? 0;
    final type = printerState.typeController.text.trim();

    if (ip.isEmpty || port == 0) {
      showWarningMessage(context, ref, 'IP/PORT inválido');
      return;
    }

    try {
      await sendZplBySocket(ip: ip, port: port, zpl: df);
      showSuccessMessage(context, ref, 'Template enviado correctamente (DF)');
    } catch (e) {
      showWarningMessage(context, ref, 'Error al enviar DF: $e');
    }
  }


  Future<void> doPrintReference({
    required ZplTemplateMode m,
    required int rows,
  }) async {
    final printerState = ref.read(printerScanProvider);
    final ip = printerState.ipController.text.trim();
    final port = int.tryParse(printerState.portController.text.trim()) ?? 0;

    if (ip.isEmpty || port == 0) {
      showWarningMessage(context, ref, 'IP/PORT inválido');
      return;
    }

    final movementAndLines = ref.read(movementAndLinesProvider);

    final temp = (initial ??
        ZplTemplate(
          id: 'TEMP',
          templateFileName: nameCtrl.text.trim(),
          zplTemplateDf: dfCtrl.text,
          zplReferenceTxt: refCtrl.text,
          mode: m,
          rowPerpage: rows,
          isDefault: false,
          createdAt: DateTime.now(),
        ))
        .copyWith(
      templateFileName: nameCtrl.text.trim(),
      zplTemplateDf: dfCtrl.text,
      zplReferenceTxt: refCtrl.text,
      mode: m,
      rowPerpage: rows,
    );

    final missing = validateMissingTokens(
      template: temp,
      referenceTxt: temp.zplReferenceTxt,
    );

    if (missing.isNotEmpty) {
      showWarningMessage(
        context,
        ref,
        'Faltan tokens: ${missing.join(', ')}',
      );
      return;
    }
    try {
        await printReferenceBySocket(
          ip: ip,
          port: port,
          template: temp,
          movementAndLines: movementAndLines,
        );
        if(context.mounted) {
          showSuccessMessage(context, ref, 'Impreso correctamente');
        }
    } catch(e) {
      if(context.mounted)showWarningMessage(context, ref, 'Error al imprimir: $e');
      return;
    }

  }


  Future<void> doPreview({
    required ZplTemplateMode m,
    required int rows,
  }) async {
    final movementAndLines =
    ref.read(movementAndLinesProvider);

    final temp = (initial ??
        ZplTemplate(
          id: 'TEMP',
          templateFileName: nameCtrl.text.trim(),
          zplTemplateDf: dfCtrl.text,
          zplReferenceTxt: refCtrl.text,
          mode: m,
          isDefault: false,
          rowPerpage: rows,
          createdAt: DateTime.now(),
        ))
        .copyWith(
      templateFileName: nameCtrl.text.trim(),
      zplTemplateDf: dfCtrl.text,
      zplReferenceTxt: refCtrl.text,
      mode: m,
      rowPerpage: rows,
    );

    final filledFirst =
    buildFilledPreviewFirstPage(
      template: temp,
      movementAndLines: movementAndLines,
    );
    final filledAll =
    buildFilledPreviewAllPages(
      template: temp,
      movementAndLines: movementAndLines,
    );

    final missing = validateMissingTokens(
      template: temp,
      referenceTxt: temp.zplReferenceTxt,
    );

    await showZplPreviewSheet(
      context: context,
      template: temp,
      filledPreviewFirstPage: filledFirst,
      filledPreviewAllPages: filledAll,
      missingTokens: missing,
      onSendDf: temp.zplTemplateDf.trim().isEmpty
          ? null
          : () async => await doSendDf(),
      onPrintReference: () async =>
      await doPrintReference(m: m, rows: rows),
    );
  }

  if (initial == null) loadExampleForMode();

  return showModalBottomSheet<ZplTemplate>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final height =
          MediaQuery.of(ctx).size.height * 0.9;

      return SizedBox(
        height: height,
        width: double.infinity,
        child: StatefulBuilder(
          builder: (ctx, setState) {
            final rows = currentRows();
            final canSendDf =
                dfCtrl.text.trim().isNotEmpty && isAdmin;

            return Column(
              children: [
                Padding(
                  padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          initial == null
                              ? 'Nuevo template ZPL'
                              : 'Editar template ZPL',
                          style: Theme.of(ctx)
                              .textTheme
                              .titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            Navigator.pop(ctx, null),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ===== BODY =====
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // mode + rows + ejemplo
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormFieldScreenInput<ZplTemplateMode>(
                                label: 'Modo del template',
                                value: mode,
                                height: 46,
                                items: ZplTemplateMode.values
                                    .map(
                                      (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      m == ZplTemplateMode.movement ? 'Movement' : 'N/A',
                                      style: TextStyle(fontSize: themeFontSizeSmall),
                                    ),
                                  ),
                                )
                                    .toList(),
                                onChanged: initial != null
                                    ? null
                                    : (m) {
                                  if (m == null) return;
                                  setState(() {
                                    mode = m;
                                    if (rowPerpageCtrl.text.trim().isEmpty) {
                                      rowPerpageCtrl.text =
                                          (mode == ZplTemplateMode.movement ? 8 : 8).toString();
                                    }
                                    loadExampleForMode();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 100,
                              child: EditableFieldScreenInput(
                                label: 'Table rows',
                                controller: rowPerpageCtrl,
                                history: false,
                                title: 'Table rows',
                                numberOnly: true,
                                height: 46, // ✅ ahora sí funciona
                                onChangedAfterDialog: (_, __) => setState(() {}),
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                //minimumSize: const Size(0, 48),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onPressed: () => setState(loadExampleForMode),
                              icon: const Icon(Icons.auto_fix_high),
                              label: const Text('Ejemplo'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),


                        // acciones

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if(canSendDf)Expanded(
                              child: ElevatedButton.icon(
                                style:
                                ElevatedButton.styleFrom(
                                  minimumSize:
                                  const Size(0, 48),
                                ),
                                onPressed: canSendDf
                                    ? () async => await doSendDf()
                                    : null,
                                icon:
                                const Icon(Icons.upload),
                                label:
                                const Text('Enviar DF'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style:
                                ElevatedButton.styleFrom(
                                  minimumSize:
                                  const Size(0, 48),
                                ),
                                onPressed: () => doPrintReference(
                                  m: mode,
                                  rows: rows,
                                ),
                                icon:
                                const Icon(Icons.print),
                                label: Text(
                                    'Imprimir ($rows filas)'),
                              ),
                            ),

                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style:
                                ElevatedButton.styleFrom(
                                  minimumSize:
                                  const Size(0, 48),
                                ),
                                onPressed: () =>
                                    doPreview(m: mode, rows: rows),
                                icon:
                                const Icon(Icons.visibility),
                                label: const Text('Preview'),
                              ),
                            ),

                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style:
                                ElevatedButton.styleFrom(
                                  minimumSize:
                                  const Size(0, 48),
                                ),
                                onPressed: () async {
                                  final token =
                                  await showZplTokenPickerSheet(
                                    context: context,
                                    mode: mode,
                                    rowsPerLabel: rows,
                                  );
                                  if (token == null) return;
                                  setState(() =>
                                      insertAtCursor(refCtrl, token));
                                },
                                icon: const Icon(
                                    Icons.control_point_duplicate),
                                label: const Text('Tokens'),
                              ),
                            ),
                          ],
                        ),
                        if(canSendDf)SizedBox(height: 12),
                        if(canSendDf)Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            // ===== CON RIBBON =====
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  backgroundColor: Colors.green.shade600,
                                ),
                                onPressed: () async {
                                  await sendRibbonCommand(
                                    context: context,
                                    ref: ref,
                                    useRibbon: true,
                                  );
                                },
                                icon: const Icon(Icons.local_offer),
                                label: const Text('Use ribbon'),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // ===== SIN RIBBON =====
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  backgroundColor: Colors.orange.shade700,
                                ),
                                onPressed: () async {
                                  await sendRibbonCommand(
                                    context: context,
                                    ref: ref,
                                    useRibbon: false,
                                  );
                                },
                                icon: const Icon(Icons.print),
                                label: const Text('No ribbon'),
                              ),
                            ),
                          ],
                        ),

                        if (!canSendDf)
                          Padding(
                            padding:
                            const EdgeInsets.only(top: 10),
                            child: Container(
                              width: double.infinity,
                              padding:
                              const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade200,
                                border: Border.all(
                                    color: Colors.blue.shade500),
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'DF vacío: permitido. Se asume template existente en la impresora. '
                                    'No se enviará DF; solo se imprimirá usando Reference (^XFE).',
                                style:
                                TextStyle(fontSize: 12),
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        // ===== Nombre =====
                        EditableFieldScreenInput(
                          maxLines: 3,
                          height: 46,
                          label: 'Nombre del template en impresora',
                          controller: nameCtrl,
                          history: false,
                          title: 'Nombre del template en impresora',
                          numberOnly: false,
                          onChangedAfterDialog: (ref, newValue) {
                            setState(() {}); // refresca preview
                          },
                        ),

                        const SizedBox(height: 12),
                          /*isAdmin ? EditableFieldScreenInput(
                          maxLines: 14,
                          label: 'TEMPLATE (DF) (opcional)',
                          controller: dfCtrl,
                          history: false,
                          title:  'TEMPLATE (DF) (opcional)',
                          numberOnly: false,
                          onChangedAfterDialog: (ref, newValue) {
                          setState(() {}); // refresca preview
                          },
                          )*/
                        isAdmin ? TextField(
                          controller: dfCtrl,
                          minLines: 6,
                          maxLines: 14,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'TEMPLATE (DF) (opcional)',
                            border:
                            OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) =>
                              setState(() {}),
                        ) :
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade200,
                            border: Border.all(color: Colors.blue.shade500),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Modo usuario: este sistema usa templates ya cargados en la impresora.\n'
                                'La impresión se realiza únicamente por Reference (^XFE).',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: refCtrl,
                          minLines: 10,
                          maxLines: 20,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'REFERENCE (XF + tokens)',
                            border:
                            OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1),
                Padding(
                  padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(ctx, null),
                        child:
                        const Text('Desistir'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          final file =
                          nameCtrl.text.trim();
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
                                rowPerpage: rows,
                                isDefault: false,
                                createdAt:
                                DateTime.now(),
                              ))
                              .copyWith(
                            templateFileName: file,
                            zplTemplateDf: dfCtrl.text,
                            zplReferenceTxt: refCtrl.text,
                            mode: mode,
                            rowPerpage: rows,
                          );

                          await store.upsert(result);
                          if (ctx.mounted) {
                            Navigator.pop(ctx, result);
                          }
                        },
                        child:
                        const Text('Guardar'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

String get referenceTxtOfMovementByProductTxt {
  return
    """
^XA
^CI28
^XFE:MOVEMENT_BY_LINE_TEMPLATE.ZPL^FS

^FN1^FDLA,__DOCUMENT_NUMBER^FS
^FN2^FD__DOCUMENT_NUMBER^FS
^FN3^FD__DATE^FS
^FN4^FD__STATUS^FS
^FN5^FD__TITLE^FS
^FN6^FD__COMPANY^FS

^FN7^FD__ADDRESS^FS
^FN8^FD__WAREHOUSE_FROM^FS
^FN9^FD__WAREHOUSE_TO^FS

^FN101^FD__CATEGORY_SEQUENCE0^FS
^FN102^FD__CATEGORY_NAME0^FS
^FN103^FD__CATEGORY_QTY0^FS

^FN104^FD__CATEGORY_SEQUENCE1^FS
^FN105^FD__CATEGORY_NAME1^FS
^FN106^FD__CATEGORY_QTY1^FS

^FN107^FD__CATEGORY_SEQUENCE2^FS
^FN108^FD__CATEGORY_NAME2^FS
^FN109^FD__CATEGORY_QTY2^FS

^FN110^FD__CATEGORY_SEQUENCE3^FS
^FN111^FD__CATEGORY_NAME3^FS
^FN112^FD__CATEGORY_QTY3^FS

^FN113^FD__CATEGORY_SEQUENCE4^FS
^FN114^FD__CATEGORY_NAME4^FS
^FN115^FD__CATEGORY_QTY4^FS

^FN116^FD__CATEGORY_SEQUENCE5^FS
^FN117^FD__CATEGORY_NAME5^FS
^FN118^FD__CATEGORY_QTY5^FS

^FN119^FD__CATEGORY_SEQUENCE6^FS
^FN120^FD__CATEGORY_NAME6^FS
^FN121^FD__CATEGORY_QTY6^FS

^FN122^FD__CATEGORY_SEQUENCE7^FS
^FN123^FD__CATEGORY_NAME7^FS
^FN124^FD__CATEGORY_QTY7^FS

^FN901^FD__TOTAL_QUANTITY^FS
^FN902^FD__PAGE_NUMBER_OVER_TOTAL_PAGE^FS

^PQ1
^XZ
""".trim();
}
String get referenceTxtOfMovementByCategoryNoTemplateTxt {
  return  '''
^XA
^CI28
^PW800
^LL1200
^LH0,0
^LS0
^PR3
^FN4^FD__STATUS^FS
^FN5^FD__TITLE^FS
^FN6^^FS
^FO20,20
^BQN,2,8
^FD__DOCUMENT_NUMBER^FS
^FO192,24^FB572,1,0,R^A0N,44,32^FDLA,__DOCUMENT_NUMBER^FS
^FO192,76^FB286,1,0,C^A0N,24,18^FD__DATE^FS
^FO478,76^FB286,1,0,R^A0N,24,18^FD__STATUS^FS
^FO192,108^FB572,1,0,R^A0N,38,28^FD__TITLE^FS
^FO192,148^FB572,1,0,R^A0N,30,22^FD__COMPANY^FS
^FO192,184^FB572,1,0,R^A0N,22,18^FD__ADDRESS^FS
^FO192,212^FB572,1,0,R^A0N,22,18^FD__WAREHOUSE_FROM^FS
^FO192,240^FB572,1,0,R^A0N,22,18^FD__WAREHOUSE_TO^FS

^FO20,300^GB744,2,2^FS
^FO20,330^A0N,22,18^FDNo^FS
^FO90,330^A0N,22,18^FDCATEGORY NAME^FS
^FO624,330^FB140,1,0,R^A0N,22,18^FDQTY^FS
^FO20,382^GB744,2,2^FS

^FO20,412^FB70,1,0,L^A0N,24,18^FD__CATEGORY_SEQUENCE0^FS
^FO90,412^FB534,1,0,L^A0N,24,18^FD__CATEGORY_NAME0^FS
^FO624,412^FB140,1,0,R^A0N,28,22^FD__CATEGORY_QTY0^FS
^FO20,466^GB744,1,1^FS

^FO20,492^FB70,1,0,L^A0N,24,18^FD__CATEGORY_SEQUENCE1^FS
^FO90,492^FB534,1,0,L^A0N,24,18^FD__CATEGORY_NAME1^FS
^FO624,492^FB140,1,0,R^A0N,28,22^FD__CATEGORY_QTY1^FS
^FO20,546^GB744,1,1^FS

^FO20,572^FB70,1,0,L^A0N,24,18^FD__CATEGORY_SEQUENCE2^FS
^FO90,572^FB534,1,0,L^A0N,24,18^FD__CATEGORY_NAME2^FS
^FO624,572^FB140,1,0,R^A0N,28,22^FD__CATEGORY_QTY2^FS
^FO20,626^GB744,1,1^FS

^FO20,652^FB70,1,0,L^A0N,24,18^FD__CATEGORY_SEQUENCE3^FS
^FO90,652^FB534,1,0,L^A0N,24,18^FD__CATEGORY_NAME3^FS
^FO624,652^FB140,1,0,R^A0N,28,22^FD__CATEGORY_QTY3^FS
^FO20,706^GB744,1,1^FS

^FO20,732^FB70,1,0,L^A0N,24,18^FD__CATEGORY_SEQUENCE4^FS
^FO90,732^FB534,1,0,L^A0N,24,18^FD__CATEGORY_NAME4^FS
^FO624,732^FB140,1,0,R^A0N,28,22^FD__CATEGORY_QTY4^FS
^FO20,786^GB744,1,1^FS

^FO20,812^FB70,1,0,L^A0N,24,18^FD__CATEGORY_SEQUENCE5^FS
^FO90,812^FB534,1,0,L^A0N,24,18^FD__CATEGORY_NAME5^FS
^FO624,812^FB140,1,0,R^A0N,28,22^FD__CATEGORY_QTY5^FS
^FO20,866^GB744,1,1^FS

^FO20,892^FB70,1,0,L^A0N,24,18^FD__CATEGORY_SEQUENCE6^FS
^FO90,892^FB534,1,0,L^A0N,24,18^FD__CATEGORY_NAME6^FS
^FO624,892^FB140,1,0,R^A0N,28,22^FD__CATEGORY_QTY6^FS
^FO20,946^GB744,1,1^FS

^FO20,972^FB70,1,0,L^A0N,24,18^FD__CATEGORY_SEQUENCE7^FS
^FO90,972^FB534,1,0,L^A0N,24,18^FD__CATEGORY_NAME7^FS
^FO624,972^FB140,1,0,R^A0N,28,22^FD__CATEGORY_QTY7^FS
^FO20,1026^GB744,1,1^FS

^FO20,1060^FB360,1,0,L^A0N,28,20^FDTOTAL QTY : ^FS
^FO380,1060^FB384,1,0,R^A0N,28,20^FD__TOTAL_QUANTITY^FS
^FO20,1090^GB744,2,2^FS
^FO644,1120^FB120,1,0,R^A0N,28,20^FD__PAGE_NUMBER_OVER_TOTAL_PAGE^FS
^XZ
'''.trim();
}