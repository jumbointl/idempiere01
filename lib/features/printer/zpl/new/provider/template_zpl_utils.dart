import 'dart:io';
import 'package:flutter/material.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';
import 'package:path/path.dart' as p;
import '../../../../products/domain/idempiere/idempiere_movement_line.dart';
import '../../../../products/domain/idempiere/movement_and_lines.dart';
import '../../../../products/domain/models/zpl_printing_template.dart';
import '../../../../shared/data/memory.dart';
import '../../../web_template/provider/providers_create_zpl_template_request.dart';
import '../models/category_agg.dart';
import '../models/zpl_template.dart';
import '../models/zpl_template_store.dart';

// ========= Tokens base (tuyos) =========
const String DOCUMENT_NUMBER__ = '__DOCUMENT_NUMBER';
const String DATE__ = '__DATE';
const String STATUS__ = '__STATUS';
const String COMPANY__ = '__COMPANY';
const String TITLE__ = '__TITLE';
const String ADDRESS__ = '__ADDRESS';
const String WAREHOUSE_FROM__ = '__WAREHOUSE_FROM';
const String WAREHOUSE_TO__ = '__WAREHOUSE_TO';
const String GENERATED_BY__ = '__GENERATED_BY';

String CATEGORY_SEQUENCE__(int i) => '__CATEGORY_SEQUENCE$i';
String CATEGORY_NAME__(int i)     => '__CATEGORY_NAME$i';
String CATEGORY_QTY__(int i)      => '__CATEGORY_QTY$i';

String PRODUCT_SQCUENCE__(int i) => '__PRODUCT_SEQUENCE$i';
String PRODUCT_NAME__(int i)     => '__PRODUCT_NAME$i';
String PRODUCT_UPC__(int i)      => '__PRODUCT_UPC$i';
String PRODUCT_SKU__(int i)      => '__PRODUCT_SKU$i';
String PRODUCT_ATT__(int i)      => '__PRODUCT_ATT$i';

String MOVEMENT_LINE_MOVEMENT_QTY__(int i) => '__MOVEMENT_LINE_MOVEMENT_QTY$i';
String MOVEMENT_LINE_LINE__(int i)         => '__MOVEMENT_LINE_LINE$i';

const String TOTAL_QUANTITY__ = '__TOTAL_QUANTITY';
const String PAGE_NUMBER_OVER_TOTAL_PAGE__ = '__PAGE_NUMBER_OVER_TOTAL_PAGE';

// ========= Helpers =========
String s(dynamic v) {
  if (v == null) return '';

  // Números reales
  if (v is num) {
    return Memory.numberFormatter0Digit.format(v);
  }
  return v.toString();
}


String zplText(dynamic v) {
  final text = s(v)
      .replaceAll('^', ' ')
      .replaceAll('~', ' ')
      .replaceAll('\r', ' ')
      .replaceAll('\n', ' ')
      .trim();

  final int maxLen = Memory.MAX_ZPL_TEXT_LENGTH;

  if (text.length <= maxLen) return text;

  // English comment: "Trim text and append ellipsis"
  return '${text.substring(0, maxLen)} ..';
}


String stripDrive(String fileName) {
  final idx = fileName.indexOf(':');
  return (idx >= 0 && idx < fileName.length - 1) ? fileName.substring(idx + 1) : fileName;
}

List<List<T>> chunkByRows<T>(List<T> items, int rowsPerLabel) {
  final out = <List<T>>[];
  for (int i = 0; i < items.length; i += rowsPerLabel) {
    out.add(items.sublist(i, (i + rowsPerLabel) > items.length ? items.length : (i + rowsPerLabel)));
  }
  return out;
}

String replaceAllTokens(String template, Map<String, String> tokens) {
  var out = template;

  final sortedKeys = tokens.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length)); // 🔑 CLAVE

  for (final k in sortedKeys) {
    out = out.replaceAll(k, tokens[k]!);
  }

  return out;
}

/// ========= Socket =========
/// Sends ZPL to printer by TCP socket.
/// Returns true on success, throws Exception on error.
Future<bool> sendZplBySocket({
  required String ip,
  required int port,
  required String zpl,
}) async {
  Socket? socket;

  try {
    // English comment: "Connect with timeout"
    socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));

    // English comment: "Write and flush ZPL"
    socket.add(zpl.codeUnits);
    await socket.flush();

    // English comment: "Close socket gracefully"
    await socket.close();
    return true;
  } catch (e) {
    try {
      socket?.destroy();
    } catch (_) {}

    throw Exception('Error al enviar ZPL a $ip:$port -> $e');
  }
}


// ========= Tokens comunes =========
Map<String, String> buildCommonTokens({
  required MovementAndLines movementAndLines,
  required String totalQty,
  required String pageInfo,
}) {
  String generatesBy = movementAndLines.createdBy?.identifier ?? '';
  return {

    GENERATED_BY__ : zplText(generatesBy),
    DOCUMENT_NUMBER__: zplText(movementAndLines.documentNumber),
    DATE__: zplText(movementAndLines.movementDate),
    STATUS__: zplText(movementAndLines.documentStatus),
    COMPANY__: movementAndLines.cBPartnerID?.identifier == null ? ''
        : '${Messages.COMPANY} : ${zplText(movementAndLines.cBPartnerID?.identifier)}',
    TITLE__: zplText(movementAndLines.documentMovementTitle),
    ADDRESS__: zplText(movementAndLines.cBPartnerLocationID?.identifier),
    WAREHOUSE_FROM__: '${Messages.FROM} : ${zplText(movementAndLines.mWarehouseID?.identifier)}',
    WAREHOUSE_TO__: '${Messages.TO} : ${zplText(movementAndLines.warehouseTo?.identifier)}',

    TOTAL_QUANTITY__: zplText(totalQty),
    PAGE_NUMBER_OVER_TOTAL_PAGE__: zplText(pageInfo),
  };
}

// ========= CategoryAgg =========
Map<String, String> buildMovementLineCategoryTokensPage({
  required List<CategoryAgg> pageRows,
  required int rowsPerLabel,
}) {
  final tokens = <String, String>{};
  for (int i = 0; i < rowsPerLabel; i++) {
    final row = (i < pageRows.length) ? pageRows[i] : null;
    tokens[CATEGORY_SEQUENCE__(i)] = zplText(row?.sequence ?? (i + 1));
    tokens[CATEGORY_NAME__(i)]     = zplText(row?.categoryName ?? '');
    tokens[CATEGORY_QTY__(i)]      = zplText(row?.totalQty  ?? '');
  }
  return tokens;
}

// ========= Product lines =========
Map<String, String> buildByMovementLineProductTokensPage({
  required List<IdempiereMovementLine> pageLines,
  required int rowsPerLabel,
}) {
  final tokens = <String, String>{};

  for (int i = 0; i < rowsPerLabel; i++) {
    final IdempiereMovementLine? ml = (i < pageLines.length) ? pageLines[i] : null;

    tokens[PRODUCT_SQCUENCE__(i)] = zplText(ml?.line ?? (i + 1));
    tokens[PRODUCT_NAME__(i)]     = zplText(ml?.productName);
    tokens[PRODUCT_UPC__(i)]      = zplText(ml?.uPC);
    tokens[PRODUCT_SKU__(i)]      = zplText(ml?.sKU);
    tokens[PRODUCT_ATT__(i)]      = zplText(ml?.mAttributeSetInstanceID?.identifier);

    tokens[MOVEMENT_LINE_LINE__(i)]         = zplText(ml?.line);
    tokens[MOVEMENT_LINE_MOVEMENT_QTY__(i)] = zplText(ml?.movementQty);
  }

  return tokens;
}

// ========= Preview filled 1ra página =========
String buildFilledPreviewFirstPage({
  required ZplTemplate template,
  required MovementAndLines movementAndLines,
}) {
  final rowsPerLabel = template.rowPerpage;
  final totalQty = zplText(movementAndLines.totalMovementQty ?? '');
  final pageInfo = '1/1';

  final refTxt = template.zplReferenceTxt;

  final bool wantsCategory = refTxt.contains('__CATEGORY_');
  final bool wantsProduct =
      refTxt.contains('__MOVEMENT_LINE') || refTxt.contains('__PRODUCT_');

  final tokens = <String, String>{}
    ..addAll(buildCommonTokens(
      movementAndLines: movementAndLines,
      totalQty: totalQty,
      pageInfo: pageInfo,
    ));

  // ✅ Nuevo comportamiento según tokens presentes
  if (template.mode == ZplTemplateMode.movement) {
    if (wantsProduct) {
      final all = movementAndLines.movementLines ?? <IdempiereMovementLine>[];
      tokens.addAll(buildByMovementLineProductTokensPage(
        pageLines: all.take(rowsPerLabel).toList(),
        rowsPerLabel: rowsPerLabel,
      ));
    } else if (wantsCategory) {
      final all = movementAndLines.movementLineByCategories;
      tokens.addAll(buildMovementLineCategoryTokensPage(
        pageRows: all.take(rowsPerLabel).toList(),
        rowsPerLabel: rowsPerLabel,
      ));
    }
  } else {
    // Por si en el futuro agregas shipping u otros modos:
    // aquí decides el comportamiento de otros modos.
  }

  return replaceAllTokens(refTxt, tokens);
}

// ========= Imprimir Reference (paginado) =========
Future<bool?> printReferenceBySocket({
  required String ip,
  required int port,
  required ZplTemplate template,
  required MovementAndLines movementAndLines,
}) async {

  // Solo movement por ahora (luego shipping, etc.)
  if (template.mode == ZplTemplateMode.movement) {
    // ✅ Prioridad: PRODUCT > CATEGORY

    String result = buildFilledPreviewAllPages(
      hidePageLine: true,
      template: template,
      movementAndLines: movementAndLines,
    );
    try{
      bool printed = await sendZplBySocket(
        ip: ip,
        port: port,
        zpl: result,
      );
      return printed ;
    } catch(e){
      print('Error al enviar zpl: $e');
      //throw Exception('Error al enviar zpl: $e');
    }
    return null;
  }
  return null;

}


Future<String> readTxtFile(String filePath) async {
  return File(filePath).readAsString();
}

bool isReferenceFile(String filePath) =>
    p.basename(filePath).toUpperCase().endsWith('_REFERENCE.TXT');

bool isTemplateDfFile(String filePath) {
  final name = p.basename(filePath).toUpperCase();
  return name.endsWith('TEMPLATE.TXT') || name.endsWith('TEMPLATE.ZPL') || name.endsWith('_TEMPLATE.TXT');
}


final RegExp _tokenRx = RegExp(r'__[_A-Z0-9]+');

Set<String> extractTokensUsed(String referenceTxt) {
  return _tokenRx.allMatches(referenceTxt).map((m) => m.group(0)!).toSet();
}
Set<String> buildAvailableTokenSet({
  required ZplTemplateMode mode,
  required int rowsPerLabel,
}) {
  final s = <String>{
    DOCUMENT_NUMBER__,
    DATE__,
    STATUS__,
    COMPANY__,
    TITLE__,
    ADDRESS__,
    WAREHOUSE_FROM__,
    WAREHOUSE_TO__,
    TOTAL_QUANTITY__,
    PAGE_NUMBER_OVER_TOTAL_PAGE__,
    GENERATED_BY__,
  };

  if (mode == ZplTemplateMode.movement) {
    for (int i = 0; i < rowsPerLabel; i++) {
      s.add(CATEGORY_SEQUENCE__(i));
      s.add(CATEGORY_NAME__(i));
      s.add(CATEGORY_QTY__(i));
      s.add(MOVEMENT_LINE_LINE__(i));
      s.add(MOVEMENT_LINE_MOVEMENT_QTY__(i));
      s.add(PRODUCT_SQCUENCE__(i));
      s.add(PRODUCT_NAME__(i));
      s.add(PRODUCT_UPC__(i));
      s.add(PRODUCT_SKU__(i));
      s.add(PRODUCT_ATT__(i));

    }
  }
  return s;
}
List<String> validateMissingTokens({
  required ZplTemplate template,
  required String referenceTxt,
}) {
  final used = extractTokensUsed(referenceTxt);
  final rows = template.rowPerpage;

  final available = buildAvailableTokenSet(mode: template.mode, rowsPerLabel: rows);
  final missing = used.difference(available).toList()..sort();
  return missing;
}
String buildFilledPreviewAllPages({
  bool? hidePageLine,
  required ZplTemplate template,
  required MovementAndLines movementAndLines,
}) {
  final rowsPerLabel = template.rowPerpage;
  final totalQty = zplText(movementAndLines.totalMovementQty ?? '');
  final refTxt = template.zplReferenceTxt;

  final bool wantsCategory = refTxt.contains('__CATEGORY_');
  final bool wantsProduct =
      refTxt.contains('__MOVEMENT_LINE') || refTxt.contains('__PRODUCT_');

  final out = StringBuffer();
  bool noDisplayPageLine = hidePageLine ?? false;

  if (template.mode == ZplTemplateMode.movement) {
    // ✅ Prioridad: PRODUCT > CATEGORY (si están ambos)
    if (wantsProduct) {
      final all = movementAndLines.movementLines ?? <IdempiereMovementLine>[];
      final pages = chunkByRows<IdempiereMovementLine>(all, rowsPerLabel);
      final totalPages = pages.isEmpty ? 1 : pages.length;

      if (pages.isEmpty) {
        final tokens = <String, String>{}
          ..addAll(buildCommonTokens(
            movementAndLines: movementAndLines,
            totalQty: totalQty,
            pageInfo: '1/1',
          ))
          ..addAll(buildByMovementLineProductTokensPage(pageLines: const [], rowsPerLabel: rowsPerLabel));

        if(!noDisplayPageLine) out.writeln('----- PAGE 1/1 -----');
        out.writeln(replaceAllTokens(refTxt, tokens));
        return out.toString().trim();
      }

      for (int p = 0; p < pages.length; p++) {
        final pageInfo = '${p + 1}/$totalPages';
        final tokens = <String, String>{}
          ..addAll(buildCommonTokens(
            movementAndLines: movementAndLines,
            totalQty: totalQty,
            pageInfo: pageInfo,
          ))
          ..addAll(buildByMovementLineProductTokensPage(
            pageLines: pages[p],
            rowsPerLabel: rowsPerLabel,
          ));

        if(!noDisplayPageLine)out.writeln('----- PAGE ${p + 1}/$totalPages -----');
        out.writeln(replaceAllTokens(refTxt, tokens));
        out.writeln();
      }

      return out.toString().trim();
    }

    if (wantsCategory) {
      final all = movementAndLines.movementLineByCategories;
      final pages = chunkByRows<CategoryAgg>(all, rowsPerLabel);
      final totalPages = pages.isEmpty ? 1 : pages.length;

      if (pages.isEmpty) {
        final tokens = <String, String>{}
          ..addAll(buildCommonTokens(
            movementAndLines: movementAndLines,
            totalQty: totalQty,
            pageInfo: '1/1',
          ))
          ..addAll(buildMovementLineCategoryTokensPage(pageRows: const [], rowsPerLabel: rowsPerLabel));

        if(!noDisplayPageLine)out.writeln('----- PAGE 1/1 -----');
        out.writeln(replaceAllTokens(refTxt, tokens));
        return out.toString().trim();
      }

      for (int p = 0; p < pages.length; p++) {
        final pageInfo = '${p + 1}/$totalPages';
        final tokens = <String, String>{}
          ..addAll(buildCommonTokens(
            movementAndLines: movementAndLines,
            totalQty: totalQty,
            pageInfo: pageInfo,
          ))
          ..addAll(buildMovementLineCategoryTokensPage(
            pageRows: pages[p],
            rowsPerLabel: rowsPerLabel,
          ));

        if(!noDisplayPageLine)out.writeln('----- PAGE ${p + 1}/$totalPages -----');
        out.writeln(replaceAllTokens(refTxt, tokens));
        out.writeln();
      }

      return out.toString().trim();
    }

    // ✅ movement pero sin tokens reconocibles: solo common tokens
    final tokens = <String, String>{}
      ..addAll(buildCommonTokens(
        movementAndLines: movementAndLines,
        totalQty: totalQty,
        pageInfo: '1/1',
      ));

    if(!noDisplayPageLine)out.writeln('----- PAGE 1/1 -----');
    out.writeln(replaceAllTokens(refTxt, tokens));
    return out.toString().trim();
  }

  // Otros modos futuros (shipping, etc.)
  final tokens = <String, String>{}
    ..addAll(buildCommonTokens(
      movementAndLines: movementAndLines,
      totalQty: totalQty,
      pageInfo: '1/1',
    ));

  if(!noDisplayPageLine)out.writeln('----- PAGE 1/1 -----');
  out.writeln(replaceAllTokens(refTxt, tokens));
  return out.toString().trim();
}

/// Try to fill DF content from locally downloaded templates using the Reference (^XFE/^DF).
/// If DF is empty, we extract the referenced template name (e.g. MOV_CAT1.ZPL),
/// then find a downloaded template whose file name contains:
/// - ZplPrintingTemplate.filterOfFileToPrinter
/// - the referenced name
/// Returns an updated template if found, otherwise original.
ZplTemplate resolveDfFromLocalDownloadedTemplates({
  required ZplTemplate result,
  required ZplTemplateStore store,
}) {
  final df = result.zplTemplateDf.trim();
  if (df.isNotEmpty) return result;

  final baseName = extractTemplateNameFromZpl(result.zplReferenceTxt);
  if (baseName == null || baseName.trim().isEmpty) return result;

  //final searchName = '${baseName.trim()}.ZPL';
  final searchName = baseName.trim();

  // English comment: "Search among locally downloaded templates"
  final all = store.loadAll();
  for (final t in all) {
    final fileName = (t.templateFileName).toUpperCase();
    final wanted = searchName.toUpperCase();
    print(wanted);

    // English comment: "Only consider templates that are the 'to printer' variant"
    final hasPrinterSuffix =
    fileName.contains(ZplPrintingTemplate.filterOfFileToPrinter.toUpperCase());

    if (!hasPrinterSuffix) continue;

    // English comment: "Match by referenced .ZPL name"
    if (fileName.contains(wanted)) {
      final candidateDf = t.zplTemplateDf.trim();
      if (candidateDf.isEmpty) continue;
      final newWanted = '$wanted.ZPL';
      // English comment: "Return a copy of the selected template but with DF filled"
      if(candidateDf.contains(newWanted)){
        debugPrint('[FOUND]');
        return result.copyWith(zplTemplateDf: candidateDf);
      }
    }
  }

  return result;
}
