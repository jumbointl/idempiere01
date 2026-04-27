import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/printer/printer_scan_notifier.dart';
import 'package:monalisa_app_001/features/printer/printer_setup_screen.dart';
import 'package:monalisapy_features/printer/zpl/new/models/locator_zpl_template.dart';
import 'package:monalisapy_features/printer/zpl/new/models/locator_zpl_template_provider.dart';
import 'package:monalisa_app_001/features/printer/zpl/new/provider/template_zpl_utils.dart';

import '../products/common/messages_dialog.dart';
import '../products/common/widget_utils.dart';
import 'package:monalisapy_features/models/idempiere/idempiere_locator.dart';
import '../products/presentation/providers/common_provider.dart';
import '../shared/data/messages.dart';

class LocatorPrintScreen extends PrinterSetupScreen {
  LocatorPrintScreen({super.key, required super.dataToPrint,required super.oldAction});


  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ guardar dataToPrint en provider para usar en impresión futura
    if (dataToPrint is IdempiereLocator) {
      ref.read(locatorDataToPrintProvider.notifier).state =
      dataToPrint as IdempiereLocator;
    }
    return printerSetupScreenBody(context, ref, dataToPrint: dataToPrint);
  }

  @override
  Widget getPrintPanel(WidgetRef ref, BuildContext context) {
    final selected = ref.watch(selectedLocatorZplTemplateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // ✅ Locator ZPL Template botón (stub)
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => openLocatorTemplateSheet(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    selected == null ? Icons.add_circle_outline : Icons.edit,
                    color: themeColorPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Locator ZPL Template',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selected == null
                              ? 'Ninguno seleccionado (tocar para agregar/seleccionar)'
                              : '${selected.name}  •  ${selected.size}  •  ${selected.templateFilename}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black54),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // ✅ Print botón (stub)
        Row(
          children: [
            Expanded(
              child: compactElevatedButton(
                label: Messages.CREATE_ZPL_TEMPLATE,
                backgroundColor:
                (ref.read(lastPrinterProvider.notifier).state != null
                    ? Colors.cyan.shade800
                    : themeColorPrimary),
                onPressed: () async {
                  LocatorZplTemplate? template = ref.read(selectedLocatorZplTemplateProvider);
                  if(template==null){
                    showWarningMessage(context, ref, 'No template selected');
                    return;
                  }
                  String zpl =  template.sentenceToSendToPrinter.isEmpty ?
                  LocatorZplTemplate.getDefaultTemplate().sentenceToSendToPrinter
                  : template.sentenceToSendToPrinter;
                  final newZpl = await context.push<String>(
                    '/locator_zpl_sentence_editor',
                    extra: {
                      'sentence': zpl,
                      'focusNode': focusNode,
                    },
                  );
                  if(newZpl==null || newZpl.isEmpty){
                    if(context.mounted) {
                      showWarningMessage(context, ref, 'No template created');
                    }
                    return;
                  }
                  template = template.copyWith(sentenceToSendToPrinter: newZpl);
                  ref.read(locatorZplTemplatesProvider.notifier).upsert(template);

                  final state = ref.read(printerScanNotifierProvider);
                  String ip = state.ipController.text ;
                  int port = int.parse(state.portController.text);
                  if(ip.isEmpty) {
                    if(context.mounted) showWarningMessage(context, ref, 'IP address is empty');
                    return;
                  }
                  if(port<=0) {
                    if(context.mounted) showWarningMessage(context, ref, 'Port is empty');
                    return;
                  }
                  if(zpl.isEmpty) {
                    if(context.mounted) showWarningMessage(context, ref, 'Template is empty');
                    return;
                  }

                  bool res = await sendZplBySocket(ip: ip, port: port, zpl: newZpl);
                  if(res) {
                    if(context.mounted) showSuccessMessage(context, ref, 'ZPL sent successfully ${template.templateFilename}');
                  }else{
                    if(context.mounted) showErrorMessage(context, ref, 'Error sending ZPL');
                  }


                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: compactElevatedButton(
                label: Messages.PRINT,
                backgroundColor:
                (ref.read(lastPrinterProvider.notifier).state != null
                    ? Colors.green
                    : themeColorPrimary),
                onPressed: () async {
                  LocatorZplTemplate? template = ref.read(selectedLocatorZplTemplateProvider);
                  if(template==null){
                    showWarningMessage(context, ref, 'No template selected');
                    return;
                  }

                  await printFromCurrentSetup(ref, context, dataToPrint);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

}

