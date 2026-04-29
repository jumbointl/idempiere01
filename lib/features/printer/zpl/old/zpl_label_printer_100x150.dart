import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image/image.dart' as img;
import 'package:monalisapy_features/printer/zpl/new/models/locator_zpl_template_provider.dart';
import 'package:monalisa_app_001/features/printer/zpl/old/zpl_print_widget.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common_provider.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

import '../../../products/common/messages_dialog.dart';
import 'package:monalisapy_core/models/idempiere/idempiere_locator.dart';
import '../../../products/domain/idempiere/idempiere_movement_line.dart';
import '../../../products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisapy_core/api_client/response_async_value.dart';
import '../../../shared/data/memory.dart';
import '../../printer_scan_notifier.dart';
import '../../web_template/screen/show_search_zpl_template_sheet.dart';
import 'package:monalisapy_features/printer/zpl/new/models/locator_zpl_template.dart';
import 'package:monalisapy_features/zpl_template/models/zpl_template.dart';
import 'package:monalisapy_features/printer/zpl/new/provider/always_use_last_template_provider.dart';
import 'package:monalisapy_features/printer/zpl/new/screen/template_zpl_on_use_sheet.dart';
import 'package:monalisapy_features/printer/zpl/new/provider/template_zpl_provider.dart';
import 'package:monalisapy_features/printer/zpl/new/models/zpl_template_store.dart';
import '../new/provider/template_zpl_utils.dart';
import 'package:monalisapy_features/printer/zpl/zpl_send_item_result.dart';
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



Future<void> printMovementZplDirectOrConfigure(
    WidgetRef ref,
    MovementAndLines movementAndLines,
    ) async {
  final state = ref.read(printerScanNotifierProvider);

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
      final filledAllToPrint = buildFilledMovementPreviewAllPages(
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



Future<void> printListLocatorZplDirectOrConfigure(
    WidgetRef ref,
    List<IdempiereLocator> locators,
    ) async {
  final state = ref.read(printerScanNotifierProvider);

  final ip = state.ipController.text.trim();
  final port = int.tryParse(state.portController.text.trim()) ?? 0;

  if (ip.isEmpty || port == 0) {
    showWarningMessage(ref.context, ref, Messages.ERROR_IP_PORT_INVALID);
    return;
  }
  LocatorZplTemplate? template = ref.read(selectedLocatorZplTemplateProvider) ;
  if (template == null) {
    showWarningMessage(ref.context, ref, 'Seleccione un template ZPL primero');
    return;
  }
  ref.read(initializingProvider.notifier).state = true ;
  await Future.delayed(const Duration(milliseconds: 100));
  List<String> zplList =[];
  for(IdempiereLocator locator in locators){
    final zpl = template.getSentenceToZplPrinter(locator);
    debugPrint('prepare send to zpl :${template.sentenceToSendToPrinter}');
    if (zpl.isNotEmpty) {
        zplList.add(zpl);
    }
  }
  if(zplList.isEmpty) {
    if(ref.context.mounted) {
      showWarningMessage(ref.context, ref, 'No hay locators para imprimir');
    }
    return;
  }
  final result = await sendMultipleZplBySocket(
    ip: ip,
    port: port,
    zplList: zplList,
    printingIntervalMs: 200,
    batchSize: 5,
  );

  if (ref.context.mounted) {
    await showZplBatchResultDialog(
      context: ref.context,
      result: result,
    );
  }
  await Future.delayed(const Duration(milliseconds: 100));
  ref.read(initializingProvider.notifier).state = false ;


}
/// ✅ Envía múltiples ZPL, con:
/// - printingIntervalMs: espera entre envíos (0 = no espera)
/// - batchSize: si > 1, envía en "chunks" (por ejemplo 5) y reusa una sola conexión por chunk
///   (esto suele ser más rápido y estable para muchas etiquetas)
///
/// Retorna ResponseAsyncValue:
/// - success: true si TODOS ok
/// - message: "Enviados OK X/Y"
/// - data: lista de resultados por item (index/ok/error)
Future<ResponseAsyncValue> sendMultipleZplBySocket({
  required String ip,
  required int port,
  required List<String> zplList,
  int printingIntervalMs = 0,
  int batchSize = 1,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final results = <ZplSendItemResult>[];

  if (ip.trim().isEmpty || port <= 0) {
    return ResponseAsyncValue(
      isInitiated: true,
      success: false,
      message: 'IP/Port inválidos',
      data: <Map<String, dynamic>>[],
    );
  }

  final cleanList = zplList.where((z) => z.trim().isNotEmpty).toList();
  if (cleanList.isEmpty) {
    return ResponseAsyncValue(
      isInitiated: true,
      success: false,
      message: 'Lista ZPL vacía',
      data: <Map<String, dynamic>>[],
    );
  }

  final interval = printingIntervalMs <= 0
      ? Duration.zero
      : Duration(milliseconds: printingIntervalMs);

  final int bs = batchSize < 1 ? 1 : batchSize;

  String formatPayload(String zpl) =>
      '${zpl.trim().replaceAll('\n', '\r\n')}\r\n\r\n';

  int sentOk = 0;
  int globalIndex = 0;

  for (int i = 0; i < cleanList.length; i += bs) {
    final chunk = cleanList.sublist(i, (i + bs).clamp(0, cleanList.length));

    Socket? socket;
    bool chunkSocketOk = false;
    Object? chunkError;

    try {
      socket = await Socket.connect(ip, port, timeout: timeout);
      chunkSocketOk = true;

      for (int j = 0; j < chunk.length; j++) {
        final payload = formatPayload(chunk[j]);

        try {
          socket.add(latin1.encode(payload));
          await socket.flush();

          results.add(ZplSendItemResult(index: globalIndex, ok: true));
          sentOk++;

          if (interval != Duration.zero) {
            await Future.delayed(interval);
          }
        } catch (e) {
          results.add(ZplSendItemResult(
            index: globalIndex,
            ok: false,
            error: 'write/flush error: $e',
          ));
        }

        globalIndex++;
      }
    } catch (e) {
      chunkError = e;
    } finally {
      if (!chunkSocketOk) {
        for (int j = 0; j < chunk.length; j++) {
          results.add(ZplSendItemResult(
            index: globalIndex,
            ok: false,
            error: 'connect error: $chunkError',
          ));
          globalIndex++;
        }
      }

      try {
        await socket?.close();
      } catch (_) {
        try {
          socket?.destroy();
        } catch (_) {}
      }
    }
  }

  final total = cleanList.length;
  final allOk = sentOk == total;

  return ResponseAsyncValue(
    isInitiated: true,
    success: allOk,
    message: 'Enviados OK $sentOk/$total',
    data: results.map((e) => e.toJson()).toList(),
  );
}
Future<void> printMovementTsplDirectOrConfigure(WidgetRef ref,
    MovementAndLines movementAndLines,) async {
  final state = ref.read(printerScanNotifierProvider);

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

Future<void> printLabelMovementByProductTspl60x150NoLogo({
  required String ip,
  required int port,
  required dynamic movementAndLines, // tu MovementAndLines real
  required int rowsPerLabel,         // max filas por etiqueta (ej 8)
  required int marginX,              // dots
  required int marginY,
  required WidgetRef ref,              // dots
}) async {
  // =============================
  // FÍSICO (203 dpi = 8 dots/mm)
  // =============================
  const int defaultRowsPerLabel = 13;
  const int dotsPerMm = 8;
  const int labelWmm = 60;
  const int labelHmm = 150;
  const int gapMm = 3;
  rowsPerLabel =  rowsPerLabel<defaultRowsPerLabel ? defaultRowsPerLabel : rowsPerLabel;
  const int reduceMm = 2;
  final int reduceDots = reduceMm * dotsPerMm;

  final int pw = labelWmm * dotsPerMm; // 480
  final int ll = labelHmm * dotsPerMm; // 1200
  final int usableWidth = pw - reduceDots;

  final int footerHeight = 10 * dotsPerMm; // 80

  // QR
  final int qrSize = 16 * dotsPerMm; // 128
  const int qrModel = 5;

  String stripAccents(String s) {
    return s
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ñ', 'N')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C');
  }

  String safe(dynamic v) {
    if (v == null) return '';
    if (v is num) return Memory.numberFormatter0Digit.format(v);

    final s = stripAccents(
      v.toString()
          .replaceAll('\n', ' ')
          .replaceAll('\r', ' ')
          .replaceAll('"', r'\"')
          .trim(),
    );

    if (s.isEmpty) return '';

    final asNum = num.tryParse(s.replaceAll(',', '.'));
    if (asNum != null) return Memory.numberFormatter0Digit.format(asNum);

    return s;
  }

  bool isEmptyRowProduct(IdempiereMovementLine r) {
    final name = (r.productName ?? r.uPC ?? r.sKU ?? '').trim();
    final qty = (r.movementQty is num) ? (r.movementQty as num) : num.tryParse('${r.movementQty}'.replaceAll(',', '.')) ?? 0;
    return name.isEmpty && qty == 0;
  }

  String truncateToMaxChars(String s, int maxChars) {
    final t = s.trim();
    if (maxChars <= 0) return '';
    if (t.length <= maxChars) return t;
    if (maxChars <= 1) return t.substring(0, 1);
    return '${t.substring(0, maxChars - 1)}…';
  }

  // =============================
  // HEADER DATA
  // =============================
  final String qrData = safe(movementAndLines.documentNumber ?? '');
  final String documentNumber = safe(movementAndLines.documentNumber ?? '');
  final String date = safe(movementAndLines.movementDate ?? '');
  final String documentStatus = safe(movementAndLines.documentStatus ?? '');
  final String title = safe(movementAndLines.documentMovementTitle ?? '');

  final String company = (movementAndLines.cBPartnerID?.identifier == null)
      ? ''
      : '${Messages.COMPANY} : ${safe(movementAndLines.cBPartnerID?.identifier)}';

  final String address = safe(movementAndLines.cBPartnerLocationID?.identifier ?? '');

  final String whFrom =
      '${Messages.FROM} : ${safe(movementAndLines.mWarehouseID?.identifier ?? '')}';
  final String whTo =
      '${Messages.TO} : ${safe(movementAndLines.warehouseTo?.identifier ?? '')}';

  final String totalQty = safe(movementAndLines.totalMovementQty ?? '');
  final int rowHeight = 46;   // antes 32
  final int sepY = 34;        // línea separadora dentro de la fila
  final int nameBlockH = 40;  // alto para 2 líneas

  // =============================
  // PRODUCTS (sin vacíos)
  // =============================
  final List<IdempiereMovementLine> raw =
      (movementAndLines.movementLines as List<IdempiereMovementLine>?) ?? <IdempiereMovementLine>[];

  final List<IdempiereMovementLine> lines =
  raw.where((r) => !isEmptyRowProduct(r)).toList();

  final int perPage = max(1, rowsPerLabel);
  final pages = chunkByRows<IdempiereMovementLine>(lines, perPage);
  final int totalPages = pages.isEmpty ? 1 : pages.length;
  Socket? socket ;
  try {
    // Socket
    socket = await Socket.connect(
        ip, port, timeout: const Duration(seconds: 5));

    final List<List<IdempiereMovementLine>> safePages =
    pages.isEmpty
        ? <List<IdempiereMovementLine>>[<IdempiereMovementLine>[]]
        : pages;

    for (int page = 0; page < safePages.length; page++) {
      final slice = safePages[page];
      final sb = StringBuffer();

      // =============================
      // TSPL SETUP
      // =============================
      sb.writeln('SIZE $labelWmm mm,$labelHmm mm');
      sb.writeln('GAP $gapMm mm,0 mm');
      sb.writeln('DENSITY 7');
      sb.writeln('SPEED 4');
      sb.writeln('DIRECTION 1');
      sb.writeln('REFERENCE 0,0');
      sb.writeln('CLS');

      // =========================
      // QR arriba centrado
      // =========================
      final int qrX = marginX + ((pw - qrSize) ~/ 2);
      final int qrY = marginY + 20;
      sb.writeln('QRCODE $qrX,$qrY,L,$qrModel,A,0,"$qrData"');

      // =========================
      // HEADER (igual que tu versión actual)
      // =========================
      int hy = qrY + qrSize + 14;

      final int hx = marginX + 20;
      final int hw = usableWidth - 40;

      final int fontSizeTitleY = 2;
      int fontSizeTitleX = 2;
      final int fontSize = 1;
      if (documentNumber.length > 20) fontSizeTitleX = 1;

      sb.writeln(
          'BLOCK $hx,$hy,$hw,54,"0",0,$fontSizeTitleX,$fontSizeTitleY,0,0,"No : $documentNumber"');
      hy += 60;

      final int halfW = (hw ~/ 2);
      sb.writeln(
          'BLOCK $hx,$hy,$halfW,28,"0",0,$fontSize,$fontSize,0,0,"$date"');
      sb.writeln(
          'BLOCK ${hx +
              halfW},$hy,$halfW,28,"0",0,$fontSize,$fontSize,0,2,"$documentStatus"');
      hy += 34;

      sb.writeln('BLOCK $hx,$hy,$hw,34,"0",0,$fontSize,$fontSize,0,0,"$title"');
      hy += 38;

      if (company.isNotEmpty) {
        sb.writeln(
            'BLOCK $hx,$hy,$hw,28,"0",0,$fontSize,$fontSize,0,0,"$company"');
        hy += 32;
      }
      if (address.isNotEmpty) {
        sb.writeln(
            'BLOCK $hx,$hy,$hw,26,"0",0,$fontSize,$fontSize,0,0,"$address"');
        hy += 30;
      }
      sb.writeln(
          'BLOCK $hx,$hy,$hw,26,"0",0,$fontSize,$fontSize,0,0,"$whFrom"');
      hy += 30;
      sb.writeln('BLOCK $hx,$hy,$hw,26,"0",0,$fontSize,$fontSize,0,0,"$whTo"');
      hy += 34;

      // =========================
      // TABLE HEADER
      // =========================
      sb.writeln('BAR ${marginX + 20},$hy,$hw,2');
      hy += 18;

      final int colNoX = marginX + 20;
      final int colNameX = marginX + 70;
      final int colQtyW = 96;
      final int colQtyX = marginX + pw - 20 - colQtyW;

      sb.writeln('TEXT $colNoX,$hy,"0",0,1,1,"No"');
      sb.writeln('TEXT $colNameX,$hy,"0",0,1,1,"PRODUCT"');
      sb.writeln('BLOCK $colQtyX,$hy,$colQtyW,22,"0",0,1,1,0,2,"QTY"');

      hy += 26;
      sb.writeln('BAR ${marginX + 20},$hy,$hw,2');
      hy += 24;

      // max chars para productName
      final int nameMaxDots = max(0, (colQtyX - 8) - colNameX);

      // =========================
      // BODY
      // =========================
      int y = hy;
      final int nameW = (colQtyX - 8) - colNameX;
      for (int i = 0; i < slice.length; i++) {
        final IdempiereMovementLine m = slice[i];
        const int nameLineSpacing = 10;
        final seq = safe(m.line ?? (page * perPage + i + 1));
        final nameRaw = safe(m.productName ?? m.uPC ?? m.sKU ?? '');
        final qty = safe(m.movementQty ?? 0);

        // si llega vacío de verdad
        if (nameRaw.isEmpty && qty == '0') continue;

        // Truncado: ahora calcula por ancho, pero pensando en 2 líneas
        // (dejamos un poco más de margen por seguridad)
        final int maxNameChars2Lines = max(8, (nameMaxDots ~/ 8) * 2);
        final name = truncateToMaxChars(nameRaw, maxNameChars2Lines);

        sb.writeln('TEXT $colNoX,$y,"0",0,1,1,"$seq"');

        // ✅ productName en 2 líneas (alineado izquierda)
        sb.writeln(
            'BLOCK $colNameX,$y,$nameW,$nameBlockH,"0",0,1,1,$nameLineSpacing,0,"$name"'
        );
        sb.writeln('BLOCK $colQtyX,$y,$colQtyW,24,"0",0,1,1,0,2,"$qty"');

        sb.writeln('BAR ${marginX + 20},${y + sepY},$hw,1');
        y += rowHeight;

        final footerTop = ll - marginY - footerHeight;
        if (y > footerTop - 60) break;
      }


      // =========================
      // FOOTER
      // =========================
      final int fy = marginY + 1060;

      sb.writeln(
          'BLOCK ${marginX + 20},$fy,200,24,"0",0,1,1,0,0,"TOTAL QTY :"');
      sb.writeln('BLOCK $colQtyX,$fy,$colQtyW,24,"0",0,1,1,0,2,"$totalQty"');

      sb.writeln('BAR ${marginX + 20},${fy + 28},$hw,2');

      final pageInfo = '${page + 1}/$totalPages';
      sb.writeln('BLOCK $colQtyX,${fy + 54},80,24,"0",0,1,1,0,2,"$pageInfo"');

      sb.writeln('PRINT 1,1');

      socket.add(utf8.encode(sb.toString()));
    }

    await socket.flush();
    await socket.close();
    if(ref.context.mounted)showSuccessMessage(ref.context, ref, Messages.LABEL_PRINTED);
  } catch(e){
    debugPrint('Error: $e');
    socket?.close();
    if(ref.context.mounted)showErrorMessage(ref.context, ref, "${Messages.ERROR}: ${e.toString()}");
  }
}














