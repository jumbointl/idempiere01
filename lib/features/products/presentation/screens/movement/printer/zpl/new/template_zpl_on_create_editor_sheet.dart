import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/auth/presentation/providers/auth_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/new/template_zpl_provider.dart';
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
  int times =0;
  ref.read(enableScannerKeyboardProvider.notifier).state = false ;
  ref.read(isDialogShowedProvider.notifier).state = true ;
  ZplTemplateMode mode =
      initial?.mode ?? ZplTemplateMode.movement;
  final bool isAdmin = Memory.isAdmin == true;
  final nameCtrl = TextEditingController(
    text: initial?.templateFileName ??
        (mode == ZplTemplateMode.movement
            ? 'MOV_CAT1.ZPL'
            : 'TEMPLATE.ZPL'),
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
    final times = ref.watch(exampleLoadCounterProvider);
    bool wantCategory = times.isEven;

    final file =  (mode == ZplTemplateMode.movement
        ? times.isEven ? 'MOV_CAT1.ZPL' : 'MOV_PRD1.ZPL'
        : 'TEMPLATE.ZPL');

    nameCtrl.text = file;
    dfCtrl.text = zplMovementTemplateModel(file,wantCategory);
    refCtrl.text = mode == ZplTemplateMode.movement ?
    times.isEven ? referenceTxtOfMovementByCategoryTxt
        : referenceTxtOfMovementByProductTxt : 'TEMPLATE.ZPL';
    rowPerpageCtrl.text =
        (mode == ZplTemplateMode.movement ? 18 : 18)
            .toString();
    ref.read(exampleLoadCounterProvider.notifier).state++;

  }
  /*void loadExampleForMode() {
    final times = ref.watch(exampleLoadCounterProvider);
    bool wantCategory = times.isEven;

    final file = nameCtrl.text.trim().isEmpty
        ? (mode == ZplTemplateMode.movement
        ? times.isEven ? 'MOV_CAT1.ZPL' : 'MOV_PRD1.ZPL'
        : 'TEMPLATE.ZPL')
        : nameCtrl.text.trim();

    ref.read(exampleLoadCounterProvider.notifier).state++;
    if (nameCtrl.text.trim().isEmpty) {
      nameCtrl.text = file;
    }

    if (initial == null && dfCtrl.text.trim().isEmpty) {
      dfCtrl.text = templateModel(file,wantCategory);

    }

    if (initial == null && refCtrl.text.trim().isEmpty) {
      refCtrl.text = times.isEven ? referenceTxtOfMovementByCategoryTxt
          : referenceTxtOfMovementByProductTxt;

    }

    if (initial == null &&
        rowPerpageCtrl.text.trim().isEmpty) {
      rowPerpageCtrl.text =
          (mode == ZplTemplateMode.movement ? 18 : 18)
              .toString();
    }
  }*/

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
                        onPressed: () {
                          ref.read(enableScannerKeyboardProvider.notifier).state = true ;
                          ref.read(isDialogShowedProvider.notifier).state = false ;
                          Navigator.pop(ctx, null);
                        }

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
                                    ref: ref,
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
                        onPressed: () {
                          ref.read(enableScannerKeyboardProvider.notifier).state = true ;
                          ref.read(isDialogShowedProvider.notifier).state = false ;
                          Navigator.pop(ctx, null);
                        },
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
                            ref.read(enableScannerKeyboardProvider.notifier).state = true ;
                            ref.read(isDialogShowedProvider.notifier).state = false ;
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
String zplMovementTemplateModel(String file, bool wantCategory){
  String colNo ='No';
  String colName = 'CATEGORY NAME';
  String colQty ='QTY';
  if(!wantCategory) {
    colNo = 'LINE';
    colName = 'PRODUCT NAME';
    colQty = 'QTY';
  }

  return
    '''
^XA
^DFE:${stripDrive(file)}^FS
^CI28
^PW800
^LL1200
^LH0,0
^PR3
^FO20,60^BQN,2,8^FN1^FS
^FO20,285^A0N,35,30^FN3^FS
^FO300,64^FB480,1,0,R^A0N,44,32^FN2^FS 
^FO300,112^FB480,1,0,R^A0N,24,18^FN4^FS 
^FO300,140^FB480,1,0,R^A0N,38,28^FN6^FS 
^FO300,175^FB480,1,0,R^A0N,30,22^FN5^FS 
^FO300,205^FB480,1,0,R^A0N,22,18^FN7^FS 
^FO300,230^FB480,1,0,R^A0N,22,18^FN8^FS 
^FO745,355^A0B,25,20^FN5^FS
^FO20,315^GB700,2,2^FS
^FO20,328^A0N,18,16^FD$colNo^FS
^FO110,328^A0N,18,16^FD$colName^FS
^FO590,328^FB70,1,0,R^A0N,18,16^FD$colQty^FS 
^FO20,355^GB700,2,2^FS
^FO20,365^FB80,1,0,L^A0N,24,20^FN101^FS^FO110,365^FB470,1,0,L^A0N,24,20^FN102^FS^FO590,365^FB70,1,0,R^A0N,30,26^FN103^FS^FO20,396^GB700,1,1^FS
^FO20,403^FB80,1,0,L^A0N,24,20^FN104^FS^FO110,403^FB470,1,0,L^A0N,24,20^FN105^FS^FO590,403^FB70,1,0,R^A0N,30,26^FN106^FS^FO20,434^GB700,1,1^FS
^FO20,441^FB80,1,0,L^A0N,24,20^FN107^FS^FO110,441^FB470,1,0,L^A0N,24,20^FN108^FS^FO590,441^FB70,1,0,R^A0N,30,26^FN109^FS^FO20,472^GB700,1,1^FS
^FO20,479^FB80,1,0,L^A0N,24,20^FN110^FS^FO110,479^FB470,1,0,L^A0N,24,20^FN111^FS^FO590,479^FB70,1,0,R^A0N,30,26^FN112^FS^FO20,510^GB700,1,1^FS
^FO20,517^FB80,1,0,L^A0N,24,20^FN113^FS^FO110,517^FB470,1,0,L^A0N,24,20^FN114^FS^FO590,517^FB70,1,0,R^A0N,30,26^FN115^FS^FO20,548^GB700,1,1^FS
^FO20,555^FB80,1,0,L^A0N,24,20^FN116^FS^FO110,555^FB470,1,0,L^A0N,24,20^FN117^FS^FO590,555^FB70,1,0,R^A0N,30,26^FN118^FS^FO20,586^GB700,1,1^FS
^FO20,593^FB80,1,0,L^A0N,24,20^FN119^FS^FO110,593^FB470,1,0,L^A0N,24,20^FN120^FS^FO590,593^FB70,1,0,R^A0N,30,26^FN121^FS^FO20,624^GB700,1,1^FS
^FO20,631^FB80,1,0,L^A0N,24,20^FN122^FS^FO110,631^FB470,1,0,L^A0N,24,20^FN123^FS^FO590,631^FB70,1,0,R^A0N,30,26^FN124^FS^FO20,662^GB700,1,1^FS
^FO20,669^FB80,1,0,L^A0N,24,20^FN125^FS^FO110,669^FB470,1,0,L^A0N,24,20^FN126^FS^FO590,669^FB70,1,0,R^A0N,30,26^FN127^FS^FO20,700^GB700,1,1^FS
^FO20,707^FB80,1,0,L^A0N,24,20^FN128^FS^FO110,707^FB470,1,0,L^A0N,24,20^FN129^FS^FO590,707^FB70,1,0,R^A0N,30,26^FN130^FS^FO20,738^GB700,1,1^FS
^FO20,745^FB80,1,0,L^A0N,24,20^FN131^FS^FO110,745^FB470,1,0,L^A0N,24,20^FN132^FS^FO590,745^FB70,1,0,R^A0N,30,26^FN133^FS^FO20,776^GB700,1,1^FS
^FO20,783^FB80,1,0,L^A0N,24,20^FN134^FS^FO110,783^FB470,1,0,L^A0N,24,20^FN135^FS^FO590,783^FB70,1,0,R^A0N,30,26^FN136^FS^FO20,814^GB700,1,1^FS
^FO20,821^FB80,1,0,L^A0N,24,20^FN137^FS^FO110,821^FB470,1,0,L^A0N,24,20^FN138^FS^FO590,821^FB70,1,0,R^A0N,30,26^FN139^FS^FO20,852^GB700,1,1^FS
^FO20,859^FB80,1,0,L^A0N,24,20^FN140^FS^FO110,859^FB470,1,0,L^A0N,24,20^FN141^FS^FO590,859^FB70,1,0,R^A0N,30,26^FN142^FS^FO20,890^GB700,1,1^FS
^FO20,897^FB80,1,0,L^A0N,24,20^FN143^FS^FO110,897^FB470,1,0,L^A0N,24,20^FN144^FS^FO590,897^FB70,1,0,R^A0N,30,26^FN145^FS^FO20,928^GB700,1,1^FS
^FO20,935^FB80,1,0,L^A0N,24,20^FN146^FS^FO110,935^FB470,1,0,L^A0N,24,20^FN147^FS^FO590,935^FB70,1,0,R^A0N,30,26^FN148^FS^FO20,966^GB700,1,1^FS
^FO20,973^FB80,1,0,L^A0N,24,20^FN149^FS^FO110,973^FB470,1,0,L^A0N,24,20^FN150^FS^FO590,973^FB70,1,0,R^A0N,30,26^FN151^FS^FO20,1004^GB700,1,1^FS
^FO20,1011^FB80,1,0,L^A0N,24,20^FN152^FS^FO110,1011^FB470,1,0,L^A0N,24,20^FN153^FS^FO590,1011^FB70,1,0,R^A0N,30,26^FN154^FS^FO20,1042^GB700,1,1^FS
^FO20,1055^FB360,1,0,L^A0N,28,20^FDTOTAL QTY : ^FS
^FO340,1055^FB320,1,0,R^A0N,45,40^FN901^FS
^FO20,1105^GB700,2,2^FS
^FO20,1115^BY2^BCN,40,N,N,N^FN2^FS
^FO20,1160^A0N,20,18^FDGenerado por: ^FS
^FO150,1160^A0N,20,18^FN20^FS
^FO600,1160^FB100,1,0,R^A0N,24,18^FN902^FS
^XZ
'''.trim();
}
String get referenceTxtOfMovementByProductTxt {
  return """
^XA
^CI28
^XFE:MOV_PRD1^FS
^FN1^FDLA,__DOCUMENT_NUMBER^FS
^FN2^FD__DOCUMENT_NUMBER^FS
^FN3^FD__DATE^FS
^FN4^FD__STATUS^FS
^FN5^FD__TITLE^FS
^FN6^FD__COMPANY^FS
^FN7^FD__ADDRESS^FS
^FN8^FD__WAREHOUSE_FROM^FS
^FN101^FD__MOVEMENT_LINE_LINE0^FS ^FN102^FD__PRODUCT_NAME0^FS ^FN103^FD__MOVEMENT_LINE_MOVEMENT_QTY0^FS
^FN104^FD__MOVEMENT_LINE_LINE1^FS ^FN105^FD__PRODUCT_NAME1^FS ^FN106^FD__MOVEMENT_LINE_MOVEMENT_QTY1^FS
^FN107^FD__MOVEMENT_LINE_LINE2^FS ^FN108^FD__PRODUCT_NAME2^FS ^FN109^FD__MOVEMENT_LINE_MOVEMENT_QTY2^FS
^FN110^FD__MOVEMENT_LINE_LINE3^FS ^FN111^FD__PRODUCT_NAME3^FS ^FN112^FD__MOVEMENT_LINE_MOVEMENT_QTY3^FS
^FN113^FD__MOVEMENT_LINE_LINE4^FS ^FN114^FD__PRODUCT_NAME4^FS ^FN115^FD__MOVEMENT_LINE_MOVEMENT_QTY4^FS
^FN116^FD__MOVEMENT_LINE_LINE5^FS ^FN117^FD__PRODUCT_NAME5^FS ^FN118^FD__MOVEMENT_LINE_MOVEMENT_QTY5^FS
^FN119^FD__MOVEMENT_LINE_LINE6^FS ^FN120^FD__PRODUCT_NAME6^FS ^FN121^FD__MOVEMENT_LINE_MOVEMENT_QTY6^FS
^FN122^FD__MOVEMENT_LINE_LINE7^FS ^FN123^FD__PRODUCT_NAME7^FS ^FN124^FD__MOVEMENT_LINE_MOVEMENT_QTY7^FS
^FN125^FD__MOVEMENT_LINE_LINE8^FS ^FN126^FD__PRODUCT_NAME8^FS ^FN127^FD__MOVEMENT_LINE_MOVEMENT_QTY8^FS
^FN128^FD__MOVEMENT_LINE_LINE9^FS ^FN129^FD__PRODUCT_NAME9^FS ^FN130^FD__MOVEMENT_LINE_MOVEMENT_QTY9^FS
^FN131^FD__MOVEMENT_LINE_LINE10^FS ^FN132^FD__PRODUCT_NAME10^FS ^FN133^FD__MOVEMENT_LINE_MOVEMENT_QTY10^FS
^FN134^FD__MOVEMENT_LINE_LINE11^FS ^FN135^FD__PRODUCT_NAME11^FS ^FN136^FD__MOVEMENT_LINE_MOVEMENT_QTY11^FS
^FN137^FD__MOVEMENT_LINE_LINE12^FS ^FN138^FD__PRODUCT_NAME12^FS ^FN139^FD__MOVEMENT_LINE_MOVEMENT_QTY12^FS
^FN140^FD__MOVEMENT_LINE_LINE13^FS ^FN141^FD__PRODUCT_NAME13^FS ^FN142^FD__MOVEMENT_LINE_MOVEMENT_QTY13^FS
^FN143^FD__MOVEMENT_LINE_LINE14^FS ^FN144^FD__PRODUCT_NAME14^FS ^FN145^FD__MOVEMENT_LINE_MOVEMENT_QTY14^FS
^FN146^FD__MOVEMENT_LINE_LINE15^FS ^FN147^FD__PRODUCT_NAME15^FS ^FN148^FD__MOVEMENT_LINE_MOVEMENT_QTY15^FS
^FN149^FD__MOVEMENT_LINE_LINE16^FS ^FN150^FD__PRODUCT_NAME16^FS ^FN151^FD__MOVEMENT_LINE_MOVEMENT_QTY16^FS
^FN152^FD__MOVEMENT_LINE_LINE17^FS ^FN153^FD__PRODUCT_NAME17^FS ^FN154^FD__MOVEMENT_LINE_MOVEMENT_QTY17^FS
^FN901^FD__TOTAL_QUANTITY^FS
^FN902^FD__PAGE_NUMBER_OVER_TOTAL_PAGE^FS
^FN20^FD__GENERATED_BY^FS
^PQ1
^XZ
""".trim();
}

String get referenceTxtOfMovementByCategoryTxt {
  return
    """
^XA
^CI28
^XFE:MOV_CAT1^FS
^FN1^FDLA,__DOCUMENT_NUMBER^FS
^FN2^FD__DOCUMENT_NUMBER^FS
^FN3^FD__DATE^FS
^FN4^FD__STATUS^FS
^FN5^FD__TITLE^FS
^FN6^FD__COMPANY^FS
^FN7^FD__ADDRESS^FS
^FN8^FD__WAREHOUSE_FROM^FS
^FN101^FD__CATEGORY_SEQUENCE0^FS ^FN102^FD__CATEGORY_NAME0^FS ^FN103^FD__CATEGORY_QTY0^FS
^FN104^FD__CATEGORY_SEQUENCE1^FS ^FN105^FD__CATEGORY_NAME1^FS ^FN106^FD__CATEGORY_QTY1^FS
^FN107^FD__CATEGORY_SEQUENCE2^FS ^FN108^FD__CATEGORY_NAME2^FS ^FN109^FD__CATEGORY_QTY2^FS
^FN110^FD__CATEGORY_SEQUENCE3^FS ^FN111^FD__CATEGORY_NAME3^FS ^FN112^FD__CATEGORY_QTY3^FS
^FN113^FD__CATEGORY_SEQUENCE4^FS ^FN114^FD__CATEGORY_NAME4^FS ^FN115^FD__CATEGORY_QTY4^FS
^FN116^FD__CATEGORY_SEQUENCE5^FS ^FN117^FD__CATEGORY_NAME5^FS ^FN118^FD__CATEGORY_QTY5^FS
^FN119^FD__CATEGORY_SEQUENCE6^FS ^FN120^FD__CATEGORY_NAME6^FS ^FN121^FD__CATEGORY_QTY6^FS
^FN122^FD__CATEGORY_SEQUENCE7^FS ^FN123^FD__CATEGORY_NAME7^FS ^FN124^FD__CATEGORY_QTY7^FS
^FN125^FD__CATEGORY_SEQUENCE8^FS ^FN126^FD__CATEGORY_NAME8^FS ^FN127^FD__CATEGORY_QTY8^FS
^FN128^FD__CATEGORY_SEQUENCE9^FS ^FN129^FD__CATEGORY_NAME9^FS ^FN130^FD__CATEGORY_QTY9^FS
^FN131^FD__CATEGORY_SEQUENCE10^FS ^FN132^FD__CATEGORY_NAME10^FS ^FN133^FD__CATEGORY_QTY10^FS
^FN134^FD__CATEGORY_SEQUENCE11^FS ^FN135^FD__CATEGORY_NAME11^FS ^FN136^FD__CATEGORY_QTY11^FS
^FN137^FD__CATEGORY_SEQUENCE12^FS ^FN138^FD__CATEGORY_NAME12^FS ^FN139^FD__CATEGORY_QTY12^FS
^FN140^FD__CATEGORY_SEQUENCE13^FS ^FN141^FD__CATEGORY_NAME13^FS ^FN142^FD__CATEGORY_QTY13^FS
^FN143^FD__CATEGORY_SEQUENCE14^FS ^FN144^FD__CATEGORY_NAME14^FS ^FN145^FD__CATEGORY_QTY14^FS
^FN146^FD__CATEGORY_SEQUENCE15^FS ^FN147^FD__CATEGORY_NAME15^FS ^FN148^FD__CATEGORY_QTY15^FS
^FN149^FD__CATEGORY_SEQUENCE16^FS ^FN150^FD__CATEGORY_NAME16^FS ^FN151^FD__CATEGORY_QTY16^FS
^FN152^FD__CATEGORY_SEQUENCE17^FS ^FN153^FD__CATEGORY_NAME17^FS ^FN154^FD__CATEGORY_QTY17^FS
^FN901^FD__TOTAL_QUANTITY^FS
^FN902^FD__PAGE_NUMBER_OVER_TOTAL_PAGE^FS
^FN20^FD__GENERATED_BY^FS

^PQ1
^XZ
""".trim();
}


ZplTemplate defaultZplMovementTemplate = ZplTemplate(
  id:'',
  isDefault: false,
  zplReferenceTxt: referenceTxtOfMovementByCategoryNoTemplateTxt,
  zplTemplateDf: '',
  mode: ZplTemplateMode.movement,
  rowPerpage: 8,
  createdAt: DateTime.now(),
  templateFileName: '',
);
String get referenceTxtOfMovementByCategoryNoTemplateTxt {
  int marginAddY = 40;
  final zpl =  '''
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
^FDLA,__DOCUMENT_NUMBER^FS
^FO192,24^FB572,1,0,R^A0N,44,32^FD__DOCUMENT_NUMBER^FS
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
  final result  = applyMarginAddY(zpl, marginAddY);
  return result;
}

String applyMarginAddY(String zpl, int marginAddY) {
  final reg = RegExp(r'\^FO(\d+),(\d+)');

  return zpl.replaceAllMapped(reg, (m) {
    final x = m.group(1);
    final y = int.parse(m.group(2)!);
    return '^FO$x,${y + marginAddY}';
  });
}