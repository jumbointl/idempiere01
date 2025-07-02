import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../providers/product_screen_provider.dart';
class CameraScannerWindow extends ConsumerStatefulWidget {

  const CameraScannerWindow({super.key});


  @override
  ConsumerState<CameraScannerWindow> createState() => CameraScannerWindowState();
}

class CameraScannerWindowState extends ConsumerState<CameraScannerWindow> {

  @override
  Widget build(BuildContext context) {
    final MobileScannerController controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 250,
      returnImage: false,
      torchEnabled: true,
      invertImage: false,
      autoZoom: true,
    );
    int count = ref.watch(scannedCodeTimesProvider.notifier).state;
    return SizedBox(
      height: MediaQuery.of(context).size.width*0.6,
      width: MediaQuery.of(context).size.width*0.9,
      child: SingleChildScrollView(
        child: Column(

          children: [
            MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                Barcode barcode = barcodes.first;
                debugPrint('Barcode found! ${barcode.rawValue}');
                ref.read(barcodeDataProvider.notifier).state = barcode.rawValue;
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Scanned Barcode: ${ref.watch(barcodeDataProvider) ?? 'None'}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}