import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image/image.dart' as img;
import 'package:monalisa_app_001/features/printer/zpl/old/zpl_print_widget.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common_provider.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

import '../../../products/common/messages_dialog.dart';
import '../../../products/domain/idempiere/movement_and_lines.dart';
import '../../printer_scan_notifier.dart';
import '../../web_template/screen/show_search_zpl_template_sheet.dart';
import '../new/models/zpl_template.dart';
import '../new/provider/always_use_last_template_provider.dart';
import '../new/screen/template_zpl_on_use_sheet.dart';
import '../new/provider/template_zpl_provider.dart';
import '../new/models/zpl_template_store.dart';
import '../new/provider/template_zpl_utils.dart';
import '../template/tspl_label_printer.dart';
import 'zpl_print_profile_providers.dart';





/// ===============================
/// PNG -> ^GFA (image v4+)
/// ===============================
String pngBytesToZplGfa(
    Uint8List bytes, {
      required int targetWidthDots,
      int threshold = 175,
      bool invert = false,
    }) {
  img.Image? image = img.decodeImage(bytes);
  if (image == null) throw Exception('pngBytesToZplGfa: decodeImage failed');

  // Mantener ratio
  final h = (image.height * (targetWidthDots / image.width)).round();
  image = img.copyResize(
    image,
    width: targetWidthDots,
    height: h,
    interpolation: img.Interpolation.average,
  );

  final width = image.width;
  final height = image.height;

  final bytesPerRow = ((width + 7) ~/ 8);
  final totalBytes = bytesPerRow * height;
  final out = Uint8List(totalBytes);

  int idx = 0;
  for (int y = 0; y < height; y++) {
    int bit = 7;
    int cur = 0;
    for (int x = 0; x < width; x++) {
      final p = image.getPixel(x, y);
      final lum = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
      bool isBlack = lum < threshold;
      if (invert) isBlack = !isBlack;
      if (isBlack) cur |= (1 << bit);

      bit--;
      if (bit < 0) {
        out[idx++] = cur;
        cur = 0;
        bit = 7;
      }
    }
    if (bit != 7) out[idx++] = cur;
  }

  final hex = StringBuffer();
  for (final b in out) {
    hex.write(b.toRadixString(16).padLeft(2, '0').toUpperCase());
  }

  return '^GFA,$totalBytes,$totalBytes,$bytesPerRow,${hex.toString()}';
}

/// ===============================
/// SOCKET SEND
/// ===============================
Future<void> sendZpl({
  required String ip,
  required int port,
  required String zpl,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final socket = await Socket.connect(ip, port, timeout: timeout);
  socket.add(utf8.encode(zpl));
  await socket.flush();
  await socket.close();
}

/// ===============================
/// COMBINAR LOGO+QR (tu función existe en tu proyecto)
/// Pasa aquí tu import real o mueve esta firma a otro archivo.
/// ===============================
/*
Future<Uint8List> combineLogoAndQrCode({
  required String logo,
  required String qrData,
}) async {
  throw UnimplementedError('Importa tu combineLogoAndQrCode real aquí.');
}
*/



Future<void> printZplDirectOrConfigure(
    WidgetRef ref,
    MovementAndLines movementAndLines,
    ) async {
  final state = ref.read(printerScanProvider);

  final ip = state.ipController.text.trim();
  final port = int.tryParse(state.portController.text.trim()) ?? 0;

  if (ip.isEmpty || port == 0) {
    showWarningMessage(ref.context, ref, Messages.ERROR_IP_PORT_INVALID);
    return;
  }

  // ============================================================
  // ✅ 0) Intentar primero: template guardado (mode=movement)
  // ============================================================
  final box = GetStorage();
  final store = ZplTemplateStore(box);

  // Normaliza por si hay más de 1 default
  await store.normalizeDefaults();
  final mode = ref.read(selectedZplTemplateModeProvider) ;
  var movementTemplates = store
      .loadAll()
      .where((t) => t.mode == mode)
      .toList();

  if(movementTemplates.isEmpty) {
    if (ref.context.mounted) {
      final list = await showSearchZplTemplateSheet(
        context: ref.context,
        ref: ref,
        mode: mode,
      );
      if(list != null) {
        movementTemplates = list;
      } else {
        if(ref.context.mounted) {
          showWarningMessage(ref.context, ref, Messages.ERROR_NO_TEMPLATE_SELECTED);
        }
        return;
      }

    }
  }

  ZplTemplate chosen;
  if (movementTemplates.length == 1) {
    chosen = movementTemplates.first;
  } else {
      ZplTemplate? result;
      if(ref.read(alwaysUseLastTemplateProvider)){
        result = store.loadDefaultByMode(mode);
      }


      if(ref.context.mounted && result == null) {
        result = await showUseZplTemplateSheet(
            context: ref.context,
            ref: ref,
            store: store);
      }

     if(result==null){
       if(ref.context.mounted) {
         showWarningMessage(ref.context, ref, Messages.ERROR_TEMPLATE_FILE_NOT_FOUND);
       }
       return;
     }
     chosen = result;
  }
  // Debe tener Reference
  final referenceTxt = chosen.zplReferenceTxt.trim();

  if (referenceTxt.isNotEmpty) {
    final missing = validateMissingTokens(
        template: chosen, referenceTxt: referenceTxt);
    if (missing.isEmpty) {
      if(!ref.context.mounted) return;
      ref.read(initializingProvider.notifier).state = true ;
      await Future.delayed(const Duration(milliseconds: 100));
      final filledAllToPrint = buildFilledPreviewAllPages(
          template: chosen, movementAndLines: movementAndLines);
      bool? printed = await sendZplBySocket(ip: ip, port: port,
          zpl: filledAllToPrint);

      await Future.delayed(const Duration(milliseconds: 100));
      ref.read(initializingProvider.notifier).state = false ;
      if(!printed) {
        if(ref.context.mounted) {
          showErrorMessage(
              ref.context, ref, Messages.ERROR_PRINTING);

        }
      } else {
        if(ref.context.mounted) {
          showSuccessMessage(ref.context, ref, Messages.PRINTED_SUCCESSFULLY);
        }
      }

      return; // ✅ ya imprimió con template
    } else {
      if(ref.context.mounted) {
        showWarningMessage(ref.context, ref, Messages.ERROR_TEMPLATE);

      }
    }
  }
}

Future<void> printTsplDirectOrConfigure(WidgetRef ref,
    MovementAndLines movementAndLines,) async {
  final state = ref.read(printerScanProvider);

  final ip = state.ipController.text.trim();
  final port = int.tryParse(state.portController.text.trim()) ?? 0;

  if (ip.isEmpty || port == 0) {
    showWarningMessage(ref.context, ref, 'IP/PORT inválido');
    return;
  }

  // 1) Intentar cargar perfil activo o primero
  ZplPrintProfile? profile = loadActiveOrFirstProfile();

  // 2) Si no hay perfiles => abrir sheet, luego volver a intentar
  if (profile == null) {
    await showZplPrintProfilesSheet(ref.context, ref);

    profile = loadActiveOrFirstProfile();
    if (profile == null) return; // usuario canceló o no guardó nada
  }

  // 3) Imprimir directo usando el perfil
  await printLabelMovementByProductTspl60x150NoLogo(
    ref: ref,
    ip: ip,
    port: port,
    movementAndLines: movementAndLines,
    rowsPerLabel: profile.rowsPerLabel,
    marginX: profile.marginX,
    marginY: profile.marginY,
  );
}












