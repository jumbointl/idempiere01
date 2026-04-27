import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:monalisa_app_001/features/printer/zpl/new/provider/template_zpl_utils.dart';
import 'package:monalisa_app_001/features/products/common/widget/cancelable_progress_dialog.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../shared/data/messages.dart';
import 'package:monalisapy_features/zpl_template/models/zpl_template.dart';
import 'package:monalisapy_features/printer/zpl/new/models/zpl_template_store.dart';

const int kLabelDpmm203 = 8; // 203 dpi
const String kLabelSize100x150mm = '3.94x5.91';

final zplPreviewProvider = StateProvider<String?>((ref) => null);
String buildRenderZpl({
  required String df,
  required String referenceFilled,
}) {
  // English comment: "Remove format-store command from DF"
  final dfClean = df.replaceAll(
    RegExp(r'^\s*\^DF[^\n]*\n?', caseSensitive: false, multiLine: true),
    '',
  );

  // English comment: "Remove recall command from reference (^XFE/^XF...)"
  final refClean = referenceFilled.replaceAll(
    RegExp(r'^\s*\^XF[^\n]*\n?|^\s*\^XFE[^\n]*\n?', caseSensitive: false, multiLine: true),
    '',
  );

  // English comment: "Ensure we have a single ^XA...^XZ wrapper"
  String stripXA(String s) => s
      .replaceAll(RegExp(r'^\s*\^XA\s*', caseSensitive: false), '')
      .replaceAll(RegExp(r'\^XZ\s*$', caseSensitive: false), '')
      .trim();

  final body = stripXA(dfClean);
  final values = stripXA(refClean);

  return '^XA\n$body\n$values\n^XZ\n';
}

Future<Uint8List> zplToPngLabelary({
  required String zpl,
  int dpmm = 8, // 8 dpmm = 203 dpi
  String sizeInInches = '4x6', // ajusta a tu etiqueta real
}) async {
  final uri = Uri.parse('https://api.labelary.com/v1/printers/${dpmm}dpmm/labels/$sizeInInches/0/');

  final resp = await http.post(
    uri,
    headers: {
      'Accept': 'image/png',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: zpl,
  );

  if (resp.statusCode != 200) {
    throw Exception('Labelary error ${resp.statusCode}: ${resp.body}');
  }
  return resp.bodyBytes;
}


Future<void> shareLabelPdfFromPng({
  required Uint8List pngBytes,
  String filename = 'label_preview.pdf',
}) async {
  final doc = pw.Document();

  final img = pw.MemoryImage(pngBytes);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Center(
        child: pw.Image(img, fit: pw.BoxFit.contain),
      ),
    ),
  );

  final bytes = await doc.save();
  await Printing.sharePdf(bytes: bytes, filename: filename);
}
Future<void> showPdfViewOrShareDialog({
  required BuildContext context,
  required Uint8List pdfBytes,
  required String filename,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('PDF Preview'),
      content: const Text('¿Qué quieres hacer con el PDF?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.visibility),
          label: const Text('VIEW'),
          onPressed: () async {
            Navigator.of(ctx).pop();

            // English comment: "Open print preview (and allow printing)"
            await Printing.layoutPdf(
              name: filename,
              onLayout: (_) async => pdfBytes,
            );
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.share),
          label: const Text('SHARE'),
          onPressed: () async {
            Navigator.of(ctx).pop();

            // English comment: "Share PDF file"
            await Printing.sharePdf(
              bytes: pdfBytes,
              filename: filename,
            );
          },
        ),
      ],
    ),
  );
}
Future<Uint8List> buildLabelPdfBytesFromPng(Uint8List pngBytes) async {
  final doc = pw.Document();
  final img = pw.MemoryImage(pngBytes);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Center(
        child: pw.Image(img, fit: pw.BoxFit.contain),
      ),
    ),
  );

  return doc.save();
}

Future<void> generateAndShareVisualPreviewPdf({
  required BuildContext context,
  required ZplTemplate template,
  required String referenceFilled, // PUEDE contener varias páginas
  required ZplTemplateStore store,
  int dpmm = 8,
  String sizeInInches = '3.94x5.91', // 100x150mm
}) async {
  try {
    // 1) Resolve DF if empty
    var t = template;
    if (t.zplTemplateDf.trim().isEmpty) {
      t = resolveDfFromLocalDownloadedTemplates(result: t, store: store);
    }

    if (t.zplTemplateDf.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Messages.DF_EMPTY_CANNOT_RENDER_PREVIEW)),
      );
      return;
    }

    // 2) Build full render ZPL (DF + Reference)
    final renderZpl = buildRenderZpl(
      df: t.zplTemplateDf,
      referenceFilled: referenceFilled,
    );

    // 3) Split into ZPL pages
    final renderPages = buildRenderZplPages(
      df: t.zplTemplateDf,
      referenceFilled: referenceFilled,
    );
    if (renderPages.isEmpty) {
      throw Exception('No ZPL pages built');
    }

    // 4) Generate PNGs);
    final progress = await showCancelableProgressDialog(
      context: context,
      total: renderPages.length,
    );

    final pngPages = <Uint8List>[];

    try {
      for (int i = 0; i < renderPages.length; i++) {
        // English comment: "Abort loop if user cancelled"
        if (progress.isCancelled()) {
          break;// 👈 sale sin error
        }
        progress.update(i + 1);
        final png = await zplToPngLabelary(
          zpl: renderPages[i],
          dpmm: dpmm,
          sizeInInches: sizeInInches,
        );
        await Future.delayed(const Duration(milliseconds: 500));
        pngPages.add(png);
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    } finally {
      progress.close();
    }

    // 5) Build multipage PDF
    final pdfBytes = await buildMultiPagePdfFromPngs(pngPages);
    await Future.delayed(const Duration(milliseconds: 500));
    // 6) Ask user: VIEW or SHARE
    if(context.mounted) {
      await showPdfViewOrShareDialog(
      context: context,
      pdfBytes: pdfBytes,
      filename: 'label_preview_${t.id}.pdf',
    );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${Messages.FAIL_TO_GENERATE_PDF} $e')),
    );
  }
}
List<String> buildRenderZplPages({
  required String df,
  required String referenceFilled,
}) {
  // English comment: "Remove separators and split reference into real ZPL pages"

  // English comment: "Clean DF: remove ^DF (store format) and strip ^XA/^XZ"
  final dfNoStore = df.replaceAll(
    RegExp(r'^\s*\^DF[^\n]*\n?', caseSensitive: false, multiLine: true),
    '',
  );

  String stripWrapper(String s) => s
      .replaceAll(RegExp(r'^\s*\^XA\s*', caseSensitive: false), '')
      .replaceAll(RegExp(r'\^XZ\s*$', caseSensitive: false), '')
      .trim();

  final dfBody = stripWrapper(dfNoStore);

  // English comment: "Split reference into pages (each has ^XA...^XZ)"
  final refPages = splitZplIntoPages(referenceFilled);
  final effectiveRefPages = refPages.isEmpty ? <String>[referenceFilled] : refPages;

  final outPages = <String>[];

  for (final refPage in effectiveRefPages) {
    // English comment: "Remove recall commands (^XF/^XFE) from reference page"
    final refNoRecall = refPage.replaceAll(
      RegExp(r'^\s*\^XF[^\n]*\n?|^\s*\^XFE[^\n]*\n?',
          caseSensitive: false, multiLine: true),
      '',
    );

    final refBody = stripWrapper(refNoRecall);

    // English comment: "Each page must include DF layout + FN values"
    outPages.add('^XA\n$dfBody\n$refBody\n^XZ\n');
  }

  return outPages;
}





List<String> splitZplIntoPages(String zpl) {
  final pages = <String>[];

  final regex = RegExp(
    r'\^XA[\s\S]*?\^XZ',
    caseSensitive: false,
  );

  for (final m in regex.allMatches(zpl)) {
    pages.add(m.group(0)!.trim());
  }

  return pages;
}
Future<List<Uint8List>> zplPagesToPngs({
  required List<String> zplPages,
  int dpmm = 8,
  String sizeInInches = '3.94x5.91', // 100x150mm
}) async {
  final images = <Uint8List>[];

  for (int i = 0; i < zplPages.length; i++) {
    final png = await zplToPngLabelary(
      zpl: zplPages[i],
      dpmm: dpmm,
      sizeInInches: sizeInInches,
    );
    images.add(png);
  }

  return images;
}
Future<Uint8List> buildMultiPagePdfFromPngs(
    List<Uint8List> pngPages,
    ) async {
  final doc = pw.Document();

  for (final png in pngPages) {
    final img = pw.MemoryImage(png);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Center(
          child: pw.Image(img, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }

  return doc.save();
}
final filledReferenceAllStringProvider = StateProvider<String>((ref) {
  return '';
});