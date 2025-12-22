import 'dart:convert';
import 'dart:io';
import 'dart:math';

Future<void> printLabelMovementByProductTspl100x150NoLogo({
  required String ip,
  required int port,
  required dynamic movementAndLines, // tu MovementAndLines real
  required int rowsPerLabel,         // productos por etiqueta
  required int rowPerProductName,    // 1 o 2
  required int marginX,              // dots (203dpi => 8 dots/mm)
  required int marginY,              // dots
}) async {
  // =============================
  // FÍSICO (203 dpi = 8 dots/mm)
  // =============================
  const int dotsPerMm = 8;
  const int labelWmm = 100;
  const int labelHmm = 150;
  const int gapMm = 3;

  // Restar 7mm al ancho de impresión: 7mm*8 = 56 dots
  const int reduceMm = 7;
  final int reduceDots = reduceMm * dotsPerMm; // 56

  // Label en dots
  final int pw = labelWmm * dotsPerMm; // 800
  final int ll = labelHmm * dotsPerMm; // 1200
  final int usableWidth = pw - reduceDots; // 744 (=93mm)

  // Header compacto: 25mm
  final int headerHeight = 25 * dotsPerMm; // 200
  // TableHeader: 10mm
  final int tableHeaderHeight = 10 * dotsPerMm; // 80
  // Footer: 10mm
  final int footerHeight = 10 * dotsPerMm; // 80

  // QR: 20mm aprox
  final int qrSize = 20 * dotsPerMm; // 160
  const int qrGap = 12; // separación QR->texto (dots)

  String safe(String s) => s
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ')
      .replaceAll('"', "'")
      .trim();

  // =============================
  // DATOS HEADER
  // =============================
  final String qrData = safe(movementAndLines.documentNumber ?? '');
  final String documentNumber = safe(movementAndLines.documentNumber ?? '');
  final String date = safe(movementAndLines.movementDate ?? '');
  final String documentStatus = safe(movementAndLines.documentStatus ?? '');
  final String company = safe(movementAndLines.cBPartnerID?.identifier ?? '');
  final String title = safe(movementAndLines.documentMovementTitle ?? '');

  // =============================
  // LINES
  // =============================
  final List<dynamic> lines =
  (movementAndLines.movementLines ?? const <dynamic>[]) as List<dynamic>;

  final int totalPages =
  lines.isEmpty ? 1 : ((lines.length + rowsPerLabel - 1) ~/ rowsPerLabel);

  // Socket
  final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));

  for (int page = 0; page < totalPages; page++) {
    final int start = page * rowsPerLabel;
    final int end = min<int>(start + rowsPerLabel, lines.length);
    final List<dynamic> slice = lines.isEmpty ? <dynamic>[] : lines.sublist(start, end);

    final sb = StringBuffer();

    // =============================
    // TSPL SETUP
    // =============================
    sb.writeln('SIZE $labelWmm mm,$labelHmm mm');
    sb.writeln('GAP $gapMm mm,0 mm');
    sb.writeln('DENSITY 12');   // ajusta 8..15 según etiqueta
    sb.writeln('SPEED 4');      // ajusta si necesitas
    sb.writeln('DIRECTION 1');  // 1 normal
    sb.writeln('REFERENCE 0,0');
    sb.writeln('CLS');

    // =========================================================
    // HEADER TSPL (25mm) - QR IZQUIERDA + TEXTOS DERECHA
    // =========================================================
    final int qrX = marginX;
    final int qrY = marginY;

    // QRCODE x,y,ECC,cell,mode,rotation,"data"
    // cell=6 suele dar tamaño cercano a 20mm (depende versión/encoding)
    // si te queda más grande/pequeño: sube/baja cell 5..7
    sb.writeln('QRCODE $qrX,$qrY,L,6,A,0,"$qrData"');

    // Área de texto a la derecha del QR dentro del ancho usable (744)
    final int textX = marginX + qrSize + qrGap;
    final int textW = usableWidth - qrSize - qrGap; // 744-160-12 = 572

    // Fila 1: documentNumber (derecha, grande)
    // BLOCK x,y,width,height,font,rotation,xmul,ymul,space,align,"text"
    // align: 0 left, 1 center, 2 right
    sb.writeln(
        'BLOCK $textX,${marginY + 4},$textW,40,"0",0,2,2,0,2,"$documentNumber"'
    );

    // Fila 2: date (center) + status (right)
    final int halfW = (textW / 2).round();
    sb.writeln(
        'BLOCK $textX,${marginY + 56},$halfW,30,"0",0,1,1,0,1,"$date"'
    );
    sb.writeln(
        'BLOCK ${textX + halfW},${marginY + 56},$halfW,30,"0",0,1,1,0,2,"$documentStatus"'
    );

    // Fila 3: company (derecha)
    sb.writeln(
        'BLOCK $textX,${marginY + 88},$textW,30,"0",0,1,1,0,2,"$company"'
    );

    // Fila 4: title (derecha)
    sb.writeln(
        'BLOCK $textX,${marginY + 120},$textW,34,"0",0,1,1,0,2,"$title"'
    );

    // Línea separadora header->tabla
    sb.writeln('BAR $marginX,${marginY + headerHeight - 2},$usableWidth,2');

    // =========================================================
    // TABLE HEADER (10mm)
    // =========================================================
    int y = marginY + headerHeight + 8;

    sb.writeln('TEXT $marginX,$y,"0",0,1,1,"UPC/SKU"');
    sb.writeln('TEXT ${marginX + usableWidth - 260},$y,"0",0,1,1,"HASTA/DESDE"');
    y += 24;
    sb.writeln('TEXT $marginX,$y,"0",0,1,1,"ATTRIBUTO"');
    sb.writeln('TEXT ${marginX + usableWidth - 200},$y,"0",0,1,1,"CANTIDAD"');

    final int yTableEnd = marginY + headerHeight + tableHeaderHeight;
    sb.writeln('BAR $marginX,$yTableEnd,$usableWidth,2');

    // =========================================================
    // BODY
    // =========================================================
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

      // Col derecha (to/from) alineada a la derecha con BLOCK
      final int rightBlockX = marginX + usableWidth - 420;

      // UPC + TO
      sb.writeln('TEXT $marginX,$y,"0",0,1,1,"$upc"');
      sb.writeln('BLOCK $rightBlockX,$y,420,30,"0",0,1,1,0,2,"$to"');
      y += linePitch;

      // SKU + FROM
      sb.writeln('TEXT $marginX,$y,"0",0,1,1,"$sku"');
      sb.writeln('BLOCK $rightBlockX,$y,420,30,"0",0,1,1,0,2,"$from"');
      y += linePitch;

      // ATR
      sb.writeln('TEXT $marginX,$y,"0",0,1,1,"$atr"');
      y += linePitch;

      // PRODUCT (1 o 2 líneas) + QTY grande derecha
      // Reservamos 160 dots para qty grande
      final int productW = usableWidth - 160;

      // Alto del bloque product: 1 línea ~32, 2 líneas ~64
      final int productH = linePitch * nameLines;

      sb.writeln(
          'BLOCK $marginX,$y,$productW,$productH,"0",0,1,1,0,0,"$product"'
      );

      sb.writeln(
          'BLOCK ${marginX + usableWidth - 140},${y - 6},140,60,"0",0,2,2,0,2,"$qty"'
      );

      y += productH;

      // separador
      sb.writeln('BAR $marginX,$y,$usableWidth,1');
      y += 10;
    }

    // =========================================================
    // FOOTER (10mm) - solo page count a la derecha (como tu versión)
    // =========================================================
    final int yFooterLine = ll - marginY - footerHeight;
    final int yFooterText = yFooterLine + 20;

    sb.writeln('BAR $marginX,$yFooterLine,$usableWidth,2');
    sb.writeln(
        'BLOCK ${marginX + usableWidth - 120},$yFooterText,120,30,"0",0,1,1,0,2,"${page + 1}/$totalPages"'
    );

    // Imprime 1 etiqueta
    sb.writeln('PRINT 1,1');

    socket.add(utf8.encode(sb.toString()));
  }

  await socket.flush();
  await socket.close();
}
