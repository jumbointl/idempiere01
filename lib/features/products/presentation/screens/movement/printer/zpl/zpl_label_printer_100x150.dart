import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image/image.dart' as img;
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/template/tspl_label_printer.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/zpl_print_widget.dart';

import '../../../../../common/messages_dialog.dart';
import '../../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../../domain/idempiere/movement_and_lines.dart';
import '../pos_image_utility.dart';
import '../printer_scan_notifier.dart';
import 'label_utils.dart';
import 'new/template_zpl_models.dart';
import 'new/template_zpl_on_create_editor_sheet.dart';
import 'new/template_zpl_store.dart';
import 'new/template_zpl_utils.dart';
import 'zpl_print_profile_providers.dart';

String zplSafe(String s) {
  return s
      .replaceAll('^', ' ')
      .replaceAll('~', ' ')
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ')
      .trim();
}

/// ===============================
/// CONFIG (solo márgenes afectan impresión práctica)
/// ===============================
class ZplLabelConfig100x150 {
  final int marginX;
  final int marginY;
  const ZplLabelConfig100x150({required this.marginX, required this.marginY});

  static const int pw = 800;  // 100mm * 8
  static const int ll = 1200; // 150mm * 8

  // Layout fijo en dots (según tu decisión)
  static const int headerHeight = 320;      // 40mm incl QR
  static const int tableHeaderHeight = 80;  // 10mm
  static const int footerHeight = 80;       // 10mm
}

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

/// ===============================
/// PRINT API (paginado)
/// movementAndLines: tu MovementAndLines real
/// ===============================
Future<void> printLabelZpl100x150({
  required String ip,
  required int port,
  required dynamic movementAndLines, // MovementAndLines real
  required ZplPrintProfile profile,
  int gfaTargetWidth = 760,
  int gfaThreshold = 175,
  bool gfaInvert = false,
}) async {
  final cfg = ZplLabelConfig100x150(
    marginX: profile.marginX,
    marginY: profile.marginY,
  );

  // clamp por cálculo físico
  final maxAllowed = maxRowsAllowed(
    marginY: profile.marginY,
    rowPerProductName: profile.rowPerProductName,
  );
  final rowsPerLabel = min(profile.rowsPerLabel, maxAllowed);

  // Header combinado (logo+QR)
  final String qrData = zplSafe((movementAndLines.documentNumber ?? '') as String);
  final String logo = (movementAndLines.movementIcon ?? '') as String;

  final combinedPng = await combineLogoAndQrCode(logo: logo, qrData: qrData);
  final gfa = pngBytesToZplGfa(
    combinedPng,
    targetWidthDots: min(gfaTargetWidth, ZplLabelConfig100x150.pw - cfg.marginX * 2),
    threshold: gfaThreshold,
    invert: gfaInvert,
  );

  // Datos básicos
  final String title = zplSafe((movementAndLines.documentMovementTitle ?? '') as String);
  final String date = zplSafe((movementAndLines.movementDate ?? '') as String);
  final String company = zplSafe((movementAndLines.cBPartnerID?.identifier ?? '') as String);
  final String documentNumber = zplSafe((movementAndLines.documentNumber ?? '') as String);
  final String documentStatus = zplSafe((movementAndLines.documentStatus ?? '') as String);
  final String address = zplSafe((movementAndLines.cBPartnerLocationID?.identifier ?? '') as String);
  final String description = zplSafe((movementAndLines.description ?? '') as String);

  final List<dynamic> lines =
  (movementAndLines.movementLines ?? const <dynamic>[]) as List<dynamic>;

  final double totalQty = lines.fold<double>(
    0,
        (a, e) => a + (((e.movementQty as num?)?.toDouble()) ?? 0.0),
  );

  final int totalPages = lines.isEmpty
      ? 1
      : ((lines.length + rowsPerLabel - 1) ~/ rowsPerLabel);

  for (int page = 0; page < totalPages; page++) {
    final int start = page * rowsPerLabel;
    final int end = min<int>(start + rowsPerLabel, lines.length);
    final List<dynamic> slice = lines.isEmpty ? <dynamic>[] : lines.sublist(start, end);

    final sb = StringBuffer();
    sb.writeln('^XA');
    sb.writeln('^CI28');
    sb.writeln('^PW${ZplLabelConfig100x150.pw}');
    sb.writeln('^LL${ZplLabelConfig100x150.ll}');
    sb.writeln('^LH0,0');
    //sb.writeln('^SD8');
    sb.writeln('^PR3');

    // ===== HEADER (40mm total) =====
    // Imagen combinada
    sb.writeln('^FO${cfg.marginX},${cfg.marginY}');
    sb.writeln('$gfa^FS');

    // Info compacta en 2 columnas dentro del header
    // (ponerla debajo de la imagen; ajusta yInfo si tu imagen es alta)
    final int yInfo = cfg.marginY + 120;
    final int rightColX = ZplLabelConfig100x150.pw - cfg.marginX - 360;

    sb.writeln('^FO${cfg.marginX},$yInfo^A0N,24,18^FD$date^FS');
    sb.writeln('^FO$rightColX,$yInfo^FB360,1,0,R^A0N,24,18^FD$documentStatus^FS');
    sb.writeln('^FO$rightColX,${yInfo + 28}^FB360,1,0,R^A0N,44,32^FD$documentNumber^FS');

    // Company / Address / Desc (compacto)
    final int y2 = yInfo + 65;
    sb.writeln('^FO${cfg.marginX},$y2^A0N,22,18^FD$company^FS');
    sb.writeln('^FO${cfg.marginX},${y2 + 24}^A0N,22,18^FD$address^FS');
    sb.writeln('^FO${cfg.marginX},${y2 + 48}^FB${ZplLabelConfig100x150.pw - cfg.marginX * 2},2,0,L^A0N,22,18^FD$description^FS');

    // Separador header->tabla
    final int yHeaderSep = cfg.marginY + ZplLabelConfig100x150.headerHeight - 2;
    sb.writeln('^FO${cfg.marginX},$yHeaderSep^GB${ZplLabelConfig100x150.pw - cfg.marginX * 2},2,2^FS');

    // ===== TABLE HEADER (10mm) =====
    int y = cfg.marginY + ZplLabelConfig100x150.headerHeight + 8;
    sb.writeln('^FO${cfg.marginX},$y^A0N,22,18^FDUPC/SKU^FS');
    sb.writeln('^FO${ZplLabelConfig100x150.pw - cfg.marginX - 260},$y^A0N,22,18^FDHASTA/DESDE^FS');
    y += 24;
    sb.writeln('^FO${cfg.marginX},$y^A0N,22,18^FDATTRIBUTO^FS');
    sb.writeln('^FO${ZplLabelConfig100x150.pw - cfg.marginX - 200},$y^A0N,22,18^FDCANTIDAD^FS');

    final int yTableEnd = cfg.marginY +
        ZplLabelConfig100x150.headerHeight +
        ZplLabelConfig100x150.tableHeaderHeight;
    sb.writeln('^FO${cfg.marginX},$yTableEnd^GB${ZplLabelConfig100x150.pw - cfg.marginX * 2},2,2^FS');

    // ===== BODY (paginado) =====
    y = yTableEnd + 10;

    // linePitch consistente con el cálculo
    const int linePitch = 32;
    final int nameLines = profile.rowPerProductName.clamp(1, 2);

    for (final r in slice) {
      final upc = zplSafe((r.uPC ?? '') as String);
      final sku = zplSafe((r.sKU ?? '') as String);
      final to = zplSafe((r.locatorToName ?? '') as String);
      final from = zplSafe((r.locatorFromName ?? '') as String);
      final atr = zplSafe((r.attributeName ?? '--') as String);
      final product = zplSafe((r.productNameWithLine ?? '') as String);
      final qty = (((r.movementQty as num?)?.toDouble()) ?? 0.0).toStringAsFixed(0);

      // UPC + TO
      sb.writeln('^FO${cfg.marginX},$y^A0N,28,20^FD$upc^FS');
      sb.writeln('^FO${ZplLabelConfig100x150.pw - cfg.marginX - 420},$y^FB420,1,0,R^A0N,28,20^FD$to^FS');
      y += linePitch;

      // SKU + FROM
      sb.writeln('^FO${cfg.marginX},$y^A0N,28,20^FD$sku^FS');
      sb.writeln('^FO${ZplLabelConfig100x150.pw - cfg.marginX - 420},$y^FB420,1,0,R^A0N,28,20^FD$from^FS');
      y += linePitch;

      // ATR
      sb.writeln('^FO${cfg.marginX},$y^A0N,28,20^FD$atr^FS');
      y += linePitch;

      // PRODUCT (1 o 2 líneas)
      sb.writeln(
        '^FO${cfg.marginX},$y'
            '^FB${ZplLabelConfig100x150.pw - cfg.marginX * 2 - 160},$nameLines,0,L'
            '^A0N,28,20'
            '^FD$product^FS',
      );

      // QTY grande derecha (alineado arriba de la zona product)
      sb.writeln(
        '^FO${ZplLabelConfig100x150.pw - cfg.marginX - 140},${y - 6}'
            '^FB140,1,0,R^A0N,50,40^FD$qty^FS',
      );

      y += (linePitch * nameLines);

      // separador
      sb.writeln('^FO${cfg.marginX},$y^GB${ZplLabelConfig100x150.pw - cfg.marginX * 2},1,1^FS');
      y += 10;
    }

    // ===== FOOTER (10mm) =====
    final int yFooter = ZplLabelConfig100x150.ll - cfg.marginY - ZplLabelConfig100x150.footerHeight + 20;
    final String left = 'ITEMS: ${lines.length}';
    final String mid = 'TOTAL: ${totalQty.toStringAsFixed(0)}';
    final String right = '${page + 1}/$totalPages';

    sb.writeln('^FO${cfg.marginX},${ZplLabelConfig100x150.ll - cfg.marginY - ZplLabelConfig100x150.footerHeight}^GB${ZplLabelConfig100x150.pw - cfg.marginX * 2},2,2^FS');

    sb.writeln('^FO${cfg.marginX},$yFooter^A0N,28,20^FD$left^FS');
    sb.writeln('^FO${(ZplLabelConfig100x150.pw / 2).round() - 120},$yFooter^A0N,28,20^FD$mid^FS');
    sb.writeln('^FO${ZplLabelConfig100x150.pw - cfg.marginX - 120},$yFooter^FB120,1,0,R^A0N,28,20^FD$right^FS');

    sb.writeln('^XZ');

    await sendZpl(ip: ip, port: port, zpl: sb.toString());
  }



}


Future<void> printZplDirectOrConfigure(
    WidgetRef ref,
    MovementAndLines movementAndLines,
    ) async {
  final state = ref.read(printerScanProvider);

  final ip = state.ipController.text.trim();
  final port = int.tryParse(state.portController.text.trim()) ?? 0;

  if (ip.isEmpty || port == 0) {
    showWarningMessage(ref.context, ref, 'IP/PORT inválido');
    return;
  }

  // ============================================================
  // ✅ 0) Intentar primero: template guardado (mode=movement)
  // ============================================================
  final box = GetStorage();
  final store = ZplTemplateStore(box);

  // Normaliza por si hay más de 1 default
  await store.normalizeDefaults();

  final movementTemplates = store
      .loadAll()
      .where((t) => t.mode == ZplTemplateMode.movement)
      .toList();
  if(movementTemplates.isEmpty) {

    ZplTemplate newTemplate = defaultZplMovementTemplate;
    if (newTemplate.zplReferenceTxt.isNotEmpty) {
      final missing = validateMissingTokens(
          template: newTemplate, referenceTxt: newTemplate.zplReferenceTxt);
      if (missing.isEmpty) {
        await printReferenceBySocket(
          ip: ip,
          port: port,
          template: newTemplate,
          movementAndLines: movementAndLines,
        );
        return; // ✅ ya imprimió con template
      }
    }

  } else {
    ZplTemplate chosen;

    // Elegir default si existe
    final defaults = movementTemplates.where((t) => t.isDefault).toList();
    if (defaults.isNotEmpty) {
      chosen = defaults.first;
    } else {
      chosen = movementTemplates.first;
    }

    // ✅ Si hay 1 solo y no está default => marcarlo default
    if (movementTemplates.length == 1 && chosen.isDefault == false) {
      final updated = chosen.copyWith(isDefault: true);
      await store.upsert(updated);
      chosen = updated;
    }

    // Debe tener Reference
    final referenceTxt = chosen.zplReferenceTxt.trim();

    if (referenceTxt.isNotEmpty) {
      print(referenceTxt);
      final missing = validateMissingTokens(
          template: chosen, referenceTxt: referenceTxt);
      if (missing.isEmpty) {
        await printReferenceBySocket(
          ip: ip,
          port: port,
          template: chosen,
          movementAndLines: movementAndLines,
        );
        return; // ✅ ya imprimió con template
      }
    }
  }

  // ============================================================
  // ✅ 1) Si no hay template movement guardado, seguir flujo actual
  // ============================================================

  // ===== 0) Leer tipo guardado o pedirlo =====
  ZplLabelType? labelType =
  zplLabelTypeFromStorage(box.read<String>(kZplLabelTypeKey));

  if (labelType == null && ref.context.mounted) {
    labelType = await showZplLabelTypeSheet(ref.context);
    if (labelType == null) return; // canceló
  }

  // ===== 1) Perfil =====
  ZplPrintProfile? profile = loadActiveOrFirstProfile();

  if (profile == null) {
    if(ref.context.mounted) {
      await showZplPrintProfilesSheet(ref.context, ref);
    }

    profile = loadActiveOrFirstProfile();
    if (profile == null) return;
  }

  final int rows = profile.rowsPerLabel < 4 ? 4 : profile.rowsPerLabel;
  final int my = profile.marginY > 40 ? profile.marginY : 40;
  if (labelType == null) return;
  // ===== 2) Imprimir según tipo =====
  switch (labelType) {
    case ZplLabelType.movementDetail:
      await printLabelZplMovementByProduct100x150NoLogo(
        ip: ip,
        port: port,
        movementAndLines: movementAndLines,
        rowsPerLabel: rows <8 ? 8:rows,
        marginX: profile.marginX,
        marginY: my, ref: ref,
      );
      break;

    case ZplLabelType.movementByCategory:
      await printLabelZplMovementSortedByCategory100x150NoLogo(
        ip: ip,
        port: port,
        movementAndLines: movementAndLines,
        rowsPerLabel: rows,
        marginX: profile.marginX,
        marginY: my, ref: ref,
      );
      break;
  }
}
/*Future<void> printZplDirectOrConfigure(
    WidgetRef ref,
    MovementAndLines movementAndLines,
    ) async {
  final state = ref.read(printerScanProvider);

  final ip = state.ipController.text.trim();
  final port = int.tryParse(state.portController.text.trim()) ?? 0;

  if (ip.isEmpty || port == 0) {
    showWarningMessage(ref.context, ref, 'IP/PORT inválido');
    return;
  }

  // ============================================================
  // ✅ 0) Intentar primero: template guardado (mode=movement)
  // ============================================================
  final box = GetStorage();
  final store = ZplTemplateStore(box);

  // Normaliza por si hay más de 1 default
  await store.normalizeDefaults();

  final movementTemplates = store
      .loadAll()
      .where((t) => t.mode == ZplTemplateMode.movement)
      .toList();
  if(movementTemplates.isEmpty) {

    ZplTemplate newTemplate = ZplTemplate(
      id:'',
      isDefault: false,
      zplReferenceTxt: referenceTxtOfMovementByCategoryNoTemplateTxt,
      zplTemplateDf: '',
      mode: ZplTemplateMode.movement,
      rowPerpage: 8,
      createdAt: DateTime.now(),
      templateFileName: '',
    );
    if (newTemplate.zplReferenceTxt.isNotEmpty) {
      final missing = validateMissingTokens(
          template: newTemplate, referenceTxt: newTemplate.zplReferenceTxt);
      if (missing.isEmpty) {
        await printReferenceBySocket(
          ip: ip,
          port: port,
          template: newTemplate,
          movementAndLines: movementAndLines,
        );
        return; // ✅ ya imprimió con template
      }
    }

  } else {
    ZplTemplate chosen;

    // Elegir default si existe
    final defaults = movementTemplates.where((t) => t.isDefault).toList();
    if (defaults.isNotEmpty) {
      chosen = defaults.first;
    } else {
      chosen = movementTemplates.first;
    }

    // ✅ Si hay 1 solo y no está default => marcarlo default
    if (movementTemplates.length == 1 && chosen.isDefault == false) {
      final updated = chosen.copyWith(isDefault: true);
      await store.upsert(updated);
      chosen = updated;
    }

    // Debe tener Reference
    final referenceTxt = chosen.zplReferenceTxt.trim();
    if (referenceTxt.isNotEmpty) {
      final missing = validateMissingTokens(
          template: chosen, referenceTxt: referenceTxt);
      if (missing.isEmpty) {
        await printReferenceBySocket(
          ip: ip,
          port: port,
          template: chosen,
          movementAndLines: movementAndLines,
        );
        return; // ✅ ya imprimió con template
      }
    }
  }

  // ============================================================
  // ✅ 1) Si no hay template movement guardado, seguir flujo actual
  // ============================================================

  // ===== 0) Leer tipo guardado o pedirlo =====
  ZplLabelType? labelType =
  zplLabelTypeFromStorage(box.read<String>(kZplLabelTypeKey));

  if (labelType == null) {
    labelType = await showZplLabelTypeSheet(ref.context);
    if (labelType == null) return; // canceló
  }

  // ===== 1) Perfil =====
  ZplPrintProfile? profile = loadActiveOrFirstProfile();

  if (profile == null) {
    if(ref.context.mounted) {
      await showZplPrintProfilesSheet(ref.context, ref);
    }

    profile = loadActiveOrFirstProfile();
    if (profile == null) return;
  }

  final int rows = profile.rowsPerLabel < 4 ? 4 : profile.rowsPerLabel;
  final int my = profile.marginY > 40 ? profile.marginY : 40;

  // ===== 2) Imprimir según tipo =====
  switch (labelType) {
    case ZplLabelType.movementDetail:
      await printLabelZplMovementByProduct100x150NoLogo(
        ip: ip,
        port: port,
        movementAndLines: movementAndLines,
        rowsPerLabel: rows <8 ? 8:rows,
        marginX: profile.marginX,
        marginY: my, ref: ref,
      );
      break;

    case ZplLabelType.movementByCategory:
      await printLabelZplMovementSortedByCategory100x150NoLogo(
        ip: ip,
        port: port,
        movementAndLines: movementAndLines,
        rowsPerLabel: rows,
        marginX: profile.marginX,
        marginY: my, ref: ref,
      );
      break;
  }
}*/


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

Future<void> printLabelZplMovementDetail100x150NoLogo({
  required String ip,
  required int port,
  required dynamic movementAndLines, // tu MovementAndLines real
  required int rowsPerLabel,         // productos por etiqueta
  required int rowPerProductName,    // 1 o 2
  required int marginX,              // dots
  required int marginY,              // dots
}) async {
  // ===== Constantes físicas (203dpi = 8 dots/mm) =====
  const int pw = 800;          // 100mm
  const int ll = 1200;         // 150mm
  const int headerHeight = 200;      // 25mm
  const int tableHeaderHeight = 80;  // 10mm
  const int footerHeight = 80;       // 10mm

  // Restar 7mm al ancho de área de impresión:
  // 7mm * 8 dots/mm = 56 dots
  const int reduceWidthDots = 56;
  final int usableWidth = pw - reduceWidthDots; // 744

  String safe(String s) => s
      .replaceAll('^', ' ')
      .replaceAll('~', ' ')
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ')
      .trim();

  // ===== Datos header =====
  final String qrData = safe(movementAndLines.documentNumber ?? '');
  final String documentNumber = safe(movementAndLines.documentNumber ?? '');
  final String date = safe(movementAndLines.movementDate ?? '');
  final String documentStatus = safe(movementAndLines.documentStatus ?? '');
  final String company = safe(movementAndLines.cBPartnerID?.identifier ?? '');
  final String title = safe(movementAndLines.documentMovementTitle ?? '');






  // ===== Lines =====
  final List<dynamic> lines =
  (movementAndLines.movementLines ?? const <dynamic>[]) as List<dynamic>;

  final int totalPages =
  lines.isEmpty ? 1 : ((lines.length + rowsPerLabel - 1) ~/ rowsPerLabel);

  // ===== Socket =====
  final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));

  for (int page = 0; page < totalPages; page++) {
    final int start = page * rowsPerLabel;
    final int end = min<int>(start + rowsPerLabel, lines.length);
    final List<dynamic> slice = lines.isEmpty ? <dynamic>[] : lines.sublist(start, end);

    final sb = StringBuffer();

    sb.writeln('^XA');
    sb.writeln('^CI28');
    sb.writeln('^PW$pw');
    sb.writeln('^LL$ll');
    sb.writeln('^LH0,0');
    sb.writeln('^LS0');
    //sb.writeln('^SD8');
    sb.writeln('^PR3');
    // =====================================================
    // HEADER NUEVO ~25mm (200 dots)
    // QR a la IZQUIERDA (20mm ≈ 160 dots)
    // Textos a la derecha, alineados a la DERECHA
    // Ancho usable = 744 dots
    // =====================================================

    final int qrSize = 160; // ~20mm
    const int gap = 12;     // separación QR->texto

    final int qrX = marginX;      // izquierda
    final int qrY = marginY;

    // QR
    sb.writeln('^FO$qrX,$qrY');
    sb.writeln('^BQN,2,8'); // ajusta 7..9 si quieres
    sb.writeln('^FD$qrData^FS');

    // Texto a la derecha del QR dentro de ancho usable
    final int textX = marginX + qrSize + gap;
    final int textWidth = usableWidth - qrSize - gap;

    // Fila 1: documentNumber (derecha)
    sb.writeln(
      '^FO$textX,${marginY + 4}'
          '^FB$textWidth,1,0,R'
          '^A0N,44,32'
          '^FD$documentNumber^FS',
    );

    // Fila 2: date (center) + documentStatus (right)
    final int half = (textWidth / 2).round();
    sb.writeln(
      '^FO$textX,${marginY + 56}'
          '^FB$half,1,0,C'
          '^A0N,24,18'
          '^FD$date^FS',
    );
    sb.writeln(
      '^FO${textX + half},${marginY + 56}'
          '^FB$half,1,0,R'
          '^A0N,24,18'
          '^FD$documentStatus^FS',
    );

    // Fila 3: company (derecha)
    sb.writeln(
      '^FO$textX,${marginY + 88}'
          '^FB$textWidth,1,0,R'
          '^A0N,26,20'
          '^FD$company^FS',
    );

    // Fila 4: title (derecha)
    sb.writeln(
      '^FO$textX,${marginY + 120}'
          '^FB$textWidth,1,0,R'
          '^A0N,30,22'
          '^FD$title^FS',
    );

    // Separador header -> tabla (mismo ancho usable)
    sb.writeln(
      '^FO$marginX,${marginY + headerHeight - 2}'
          '^GB$usableWidth,2,2^FS',
    );

    // =====================================================
    // TABLE HEADER (10mm)
    // =====================================================
    int y = marginY + headerHeight + 8;

    // Usamos el ancho usable para posicionar columnas
    sb.writeln('^FO$marginX,$y^A0N,22,18^FDUPC/SKU^FS');
    sb.writeln('^FO${marginX + usableWidth - 260},$y^A0N,22,18^FDHASTA/DESDE^FS');

    y += 24;
    sb.writeln('^FO$marginX,$y^A0N,22,18^FDATTRIBUTO^FS');
    sb.writeln('^FO${marginX + usableWidth - 200},$y^A0N,22,18^FDCANTIDAD^FS');

    final int yTableEnd = marginY + headerHeight + tableHeaderHeight;
    sb.writeln('^FO$marginX,$yTableEnd^GB$usableWidth,2,2^FS');

    // =====================================================
    // BODY
    // =====================================================
    y = yTableEnd + 10;

    const int linePitch = 32;
    final int nameLines = rowPerProductName.clamp(1, 2);

    for (final r in slice) {
      final upc = safe(r.uPC ?? '');
      final sku = safe(r.sKU ?? '');
      final to = safe(r.locatorToName ?? '');
      final from = safe(r.locatorFromName ?? '');
      final atr = safe(r.attributeName ?? '--');
      final product = safe(r.productNameWithLine ?? '');
      final qty = ((r.movementQty as num?)?.toInt() ?? 0).toString();

      // Col derecha (to/from) dentro del ancho usable
      final int rightBlockX = marginX + usableWidth - 420;

      // UPC + TO
      sb.writeln('^FO$marginX,$y^A0N,28,20^FD$upc^FS');
      sb.writeln('^FO$rightBlockX,$y^FB420,1,0,R^A0N,28,20^FD$to^FS');
      y += linePitch;

      // SKU + FROM
      sb.writeln('^FO$marginX,$y^A0N,28,20^FD$sku^FS');
      sb.writeln('^FO$rightBlockX,$y^FB420,1,0,R^A0N,28,20^FD$from^FS');
      y += linePitch;

      // ATR
      sb.writeln('^FO$marginX,$y^A0N,28,20^FD$atr^FS');
      y += linePitch;

      // PRODUCT (1 o 2 líneas)
      // reservamos 160 dots a la derecha para QTY grande
      final int productWidth = usableWidth - 160;

      sb.writeln(
        '^FO$marginX,$y'
            '^FB$productWidth,$nameLines,0,L'
            '^A0N,28,20'
            '^FD$product^FS',
      );

      // QTY grande a la derecha dentro del ancho usable
      sb.writeln(
        '^FO${marginX + usableWidth - 140},${y - 6}'
            '^FB140,1,0,R'
            '^A0N,50,40'
            '^FD$qty^FS',
      );

      y += linePitch * nameLines;

      // separador
      sb.writeln('^FO$marginX,$y^GB$usableWidth,1,1^FS');
      y += 10;
    }

    // =====================================================
    // FOOTER (10mm)
    // =====================================================
    final int yFooterLine = ll - marginY - footerHeight;
    final int yFooterText = yFooterLine + 20;

    sb.writeln('^FO$marginX,$yFooterLine^GB$usableWidth,2,2^FS');

    final String right = '${page + 1}/$totalPages';
    sb.writeln(
      '^FO${marginX + usableWidth - 120},$yFooterText'
          '^FB120,1,0,R'
          '^A0N,28,20'
          '^FD$right^FS',
    );

    sb.writeln('^XZ');

    socket.add(utf8.encode(sb.toString()));
  }

  await socket.flush();
  await socket.close();
}


Map<String, int> pickA0ByWidth({
  required String text,
  required int maxDots,
  required int baseH,
  required int baseW,
  int minH = 16,
  int minW = 12,
}) {
  final t = text.trim();
  if (t.isEmpty) return {'h': baseH, 'w': baseW};

  final est = t.length * baseW;
  if (est <= maxDots) return {'h': baseH, 'w': baseW};

  final scale = maxDots / est; // < 1
  final newW = max(minW, (baseW * scale).floor());
  final newH = max(minH, (baseH * scale).floor());

  return {'h': newH, 'w': newW};
}

String truncateEllipsis(String s, int maxChars) {
  final t = s.trim();
  if (maxChars <= 0) return '';
  if (t.length <= maxChars) return t;
  if (maxChars == 1) return '…';
  return '${t.substring(0, maxChars - 1)}…';
}

Future<void> printLabelZplMovementSortedByCategory100x150NoLogo({
  required String ip,
  required int port,
  required dynamic movementAndLines,
  required int rowsPerLabel,
  required int marginX,
  required int marginY,
  required WidgetRef ref,
}) async {
  // ===== Físico =====
  const int pw = 800;   // 100mm
  const int ll = 1200;  // 150mm

  const int footerHeight = 80;       // 10mm
  const int tableHeaderHeight = 80;  // 10mm

  const int reduceWidthDots = 56; // 7mm
  final int usableWidth = pw - reduceWidthDots; // 744

  // Header normal/compacto
  const int headerNormal = 480; // 60mm
  const int headerCompact = 420; // ~52.5mm

  // gaps internos de seguridad (líneas + separaciones)
  const int gapHeaderToTable = 8;
  const int gapTableToBody = 10;
  const int gapBodyToFooterSafety = 8;

  // ===== Datos header =====
  final String qrData = safe(movementAndLines.documentNumber ?? '');
  final String documentNumber = safe(movementAndLines.documentNumber ?? '');
  final String date = safe(movementAndLines.movementDate ?? '');
  final String documentStatus = safe(movementAndLines.documentStatus ?? '');
  final String company = safe(movementAndLines.cBPartnerID?.identifier ?? '');
  final String title = safe(movementAndLines.documentMovementTitle ?? '');

  final String address = safe(movementAndLines.cBPartnerLocationID?.identifier ?? '');
  final String warehouseFrom = safe(movementAndLines.mWarehouseID?.identifier ?? '');
  final String warehouseTo = safe(movementAndLines.warehouseTo?.identifier ?? '');

  // ===== Lines -> Categories agg =====
  final List<dynamic> lines =
  (movementAndLines.movementLines ?? const <dynamic>[]) as List<dynamic>;

  final Map<String, CategoryAgg> map = {};
  for (final r in lines) {
    final String categoryName = safe(
      r.mProductID?.mProductCategoryID?.identifier ?? 'category null',
    );
    final String categoryId = safe(
      r.mProductID?.mProductCategoryID?.id?.toString() ?? 'category id null',
    );

    final String key = '$categoryId|$categoryName';
    final num q = (r.movementQty as num?) ?? 0;

    map.update(
      key,
          (old) => old.copyWith(totalQty: old.totalQty + q),
      ifAbsent: () => CategoryAgg(
        categoryId: categoryId,
        categoryName: categoryName,
        totalQty: q,
      ),
    );
  }

  final List<CategoryAgg> categories = map.values.toList()
    ..sort((a, b) => a.categoryName.toLowerCase().compareTo(b.categoryName.toLowerCase()));

  final num totalQtyAll = categories.fold<num>(0, (sum, c) => sum + c.totalQty);
  final String totalItemsText = 'Total items: ${totalQtyAll.toStringAsFixed(0)}';

  final int perPage = max(1, rowsPerLabel);
  final int totalPages = categories.isEmpty ? 1 : ((categories.length + perPage - 1) ~/ perPage);

  // ===== Decide header compacto si hace falta =====
  bool headerWouldOverflow(int headerH, int rowH) {
    final needed = marginY +
        headerH +
        gapHeaderToTable +
        tableHeaderHeight +
        gapTableToBody +
        (perPage * rowH) +
        gapBodyToFooterSafety +
        footerHeight;
    return needed > ll;
  }

  // first guess
  int headerHeight = headerNormal;

  // espacio disponible para body (según headerHeight)
  int computeRowHeight(int headerH) {
    final availableBody = ll
        - marginY
        - footerHeight
        - gapBodyToFooterSafety
        - (marginY + headerH + gapHeaderToTable + tableHeaderHeight + gapTableToBody);
    if (availableBody <= 0) return 40; // fallback ultra seguro
    return (availableBody ~/ perPage);
  }

  // rowHeight dinámico (primero con header normal)
  int rowHeight = computeRowHeight(headerHeight);

  // límites razonables
  rowHeight = rowHeight.clamp(50, 80); // 6.25mm .. 10mm aprox

  // si aún así overflow, usa header compacto y recalcula rowHeight
  if (headerWouldOverflow(headerHeight, rowHeight)) {
    headerHeight = headerCompact;
    rowHeight = computeRowHeight(headerHeight).clamp(50, 80);
  }

  // si todavía overflow (caso extremo), fuerza rowHeight mínimo
  if (headerWouldOverflow(headerHeight, rowHeight)) {
    rowHeight = 50; // mínimo razonable
  }

  // ===== Socket con manejo de errores =====
  Socket? socket;
  try {
    socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));

    for (int page = 0; page < totalPages; page++) {
      final int start = page * perPage;
      final int end = min<int>(start + perPage, categories.length);

      final List<CategoryAgg> slice =
      categories.isEmpty ? <CategoryAgg>[] : categories.sublist(start, end);

      final sb = StringBuffer();

      sb.writeln('^XA');
      sb.writeln('^CI28');
      sb.writeln('^PW$pw');
      sb.writeln('^LL$ll');
      sb.writeln('^LH0,0');
      sb.writeln('^LS0');
      sb.writeln('^PR3');

      // =====================================================
      // HEADER (normal/compacto)
      // =====================================================
      final int qrSize = 160;
      const int gap = 12;

      final int qrX = marginX;
      final int qrY = marginY;

      sb.writeln('^FO$qrX,$qrY');
      sb.writeln('^BQN,2,8');
      sb.writeln('^FD$qrData^FS');

      final int textX = marginX + qrSize + gap;
      final int textWidth = usableWidth - qrSize - gap;

      // fuentes dependientes del modo compacto
      final bool compact = headerHeight == headerCompact;
      final int hDoc = compact ? 36 : 44;
      final int wDoc = compact ? 26 : 32;

      final int hSmall = compact ? 20 : 24;
      final int wSmall = compact ? 14 : 18;

      final int hCompany = compact ? 24 : 26;
      final int wCompany = compact ? 18 : 20;

      final int hTitle = compact ? 26 : 30;
      final int wTitle = compact ? 18 : 22;

      final int d1 = compact ? 44 : 52;
      final int d2 = compact ? 26 : 32;
      final int d3 = compact ? 28 : 32;
      final int d4 = compact ? 28 : 36;
      final int d5 = compact ? 24 : 28;
      final int d6 = compact ? 24 : 28;

      int ty = marginY + 4;

      // 1) documentNumber
      sb.writeln(
        '^FO$textX,$ty'
            '^FB$textWidth,1,0,R'
            '^A0N,$hDoc,$wDoc'
            '^FD$documentNumber^FS',
      );

      // 2) date + status (fecha izquierda, status derecha)
      ty += d1;
      final int half = (textWidth / 2).round();
      sb.writeln(
        '^FO$textX,$ty'
            '^FB$half,1,0,L'
            '^A0N,$hSmall,$wSmall'
            '^FD$date^FS',
      );
      sb.writeln(
        '^FO${textX + half},$ty'
            '^FB$half,1,0,R'
            '^A0N,$hSmall,$wSmall'
            '^FD$documentStatus^FS',
      );

      // 3) company
      ty += d2;
      sb.writeln(
        '^FO$textX,$ty'
            '^FB$textWidth,1,0,R'
            '^A0N,$hCompany,$wCompany'
            '^FD$company^FS',
      );

      // 4) title
      ty += d3;
      sb.writeln(
        '^FO$textX,$ty'
            '^FB$textWidth,1,0,R'
            '^A0N,$hTitle,$wTitle'
            '^FD$title^FS',
      );

      // 5) Dirección
      ty += d4;
      sb.writeln(
        '^FO$textX,$ty'
            '^FB$textWidth,1,0,R'
            '^A0N,22,18'
            '^FDDireccion: $address^FS',
      );

      // 6) From
      ty += d5;
      sb.writeln(
        '^FO$textX,$ty'
            '^FB$textWidth,1,0,R'
            '^A0N,22,18'
            '^FDFrom: $warehouseFrom^FS',
      );

      // 7) To
      ty += d6;
      sb.writeln(
        '^FO$textX,$ty'
            '^FB$textWidth,1,0,R'
            '^A0N,22,18'
            '^FDTO: $warehouseTo^FS',
      );

      // Separador header -> tabla
      sb.writeln(
        '^FO$marginX,${marginY + headerHeight - 2}'
            '^GB$usableWidth,2,2^FS',
      );

      // =====================================================
      // TABLE HEADER
      // =====================================================
      int y = marginY + headerHeight + gapHeaderToTable;

      const int colNo = 70;
      const int colQty = 140;
      final int colName = usableWidth - colNo - colQty;

      sb.writeln('^FO$marginX,$y^A0N,22,18^FDNo^FS');
      sb.writeln('^FO${marginX + colNo},$y^A0N,22,18^FDCATEGORY NAME^FS');
      sb.writeln(
        '^FO${marginX + colNo + colName},$y'
            '^FB$colQty,1,0,R'
            '^A0N,22,18'
            '^FDQTY^FS',
      );

      final int yTableEnd = marginY + headerHeight + tableHeaderHeight;
      sb.writeln('^FO$marginX,$yTableEnd^GB$usableWidth,2,2^FS');

      // =====================================================
      // BODY – N filas por categoría (AUTO rowHeight)
      // =====================================================
      y = yTableEnd + gapTableToBody;

      for (int i = 0; i < slice.length && i < perPage; i++) {
        final item = slice[i];

        final int seq = start + i + 1;
        final String catNameRaw = safe(item.categoryName);
        final String qtyText = item.totalQty.toStringAsFixed(0);

        // (opcional) truncado suave para evitar nombres absurdos
        final String catName = truncateEllipsis(catNameRaw, 60);

        // Auto font para categoryName
        final font = pickA0ByWidth(
          text: catName,
          maxDots: colName,
          baseH: 24,
          baseW: 18,
          minH: 16,
          minW: 12,
        );

        // No
        sb.writeln(
          '^FO$marginX,$y'
              '^FB$colNo,1,0,L'
              '^A0N,24,18'
              '^FD$seq^FS',
        );

        // Category name (auto reduce)
        sb.writeln(
          '^FO${marginX + colNo},$y'
              '^FB$colName,1,0,L'
              '^A0N,${font['h']},${font['w']}'
              '^FD$catName^FS',
        );

        // Qty derecha
        sb.writeln(
          '^FO${marginX + colNo + colName},$y'
              '^FB$colQty,1,0,R'
              '^A0N,28,22'
              '^FD$qtyText^FS',
        );

        // Separador
        final int ySep = y + rowHeight - 4;
        sb.writeln('^FO$marginX,$ySep^GB$usableWidth,1,1^FS');

        y += rowHeight;
      }

      // =====================================================
      // FOOTER
      // =====================================================
      final int yFooterLine = ll - marginY - footerHeight;
      final int yFooterText = yFooterLine + 20;

      sb.writeln('^FO$marginX,$yFooterLine^GB$usableWidth,2,2^FS');

      sb.writeln(
        '^FO$marginX,$yFooterText'
            '^FB${usableWidth - 140},1,0,L'
            '^A0N,26,20'
            '^FD$totalItemsText^FS',
      );

      final String right = '${page + 1}/$totalPages';
      sb.writeln(
        '^FO${marginX + usableWidth - 120},$yFooterText'
            '^FB120,1,0,R'
            '^A0N,28,20'
            '^FD$right^FS',
      );

      sb.writeln('^XZ');

      socket.add(utf8.encode(sb.toString()));
    }

    await socket.flush();
    await socket.close();

    if(ref.context.mounted)showSuccessMessage(ref.context,ref,'Impresión enviada correctamente.');
  } catch (e) {
    try {
      await socket?.close();
    } catch (_) {}
    if(ref.context.mounted)showErrorMessage(ref.context,ref,'Error al imprimir / conectar: $e');
  }
}

Future<void> printLabelZplMovementByProduct100x150NoLogo({
  required String ip,
  required int port,
  required MovementAndLines movementAndLines,
  required int rowsPerLabel, // recomendado: 8
  required int marginX,
  required int marginY,
  required WidgetRef ref,
}) async {
  // ===== Físico =====
  const int pw = 800;   // 100mm
  const int ll = 1200;  // 150mm

  const int footerHeight = 80;
  const int tableHeaderHeight = 80;

  const int reduceWidthDots = 56;
  final int usableWidth = pw - reduceWidthDots;

  const int headerNormal = 480;
  const int headerCompact = 420;

  const int gapHeaderToTable = 8;
  const int gapTableToBody = 10;
  const int gapBodyToFooterSafety = 8;

  // ===== Header data =====
  final String qrData = safe(movementAndLines.documentNumber ?? '');
  final String documentNumber = safe(movementAndLines.documentNumber ?? '');
  final String date = safe(movementAndLines.movementDate ?? '');
  final String documentStatus = safe(movementAndLines.documentStatus ?? '');
  final String company = safe(movementAndLines.cBPartnerID?.identifier ?? '');
  final String title = safe(movementAndLines.documentMovementTitle ?? '');

  final String address = safe(movementAndLines.cBPartnerLocationID?.identifier ?? '');
  final String warehouseFrom = safe(movementAndLines.mWarehouseID?.identifier ?? '');
  final String warehouseTo = safe(movementAndLines.warehouseTo?.identifier ?? '');

  // ===== PRODUCTS =====
  final List<IdempiereMovementLine> lines = movementAndLines.movementLines ??
          <IdempiereMovementLine>[];

  final int perPage = max(1, rowsPerLabel);
  final int totalPages =
  lines.isEmpty ? 1 : ((lines.length + perPage - 1) ~/ perPage);

  // ===== Layout helpers =====
  bool headerWouldOverflow(int headerH, int rowH) {
    final needed = marginY +
        headerH +
        gapHeaderToTable +
        tableHeaderHeight +
        gapTableToBody +
        (perPage * rowH) +
        gapBodyToFooterSafety +
        footerHeight;
    return needed > ll;
  }

  int computeRowHeight(int headerH) {
    final availableBody = ll -
        marginY -
        footerHeight -
        gapBodyToFooterSafety -
        (marginY +
            headerH +
            gapHeaderToTable +
            tableHeaderHeight +
            gapTableToBody);
    if (availableBody <= 0) return 40;
    return (availableBody ~/ perPage);
  }

  int headerHeight = headerNormal;
  int rowHeight = computeRowHeight(headerHeight).clamp(50, 80);

  if (headerWouldOverflow(headerHeight, rowHeight)) {
    headerHeight = headerCompact;
    rowHeight = computeRowHeight(headerHeight).clamp(50, 80);
  }
  if (headerWouldOverflow(headerHeight, rowHeight)) {
    rowHeight = 50;
  }

  // ===== Socket =====
  Socket? socket;
  try {
    socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));

    for (int page = 0; page < totalPages; page++) {
      final int start = page * perPage;
      final int end = min(start + perPage, lines.length);
      final slice = lines.sublist(start, end);

      final sb = StringBuffer();

      sb
        ..writeln('^XA')
        ..writeln('^CI28')
        ..writeln('^PW$pw')
        ..writeln('^LL$ll')
        ..writeln('^LH0,0')
        ..writeln('^LS0')
        ..writeln('^PR3');

      // ================= HEADER =================
      final int qrSize = 160;
      const int gap = 12;

      sb
        ..writeln('^FO$marginX,$marginY')
        ..writeln('^BQN,2,8')
        ..writeln('^FD$qrData^FS');

      final int textX = marginX + qrSize + gap;
      final int textWidth = usableWidth - qrSize - gap;

      final bool compact = headerHeight == headerCompact;

      final int hDoc = compact ? 36 : 44;
      final int wDoc = compact ? 26 : 32;

      final int hSmall = compact ? 20 : 24;
      final int wSmall = compact ? 14 : 18;

      final int hTitle = compact ? 26 : 30;
      final int wTitle = compact ? 18 : 22;

      int ty = marginY + 4;

      sb.writeln(
        '^FO$textX,$ty^FB$textWidth,1,0,R^A0N,$hDoc,$wDoc^FD$documentNumber^FS',
      );

      ty += compact ? 44 : 52;
      final half = (textWidth / 2).round();

      sb.writeln(
        '^FO$textX,$ty^FB$half,1,0,L^A0N,$hSmall,$wSmall^FD$date^FS',
      );
      sb.writeln(
        '^FO${textX + half},$ty^FB$half,1,0,R^A0N,$hSmall,$wSmall^FD$documentStatus^FS',
      );

      ty += compact ? 26 : 32;
      sb.writeln(
        '^FO$textX,$ty^FB$textWidth,1,0,R^A0N,26,20^FD$company^FS',
      );

      ty += compact ? 28 : 32;
      sb.writeln(
        '^FO$textX,$ty^FB$textWidth,1,0,R^A0N,$hTitle,$wTitle^FD$title^FS',
      );

      ty += compact ? 28 : 36;
      sb.writeln(
        '^FO$textX,$ty^FB$textWidth,1,0,R^A0N,22,18^FDDireccion: $address^FS',
      );

      ty += compact ? 24 : 28;
      sb.writeln(
        '^FO$textX,$ty^FB$textWidth,1,0,R^A0N,22,18^FDFrom: $warehouseFrom^FS',
      );

      ty += compact ? 24 : 28;
      sb.writeln(
        '^FO$textX,$ty^FB$textWidth,1,0,R^A0N,22,18^FDTO: $warehouseTo^FS',
      );

      sb.writeln(
        '^FO$marginX,${marginY + headerHeight - 2}^GB$usableWidth,2,2^FS',
      );

      // ================= TABLE HEADER =================
      int y = marginY + headerHeight + gapHeaderToTable;

      const int colNo = 70;
      const int colQty = 140;
      final int colName = usableWidth - colNo - colQty;

      sb
        ..writeln('^FO$marginX,$y^A0N,22,18^FDNo^FS')
        ..writeln('^FO${marginX + colNo},$y^A0N,22,18^FDPRODUCT NAME^FS')
        ..writeln(
          '^FO${marginX + colNo + colName},$y^FB$colQty,1,0,R^A0N,22,18^FDQTY^FS',
        );

      final int yTableEnd = marginY + headerHeight + tableHeaderHeight;
      sb.writeln('^FO$marginX,$yTableEnd^GB$usableWidth,2,2^FS');

      // ================= BODY =================
      y = yTableEnd + gapTableToBody;

      for (int i = 0; i < slice.length && i < perPage; i++) {
        final m = slice[i];

        final seq = safe((m.line ?? (start + i + 1)).toString());
        final nameRaw = safe(m.productName ?? '');
        final qtyText = safe((m.movementQty ?? 0).toString());

        final name = truncateEllipsis(nameRaw, 60);

        final font = pickA0ByWidth(
          text: name,
          maxDots: colName,
          baseH: 24,
          baseW: 18,
          minH: 16,
          minW: 12,
        );

        sb.writeln(
          '^FO$marginX,$y^FB$colNo,1,0,L^A0N,24,18^FD$seq^FS',
        );

        sb.writeln(
          '^FO${marginX + colNo},$y'
              '^FB$colName,1,0,L'
              '^A0N,${font['h']},${font['w']}'
              '^FD$name^FS',
        );

        sb.writeln(
          '^FO${marginX + colNo + colName},$y'
              '^FB$colQty,1,0,R'
              '^A0N,28,22'
              '^FD$qtyText^FS',
        );

        sb.writeln(
          '^FO$marginX,${y + rowHeight - 4}^GB$usableWidth,1,1^FS',
        );

        y += rowHeight;
      }

      // ================= FOOTER =================
      final int yFooterLine = ll - marginY - footerHeight;
      final int yFooterText = yFooterLine + 20;

      sb.writeln('^FO$marginX,$yFooterLine^GB$usableWidth,2,2^FS');

      sb.writeln(
        '^FO$marginX,$yFooterText'
            '^FB${usableWidth - 140},1,0,L'
            '^A0N,26,20'
            '^FDItems: ${lines.length}^FS',
      );

      final right = '${page + 1}/$totalPages';
      sb.writeln(
        '^FO${marginX + usableWidth - 120},$yFooterText'
            '^FB120,1,0,R'
            '^A0N,28,20'
            '^FD$right^FS',
      );

      sb.writeln('^XZ');

      socket.add(utf8.encode(sb.toString()));
    }

    await socket.flush();
    await socket.close();

    if (ref.context.mounted) {
      showSuccessMessage(ref.context, ref, 'Impresión enviada correctamente.');
    }
  } catch (e) {
    try {
      await socket?.close();
    } catch (_) {}
    if (ref.context.mounted) {
      showErrorMessage(ref.context, ref, 'Error al imprimir / conectar: $e');
    }
  }
}


