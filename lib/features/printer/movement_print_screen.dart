import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/printer/printer_scan_notifier.dart';
import 'package:monalisa_app_001/features/printer/printer_setup_screen.dart';
import 'package:monalisapy_features/zpl_template/models/zpl_template.dart';
import 'package:monalisapy_features/printer/zpl/new/models/zpl_template_store.dart';
import 'package:monalisapy_features/printer/zpl/new/provider/always_use_last_template_provider.dart';
import 'package:monalisa_app_001/features/printer/zpl/new/provider/template_zpl_utils.dart';
import 'package:monalisapy_features/printer/zpl/new/screen/template_zpl_on_use_sheet.dart';
import 'package:monalisa_app_001/features/printer/zpl/new/screen/template_zpl_preview_screen.dart';
import 'package:printing/printing.dart';
import '../../config/router/app_router.dart';
import '../../config/theme/app_theme.dart';
import '../products/common/messages_dialog.dart';
import '../products/common/widget_utils.dart';
import '../products/domain/idempiere/movement_and_lines.dart';
import '../products/presentation/providers/common_provider.dart';
import '../products/presentation/providers/product_provider_common.dart';
import '../shared/data/memory.dart';
import '../shared/data/messages.dart';
import 'package:monalisapy_features/printer/models/mo_printer.dart';
import 'cups_printer.dart';
import 'movement_pdf_generator.dart';
// Tu método para generar el PDF

class MovementPrintScreen extends PrinterSetupScreen {
  MovementPrintScreen({super.key, super.dataToPrint,required super.oldAction });

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) {
    MovementAndLines movementAndLines = super.dataToPrint as MovementAndLines;
    int movementId = movementAndLines.id ?? -1;
    ref.read(actionScanProvider.notifier).state = Memory.ACTION_FIND_MOVEMENT_BY_ID;
    context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$movementId/1');
  }

  Widget build(BuildContext context, WidgetRef ref) {

    return printerSetupScreenBody(context,ref,dataToPrint: dataToPrint);
  }
  @override
  Future<void> printPdf(WidgetRef ref, BuildContext context, {required bool direct}) async {
    MovementAndLines movementAndLines = dataToPrint as MovementAndLines;
    final image = await imageLogo;
    final pdfBytes = await generateMovementDocument(movementAndLines, image);
    direct ?  ref.read(printerScanNotifierProvider.notifier).printDirectly(bytes: pdfBytes,ref: ref)
        : await Printing.sharePdf(bytes: pdfBytes, filename: 'documento.pdf');
  }
  @override
  Widget getPrintPanel(WidgetRef ref, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: compactElevatedButton(
            label: Messages.SHARE,
            backgroundColor: themeColorPrimary,
            onPressed: () async {
              await printPdf(ref, context, direct: false);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: compactElevatedButton(
            label: Messages.PRINT,
            backgroundColor: (ref
                .read(lastPrinterProvider.notifier)
                .state != null
                ? Colors.green
                : themeColorPrimary),
            onPressed: () async {
              printFromCurrentSetup(ref, context,dataToPrint);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: compactElevatedButton(
            label: 'PREVIEW',
            backgroundColor: themeColorPrimary,
            onPressed: () async {
              await onZplPreviewPressed(context, ref);
            },
          ),
        ),
      ],
    );
  }
  Future<void> onZplPreviewPressed(BuildContext context, WidgetRef ref) async {
    final printerState = ref.read(printerScanNotifierProvider);
    final type = printerState.typeController.text.trim().toUpperCase();
    // English comment: "Preview only for LABEL printers"
    if (!type.startsWith('LABEL')) {
      showWarningMessage(context, ref, Messages.ONLY_FOR_LABEL_PRINTER);
      return;
    }

    final box = GetStorage();
    final store = ZplTemplateStore(box);
    final mode = ZplTemplateMode.movement;

    ZplTemplate? result;

    // English comment: "Use last default template or let user pick one"
    if (ref.read(alwaysUseLastTemplateProvider)) {
      result = store.loadDefaultByMode(mode);
    } else {
      result = await showUseZplTemplateSheet(
        context: context,
        ref: ref,
        store: store,
      );
    }

    if (result == null) {
      showWarningMessage(context, ref, Messages.NO_TEMPLATE_SELECTED);
      return;
    }


    // result ya calculado (default o sheet)
    result = resolveDfFromLocalDownloadedTemplates(
      result: result,
      store: store,
    );

    // English comment: "Build filled previews"
    final filledFirst = buildFilledMovementPreviewAllPages(
      template: result,
      movementAndLines: dataToPrint,
    ).split('----- PAGE').first.trim().isEmpty
        ? buildFilledMovementPreviewAllPages(template: result, movementAndLines: dataToPrint)
        : buildFilledMovementPreviewAllPages(template: result, movementAndLines: dataToPrint);

    // If you already have a dedicated first-page builder, use it instead:
    // final filledFirst = buildFilledPreviewFirstPage(template: result, movementAndLines: movementAndLines);

    final filledAll = buildFilledMovementPreviewAllPages(
      template: result,
      movementAndLines: dataToPrint,
    );


    final filledAllToPdf = buildFilledMovementPreviewAllPages(
      hidePageLine: true,
      template: result,
      movementAndLines: dataToPrint,
    );
    // English comment: "Validate missing tokens"
    final missing = validateMissingTokens(
      template: result,
      referenceTxt: result.zplReferenceTxt,
    );
    if(context.mounted) {
      await showZplPreviewSheet(
        context: context,
        template: result,
        filledPreviewFirstPage: filledFirst,
        filledPreviewAllPages: filledAll,
        filledReferenceForPdf: filledAllToPdf,
        missingTokens: missing,
        onSendDf: null,
        onPrintReference: () async {
          await _printFromCurrentSetupZpl(ref,context,filledAllToPdf);
        },
      );
    }
  }
  Future<void> _printFromCurrentSetupZpl(WidgetRef ref,BuildContext context,String zpl) async {
    final printerState = ref.read(printerScanNotifierProvider);
    String ip        = printerState.ipController.text.trim();
    String port      = printerState.portController.text.trim();
    String type      = printerState.typeController.text.trim();
    String name      = printerState.nameController.text.trim();
    String serverIp  = printerState.serverIpController.text.trim();
    String serverPort= printerState.serverPortController.text.trim();

    if (ip.isEmpty || port.isEmpty || type.isEmpty) {
      showWarningMessage(context, ref, Messages.ERROR_SAVE_PRINTER);
      return;
    }

    final printer = MOPrinter()
      ..name       = name
      ..ip         = ip
      ..port       = port
      ..type       = type
      ..serverIp   = serverIp
      ..noDelete   = noDeleteFlag
      ..serverPort = serverPort;

    await savePrinterToStorage(ref, printer);

    String qrData = '$ip:$port:$type';
    if (name.isNotEmpty)    qrData = '$qrData:$name';
    if (serverIp.isNotEmpty)   qrData = '$qrData:$serverIp';
    if (serverPort.isNotEmpty) qrData = '$qrData:$serverPort';
    int portInt = int.tryParse(port) ?? 91000;

    if(zpl.isNotEmpty){
      bool? result = await sendZplBySocket(ip: ip, port: portInt, zpl: zpl);
      if(result==true){
        if(context.mounted) {
          showSuccessMessage(context, ref, 'Impreso con éxito');
        }
      } else {
        if(context.mounted) {
          showWarningMessage(context, ref, 'Error al imprimir');
        }
      }

    }

  }
}