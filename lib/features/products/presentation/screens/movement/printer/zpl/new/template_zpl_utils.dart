import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../../../../common/messages_dialog.dart';
import '../../../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../../../domain/idempiere/movement_and_lines.dart';
import '../../printer_scan_notifier.dart';
import 'template_zpl_models.dart';

// ========= Tokens base (tuyos) =========
const String __DOCUMENT_NUMBER = '__DOCUMENT_NUMBER';
const String __DATE = '__DATE';
const String __STATUS = '__STATUS';
const String __COMPANY = '__COMPANY';
const String __TITLE = '__TITLE';
const String __ADDRESS = '__ADDRESS';
const String __WAREHOUSE_FROM = '__WAREHOUSE_FROM';
const String __WAREHOUSE_TO = '__WAREHOUSE_TO';

String __CATEGORY_SECUENCE(int i) => '__CATEGORY_SECUENCE$i';
String __CATEGORY_NAME(int i)     => '__CATEGORY_NAME$i';
String __CATEGORY_QTY(int i)      => '__CATEGORY_QTY$i';

String __PRODUCT_SECUENCE(int i) => '__PRODUCT_SECUENCE$i';
String __PRODUCT_NAME(int i)     => '__PRODUCT_NAME$i';
String __PRODUCT_UPC(int i)      => '__PRODUCT_UPC$i';
String __PRODUCT_SKU(int i)      => '__PRODUCT_SKU$i';
String __PRODUCT_ATT(int i)      => '__PRODUCT_ATT$i';

String __MOVEMENT_LINE_MOVEMENT_QTY(int i) => '__MOVEMENT_LINE_MOVEMENT_QTY$i';
String __MOVEMENT_LINE_LINE(int i)         => '__MOVEMENT_LINE_LINE$i';

const String __TOTAL_QUANTITY = '__TOTAL_QUANTITY';
const String __PAGE_NUMBER_OVER_TOTAL_PAGE = '__PAGE_NUMBER_OVER_TOTAL_PAGE';

// ========= Helpers =========
String s(dynamic v) => (v == null) ? '' : v.toString();

String zplText(dynamic v) => s(v)
    .replaceAll('^', ' ')
    .replaceAll('~', ' ')
    .replaceAll('\r', ' ')
    .replaceAll('\n', ' ')
    .trim();

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
  tokens.forEach((k, v) => out = out.replaceAll(k, v));
  return out;
}

// ========= Socket =========
Future<void> sendZplBySocket({
  required String ip,
  required int port,
  required String zpl,
}) async {
  final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
  socket.add(zpl.codeUnits);
  await socket.flush();
  await socket.close();
}

// ========= Tokens comunes =========
Map<String, String> buildCommonTokens({
  required MovementAndLines movementAndLines,
  required String totalQty,
  required String pageInfo,
}) {
  return {
    __DOCUMENT_NUMBER: zplText(movementAndLines.documentNumber),
    __DATE: zplText(movementAndLines.movementDate),
    __STATUS: zplText(movementAndLines.documentStatus),
    __COMPANY: zplText(movementAndLines.cBPartnerID?.identifier),
    __TITLE: zplText(movementAndLines.documentMovementTitle),
    __ADDRESS: zplText(movementAndLines.cBPartnerLocationID?.identifier),
    __WAREHOUSE_FROM: zplText(movementAndLines.mWarehouseID?.identifier),
    __WAREHOUSE_TO: zplText(movementAndLines.warehouseTo?.identifier),

    __TOTAL_QUANTITY: zplText(totalQty),
    __PAGE_NUMBER_OVER_TOTAL_PAGE: zplText(pageInfo),
  };
}

// ========= CategoryAgg =========
Map<String, String> buildCategoryTokensPage({
  required List<CategoryAgg> pageRows,
  required int rowsPerLabel,
}) {
  final tokens = <String, String>{};
  for (int i = 0; i < rowsPerLabel; i++) {
    final row = (i < pageRows.length) ? pageRows[i] : null;
    tokens[__CATEGORY_SECUENCE(i)] = zplText(row?.sequence ?? (i + 1));
    tokens[__CATEGORY_NAME(i)]     = zplText(row?.categoryName ?? '');
    tokens[__CATEGORY_QTY(i)]      = zplText(row?.totalQty  ?? '');
  }
  return tokens;
}

// ========= Product lines =========
Map<String, String> buildProductTokensPage({
  required List<IdempiereMovementLine> pageLines,
  required int rowsPerLabel,
}) {
  final tokens = <String, String>{};

  for (int i = 0; i < rowsPerLabel; i++) {
    final IdempiereMovementLine? ml = (i < pageLines.length) ? pageLines[i] : null;

    tokens[__PRODUCT_SECUENCE(i)] = zplText(ml?.line ?? (i + 1));
    tokens[__PRODUCT_NAME(i)]     = zplText(ml?.productName);
    tokens[__PRODUCT_UPC(i)]      = zplText(ml?.uPC);
    tokens[__PRODUCT_SKU(i)]      = zplText(ml?.sKU);
    tokens[__PRODUCT_ATT(i)]      = zplText(ml?.mAttributeSetInstanceID?.identifier);

    tokens[__MOVEMENT_LINE_LINE(i)]         = zplText(ml?.line);
    tokens[__MOVEMENT_LINE_MOVEMENT_QTY(i)] = zplText(ml?.movementQty);
  }

  return tokens;
}

// ========= Preview filled 1ra página =========
String buildFilledPreviewFirstPage({
  required ZplTemplate template,
  required MovementAndLines movementAndLines,
}) {
  final rowsPerLabel = template.mode == ZplTemplateMode.category ? 6 : 8;
  final totalQty = zplText(movementAndLines.totalMovementQty ?? '');
  final pageInfo = '1/1';

  final tokens = <String, String>{}
    ..addAll(buildCommonTokens(movementAndLines: movementAndLines, totalQty: totalQty, pageInfo: pageInfo));

  if (template.mode == ZplTemplateMode.category) {
    final all = movementAndLines.movementLineByCategories ;
    tokens.addAll(buildCategoryTokensPage(pageRows: all.take(rowsPerLabel).toList(), rowsPerLabel: rowsPerLabel));
  } else {
    final all = movementAndLines.movementLines ?? <IdempiereMovementLine>[];
    tokens.addAll(buildProductTokensPage(pageLines: all.take(rowsPerLabel).toList(), rowsPerLabel: rowsPerLabel));
  }

  return replaceAllTokens(template.zplReferenceTxt, tokens);
}

// ========= Imprimir Reference (paginado) =========
Future<void> printReferenceBySocket({
  required String ip,
  required int port,
  required ZplTemplate template,
  required MovementAndLines movementAndLines,
}) async {
  final rowsPerLabel = template.mode == ZplTemplateMode.category ? 6 : 8;
  final totalQty = zplText(movementAndLines.totalMovementQty ?? '');

  if (template.mode == ZplTemplateMode.category) {
    final List<CategoryAgg> all = movementAndLines.movementLineByCategories ;
    final pages = chunkByRows<CategoryAgg>(all, rowsPerLabel);
    final totalPages = pages.isEmpty ? 1 : pages.length;

    for (int p = 0; p < pages.length; p++) {
      final pageInfo = '${p + 1}/$totalPages';
      final tokens = <String, String>{}
        ..addAll(buildCommonTokens(movementAndLines: movementAndLines, totalQty: totalQty, pageInfo: pageInfo))
        ..addAll(buildCategoryTokensPage(pageRows: pages[p], rowsPerLabel: rowsPerLabel));

      await sendZplBySocket(ip: ip, port: port, zpl: replaceAllTokens(template.zplReferenceTxt, tokens));
    }
    return;
  }

  final all = movementAndLines.movementLines ?? <IdempiereMovementLine>[];
  final pages = chunkByRows<IdempiereMovementLine>(all, rowsPerLabel);
  final totalPages = pages.isEmpty ? 1 : pages.length;

  for (int p = 0; p < pages.length; p++) {
    final pageInfo = '${p + 1}/$totalPages';
    final tokens = <String, String>{}
      ..addAll(buildCommonTokens(movementAndLines: movementAndLines, totalQty: totalQty, pageInfo: pageInfo))
      ..addAll(buildProductTokensPage(pageLines: pages[p], rowsPerLabel: rowsPerLabel));

    await sendZplBySocket(ip: ip, port: port, zpl: replaceAllTokens(template.zplReferenceTxt, tokens));
  }
}
String buildReferenceProductExample({required String templateFileNoDrive}) {
  final sb = StringBuffer();
  sb.writeln('^XA');
  sb.writeln('^CI28');
  sb.writeln('^XFE:$templateFileNoDrive^FS');
  sb.writeln('');
  sb.writeln('^FN1^FDLA,__DOCUMENT_NUMBER^FS');
  sb.writeln('^FN2^FD__DOCUMENT_NUMBER^FS');
  sb.writeln('^FN3^FD__DATE^FS');
  sb.writeln('^FN4^FD__STATUS^FS');
  sb.writeln('^FN5^FD__COMPANY^FS');
  sb.writeln('^FN6^FD__TITLE^FS');
  sb.writeln('^FN7^FDDireccion: __ADDRESS^FS');
  sb.writeln('^FN8^FDFrom: __WAREHOUSE_FROM^FS');
  sb.writeln('^FN9^FDTO: __WAREHOUSE_TO^FS');
  sb.writeln('');

  // 8 filas: FN101.. (por fila: sequence, name, upc, sku, att, line, qty)
  // OJO: esto es un ejemplo de “reference”; tu TEMPLATE DF debe tener esos FN puestos en el layout de producto.
  int fn = 101;
  for (int i = 0; i < 8; i++) {
    sb.writeln('^FN${fn++}^FD${__PRODUCT_SECUENCE(i)}^FS');
    sb.writeln('^FN${fn++}^FD${__PRODUCT_NAME(i)}^FS');
    sb.writeln('^FN${fn++}^FD${__PRODUCT_UPC(i)}^FS');
    sb.writeln('^FN${fn++}^FD${__PRODUCT_SKU(i)}^FS');
    sb.writeln('^FN${fn++}^FD${__PRODUCT_ATT(i)}^FS');
    sb.writeln('^FN${fn++}^FD${__MOVEMENT_LINE_LINE(i)}^FS');
    sb.writeln('^FN${fn++}^FD${__MOVEMENT_LINE_MOVEMENT_QTY(i)}^FS');
    sb.writeln('');
  }

  sb.writeln('^FN901^FD__TOTAL_QUANTITY^FS');
  sb.writeln('^FN902^FD__PAGE_NUMBER_OVER_TOTAL_PAGE^FS');
  sb.writeln('');
  sb.writeln('^PQ1');
  sb.writeln('^XZ');
  return sb.toString().trim();
}
List<PopupMenuEntry<String>> tokenMenuItemsByMode({
  required ZplTemplateMode mode,
  required int rowsPerLabel,
}) {
  final items = <PopupMenuEntry<String>>[];

  // HEADER
  items.add(const PopupMenuItem(enabled: false, child: Text('HEADER', style: TextStyle(fontWeight: FontWeight.bold))));
  items.add(const PopupMenuItem(value: __DOCUMENT_NUMBER, child: Text('__DOCUMENT_NUMBER')));
  items.add(const PopupMenuItem(value: __DATE, child: Text('__DATE')));
  items.add(const PopupMenuItem(value: __STATUS, child: Text('__STATUS')));
  items.add(const PopupMenuItem(value: __COMPANY, child: Text('__COMPANY')));
  items.add(const PopupMenuItem(value: __TITLE, child: Text('__TITLE')));
  items.add(const PopupMenuItem(value: __ADDRESS, child: Text('__ADDRESS')));
  items.add(const PopupMenuItem(value: __WAREHOUSE_FROM, child: Text('__WAREHOUSE_FROM')));
  items.add(const PopupMenuItem(value: __WAREHOUSE_TO, child: Text('__WAREHOUSE_TO')));
  items.add(const PopupMenuDivider());

  // CATEGORY tokens (solo en modo category; si quieres también en product, cambia condición)
  if (mode == ZplTemplateMode.category) {
    items.add(const PopupMenuItem(enabled: false, child: Text('CATEGORY (por fila)', style: TextStyle(fontWeight: FontWeight.bold))));
    for (int i = 0; i < rowsPerLabel; i++) {
      items.add(PopupMenuItem(value: __CATEGORY_SECUENCE(i), child: Text('__CATEGORY_SECUENCE$i')));
      items.add(PopupMenuItem(value: __CATEGORY_NAME(i), child: Text('__CATEGORY_NAME$i')));
      items.add(PopupMenuItem(value: __CATEGORY_QTY(i), child: Text('__CATEGORY_QTY$i')));
      if (i != rowsPerLabel - 1) items.add(const PopupMenuDivider());
    }
    items.add(const PopupMenuDivider());
  }

  // PRODUCT + MOVEMENT LINE tokens (solo en modo product)
  if (mode == ZplTemplateMode.product) {
    items.add(const PopupMenuItem(enabled: false, child: Text('PRODUCT (por fila)', style: TextStyle(fontWeight: FontWeight.bold))));
    for (int i = 0; i < rowsPerLabel; i++) {
      items.add(PopupMenuItem(value: __PRODUCT_SECUENCE(i), child: Text('__PRODUCT_SECUENCE$i')));
      items.add(PopupMenuItem(value: __PRODUCT_NAME(i), child: Text('__PRODUCT_NAME$i')));
      items.add(PopupMenuItem(value: __PRODUCT_UPC(i), child: Text('__PRODUCT_UPC$i')));
      items.add(PopupMenuItem(value: __PRODUCT_SKU(i), child: Text('__PRODUCT_SKU$i')));
      items.add(PopupMenuItem(value: __PRODUCT_ATT(i), child: Text('__PRODUCT_ATT$i')));
      if (i != rowsPerLabel - 1) items.add(const PopupMenuDivider());
    }
    items.add(const PopupMenuDivider());

    items.add(const PopupMenuItem(enabled: false, child: Text('MOVEMENT LINE (por fila)', style: TextStyle(fontWeight: FontWeight.bold))));
    for (int i = 0; i < rowsPerLabel; i++) {
      items.add(PopupMenuItem(value: __MOVEMENT_LINE_LINE(i), child: Text('__MOVEMENT_LINE_LINE$i')));
      items.add(PopupMenuItem(value: __MOVEMENT_LINE_MOVEMENT_QTY(i), child: Text('__MOVEMENT_LINE_MOVEMENT_QTY$i')));
      if (i != rowsPerLabel - 1) items.add(const PopupMenuDivider());
    }
    items.add(const PopupMenuDivider());
  }

  // FOOTER
  items.add(const PopupMenuItem(enabled: false, child: Text('FOOTER', style: TextStyle(fontWeight: FontWeight.bold))));
  items.add(const PopupMenuItem(value: __TOTAL_QUANTITY, child: Text('__TOTAL_QUANTITY')));
  items.add(const PopupMenuItem(value: __PAGE_NUMBER_OVER_TOTAL_PAGE, child: Text('__PAGE_NUMBER_OVER_TOTAL_PAGE')));

  return items;
}

String buildReferenceTxtByCategory({
  String templateFileNameNoDrive = 'TEMPLATE.ZPL', // va dentro de ^XFE:...
}) {
  return '''
^XA
^CI28
^XFE:$templateFileNameNoDrive^FS

^FN1^FDLA,__DOCUMENT_NUMBER^FS
^FN2^FD__DOCUMENT_NUMBER^FS
^FN3^FD__DATE^FS
^FN4^FD__STATUS^FS
^FN5^FD__COMPANY^FS
^FN6^FD__TITLE^FS

^FN7^FDDireccion: __ADDRESS^FS
^FN8^FDFrom: __WAREHOUSE_FROM^FS
^FN9^FDTO: __WAREHOUSE_TO^FS

^FN101^FD__CATEGORY_SECUENCE0^FS
^FN102^FD__CATEGORY_NAME0^FS
^FN103^FD__CATEGORY_QTY0^FS

^FN104^FD__CATEGORY_SECUENCE1^FS
^FN105^FD__CATEGORY_NAME1^FS
^FN106^FD__CATEGORY_QTY1^FS

^FN107^FD__CATEGORY_SECUENCE2^FS
^FN108^FD__CATEGORY_NAME2^FS
^FN109^FD__CATEGORY_QTY2^FS

^FN110^FD__CATEGORY_SECUENCE3^FS
^FN111^FD__CATEGORY_NAME3^FS
^FN112^FD__CATEGORY_QTY3^FS

^FN113^FD__CATEGORY_SECUENCE4^FS
^FN114^FD__CATEGORY_NAME4^FS
^FN115^FD__CATEGORY_QTY4^FS

^FN116^FD__CATEGORY_SECUENCE5^FS
^FN117^FD__CATEGORY_NAME5^FS
^FN118^FD__CATEGORY_QTY5^FS

^FN901^FD__TOTAL_QUANTITY^FS
^FN902^FD__PAGE_NUMBER_OVER_TOTAL_PAGE^FS

^PQ1
^XZ
'''.trim();
}
String buildTemplateZpl100x150ByCategoryDf({
  String printerFile = 'E:TEMPLATE.ZPL',
  int rowsPerLabel = 6,
}) {
  final sb = StringBuffer();
  sb.writeln('^XA');
  sb.writeln('^CI28');
  sb.writeln('^PW800');
  sb.writeln('^LL1200');
  sb.writeln('^LH0,0');
  sb.writeln('^LS0');
  sb.writeln('^PR3');
  sb.writeln('');
  sb.writeln('^DF$printerFile^FS');
  sb.writeln('');
  sb.writeln('^FO20,20');
  sb.writeln('^BQN,2,8');
  sb.writeln('^FN1^FS');
  sb.writeln('');
  sb.writeln('^FO192,24^FB572,1,0,R^A0N,44,32^FN2^FS');
  sb.writeln('^FO192,76^FB286,1,0,C^A0N,24,18^FN3^FS');
  sb.writeln('^FO478,76^FB286,1,0,R^A0N,24,18^FN4^FS');
  sb.writeln('^FO192,108^FB572,1,0,R^A0N,26,20^FN5^FS');
  sb.writeln('^FO192,140^FB572,1,0,R^A0N,30,22^FN6^FS');
  sb.writeln('');
  sb.writeln('^FO192,176^FB572,1,0,R^A0N,22,18^FN7^FS');
  sb.writeln('^FO192,204^FB572,1,0,R^A0N,22,18^FN8^FS');
  sb.writeln('^FO192,232^FB572,1,0,R^A0N,22,18^FN9^FS');
  sb.writeln('');
  sb.writeln('^FO20,498^GB744,2,2^FS');
  sb.writeln('^FO20,508^A0N,22,18^FDNo^FS');
  sb.writeln('^FO90,508^A0N,22,18^FDCATEGORY NAME^FS');
  sb.writeln('^FO624,508^FB140,1,0,R^A0N,22,18^FDQTY^FS');
  sb.writeln('^FO20,580^GB744,2,2^FS');
  sb.writeln('');

  // Body 6 filas: FN101..FN118
  final rows = [
    [590, 664],
    [670, 744],
    [750, 824],
    [830, 904],
    [910, 984],
    [990, 1064],
  ];
  int fn = 101;
  for (final r in rows) {
    final y = r[0];
    final sep = r[1];
    sb.writeln('^FO20,$y^FB70,1,0,L^A0N,24,18^FN$fn^FS'); fn++;
    sb.writeln('^FO90,$y^FB534,1,0,L^A0N,24,18^FN$fn^FS'); fn++;
    sb.writeln('^FO624,$y^FB140,1,0,R^A0N,28,22^FN$fn^FS'); fn++;
    sb.writeln('^FO20,$sep^GB744,1,1^FS');
    sb.writeln('');
  }

  // Total + footer (FN901/FN902)
  sb.writeln('^FO20,1074^FB360,1,0,L^A0N,28,20^FDTOTAL QTY : ^FS');
  sb.writeln('^FO380,1074^FB384,1,0,R^A0N,28,20^FN901^FS');
  sb.writeln('');
  sb.writeln('^FO20,1100^GB744,2,2^FS');
  sb.writeln('^FO644,1120^FB120,1,0,R^A0N,28,20^FN902^FS');
  sb.writeln('^XZ');

  return sb.toString();
}

String fillReferenceZpl({
  required String referenceTxt,        // contenido de TEMPLATE.ZPL_REFERENCE.TXT
  required dynamic movementAndLines,
  required List<dynamic> categories,
  required int rowsPerLabel,
}) {
  final tokens = <String, String>{}
    ..addAll(buildHeaderFooterTokens(movementAndLines))
    ..addAll(buildCategoryTokens(categories: categories, rowsPerLabel: rowsPerLabel));

  return replaceAllTokens(referenceTxt, tokens);
}
Map<String, String> buildCategoryTokens({
  required List<dynamic> categories, // tu lista ya ordenada
  required int rowsPerLabel,
}) {
  final map = <String, String>{};
  for (int i = 0; i < rowsPerLabel; i++) {
    final row = (i < categories.length) ? categories[i] : null;

    map[__CATEGORY_SECUENCE(i)] = _zplText(row?.sequence);
    map[__CATEGORY_NAME(i)]     = _zplText(row?.name);
    map[__CATEGORY_QTY(i)]      = _zplText(row?.qty);
  }
  return map;
}
Map<String, String> buildHeaderFooterTokens(dynamic movementAndLines) {
  return {
    __DOCUMENT_NUMBER: _zplText(movementAndLines.documentNumber),
    __DATE:            _zplText(movementAndLines.movementDate),
    __STATUS:          _zplText(movementAndLines.documentStatus),
    __COMPANY:         _zplText(movementAndLines.cBPartnerID?.identifier),
    __TITLE:           _zplText(movementAndLines.documentMovementTitle),
    __ADDRESS:         _zplText(movementAndLines.cBPartnerLocationID?.identifier),
    __WAREHOUSE_FROM:  _zplText(movementAndLines.mWarehouseID?.identifier),
    __WAREHOUSE_TO:    _zplText(movementAndLines.warehouseTo?.identifier),

    __TOTAL_QUANTITY: _zplText(movementAndLines.totalQty), // si lo tienes calculado
    __PAGE_NUMBER_OVER_TOTAL_PAGE: _zplText(movementAndLines.pageInfo), // ej: "1/3"
  };
}
String _s(dynamic v) => (v == null) ? '' : v.toString();

String _zplText(dynamic v) {
  // evita caracteres problemáticos; ajusta a tu gusto
  return _s(v)
      .replaceAll('^', ' ')
      .replaceAll('~', ' ')
      .replaceAll('\r', ' ')
      .trim();
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
Future<void> printZplFromReferenceFile(
    WidgetRef ref,
    MovementAndLines movementAndLines, {
      required String referenceFilePath,
      required ZplTemplateMode mode, // category(6) o product(8)
      String templateFileName = 'E:TEMPLATE.ZPL', // solo para info / ^XFE:...
    }) async {
  final state = ref.read(printerScanProvider);
  final ip = state.ipController.text.trim();
  final port = int.tryParse(state.portController.text.trim()) ?? 0;

  if (ip.isEmpty || port == 0) {
    showWarningMessage(ref.context, ref, 'IP/PORT inválido');
    return;
  }

  if (!isReferenceFile(referenceFilePath)) {
    showWarningMessage(ref.context, ref, 'El archivo debe terminar en _REFERENCE.TXT');
    return;
  }

  final referenceTxt = await readTxtFile(referenceFilePath);

  // Template “temporal” (no requiere DF)
  final temp = ZplTemplate(
    id: 'FILE_REF_${DateTime.now().millisecondsSinceEpoch}',
    templateFileName: templateFileName,
    zplTemplateDf: '',
    zplReferenceTxt: referenceTxt,
    mode: mode,
    createdAt: DateTime.now(),
  );

  await printReferenceBySocket(
    ip: ip,
    port: port,
    template: temp,
    movementAndLines: movementAndLines,
  );
}
Future<void> sendZplTemplateDfFromFile(
    WidgetRef ref, {
      required String templateDfFilePath,
    }) async {
  final state = ref.read(printerScanProvider);
  final ip = state.ipController.text.trim();
  final port = int.tryParse(state.portController.text.trim()) ?? 0;

  if (ip.isEmpty || port == 0) {
    showWarningMessage(ref.context, ref, 'IP/PORT inválido');
    return;
  }

  if (!isTemplateDfFile(templateDfFilePath)) {
    showWarningMessage(ref.context, ref, 'El archivo debe terminar en TEMPLATE.TXT');
    return;
  }

  final dfTxt = await readTxtFile(templateDfFilePath);

  // Enviar DF a impresora (instalar plantilla)
  await sendZplBySocket(ip: ip, port: port, zpl: dfTxt);
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
    __DOCUMENT_NUMBER,
    __DATE,
    __STATUS,
    __COMPANY,
    __TITLE,
    __ADDRESS,
    __WAREHOUSE_FROM,
    __WAREHOUSE_TO,
    __TOTAL_QUANTITY,
    __PAGE_NUMBER_OVER_TOTAL_PAGE,
  };

  if (mode == ZplTemplateMode.category) {
    for (int i = 0; i < rowsPerLabel; i++) {
      s.add(__CATEGORY_SECUENCE(i));
      s.add(__CATEGORY_NAME(i));
      s.add(__CATEGORY_QTY(i));
    }
  } else {
    for (int i = 0; i < rowsPerLabel; i++) {
      s.add(__PRODUCT_SECUENCE(i));
      s.add(__PRODUCT_NAME(i));
      s.add(__PRODUCT_UPC(i));
      s.add(__PRODUCT_SKU(i));
      s.add(__PRODUCT_ATT(i));
      s.add(__MOVEMENT_LINE_LINE(i));
      s.add(__MOVEMENT_LINE_MOVEMENT_QTY(i));
    }
  }
  return s;
}
List<String> validateMissingTokens({
  required ZplTemplate template,
  required String referenceTxt,
}) {
  final used = extractTokensUsed(referenceTxt);
  final rows = template.mode == ZplTemplateMode.category ? 6 : 8;
  final available = buildAvailableTokenSet(mode: template.mode, rowsPerLabel: rows);

  final missing = used.difference(available).toList()..sort();
  return missing;
}
String buildFilledPreviewAllPages({
  required ZplTemplate template,
  required MovementAndLines movementAndLines,
}) {
  final rowsPerLabel = template.mode == ZplTemplateMode.category ? 6 : 8;
  final totalQty = zplText(movementAndLines.totalMovementQty ?? '');

  final out = StringBuffer();

  if (template.mode == ZplTemplateMode.category) {
    final all = movementAndLines.movementLineByCategories ?? <CategoryAgg>[];
    final pages = chunkByRows<CategoryAgg>(all, rowsPerLabel);
    final totalPages = pages.isEmpty ? 1 : pages.length;

    for (int p = 0; p < pages.length; p++) {
      final pageInfo = '${p + 1}/$totalPages';
      final tokens = <String, String>{}
        ..addAll(buildCommonTokens(movementAndLines: movementAndLines, totalQty: totalQty, pageInfo: pageInfo))
        ..addAll(buildCategoryTokensPage(pageRows: pages[p], rowsPerLabel: rowsPerLabel));

      out.writeln('----- PAGE ${p + 1}/$totalPages -----');
      out.writeln(replaceAllTokens(template.zplReferenceTxt, tokens));
      out.writeln();
    }
    return out.toString().trim();
  }

  final all = movementAndLines.movementLines ?? <IdempiereMovementLine>[];
  final pages = chunkByRows<IdempiereMovementLine>(all, rowsPerLabel);
  final totalPages = pages.isEmpty ? 1 : pages.length;

  for (int p = 0; p < pages.length; p++) {
    final pageInfo = '${p + 1}/$totalPages';
    final tokens = <String, String>{}
      ..addAll(buildCommonTokens(movementAndLines: movementAndLines, totalQty: totalQty, pageInfo: pageInfo))
      ..addAll(buildProductTokensPage(pageLines: pages[p], rowsPerLabel: rowsPerLabel));

    out.writeln('----- PAGE ${p + 1}/$totalPages -----');
    out.writeln(replaceAllTokens(template.zplReferenceTxt, tokens));
    out.writeln();
  }

  return out.toString().trim();
}
