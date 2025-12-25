import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';
import 'package:path/path.dart' as p;
import '../../../../../../../shared/data/memory.dart';
import '../../../../../../common/messages_dialog.dart';
import '../../../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../../../domain/idempiere/movement_and_lines.dart';
import '../../../../../providers/common_provider.dart';
import '../../../../../providers/product_provider_common.dart';
import '../../printer_scan_notifier.dart';
import 'template_zpl_models.dart';

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

  /*// Strings que representan números
  if (v is String) {
    final parsed = num.tryParse(v.replaceAll(',', '.'));
    if (parsed != null) {
      return Memory.numberFormatter0Digit.format(parsed);
    }
    return v;
  }*/

  // Fallback seguro
  return v.toString();
}


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

  final sortedKeys = tokens.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length)); // 🔑 CLAVE

  for (final k in sortedKeys) {
    out = out.replaceAll(k, tokens[k]!);
  }

  return out;
}

// ========= Socket =========
Future<void> sendZplBySocket({
  required String ip,
  required int port,
  required String zpl,
}) async {
  Socket? socket;
  print(zpl);
  try{
    socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
    socket.add(zpl.codeUnits);
    await socket.flush();
    await socket.close();
  } catch(e){
    print('Error al enviar zpl: $e');
    socket?.close();
    throw Exception('Error al enviar zpl: $e');
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
Future<void> printReferenceBySocket({
  required String ip,
  required int port,
  required ZplTemplate template,
  required MovementAndLines movementAndLines,
}) async {
  final rowsPerLabel = template.rowPerpage;
  final totalQty = zplText(movementAndLines.totalMovementQty ?? '');
  final refTxt = template.zplReferenceTxt;

  final bool wantsCategory = refTxt.contains('__CATEGORY_');
  final bool wantsProduct =
      refTxt.contains('__MOVEMENT_LINE') || refTxt.contains('__PRODUCT_');

  // Solo movement por ahora (luego shipping, etc.)
  if (template.mode == ZplTemplateMode.movement) {
    // ✅ Prioridad: PRODUCT > CATEGORY
    if (wantsProduct) {
      final all = movementAndLines.movementLines ?? <IdempiereMovementLine>[];
      final pages = chunkByRows<IdempiereMovementLine>(all, rowsPerLabel);
      final totalPages = pages.isEmpty ? 1 : pages.length;

      // Si no hay datos, igual imprimir 1 página (header/footer)
      final safePages = pages.isEmpty ? [<IdempiereMovementLine>[]] : pages;

      for (int p = 0; p < safePages.length; p++) {
        final pageInfo = '${p + 1}/$totalPages';
        final tokens = <String, String>{}
          ..addAll(buildCommonTokens(
            movementAndLines: movementAndLines,
            totalQty: totalQty,
            pageInfo: pageInfo,
          ))
          ..addAll(buildByMovementLineProductTokensPage(
            pageLines: safePages[p],
            rowsPerLabel: rowsPerLabel,
          ));
        String result = replaceAllTokens(refTxt, tokens);
        try{
          await sendZplBySocket(
            ip: ip,
            port: port,
            zpl: result,
          );
        } catch(e){
          print('Error al enviar zpl: $e');
          throw Exception('Error al enviar zpl: $e');
        }

      }
      return;
    }

    if (wantsCategory) {
      final all = movementAndLines.movementLineByCategories;
      final pages = chunkByRows<CategoryAgg>(all, rowsPerLabel);
      final totalPages = pages.isEmpty ? 1 : pages.length;

      final safePages = pages.isEmpty ? [<CategoryAgg>[]] : pages;

      for (int p = 0; p < safePages.length; p++) {
        final pageInfo = '${p + 1}/$totalPages';
        final categoryTokens =buildMovementLineCategoryTokensPage(
          pageRows: safePages[p],
          rowsPerLabel: rowsPerLabel,
        ) ;
        final tokens = <String, String>{}
          ..addAll(buildCommonTokens(
            movementAndLines: movementAndLines,
            totalQty: totalQty,
            pageInfo: pageInfo,
          ))
          ..addAll(categoryTokens);

        String result = replaceAllTokens(refTxt, tokens);
        try{
          await sendZplBySocket(
            ip: ip,
            port: port,
            zpl: result,
          );
        } catch(e){
          print('Error al enviar zpl: $e');
          throw Exception('Error al enviar zpl: $e');
        }
      }
      return;
    }

    // ✅ movement pero sin tokens de tabla: imprime solo common tokens (1 página)
    final tokens = <String, String>{}
      ..addAll(buildCommonTokens(
        movementAndLines: movementAndLines,
        totalQty: totalQty,
        pageInfo: '1/1',
      ));
    String result = replaceAllTokens(refTxt, tokens);
    try{
      await sendZplBySocket(
        ip: ip,
        port: port,
        zpl: result,
      );
    } catch(e){
      print('Error al enviar zpl: $e');
      throw Exception('Error al enviar zpl: $e');
    }
    return;
  }

  // Otros modos futuros (shipping, etc.) => por ahora 1 página common
  final tokens = <String, String>{}
    ..addAll(buildCommonTokens(
      movementAndLines: movementAndLines,
      totalQty: totalQty,
      pageInfo: '1/1',
    ));
  String result = replaceAllTokens(refTxt, tokens);
  try{
    await sendZplBySocket(
      ip: ip,
      port: port,
      zpl: result,
    );
  } catch(e){
    print('Error al enviar zpl: $e');
    throw Exception('Error al enviar zpl: $e');
  }
}



/*String fillReferenceZpl({
  required String referenceTxt,        // contenido de TEMPLATE.ZPL_REFERENCE.TXT
  required dynamic movementAndLines,
  required List<dynamic> categories,
  required int rowsPerLabel,
}) {
  final tokens = <String, String>{}
    ..addAll(buildHeaderFooterTokens(movementAndLines))
    ..addAll(buildCategoryTokens(categories: categories, rowsPerLabel: rowsPerLabel));

  return replaceAllTokens(referenceTxt, tokens);
}*/
/*Map<String, String> buildCategoryTokens({
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
}*/
/*Map<String, String> buildHeaderFooterTokens(dynamic movementAndLines) {
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
}*/
/*String _s(dynamic v) => (v == null) ? '' : v.toString();

String _zplText(dynamic v) {
  // evita caracteres problemáticos; ajusta a tu gusto
  return _s(v)
      .replaceAll('^', ' ')
      .replaceAll('~', ' ')
      .replaceAll('\r', ' ')
      .trim();
}*/


Future<String> readTxtFile(String filePath) async {
  return File(filePath).readAsString();
}

bool isReferenceFile(String filePath) =>
    p.basename(filePath).toUpperCase().endsWith('_REFERENCE.TXT');

bool isTemplateDfFile(String filePath) {
  final name = p.basename(filePath).toUpperCase();
  return name.endsWith('TEMPLATE.TXT') || name.endsWith('TEMPLATE.ZPL') || name.endsWith('_TEMPLATE.TXT');
}


/*Future<void> sendZplTemplateDfFromFile(
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
}*/
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

        out.writeln('----- PAGE 1/1 -----');
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

        out.writeln('----- PAGE ${p + 1}/$totalPages -----');
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

        out.writeln('----- PAGE 1/1 -----');
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

        out.writeln('----- PAGE ${p + 1}/$totalPages -----');
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

    out.writeln('----- PAGE 1/1 -----');
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

  out.writeln('----- PAGE 1/1 -----');
  out.writeln(replaceAllTokens(refTxt, tokens));
  return out.toString().trim();
}




List<TokenItem> buildTokenCatalog({
  required ZplTemplateMode mode,
  required int rowsPerLabel,
}) {
  final rows = rowsPerLabel.clamp(1, 50);
  final list = <TokenItem>[];

  // HEADER
  const header = 'HEADER';
  list.addAll([
    const TokenItem(header, DOCUMENT_NUMBER__),
    const TokenItem(header, DATE__),
    const TokenItem(header, STATUS__),
    const TokenItem(header, COMPANY__),
    const TokenItem(header, TITLE__),
    const TokenItem(header, ADDRESS__),
    const TokenItem(header, WAREHOUSE_FROM__),
    const TokenItem(header, WAREHOUSE_TO__),
  ]);

  // CATEGORY
  if (mode == ZplTemplateMode.movement) {
    const sec = 'LINE (por fila)';
    for (int i = 0; i < rows; i++) {
      list.add(TokenItem(sec, CATEGORY_SEQUENCE__(i)));
      list.add(TokenItem(sec, CATEGORY_NAME__(i)));
      list.add(TokenItem(sec, CATEGORY_QTY__(i)));
      list.add(TokenItem(sec, MOVEMENT_LINE_LINE__(i)));
      list.add(TokenItem(sec, MOVEMENT_LINE_MOVEMENT_QTY__(i)));
      list.add(TokenItem(sec, PRODUCT_SQCUENCE__(i)));
      list.add(TokenItem(sec, PRODUCT_NAME__(i)));
      list.add(TokenItem(sec, PRODUCT_UPC__(i)));
      list.add(TokenItem(sec, PRODUCT_SKU__(i)));
      list.add(TokenItem(sec, PRODUCT_ATT__(i)));
    }
  }

  // FOOTER
  const footer = 'FOOTER';
  list.addAll([
    const TokenItem(footer, TOTAL_QUANTITY__),
    const TokenItem(footer, PAGE_NUMBER_OVER_TOTAL_PAGE__),
    const TokenItem(footer, GENERATED_BY__),
  ]);

  return list;
}

/// BottomSheet con búsqueda.
/// Devuelve el token seleccionado o null si canceló.
Future<String?> showZplTokenPickerSheet({
  required WidgetRef ref,
  required BuildContext context,
  required ZplTemplateMode mode,
  required int rowsPerLabel,
}) async {
  final all = buildTokenCatalog(mode: mode, rowsPerLabel: rowsPerLabel);
  ref.read(enableScannerKeyboardProvider.notifier).state = false;
  ref.read(isDialogShowedProvider.notifier).state = true;
  return showModalBottomSheet<String>(
    isDismissible: false,
    enableDrag: false,
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {

      return StatefulBuilder(
        builder: (ctx, setState) {
          String q = '';
          final query = q.trim().toUpperCase();

          final filtered = (query.isEmpty)
              ? all
              : all.where((t) {
            final hay = '${t.section} ${t.token}'.toUpperCase();
            return hay.contains(query);
          }).toList();

          // Agrupar por sección (manteniendo orden)
          final sections = <String, List<TokenItem>>{};
          for (final item in filtered) {
            sections.putIfAbsent(item.section, () => []).add(item);
          }

          final height = MediaQuery.of(ctx).size.height * 0.85;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              if (didPop) {
                return;
              }
              ref.read(enableScannerKeyboardProvider.notifier).state = true;
              ref.read(isDialogShowedProvider.notifier).state = false;
              Navigator.pop(context, null);
            },
            child: SizedBox(
              height: height,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Buscar token',
                        hintText: 'Ej: PRODUCT_NAME, TOTAL, PAGE, CATEGORY_QTY…',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: (q.isEmpty)
                            ? null
                            : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => q = ''),
                        ),
                      ),
                      onChanged: (v) => setState(() => q = v),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      children: [
                        for (final entry in sections.entries) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          ...entry.value.map(
                                (it) => Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Colors.black12),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  it.token,
                                  style: const TextStyle(fontFamily: 'monospace'),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                onTap: () {
                                  ref.read(enableScannerKeyboardProvider.notifier).state = true;
                                  ref.read(isDialogShowedProvider.notifier).state = false;
                                  Navigator.pop(ctx, it.token);
                                },
                              ),
                            ),
                          ),
                        ],
                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No hay resultados.'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> printTemplateSmart({
  required WidgetRef ref,
  required ZplTemplate template,
  required MovementAndLines movementAndLines,
  required userName,
}) async {
  if(!Memory.isAdmin) return ;
  final printerState = ref.read(printerScanProvider);
  final ip = printerState.ipController.text.trim();
  final port = int.tryParse(printerState.portController.text.trim()) ?? 0;

  if (ip.isEmpty || port == 0) {
    showWarningMessage(ref.context, ref, 'IP/PORT inválido');
    return;
  }

  final missing = validateMissingTokens(template: template, referenceTxt: template.zplReferenceTxt);
  if (missing.isNotEmpty) {
    showWarningMessage(ref.context, ref, 'Tokens no soportados: ${missing.join(', ')}');
    return;
  }

  final df = template.zplTemplateDf.trim();
  if (df.isNotEmpty) {
    await sendZplBySocket(ip: ip, port: port, zpl: df);
  }

  await printReferenceBySocket(
    ip: ip,
    port: port,
    template: template,
    movementAndLines: movementAndLines,
  );
}
//--------------------
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
  sb.writeln('^FN7^FD__ADDRESS^FS');
  sb.writeln('^FN8^FD__WAREHOUSE_FROM^FS');
  sb.writeln('^FN9^FD__WAREHOUSE_TO^FS');
  sb.writeln('');

  // 8 filas: FN101.. (por fila: sequence, name, upc, sku, att, line, qty)
  // OJO: esto es un ejemplo de “reference”; tu TEMPLATE DF debe tener esos FN puestos en el layout de producto.
  int fn = 101;
  for (int i = 0; i < 8; i++) {
    sb.writeln('^FN${fn++}^FD${PRODUCT_SQCUENCE__(i)}^FS');
    sb.writeln('^FN${fn++}^FD${PRODUCT_NAME__(i)}^FS');
    sb.writeln('^FN${fn++}^FD${PRODUCT_UPC__(i)}^FS');
    sb.writeln('^FN${fn++}^FD${PRODUCT_SKU__(i)}^FS');
    sb.writeln('^FN${fn++}^FD${PRODUCT_ATT__(i)}^FS');
    sb.writeln('^FN${fn++}^FD${MOVEMENT_LINE_LINE__(i)}^FS');
    sb.writeln('^FN${fn++}^FD${MOVEMENT_LINE_MOVEMENT_QTY__(i)}^FS');
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

  final int rows = rowsPerLabel.clamp(1, 50);

  PopupMenuItem<String> token(String v) => PopupMenuItem(value: v, child: Text(v));
  PopupMenuItem<String> header(String t) => PopupMenuItem<String>(
    enabled: false,
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  // HEADER
  items.add(header('HEADER'));
  items.addAll([
    token(DOCUMENT_NUMBER__),
    token(DATE__),
    token(STATUS__),
    token(COMPANY__),
    token(TITLE__),
    token(ADDRESS__),
    token(WAREHOUSE_FROM__),
    token(WAREHOUSE_TO__),
  ]);
  items.add(const PopupMenuDivider());

  if (mode == ZplTemplateMode.movement) {
    items.add(header('TABLE(por fila)'));
    for (int i = 0; i < rows; i++) {
      items.addAll([
        token(CATEGORY_SEQUENCE__(i)),
        token(CATEGORY_NAME__(i)),
        token(CATEGORY_QTY__(i)),
        token(MOVEMENT_LINE_LINE__(i)),
        token(MOVEMENT_LINE_MOVEMENT_QTY__(i)),
        token(PRODUCT_SQCUENCE__(i)),
        token(PRODUCT_NAME__(i)),
        token(PRODUCT_UPC__(i)),
        token(PRODUCT_SKU__(i)),
        token(PRODUCT_ATT__(i)),
      ]);
      if (i != rows - 1) items.add(const PopupMenuDivider());
    }
    items.add(const PopupMenuDivider());
  }


  // FOOTER
  items.add(header('FOOTER'));
  items.addAll([
    token(TOTAL_QUANTITY__),
    token(PAGE_NUMBER_OVER_TOTAL_PAGE__),
  ]);

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

^FN7^FD__ADDRESS^FS
^FN8^FD__WAREHOUSE_FROM^FS
^FN9^FD__WAREHOUSE_TO^FS

^FN101^FD__CATEGORY_SEQUENCE0^FS
^FN102^FD__CATEGORY_NAME0^FS
^FN103^FD__CATEGORY_QTY0^FS

^FN104^FD__CATEGORY_SEQUENCE1^FS
^FN105^FD__CATEGORY_NAME1^FS
^FN106^FD__CATEGORY_QTY1^FS

^FN107^FD__CATEGORY_SEQUENCE2^FS
^FN108^FD__CATEGORY_NAME2^FS
^FN109^FD__CATEGORY_QTY2^FS

^FN110^FD__CATEGORY_SEQUENCE3^FS
^FN111^FD__CATEGORY_NAME3^FS
^FN112^FD__CATEGORY_QTY3^FS

^FN113^FD__CATEGORY_SEQUENCE4^FS
^FN114^FD__CATEGORY_NAME4^FS
^FN115^FD__CATEGORY_QTY4^FS

^FN116^FD__CATEGORY_SEQUENCE5^FS
^FN117^FD__CATEGORY_NAME5^FS
^FN118^FD__CATEGORY_QTY5^FS

^FN119^FD__CATEGORY_SEQUENCE6^FS
^FN120^FD__CATEGORY_NAME6^FS
^FN121^FD__CATEGORY_QTY6^FS

^FN122^FD__CATEGORY_SEQUENCE7^FS
^FN123^FD__CATEGORY_NAME7^FS
^FN124^FD__CATEGORY_QTY7^FS

^FN901^FD__TOTAL_QUANTITY^FS
^FN902^FD__PAGE_NUMBER_OVER_TOTAL_PAGE^FS

^PQ1
^XZ
'''.trim();
}
String buildTemplateZpl100x150ByCategoryDf({
  String printerFile = 'TEMPLATE.ZPL',
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