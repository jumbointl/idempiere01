// ===============================
// locator_label_printer_select_page.dart
// ===============================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/models/label_profile.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';

import '../../products/domain/idempiere/idempiere_locator.dart';
import '../models/printer_select_models.dart';
import '../niimbot/niimbot_printer_helper.dart';
import '../tspl/tspl_printer_helper.dart';
import 'label_printer_select_page.dart';



class LocatorLabelPrinterSelectPage extends LabelPrinterSelectPage {
  const LocatorLabelPrinterSelectPage({super.key, required super.dataToPrint});

  @override
  int get actionScanType => Memory.ACTION_FIND_PRINTER_BY_QR_WIFI_BLUETOOTH;

  @override
  String get pageTitle => 'Locator Label Printer';

  @override
  String? validateDataToPrint() {
    final data = dataToPrint;
    if (data is! IdempiereLocator) return 'dataToPrint must be IdempiereLocator.';
    if (data.value?.trim().isEmpty ?? false) return 'Locator value is empty.';
    return null;
  }
  @override
  Widget buildPrintingPanel({
    required BuildContext context,
    required WidgetRef ref,
    required PrinterConnConfig? selectedPrinter,
    required LabelProfile profile40,
    required LabelProfile profile60,
    required Future<void> Function({
    required LabelProfile profile,
    required bool printSimpleData,
    }) onPrint,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: selectedPrinter == null
                ? null
                : () => onPrint(profile: profile40, printSimpleData: true),
            child: const Text('Locator barcode'),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: selectedPrinter == null
                ? null
                : () => onPrint(profile: profile40, printSimpleData: false),
            child: const Text('Locator QR'),
          ),
        ),
      ],
    );
  }
  @override
  String buildTsplForData({
    required LabelProfile profile,
    required bool printSimpleData,
  }) {
    final loc = dataToPrint as IdempiereLocator;
    if (printSimpleData) {
      return buildTsplLocatorLabel(value: loc.value?.trim() ?? '', profile: profile);
    } else {
      return buildTsplLocatorQR(value: loc.value?.trim() ?? '', profile: profile);
    }

  }

  // ----------------------------------------------------------------------------
  // Locator label TSPL:
  // - prints locator value as text above
  // - prints Code128 barcode WITHOUT human readable text
  // ----------------------------------------------------------------------------
  String buildTsplLocatorLabel({
    required String value,
    required LabelProfile profile,
  }) {
    const int dotsPerMm = 8; // 203dpi

    final String v =
    value.trim().replaceAll('\n', ' ').replaceAll('\r', ' ');

    final double widthMm = profile.widthMm;
    final double heightMm = profile.heightMm;
    final double gapMm = profile.gapMm.toDouble();

    final int labelW = (widthMm * dotsPerMm).round();
    final int labelH = (heightMm * dotsPerMm).round();

    final int mx = (profile.marginXmm * dotsPerMm).round();
    final int my = (profile.marginYmm * dotsPerMm).round();
    final int xText = calculateCenteredTextX(text: v, profile: profile);

    final int yText = my + 10;
    final int fontId = profile.fontId > 0 ? profile.fontId : 2;

    final int barcodeHeight =
    profile.barcodeHeight > 0 ? profile.barcodeHeight : 90;

    final dims = calculateCode128NarrowWide(
      data: v,
      labelWidthDots: labelW,
      marginXDots: mx,
    );

    final int narrow = dims.narrow;
    final int wide = dims.wide;



    final int estW = estimateBarcodeWidthDots(v.length, narrow);

    int xBarcode = ((labelW - estW) / 2).round();
    xBarcode = xBarcode.clamp(mx, labelW - mx);

    final int yBarcode =
    (yText + 45).clamp(my + 20, labelH - barcodeHeight - my);

    final result = [
      'SIZE ${widthMm.toStringAsFixed(0)} mm,${heightMm.toStringAsFixed(0)} mm',
      'GAP ${gapMm.toStringAsFixed(0)} mm,0 mm',
      'DENSITY 8',
      'SPEED 4',
      'DIRECTION 1',
      'REFERENCE 0,0',
      'CLS',
      'TEXT $xText,$yText,"$fontId",0,1,1,"$v"',
      'BARCODE $xBarcode,$yBarcode,"128",$barcodeHeight,0,0,$narrow,$wide,"$v"',
      'PRINT 1,${profile.copies}',
      '',
    ].join('\n');

    debugPrint('Locator label TSPL:\n$result');
    return result;
  }

  String buildTsplLocatorQR({
    required String value,
    required LabelProfile profile,
  }) {
    const int dotsPerMm = 8; // 203dpi

    final String v = value.trim().replaceAll('\n', ' ').replaceAll('\r', ' ');

    // SIZE y GAP en mm
    final double widthMm = profile.widthMm;
    final double heightMm = profile.heightMm;
    final double gapMm = profile.gapMm.toDouble();

    // Layout en dots
    final int labelW = (widthMm * dotsPerMm).round();
    final int labelH = (heightMm * dotsPerMm).round();
    final int mx = (profile.marginXmm * dotsPerMm).round();
    final int my = (profile.marginYmm * dotsPerMm).round();
    final int xText = calculateCenteredTextX(text: v, profile: profile);

    final int fontId = profile.fontId > 0 ? profile.fontId : 2;

    // Texto arriba
    final int yText = my + 8;
    final int textBlockH = 48; // reserva aprox para el texto

    // Calcula cellwidth para que el QR quepa
    final int cell = calculateQrCellWidth(
      labelWidthDots: labelW,
      labelHeightDots: labelH,
      marginXDots: mx,
      marginYDots: my,
      topReservedDots: (yText + textBlockH),
    );

    // Posición QR
    final int yQr = (yText + textBlockH).clamp(my, labelH - my);

    // Centramos el QR en X (estimación de tamaño)
    // QR real depende de versión, pero para strings cortos suele ser 25~33 módulos + quiet zone.
    // Heurística: asumir ~ (33 + 8 quiet) * cell
    final int estQrDots = (41 * cell);
    int xQr = ((labelW - estQrDots) / 2).round();
    xQr = xQr.clamp(mx, labelW - mx);

    final result = [
      'SIZE ${widthMm.toStringAsFixed(0)} mm,${heightMm.toStringAsFixed(0)} mm',
      'GAP ${gapMm.toStringAsFixed(0)} mm,0 mm',
      'DENSITY 8',
      'SPEED 4',
      'DIRECTION 1',
      'REFERENCE 0,0',
      'CLS',
      'TEXT $xText,$yText,"$fontId",0,1,1,"$v"',
      // ✅ Formato TSPL más compatible:
      // QRCODE x,y,EC,cellwidth,A,rotation,"data"
      'QRCODE $xQr,$yQr,M,$cell,A,0,"$v"',
      'PRINT 1,${profile.copies}',
      '',
    ].join('\n');

    debugPrint('Locator label TSPL (QR):\n$result');
    return result;
  }

  /// Heurística para elegir cellwidth para que el QR quepa.
  /// Devuelve un valor típico 3..8 (clamp).

  Widget buildNiimbotLocatorWidget({required String locatorValue}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            locatorValue,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
  @override
  Future<bool> printDataToNiimbot({
    required BuildContext context,
    required PrinterConnConfig printer,
    required LabelProfile profile,
    required dynamic data,
  }) async {
    final mac = (printer.btAddress ?? '').trim();
    final helper = NiimbotPrinterHelper();
    final ok = await helper.printLabelFromWidget(
      context: context,
      mac: mac,
      widthMm: profile.widthMm,
      heightMm: profile.heightMm,
      widget: buildNiimbotLocatorWidget(locatorValue: data),
    );
    return ok ;

  }



}
