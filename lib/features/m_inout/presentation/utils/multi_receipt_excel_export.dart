import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/multi_m_in_out_session.dart';
import '../providers/multi_m_in_out_providers.dart';

/// Builds a minimal XLSX file from the current Multiple Receipt state without
/// depending on the `excel` package (avoids the archive ^3 vs ^4 conflict
/// against `image`). One sheet per MInOut session. Active sheets are named
/// after their `documentNo`; completed ones get ` CO` appended.
///
/// Cell-coloring rules per data row (cellXf style index):
///   - red    (s=2) → confirmedQty == 0       (sin confirmar)
///   - orange (s=3) → 0 < confirmedQty < movementQty  (parcial)
///   - blue   (s=4) → confirmedQty > movementQty      (excedido)
///   - default(s=0) → confirmedQty == movementQty     (ok)
class MultiReceiptExcelExport {
  static const _kMaxSheetName = 31;

  /// [persistent] = false → saves to the OS temp dir (suitable for share).
  /// [persistent] = true  → saves to external app storage on Android (or to
  /// the application documents dir as fallback) so the file survives app
  /// restarts and can be opened by a file manager.
  static Future<File> build(
    MultiMInOutState state, {
    bool persistent = false,
  }) async {
    final allSessions = <MultiMInOutSession>[
      ...state.activeSessions,
      ...state.completedSessions,
    ];
    if (allSessions.isEmpty) {
      throw Exception('No hay recepciones para exportar');
    }
    final completedFlags = <bool>[
      ...List.filled(state.activeSessions.length, false),
      ...List.filled(state.completedSessions.length, true),
    ];

    final used = <String>{};
    final sheetNames = <String>[];
    for (var i = 0; i < allSessions.length; i++) {
      final name =
          _resolveSheetName(allSessions[i].documentNo, completedFlags[i], used);
      used.add(name);
      sheetNames.add(name);
    }

    final archive = Archive();
    _addText(archive, '[Content_Types].xml', _contentTypes(sheetNames.length));
    _addText(archive, '_rels/.rels', _rootRels());
    _addText(archive, 'xl/workbook.xml', _workbook(sheetNames));
    _addText(archive, 'xl/_rels/workbook.xml.rels',
        _workbookRels(sheetNames.length));
    _addText(archive, 'xl/styles.xml', _styles());
    for (var i = 0; i < sheetNames.length; i++) {
      _addText(
        archive,
        'xl/worksheets/sheet${i + 1}.xml',
        _sheetXml(allSessions[i]),
      );
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded.isEmpty) {
      throw Exception('No se pudo generar el archivo Excel');
    }

    final Directory dir = persistent
        ? (await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory())
        : await getTemporaryDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${dir.path}/multi_receipt_$ts.xlsx');
    await file.writeAsBytes(encoded, flush: true);
    return file;
  }

  // -------- Archive helpers --------

  static void _addText(Archive archive, String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  // -------- Sheet name --------

  static String _resolveSheetName(
    String documentNo,
    bool isCompleted,
    Set<String> used,
  ) {
    final cleaned =
        documentNo.replaceAll(RegExp(r"[\\/:*?\[\]']"), '_').trim();
    final base = cleaned.isEmpty ? 'doc' : cleaned;
    final suffix = isCompleted ? ' CO' : '';
    var name = _trim('$base$suffix');
    if (!used.contains(name)) return name;
    var i = 2;
    while (true) {
      final candidate = _trim('$base$suffix ($i)');
      if (!used.contains(candidate)) return candidate;
      i++;
    }
  }

  static String _trim(String s) =>
      s.length <= _kMaxSheetName ? s : s.substring(0, _kMaxSheetName);

  // -------- XLSX skeleton XML --------

  static String _contentTypes(int sheetCount) {
    final overrides = StringBuffer();
    overrides.write(
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>');
    overrides.write(
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>');
    for (var i = 1; i <= sheetCount; i++) {
      overrides.write(
          '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>');
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '$overrides'
        '</Types>';
  }

  static String _rootRels() =>
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>';

  static String _workbook(List<String> sheetNames) {
    final sheets = StringBuffer();
    for (var i = 0; i < sheetNames.length; i++) {
      sheets.write(
        '<sheet name="${_xmlAttr(sheetNames[i])}" sheetId="${i + 1}" r:id="rId${i + 1}"/>',
      );
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets>$sheets</sheets>'
        '</workbook>';
  }

  static String _workbookRels(int sheetCount) {
    final rels = StringBuffer();
    for (var i = 1; i <= sheetCount; i++) {
      rels.write(
        '<Relationship Id="rId$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$i.xml"/>',
      );
    }
    rels.write(
      '<Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>',
    );
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '$rels'
        '</Relationships>';
  }

  /// Styles. cellXf indices used:
  ///   0 = default body
  ///   1 = header (bold + gray fill)
  ///   2 = red row
  ///   3 = orange row
  ///   4 = blue row
  static String _styles() =>
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<fonts count="2">'
      '<font><sz val="11"/><name val="Calibri"/></font>'
      '<font><b/><sz val="11"/><name val="Calibri"/></font>'
      '</fonts>'
      '<fills count="6">'
      '<fill><patternFill patternType="none"/></fill>'
      '<fill><patternFill patternType="gray125"/></fill>'
      '<fill><patternFill patternType="solid"><fgColor rgb="FFFFCDD2"/><bgColor indexed="64"/></patternFill></fill>'
      '<fill><patternFill patternType="solid"><fgColor rgb="FFFFE0B2"/><bgColor indexed="64"/></patternFill></fill>'
      '<fill><patternFill patternType="solid"><fgColor rgb="FFBBDEFB"/><bgColor indexed="64"/></patternFill></fill>'
      '<fill><patternFill patternType="solid"><fgColor rgb="FFE0E0E0"/><bgColor indexed="64"/></patternFill></fill>'
      '</fills>'
      '<borders count="1"><border/></borders>'
      '<cellStyleXfs count="1"><xf fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="5">'
      '<xf fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '<xf fontId="1" fillId="5" borderId="0" xfId="0" applyFont="1" applyFill="1"/>'
      '<xf fontId="0" fillId="2" borderId="0" xfId="0" applyFill="1"/>'
      '<xf fontId="0" fillId="3" borderId="0" xfId="0" applyFill="1"/>'
      '<xf fontId="0" fillId="4" borderId="0" xfId="0" applyFill="1"/>'
      '</cellXfs>'
      '</styleSheet>';

  // -------- Sheet content --------

  static const _headers = <String>[
    '#',
    'UPC',
    'SKU',
    'Producto',
    'Movement',
    'Confirmado',
    'Pendiente',
    'Estado',
  ];

  static String _sheetXml(MultiMInOutSession s) {
    final cols = StringBuffer();
    final widths = <double>[5, 16, 12, 36, 10, 11, 11, 14];
    for (var i = 0; i < widths.length; i++) {
      cols.write(
        '<col min="${i + 1}" max="${i + 1}" width="${widths[i]}" customWidth="1"/>',
      );
    }

    final rows = StringBuffer();
    var rowIdx = 1;

    // ── Header info block (single column A, overflows visually into empty
    // adjacent cells; bold gray header style). Goes BEFORE the line table.
    final m = s.mInOut;
    final headerLines = <String>[
      'DocumentNo: ${m.documentNo ?? "-"}',
      'Estado: ${m.docStatus.id ?? "-"}',
      if (m.movementDate != null)
        'Fecha Movimiento: ${m.movementDate!.toIso8601String().split("T").first}',
      if (m.dateOrdered != null)
        'Fecha Pedido: ${m.dateOrdered!.toIso8601String().split("T").first}',
      'Almacén ID: ${m.mWarehouseId.id ?? "-"}',
      if ((m.mWarehouseToId.id ?? 0) != 0)
        'Almacén Destino ID: ${m.mWarehouseToId.id}',
      'BPartner ID: ${m.cBPartnerId.id ?? "-"}',
      if ((m.cOrderId.id ?? 0) != 0) 'Orden ID: ${m.cOrderId.id}',
      'IsSOTrx: ${m.isSoTrx == true ? "Yes" : "No"}',
      'Sesión: ${(s.colorIndex % 5) + 1} '
          '(${s.status == "completed" ? "completada" : "activa"})',
      'Total líneas: ${m.lines.length}',
      'Confirmadas (qty exacta): ${m.lines.where((l) => (l.confirmedQty ?? 0) == (l.movementQty ?? 0)).length}',
      'Pendientes / parciales: ${m.lines.where((l) => (l.confirmedQty ?? 0) < (l.movementQty ?? 0)).length}',
      'Excedidas: ${m.lines.where((l) => (l.confirmedQty ?? 0) > (l.movementQty ?? 0)).length}',
      'Scans: ${s.scannedBarcodes.length}',
    ];
    for (final line in headerLines) {
      rows.write('<row r="$rowIdx">');
      rows.write(_textCell('A$rowIdx', 1, line));
      rows.write('</row>');
      rowIdx++;
    }

    // ── Blank separator row.
    rowIdx++;

    // ── Data table header.
    rows.write('<row r="$rowIdx">');
    for (var c = 0; c < _headers.length; c++) {
      rows.write(_textCell('${_colLetter(c)}$rowIdx', 1, _headers[c]));
    }
    rows.write('</row>');
    rowIdx++;

    // ── Data rows.
    for (var idx = 0; idx < m.lines.length; idx++) {
      final l = m.lines[idx];
      final mov = (l.movementQty ?? 0).toDouble();
      final conf = (l.confirmedQty ?? 0).toDouble();
      final pending = mov - conf;

      String estado;
      int styleId;
      if (conf == 0) {
        estado = 'SIN CONFIRMAR';
        styleId = 2; // red
      } else if (conf < mov) {
        estado = 'PARCIAL';
        styleId = 3; // orange
      } else if (conf > mov) {
        estado = 'EXCEDIDO';
        styleId = 4; // blue
      } else {
        estado = 'OK';
        styleId = 0; // none
      }

      rows.write('<row r="$rowIdx">');
      rows.write(_numCell('A$rowIdx', styleId, l.line ?? (idx + 1)));
      rows.write(_textCell('B$rowIdx', styleId, l.upc ?? ''));
      rows.write(_textCell('C$rowIdx', styleId, l.sku ?? ''));
      rows.write(_textCell('D$rowIdx', styleId, l.productName ?? ''));
      rows.write(_numCell('E$rowIdx', styleId, mov));
      rows.write(_numCell('F$rowIdx', styleId, conf));
      rows.write(_numCell('G$rowIdx', styleId, pending));
      rows.write(_textCell('H$rowIdx', styleId, estado));
      rows.write('</row>');
      rowIdx++;
    }

    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<cols>$cols</cols>'
        '<sheetData>$rows</sheetData>'
        '</worksheet>';
  }

  static String _textCell(String ref, int styleId, String value) {
    final escaped = _xmlText(value);
    return '<c r="$ref" s="$styleId" t="inlineStr"><is><t xml:space="preserve">$escaped</t></is></c>';
  }

  static String _numCell(String ref, int styleId, num value) {
    // Drop trailing .0 for integral values for cleaner Excel display.
    final s = (value == value.truncate())
        ? value.toInt().toString()
        : value.toString();
    return '<c r="$ref" s="$styleId"><v>$s</v></c>';
  }

  /// Spreadsheet column letter from 0-based index. Up to 25 (Z) is enough for
  /// our 8-column sheet.
  static String _colLetter(int idx) =>
      String.fromCharCode('A'.codeUnitAt(0) + idx);

  static String _xmlText(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _xmlAttr(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
