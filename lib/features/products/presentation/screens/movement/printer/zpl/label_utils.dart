import 'dart:math';

import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/zpl_print_profile_providers.dart';


String buildZpl100x150NoLogoAll({
  required dynamic movementAndLines,
  required ZplLabelType labelType,
  required int rowsPerLabel,
  required int rowPerProductName,
  required int marginX,
  required int marginY,
}) {
  const int pw = 800;
  const int ll = 1200;

  const int reduceWidthDots = 56; // 7mm * 8
  final int usableWidth = pw - reduceWidthDots; // 744

  const int qrSize = 160; // 20mm
  const int gap = 12;

  String safe(String s) => s
      .replaceAll('^', ' ')
      .replaceAll('~', ' ')
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ')
      .trim();

  String truncate(String s, int maxChars) {
    final t = safe(s);
    if (t.length <= maxChars) return t;
    return '${t.substring(0, maxChars - 1)}…';
  }

  final String qrData = safe(movementAndLines.documentNumber ?? '');
  final String documentNumber = safe(movementAndLines.documentNumber ?? '');
  final String date = safe(movementAndLines.movementDate ?? '');
  final String documentStatus = safe(movementAndLines.documentStatus ?? '');
  final String company = safe(movementAndLines.cBPartnerID?.identifier ?? '');
  final String title = safe(movementAndLines.documentMovementTitle ?? '');

  final out = StringBuffer();

  // =======================================================================
  // =============== 1) MOVEMENT DETAIL (TU ACTUAL) =========================
  // =======================================================================
  if (labelType == ZplLabelType.movementDetail) {
    const int headerHeight = 200; // 25mm
    const int tableHeaderHeight = 80; // 10mm
    const int footerHeight = 80; // 10mm

    final List<dynamic> lines =
    (movementAndLines.movementLines ?? const <dynamic>[]) as List<dynamic>;

    final int totalPages =
    lines.isEmpty ? 1 : ((lines.length + rowsPerLabel - 1) ~/ rowsPerLabel);

    for (int page = 0; page < totalPages; page++) {
      final int start = page * rowsPerLabel;
      final int end = min(start + rowsPerLabel, lines.length);
      final slice = lines.isEmpty ? <dynamic>[] : lines.sublist(start, end);

      final sb = StringBuffer();
      sb.writeln('^XA');
      sb.writeln('^CI28');
      sb.writeln('^PW$pw');
      sb.writeln('^LL$ll');
      sb.writeln('^LH0,0');
      sb.writeln('^LS0');
      sb.writeln('^PR3');

      // HEADER
      final int qrX = marginX;
      final int qrY = marginY;

      sb.writeln('^FO$qrX,$qrY');
      sb.writeln('^BQN,2,8');
      sb.writeln('^FDLA,$qrData^FS');

      final int textX = marginX + qrSize + gap;
      final int textWidth = usableWidth - qrSize - gap;

      sb.writeln(
        '^FO$textX,${marginY + 4}'
            '^FB$textWidth,1,0,R^A0N,44,32^FD$documentNumber^FS',
      );

      final int half = (textWidth / 2).round();
      sb.writeln(
        '^FO$textX,${marginY + 56}'
            '^FB$half,1,0,C^A0N,24,18^FD$date^FS',
      );
      sb.writeln(
        '^FO${textX + half},${marginY + 56}'
            '^FB$half,1,0,R^A0N,24,18^FD$documentStatus^FS',
      );

      sb.writeln(
        '^FO$textX,${marginY + 88}'
            '^FB$textWidth,1,0,R^A0N,26,20^FD$company^FS',
      );
      sb.writeln(
        '^FO$textX,${marginY + 120}'
            '^FB$textWidth,1,0,R^A0N,30,22^FD$title^FS',
      );

      sb.writeln(
        '^FO$marginX,${marginY + headerHeight - 2}'
            '^GB$usableWidth,2,2^FS',
      );

      // TABLE HEADER
      int y = marginY + headerHeight + 8;
      sb.writeln('^FO$marginX,$y^A0N,22,18^FDUPC/SKU^FS');
      sb.writeln('^FO${marginX + usableWidth - 260},$y^A0N,22,18^FDHASTA/DESDE^FS');
      y += 24;
      sb.writeln('^FO$marginX,$y^A0N,22,18^FDATTRIBUTO^FS');
      sb.writeln('^FO${marginX + usableWidth - 200},$y^A0N,22,18^FDCANTIDAD^FS');

      final int yTableEnd = marginY + headerHeight + tableHeaderHeight;
      sb.writeln('^FO$marginX,$yTableEnd^GB$usableWidth,2,2^FS');

      // BODY
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

        final int rightBlockX = marginX + usableWidth - 420;

        sb.writeln('^FO$marginX,$y^A0N,28,20^FD$upc^FS');
        sb.writeln('^FO$rightBlockX,$y^FB420,1,0,R^A0N,28,20^FD$to^FS');
        y += linePitch;

        sb.writeln('^FO$marginX,$y^A0N,28,20^FD$sku^FS');
        sb.writeln('^FO$rightBlockX,$y^FB420,1,0,R^A0N,28,20^FD$from^FS');
        y += linePitch;

        sb.writeln('^FO$marginX,$y^A0N,28,20^FD$atr^FS');
        y += linePitch;

        final int productWidth = usableWidth - 160;
        sb.writeln(
          '^FO$marginX,$y^FB$productWidth,$nameLines,0,L^A0N,28,20^FD$product^FS',
        );

        sb.writeln(
          '^FO${marginX + usableWidth - 140},${y - 6}'
              '^FB140,1,0,R^A0N,50,40^FD$qty^FS',
        );

        y += linePitch * nameLines;
        sb.writeln('^FO$marginX,$y^GB$usableWidth,1,1^FS');
        y += 10;
      }

      // FOOTER
      final int yFooterLine = ll - marginY - footerHeight;
      final int yFooterText = yFooterLine + 20;


      sb.writeln('^FO$marginX,$yFooterLine^GB$usableWidth,2,2^FS');
      sb.writeln(
        '^FO${marginX + usableWidth - 120},$yFooterText'
            '^FB120,1,0,R^A0N,28,20^FD${page + 1}/$totalPages^FS',
      );

      sb.writeln('^XZ');

      out.writeln(sb.toString());
      out.writeln();
    }

    return out.toString();
  }

  // =======================================================================
  // =============== 2) MOVEMENT BY CATEGORY (NUEVO) ========================
  // =======================================================================
  // Header alto 60mm
  const int headerHeight = 480; // 60mm
  const int tableHeaderHeight = 80; // 10mm
  const int footerHeight = 80; // 10mm
  const int rowHeight = 80; // 10mm (fila fija)

  final String address =
  safe(movementAndLines.cBPartnerLocationID?.identifier ?? '');
  final String warehouseFrom =
  safe(movementAndLines.mWarehouseID?.identifier ?? '');
  final String warehouseTo =
  safe(movementAndLines.warehouseTo?.identifier ?? '');

  final List<dynamic> lines =
  (movementAndLines.movementLines ?? const <dynamic>[]) as List<dynamic>;

  final Map<String, num> qtyByKey = {};
  final Map<String, String> nameByKey = {};

  for (final r in lines) {
    final String categoryName = safe(
      r.mProductID?.mProductCategoryID?.identifier ?? 'category null',
    );
    final String categoryId = safe(
      r.mProductID?.mProductCategoryID?.id?.toString() ?? 'category id null',
    );

    final String key = '$categoryId|$categoryName';
    final num q = (r.movementQty as num?) ?? 0;

    qtyByKey[key] = (qtyByKey[key] ?? 0) + q;
    nameByKey[key] = categoryName;
  }
  final num totalQtyAll = lines.fold<num>(
    0,
        (sum, r) => sum + ((r.movementQty as num?) ?? 0),
  );
  final String totalItemsText = 'Total items: ${totalQtyAll.toStringAsFixed(0)}';

  final keys = qtyByKey.keys.toList()
    ..sort((a, b) {
      final an = (nameByKey[a] ?? a).toLowerCase();
      final bn = (nameByKey[b] ?? b).toLowerCase();
      return an.compareTo(bn);
    });

  final int totalPages =
  keys.isEmpty ? 1 : ((keys.length + rowsPerLabel - 1) ~/ rowsPerLabel);

  // Columnas tabla
  const int colNo = 70;
  const int colQty = 140;
  final int colName = usableWidth - colNo - colQty;

  for (int page = 0; page < totalPages; page++) {
    final int start = page * rowsPerLabel;
    final int end = min(start + rowsPerLabel, keys.length);
    final slice = keys.isEmpty ? <String>[] : keys.sublist(start, end);

    final sb = StringBuffer();
    sb.writeln('^XA');
    sb.writeln('^CI28');
    sb.writeln('^PW$pw');
    sb.writeln('^LL$ll');
    sb.writeln('^LH0,0');
    sb.writeln('^LS0');
    sb.writeln('^PR3');

    // HEADER (con 3 filas extra)
    final int qrX = marginX;
    final int qrY = marginY;

    sb.writeln('^FO$qrX,$qrY');
    sb.writeln('^BQN,2,8');
    sb.writeln('^FDLA,$qrData^FS');

    final int textX = marginX + qrSize + gap;
    final int textWidth = usableWidth - qrSize - gap;
    final int half = (textWidth / 2).round();

    int ty = marginY + 4;

    sb.writeln('^FO$textX,$ty^FB$textWidth,1,0,R^A0N,44,32^FD$documentNumber^FS');
    ty += 52;
    sb.writeln('^FO$textX,$ty^FB$half,1,0,C^A0N,24,18^FD$date^FS');
    sb.writeln('^FO${textX + half},$ty^FB$half,1,0,R^A0N,24,18^FD$documentStatus^FS');
    ty += 32;
    sb.writeln('^FO$textX,$ty^FB$textWidth,1,0,R^A0N,26,20^FD$company^FS');
    ty += 32;
    sb.writeln('^FO$textX,$ty^FB$textWidth,1,0,R^A0N,30,22^FD$title^FS');

    ty += 36;
    sb.writeln('^FO$textX,$ty^FB$textWidth,1,0,R^A0N,22,18^FDDireccion: $address^FS');
    ty += 28;
    sb.writeln('^FO$textX,$ty^FB$textWidth,1,0,R^A0N,22,18^FDFrom: $warehouseFrom^FS');
    ty += 28;
    sb.writeln('^FO$textX,$ty^FB$textWidth,1,0,R^A0N,22,18^FDTO: $warehouseTo^FS');

    sb.writeln(
      '^FO$marginX,${marginY + headerHeight - 2}'
          '^GB$usableWidth,2,2^FS',
    );

    // TABLE HEADER (10mm)
    int y = marginY + headerHeight + 8;
    sb.writeln('^FO$marginX,$y^A0N,22,18^FDNo^FS');
    sb.writeln('^FO${marginX + colNo},$y^A0N,22,18^FDCATEGORY NAME^FS');
    sb.writeln(
      '^FO${marginX + colNo + colName},$y^FB$colQty,1,0,R^A0N,22,18^FDQTY^FS',
    );

    final int yTableEnd = marginY + headerHeight + tableHeaderHeight;
    sb.writeln('^FO$marginX,$yTableEnd^GB$usableWidth,2,2^FS');

    // BODY (fila fija 10mm, NO ajustable)
    y = yTableEnd + 10;

    for (int i = 0; i < slice.length; i++) {
      final key = slice[i];
      final int seq = start + i + 1;

      final String catName = truncate(nameByKey[key] ?? key, 36); // 1 línea
      final String qtyText = (qtyByKey[key] ?? 0).toStringAsFixed(0);

      sb.writeln('^FO$marginX,$y^FB$colNo,1,0,L^A0N,24,18^FD$seq^FS');
      sb.writeln('^FO${marginX + colNo},$y^FB$colName,1,0,L^A0N,24,18^FD$catName^FS');
      sb.writeln(
        '^FO${marginX + colNo + colName},$y^FB$colQty,1,0,R^A0N,28,22^FD$qtyText^FS',
      );

      final int ySep = y + rowHeight - 6;
      sb.writeln('^FO$marginX,$ySep^GB$usableWidth,1,1^FS');

      y += rowHeight;
    }

    // FOOTER
    final int yFooterLine = ll - marginY - footerHeight;
    final int yFooterText = yFooterLine + 20;
    final num totalQtyAll = qtyByKey.values.fold<num>(0, (s, v) => s + v);
    final String totalItemsText = 'Total items: ${totalQtyAll.toStringAsFixed(0)}';
    // IZQUIERDA: Total items
    sb.writeln(
      '^FO$marginX,$yFooterText'
          '^FB${usableWidth - 140},1,0,L'
          '^A0N,26,20'
          '^FD$totalItemsText^FS',
    );


    sb.writeln('^FO$marginX,$yFooterLine^GB$usableWidth,2,2^FS');
    sb.writeln(
      '^FO${marginX + usableWidth - 120},$yFooterText'
          '^FB120,1,0,R^A0N,28,20^FD${page + 1}/$totalPages^FS',
    );

    sb.writeln('^XZ');

    out.writeln(sb.toString());
    out.writeln();
  }

  return out.toString();
}


/*String buildTspl100x150NoLogoAll({
  required dynamic movementAndLines,
  required ZplLabelType labelType,
  required int rowsPerLabel,
  required int rowPerProductName,
  required int marginX,
  required int marginY,
}) {
  const int dotsPerMm = 8;
  const int pw = 800;
  const int ll = 1200;

  const int reduceWidthDots = 56; // 7mm
  final int usableWidth = pw - reduceWidthDots; // 744

  final int qrSize = 20 * dotsPerMm; // 160
  const int qrGap = 12;

  String safe(String s) => s
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ')
      .replaceAll('"', "'")
      .trim();

  String truncate(String s, int maxChars) {
    final t = safe(s);
    if (t.length <= maxChars) return t;
    return '${t.substring(0, maxChars - 1)}…';
  }

  final String qrData = safe(movementAndLines.documentNumber ?? '');
  final String documentNumber = safe(movementAndLines.documentNumber ?? '');
  final String date = safe(movementAndLines.movementDate ?? '');
  final String documentStatus = safe(movementAndLines.documentStatus ?? '');
  final String company = safe(movementAndLines.cBPartnerID?.identifier ?? '');
  final String title = safe(movementAndLines.documentMovementTitle ?? '');

  final out = StringBuffer();

  // =======================================================================
  // =============== 1) MOVEMENT DETAIL (TU ACTUAL) =========================
  // =======================================================================
  if (labelType == ZplLabelType.movementDetail) {
    const int headerHeight = 25 * dotsPerMm; // 200
    const int tableHeaderHeight = 10 * dotsPerMm; // 80
    const int footerHeight = 10 * dotsPerMm; // 80

    final List<dynamic> lines =
    (movementAndLines.movementLines ?? const <dynamic>[]) as List<dynamic>;

    final int totalPages =
    lines.isEmpty ? 1 : ((lines.length + rowsPerLabel - 1) ~/ rowsPerLabel);

    for (int page = 0; page < totalPages; page++) {
      final int start = page * rowsPerLabel;
      final int end = min(start + rowsPerLabel, lines.length);
      final slice = lines.isEmpty ? <dynamic>[] : lines.sublist(start, end);

      final sb = StringBuffer();

      sb.writeln('SIZE 100 mm,150 mm');
      sb.writeln('GAP 3 mm,0 mm');
      sb.writeln('DENSITY 12');
      sb.writeln('SPEED 4');
      sb.writeln('DIRECTION 1');
      sb.writeln('REFERENCE 0,0');
      sb.writeln('CLS');

      // HEADER
      final int qrX = marginX;
      final int qrY = marginY;
      sb.writeln('QRCODE $qrX,$qrY,L,6,A,0,"$qrData"');

      final int textX = marginX + qrSize + qrGap;
      final int textW = usableWidth - qrSize - qrGap;

      sb.writeln('BLOCK $textX,${marginY + 4},$textW,40,"0",0,2,2,0,2,"$documentNumber"');

      final int halfW = (textW / 2).round();
      sb.writeln('BLOCK $textX,${marginY + 56},$halfW,30,"0",0,1,1,0,1,"$date"');
      sb.writeln('BLOCK ${textX + halfW},${marginY + 56},$halfW,30,"0",0,1,1,0,2,"$documentStatus"');

      sb.writeln('BLOCK $textX,${marginY + 88},$textW,30,"0",0,1,1,0,2,"$company"');
      sb.writeln('BLOCK $textX,${marginY + 120},$textW,34,"0",0,1,1,0,2,"$title"');

      sb.writeln('BAR $marginX,${marginY + headerHeight - 2},$usableWidth,2');

      // TABLE HEADER
      int y = marginY + headerHeight + 8;
      sb.writeln('TEXT $marginX,$y,"0",0,1,1,"UPC/SKU"');
      sb.writeln('TEXT ${marginX + usableWidth - 260},$y,"0",0,1,1,"HASTA/DESDE"');
      y += 24;
      sb.writeln('TEXT $marginX,$y,"0",0,1,1,"ATTRIBUTO"');
      sb.writeln('TEXT ${marginX + usableWidth - 200},$y,"0",0,1,1,"CANTIDAD"');

      final int yTableEnd = marginY + headerHeight + tableHeaderHeight;
      sb.writeln('BAR $marginX,$yTableEnd,$usableWidth,2');

      // BODY
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

        final int rightBlockX = marginX + usableWidth - 420;

        sb.writeln('TEXT $marginX,$y,"0",0,1,1,"$upc"');
        sb.writeln('BLOCK $rightBlockX,$y,420,30,"0",0,1,1,0,2,"$to"');
        y += linePitch;

        sb.writeln('TEXT $marginX,$y,"0",0,1,1,"$sku"');
        sb.writeln('BLOCK $rightBlockX,$y,420,30,"0",0,1,1,0,2,"$from"');
        y += linePitch;

        sb.writeln('TEXT $marginX,$y,"0",0,1,1,"$atr"');
        y += linePitch;

        final int productW = usableWidth - 160;
        final int productH = linePitch * nameLines;
        sb.writeln('BLOCK $marginX,$y,$productW,$productH,"0",0,1,1,0,0,"$product"');
        sb.writeln('BLOCK ${marginX + usableWidth - 140},${y - 6},140,60,"0",0,2,2,0,2,"$qty"');

        y += productH;
        sb.writeln('BAR $marginX,$y,$usableWidth,1');
        y += 10;
      }

      // FOOTER
      final int yFooterLine = ll - marginY - footerHeight;
      final int yFooterText = yFooterLine + 20;

      sb.writeln('BAR $marginX,$yFooterLine,$usableWidth,2');
      sb.writeln('BLOCK ${marginX + usableWidth - 120},$yFooterText,120,30,"0",0,1,1,0,2,"${page + 1}/$totalPages"');

      sb.writeln('PRINT 1,1');

      out.writeln(sb.toString());
      out.writeln();
    }

    return out.toString();
  }

  // =======================================================================
  // =============== 2) MOVEMENT BY CATEGORY (NUEVO) ========================
  // =======================================================================
  const int headerHeight = 60 * dotsPerMm; // 480
  const int tableHeaderHeight = 10 * dotsPerMm; // 80
  const int footerHeight = 10 * dotsPerMm; // 80
  const int rowHeight = 10 * dotsPerMm; // 80

  final String address =
  safe(movementAndLines.cBPartnerLocationID?.identifier ?? '');
  final String warehouseFrom =
  safe(movementAndLines.mWarehouseID?.identifier ?? '');
  final String warehouseTo =
  safe(movementAndLines.warehouseTo?.identifier ?? '');

  final List<dynamic> lines =
  (movementAndLines.movementLines ?? const <dynamic>[]) as List<dynamic>;

  final Map<String, num> qtyByKey = {};
  final Map<String, String> nameByKey = {};

  for (final r in lines) {
    final String categoryName = safe(
      r.mProductID?.mProductCategoryID?.identifier ?? 'category null',
    );
    final String categoryId = safe(
      r.mProductID?.mProductCategoryID?.id?.toString() ?? 'category id null',
    );
    final String key = '$categoryId|$categoryName';
    final num q = (r.movementQty as num?) ?? 0;

    qtyByKey[key] = (qtyByKey[key] ?? 0) + q;
    nameByKey[key] = categoryName;
  }

  final keys = qtyByKey.keys.toList()
    ..sort((a, b) {
      final an = (nameByKey[a] ?? a).toLowerCase();
      final bn = (nameByKey[b] ?? b).toLowerCase();
      return an.compareTo(bn);
    });
  final num totalQtyAll = lines.fold<num>(
    0,
        (sum, r) => sum + ((r.movementQty as num?) ?? 0),
  );
  final String totalItemsText = 'Total items: ${totalQtyAll.toStringAsFixed(0)}';
  final int totalPages =
  keys.isEmpty ? 1 : ((keys.length + rowsPerLabel - 1) ~/ rowsPerLabel);

  const int colNo = 70;
  const int colQty = 140;
  final int colName = usableWidth - colNo - colQty;

  for (int page = 0; page < totalPages; page++) {
    final int start = page * rowsPerLabel;
    final int end = min(start + rowsPerLabel, keys.length);
    final slice = keys.isEmpty ? <String>[] : keys.sublist(start, end);

    final sb = StringBuffer();

    sb.writeln('SIZE 100 mm,150 mm');
    sb.writeln('GAP 3 mm,0 mm');
    sb.writeln('DENSITY 12');
    sb.writeln('SPEED 4');
    sb.writeln('DIRECTION 1');
    sb.writeln('REFERENCE 0,0');
    sb.writeln('CLS');

    // HEADER
    final int qrX = marginX;
    final int qrY = marginY;
    sb.writeln('QRCODE $qrX,$qrY,L,6,A,0,"$qrData"');

    final int textX = marginX + qrSize + qrGap;
    final int textW = usableWidth - qrSize - qrGap;
    final int halfW = (textW / 2).round();

    int ty = marginY + 4;
    sb.writeln('BLOCK $textX,$ty,$textW,40,"0",0,2,2,0,2,"$documentNumber"');
    ty += 52;
    sb.writeln('BLOCK $textX,$ty,$halfW,30,"0",0,1,1,0,1,"$date"');
    sb.writeln('BLOCK ${textX + halfW},$ty,$halfW,30,"0",0,1,1,0,2,"$documentStatus"');
    ty += 32;
    sb.writeln('BLOCK $textX,$ty,$textW,30,"0",0,1,1,0,2,"$company"');
    ty += 32;
    sb.writeln('BLOCK $textX,$ty,$textW,34,"0",0,1,1,0,2,"$title"');

    ty += 36;
    sb.writeln('BLOCK $textX,$ty,$textW,26,"0",0,1,1,0,2,"Direccion: $address"');
    ty += 28;
    sb.writeln('BLOCK $textX,$ty,$textW,26,"0",0,1,1,0,2,"From: $warehouseFrom"');
    ty += 28;
    sb.writeln('BLOCK $textX,$ty,$textW,26,"0",0,1,1,0,2,"TO: $warehouseTo"');

    sb.writeln('BAR $marginX,${marginY + headerHeight - 2},$usableWidth,2');

    // TABLE HEADER (10mm)
    int y = marginY + headerHeight + 8;
    sb.writeln('TEXT $marginX,$y,"0",0,1,1,"No"');
    sb.writeln('TEXT ${marginX + colNo},$y,"0",0,1,1,"CATEGORY NAME"');
    sb.writeln('BLOCK ${marginX + colNo + colName},$y,$colQty,26,"0",0,1,1,0,2,"QTY"');

    final int yTableEnd = marginY + headerHeight + tableHeaderHeight;
    sb.writeln('BAR $marginX,$yTableEnd,$usableWidth,2');

    // BODY (fila fija 10mm, NO ajustable)
    y = yTableEnd + 10;

    for (int i = 0; i < slice.length; i++) {
      final key = slice[i];
      final int seq = start + i + 1;

      final String catName = truncate(nameByKey[key] ?? key, 36);
      final String qtyText = (qtyByKey[key] ?? 0).toStringAsFixed(0);

      sb.writeln('TEXT $marginX,$y,"0",0,1,1,"$seq"');
      // NO ajustable: usamos TEXT (1 línea). Si es largo, ya viene truncado.
      sb.writeln('TEXT ${marginX + colNo},$y,"0",0,1,1,"$catName"');
      sb.writeln('BLOCK ${marginX + colNo + colName},$y,$colQty,26,"0",0,1,1,0,2,"$qtyText"');

      final int ySep = y + rowHeight - 6;
      sb.writeln('BAR $marginX,$ySep,$usableWidth,1');

      y += rowHeight;
    }
    // FOOTER
    final int yFooterLine = ll - marginY - footerHeight;
    final int yFooterText = yFooterLine + 20;
    final num totalQtyAll = qtyByKey.values.fold<num>(0, (s, v) => s + v);
    final String totalItemsText = 'Total items: ${totalQtyAll.toStringAsFixed(0)}';
    sb.writeln('BAR $marginX,$yFooterLine,$usableWidth,2');
// IZQUIERDA: Total items
    sb.writeln(
      'BLOCK $marginX,$yFooterText,${usableWidth - 140},30,"0",0,1,1,0,0,"$totalItemsText"',
    );

// DERECHA: página
    sb.writeln(
      'BLOCK ${marginX + usableWidth - 120},$yFooterText,120,30,"0",0,1,1,0,2,"${page + 1}/$totalPages"',
    );
    sb.writeln('PRINT 1,1');

    out.writeln(sb.toString());
    out.writeln();
  }

  return out.toString();
}*/
String safe(String s) => s
    .replaceAll('^', ' ')
    .replaceAll('~', ' ')
    .replaceAll('\n', ' ')
    .replaceAll('\r', ' ')
    .trim();

List<List<T>> chunkByRows<T>(List<T> items, int rowsPerLabel) {
  final out = <List<T>>[];
  for (int i = 0; i < items.length; i += rowsPerLabel) {
    out.add(items.sublist(i, (i + rowsPerLabel) > items.length ? items.length : (i + rowsPerLabel)));
  }
  return out;
}




