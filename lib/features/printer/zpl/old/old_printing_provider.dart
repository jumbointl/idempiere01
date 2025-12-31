import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/printer/zpl/old/zpl_print_profile_providers.dart';
import '../../../products/common/messages_dialog.dart';
import '../../../products/common/utils/common_string_utils.dart';
import '../../../products/domain/idempiere/idempiere_movement_line.dart';
import '../../../products/domain/idempiere/movement_and_lines.dart';
import '../../../products/presentation/screens/movement/pos/provider/pos_image_utility.dart';
import '../new/models/category_agg.dart';
import 'zpl_label_printer_100x150.dart' hide pngBytesToZplGfa;

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
  final String qrData = zplSafe(movementAndLines.documentNumber ?? '');
  final String documentNumber = zplSafe(movementAndLines.documentNumber ?? '');
  final String date = zplSafe(movementAndLines.movementDate ?? '');
  final String documentStatus = zplSafe(movementAndLines.documentStatus ?? '');
  final String company = zplSafe(movementAndLines.cBPartnerID?.identifier ?? '');
  final String title = zplSafe(movementAndLines.documentMovementTitle ?? '');

  final String address = zplSafe(movementAndLines.cBPartnerLocationID?.identifier ?? '');
  final String warehouseFrom = zplSafe(movementAndLines.mWarehouseID?.identifier ?? '');
  final String warehouseTo = zplSafe(movementAndLines.warehouseTo?.identifier ?? '');

  // ===== Lines -> Categories agg =====
  final List<dynamic> lines =
  (movementAndLines.movementLines ?? const <dynamic>[]) as List<dynamic>;

  final Map<String, CategoryAgg> map = {};
  for (final r in lines) {
    final String categoryName = zplSafe(
      r.mProductID?.mProductCategoryID?.identifier ?? 'category null',
    );
    final String categoryId = zplSafe(
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
        final String catNameRaw = zplSafe(item.categoryName);
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
  final String qrData = zplSafe(movementAndLines.documentNumber ?? '');
  final String documentNumber = zplSafe(movementAndLines.documentNumber ?? '');
  final String date = zplSafe(movementAndLines.movementDate ?? '');
  final String documentStatus = zplSafe(movementAndLines.documentStatus ?? '');
  final String company = zplSafe(movementAndLines.cBPartnerID?.identifier ?? '');
  final String title = zplSafe(movementAndLines.documentMovementTitle ?? '');

  final String address = zplSafe(movementAndLines.cBPartnerLocationID?.identifier ?? '');
  final String warehouseFrom = zplSafe(movementAndLines.mWarehouseID?.identifier ?? '');
  final String warehouseTo = zplSafe(movementAndLines.warehouseTo?.identifier ?? '');

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

        final seq = zplSafe((m.line ?? (start + i + 1)).toString());
        final nameRaw = zplSafe(m.productName ?? '');
        final qtyText = zplSafe((m.movementQty ?? 0).toString());

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
      sb.writeln('^FD$qrData^FS');

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
    sb.writeln('^FD$qrData^FS');

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