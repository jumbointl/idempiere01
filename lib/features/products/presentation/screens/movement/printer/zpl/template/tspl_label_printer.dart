import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_line.dart';

import '../../../../../../../shared/data/memory.dart';
import '../../../../../../../shared/data/messages.dart';
import '../new/template_zpl_models.dart';

String buildTspl100x150TemplateNoLogoAll({
  required int marginX,
  required int marginY,
}) {
  final sb = StringBuffer();

  sb.writeln('SIZE 100 mm,150 mm');
  sb.writeln('GAP 3 mm,0 mm');
  sb.writeln('DENSITY 10');
  sb.writeln('SPEED 4');
  sb.writeln('DIRECTION 1');
  sb.writeln('REFERENCE 0,0');
  sb.writeln('CLS');

  // =========================
  // HEADER
  // =========================
  sb.writeln('QRCODE 20,20,L,6,A,0,"__DOCUMENT_NUMBER"');

  sb.writeln('BLOCK 192,24,572,44,"0",0,2,2,0,2,"__DOCUMENT_NUMBER"');
  sb.writeln('BLOCK 192,76,286,24,"0",0,1,1,0,1,"__DATE"');
  sb.writeln('BLOCK 478,76,286,24,"0",0,1,1,0,2,"__STATUS"');

  sb.writeln('BLOCK 192,108,572,38,"0",0,2,2,0,2,"__TITLE"');
  sb.writeln('BLOCK 192,148,572,30,"0",0,1,1,0,2,"__COMPANY"');
  sb.writeln('BLOCK 192,184,572,22,"0",0,1,1,0,2,"__ADDRESS"');
  sb.writeln('BLOCK 192,212,572,22,"0",0,1,1,0,2,"__WAREHOUSE_FROM"');
  sb.writeln('BLOCK 192,240,572,22,"0",0,1,1,0,2,"__WAREHOUSE_TO"');

  // =========================
  // TABLE HEADER
  // =========================
  sb.writeln('BAR 20,300,744,2');

  sb.writeln('TEXT 20,330,"0",0,1,1,"No"');
  sb.writeln('TEXT 90,330,"0",0,1,1,"CATEGORY NAME"');
  sb.writeln('BLOCK 624,330,140,22,"0",0,1,1,0,2,"QTY"');

  sb.writeln('BAR 20,382,744,2');

  // =========================
  // CATEGORY ROWS (0–7)
  // =========================
  int y = 412;
  for (int i = 0; i < 8; i++) {
    sb.writeln('TEXT 20,$y,"0",0,1,1,"__CATEGORY_SEQUENCE$i"');
    sb.writeln('TEXT 90,$y,"0",0,1,1,"__CATEGORY_NAME$i"');
    sb.writeln('BLOCK 624,$y,140,28,"0",0,1,1,0,2,"__CATEGORY_QTY$i"');
    sb.writeln('BAR 20,${y + 54},744,1');
    y += 80;
  }

  // =========================
  // FOOTER
  // =========================
  sb.writeln('BLOCK 20,1060,360,28,"0",0,1,1,0,0,"TOTAL QTY :"');
  sb.writeln('BLOCK 380,1060,384,28,"0",0,1,1,0,2,"__TOTAL_QUANTITY"');

  sb.writeln('BAR 20,1090,744,2');
  sb.writeln(
    'BLOCK 644,1120,120,28,"0",0,1,1,0,2,"__PAGE_NUMBER_OVER_TOTAL_PAGE"',
  );

  sb.writeln('PRINT 1,1');

  return sb.toString();
}

Future<void> printLabelMovementByCategoryTspl100x150NoLogo({
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
  const int dotsPerMm = 8;
  const int labelWmm = 100;
  const int labelHmm = 150;
  const int gapMm = 3;

  const int reduceMm = 7;
  final int reduceDots = reduceMm * dotsPerMm; // 56

  final int pw = labelWmm * dotsPerMm; // 800
  final int ll = labelHmm * dotsPerMm; // 1200
  final int usableWidth = pw - reduceDots; // 744

  // alturas (como tu template)
  final int headerHeight = 25 * dotsPerMm; // 200
  final int tableHeaderHeight = 10 * dotsPerMm; // 80
  final int footerHeight = 10 * dotsPerMm; // 80

  // QR
  final int qrSize = 20 * dotsPerMm; // 160
  const int qrGap = 12;

  String safe(dynamic v) {
    if (v == null) return '';
    // números => 0 decimales
    if (v is num) return Memory.numberFormatter0Digit.format(v);

    final s = v
        .toString()
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll('"', r'\"')
        .trim();

    if (s.isEmpty) return '';

    final asNum = num.tryParse(s.replaceAll(',', '.'));
    if (asNum != null) return Memory.numberFormatter0Digit.format(asNum);

    return s;
  }

  bool isEmptyRow(CategoryAgg r) {
    final nameEmpty = r.categoryName.trim().isEmpty;
    final qtyEmpty = (r.totalQty == 0);
    // “vacía” si no aporta nada
    return nameEmpty && qtyEmpty;
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

  // =============================
  // CATEGORIES tipadas + filtro (sin vacías)
  // =============================
  final List<CategoryAgg> raw =
      (movementAndLines.movementLineByCategories as List<CategoryAgg>?) ??
          <CategoryAgg>[];

  final List<CategoryAgg> categories = raw.where((r) => !isEmptyRow(r)).toList();

  final int perPage = max(1, rowsPerLabel);
  final pages = chunkByRows<CategoryAgg>(categories, perPage);
  final int totalPages = pages.isEmpty ? 1 : pages.length;

  // Socket
  Socket? socket;
  try{
    socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));

    // si no hay nada, igual imprimir 1 página con header/footer
    final List<List<CategoryAgg>> safePages =
    pages.isEmpty ? <List<CategoryAgg>>[<CategoryAgg>[]] : pages;

    for (int page = 0; page < safePages.length; page++) {
      final slice = safePages[page];
      final sb = StringBuffer();

      // =============================
      // TSPL SETUP
      // =============================
      sb.writeln('SIZE $labelWmm mm,$labelHmm mm');
      sb.writeln('GAP $gapMm mm,0 mm');
      sb.writeln('DENSITY 10');
      sb.writeln('SPEED 4');
      sb.writeln('DIRECTION 1');
      sb.writeln('REFERENCE 0,0');
      sb.writeln('CLS');

      // =========================
      // HEADER (igual al template)
      // =========================
      sb.writeln('QRCODE ${marginX + 20},${marginY + 20},L,6,A,0,"$qrData"');

      final int textX = marginX + 192;
      const int textW = 572;
      const int halfW = 286;

      sb.writeln('BLOCK $textX,${marginY + 24},$textW,44,"0",0,2,2,0,2,"$documentNumber"');
      sb.writeln('BLOCK $textX,${marginY + 76},$halfW,24,"0",0,1,1,0,1,"$date"');
      sb.writeln('BLOCK ${textX + halfW},${marginY + 76},$halfW,24,"0",0,1,1,0,2,"$documentStatus"');

      sb.writeln('BLOCK $textX,${marginY + 108},$textW,38,"0",0,2,2,0,2,"$title"');
      sb.writeln('BLOCK $textX,${marginY + 148},$textW,30,"0",0,1,1,0,2,"$company"');
      sb.writeln('BLOCK $textX,${marginY + 184},$textW,22,"0",0,1,1,0,2,"$address"');
      sb.writeln('BLOCK $textX,${marginY + 212},$textW,22,"0",0,1,1,0,2,"$whFrom"');
      sb.writeln('BLOCK $textX,${marginY + 240},$textW,22,"0",0,1,1,0,2,"$whTo"');

      // =========================
      // TABLE HEADER (igual al template)
      // =========================
      sb.writeln('BAR ${marginX + 20},${marginY + 300},$usableWidth,2');
      sb.writeln('TEXT ${marginX + 20},${marginY + 330},"0",0,1,1,"No"');
      sb.writeln('TEXT ${marginX + 90},${marginY + 330},"0",0,1,1,"CATEGORY NAME"');
      sb.writeln('BLOCK ${marginX + 624},${marginY + 330},140,22,"0",0,1,1,0,2,"QTY"');
      sb.writeln('BAR ${marginX + 20},${marginY + 382},$usableWidth,2');

      // =========================
      // BODY dinámico (sin huecos)
      // =========================
      int y = marginY + 412;
      for (int i = 0; i < slice.length; i++) {
        final row = slice[i];

        final seq = safe(row.sequence ?? (page * perPage + i + 1));
        final name = safe(row.categoryName);
        final qty = safe(row.totalQty);

        // si por alguna razón llega “vacía”, saltar
        if (name.isEmpty && (row.totalQty == 0)) continue;

        sb.writeln('TEXT ${marginX + 20},$y,"0",0,1,1,"$seq"');
        sb.writeln('TEXT ${marginX + 90},$y,"0",0,1,1,"$name"');
        sb.writeln('BLOCK ${marginX + 624},$y,140,28,"0",0,1,1,0,2,"$qty"');

        sb.writeln('BAR ${marginX + 20},${y + 54},$usableWidth,1');
        y += 80;

        // seguridad: no invadir footer
        final footerTop = ll - marginY - footerHeight;
        if (y > footerTop - 40) break;
      }

      // =========================
      // FOOTER (igual al template)
      // =========================
      sb.writeln('BLOCK ${marginX + 20},${marginY + 1060},360,28,"0",0,1,1,0,0,"TOTAL QTY :"');
      sb.writeln('BLOCK ${marginX + 380},${marginY + 1060},384,28,"0",0,1,1,0,2,"$totalQty"');

      sb.writeln('BAR ${marginX + 20},${marginY + 1090},$usableWidth,2');

      final pageInfo = '${page + 1}/$totalPages';
      sb.writeln('BLOCK ${marginX + 644},${marginY + 1120},120,28,"0",0,1,1,0,2,"$pageInfo"');

      sb.writeln('PRINT 1,1');

      socket.add(utf8.encode(sb.toString()));
    }

    await socket.flush();
    await socket.close();
    if(ref.context.mounted)showSuccessMessage(ref.context, ref, Messages.LABEL_PRINTED);
  } catch(e){
    print('Error: $e');
    socket?.close();
    if(ref.context.mounted)showErrorMessage(ref.context, ref, "${Messages.ERROR}: ${e.toString()}");
  }
}

/// chunk (ya lo tenías, lo dejo igual)
List<List<T>> chunkByRows<T>(List<T> items, int rowsPerLabel) {
  final out = <List<T>>[];
  for (int i = 0; i < items.length; i += rowsPerLabel) {
    out.add(items.sublist(
      i,
      (i + rowsPerLabel) > items.length ? items.length : (i + rowsPerLabel),
    ));
  }
  return out;
}


Future<void> printLabelMovementByCategoryTspl60x150NoLogo({
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
  const int dotsPerMm = 8;
  const int labelWmm = 60;
  const int labelHmm = 150;
  const int gapMm = 3;

  // En 60mm conviene reducir menos que en 100mm
  const int reduceMm = 2;
  final int reduceDots = reduceMm * dotsPerMm;

  final int pw = labelWmm * dotsPerMm; // 480
  final int ll = labelHmm * dotsPerMm; // 1200
  final int usableWidth = pw - reduceDots;

  // Footer
  final int footerHeight = 10 * dotsPerMm; // 80

  // QR (un poco más chico para 60mm)
  final int qrSize = 16 * dotsPerMm; // 128
  const int qrModel = 5; // <- pedido

  String stripAccents(String s) {
    // Reemplazo puntual pedido (rápido y controlado)
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

  bool isEmptyRow(CategoryAgg r) {
    final nameEmpty = r.categoryName.trim().isEmpty;
    final qtyEmpty = (r.totalQty == 0);
    return nameEmpty && qtyEmpty;
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

  // =============================
  // CATEGORIES tipadas + filtro (sin vacías)
  // =============================
  final List<CategoryAgg> raw =
      (movementAndLines.movementLineByCategories as List<CategoryAgg>?) ?? <CategoryAgg>[];

  final List<CategoryAgg> categories = raw.where((r) => !isEmptyRow(r)).toList();

  final int perPage = max(1, rowsPerLabel);
  final pages = chunkByRows<CategoryAgg>(categories, perPage);
  final int totalPages = pages.isEmpty ? 1 : pages.length;

  // Socket
  Socket? socket;
  try{
    socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));

    final List<List<CategoryAgg>> safePages =
    pages.isEmpty ? <List<CategoryAgg>>[<CategoryAgg>[]] : pages;

    for (int page = 0; page < safePages.length; page++) {
      final slice = safePages[page];
      final sb = StringBuffer();

      // =============================
      // TSPL SETUP
      // =============================
      sb.writeln('SIZE $labelWmm mm,$labelHmm mm');
      sb.writeln('GAP $gapMm mm,0 mm');
      sb.writeln('DENSITY 10');
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
      // HEADER (compacto, izquierda) +1 tamaño de fuente
      // =========================
      int hy = qrY + qrSize + 14;

      final int hx = marginX + 20;
      final int hw = usableWidth - 40;
      final int fontSizeTitleY =2 ;
      int fontSizeTitleX =2 ;
      final int fontSize = 1;
      if(documentNumber.length>20) fontSizeTitleX =1 ;

      // Document No: +1 fila (más alto) y escala +1 (3,3)
      sb.writeln('BLOCK $hx,$hy,$hw,54,"0",0,$fontSizeTitleX,$fontSizeTitleY,0,0,"No : $documentNumber"');
      hy += 60;

      // Fecha (izq) y Estado (der) en la misma fila, escala +1 (2,2)
      final int halfW = (hw ~/ 2);
      sb.writeln('BLOCK $hx,$hy,$halfW,28,"0",0,$fontSize,$fontSize,0,0,"$date"');
      sb.writeln('BLOCK ${hx + halfW},$hy,$halfW,28,"0",0,$fontSize,$fontSize,0,2,"$documentStatus"');
      hy += 34;

      // Título escala +1
      sb.writeln('BLOCK $hx,$hy,$hw,34,"0",0,$fontSize,$fontSize,0,0,"$title"');
      hy += 38;

      if (company.isNotEmpty) {
        sb.writeln('BLOCK $hx,$hy,$hw,28,"0",0,$fontSize,$fontSize,0,0,"$company"');
        hy += 32;
      }
      if (address.isNotEmpty) {
        sb.writeln('BLOCK $hx,$hy,$hw,26,"0",0,$fontSize,$fontSize,0,0,"$address"');
        hy += 30;
      }
      sb.writeln('BLOCK $hx,$hy,$hw,26,"0",0,$fontSize,$fontSize,0,0,"$whFrom"');
      hy += 30;
      sb.writeln('BLOCK $hx,$hy,$hw,26,"0",0,$fontSize,$fontSize,0,0,"$whTo"');
      hy += 34;

      // =========================
      // TABLE HEADER (adaptado a 60mm)
      // =========================
      sb.writeln('BAR ${marginX + 20},$hy,$hw,2');
      hy += 18;

      // Columnas (más compactas)
      final int colNoX = marginX + 20;
      final int colNameX = marginX + 70;
      final int colQtyW = 96;
      final int colQtyX = marginX + pw - 20 - colQtyW;

      // Títulos (mantengo escala 1 para no apretar)
      sb.writeln('TEXT $colNoX,$hy,"0",0,1,1,"No"');
      sb.writeln('TEXT $colNameX,$hy,"0",0,1,1,"CATEGORY"');
      sb.writeln('BLOCK $colQtyX,$hy,$colQtyW,22,"0",0,1,1,0,2,"QTY"');

      hy += 26;
      sb.writeln('BAR ${marginX + 20},$hy,$hw,2');
      hy += 24;

      // =========================
      // Cálculo de max chars para categoryName
      // =========================
      final int nameMaxDots = max(0, (colQtyX - 8) - colNameX);
      final int maxNameChars = max(4, (nameMaxDots ~/ 8));

      // =========================
      // BODY dinámico
      // =========================
      int y = hy;
      for (int i = 0; i < slice.length; i++) {
        final row = slice[i];

        final seq = safe(row.sequence ?? (page * perPage + i + 1));
        final nameRaw = safe(row.categoryName);
        final name = truncateToMaxChars(nameRaw, maxNameChars);
        final qty = safe(row.totalQty);

        if (name.isEmpty && (row.totalQty == 0)) continue;

        sb.writeln('TEXT $colNoX,$y,"0",0,1,1,"$seq"');
        sb.writeln('TEXT $colNameX,$y,"0",0,1,1,"$name"');
        sb.writeln('BLOCK $colQtyX,$y,$colQtyW,24,"0",0,1,1,0,2,"$qty"');

        sb.writeln('BAR ${marginX + 20},${y + 22},$hw,1');
        y += 32;

        final footerTop = ll - marginY - footerHeight;
        if (y > footerTop - 60) break;
      }

      // =========================
      // FOOTER
      // =========================
      final int fy = marginY + 1060;

      // Label a la izquierda
      sb.writeln('BLOCK ${marginX + 20},$fy,200,24,"0",0,1,1,0,0,"TOTAL QTY :"');

      // Valor TOTAL alineado con la columna QTY (mismo X que colQtyX)
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
    print('Error: $e');
    socket?.close();
    if(ref.context.mounted)showErrorMessage(ref.context, ref, "${Messages.ERROR}: ${e.toString()}");
  }
}




// Reutiliza tu Memory, Messages, etc.
// Requiere: class IdempiereMovementLine { String? productName; dynamic movementQty; dynamic line; ... }

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
      final int maxNameChars = max(4, (nameMaxDots ~/ 8));

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
        /*sb.writeln(
        'BLOCK $colNameX,$y,${(colQtyX - 8) - colNameX},$nameBlockH,"0",0,1,1,0,0,"$name"',
      );*/
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
    print('Error: $e');
    socket?.close();
    if(ref.context.mounted)showErrorMessage(ref.context, ref, "${Messages.ERROR}: ${e.toString()}");
  }
}


