import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../providers/product_screen_provider.dart';

class BarcodeScannerScreen extends ConsumerWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MobileScannerController controller = MobileScannerController(
      cameraResolution: const Size(600, 400),

      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 250,
      returnImage: false,
      torchEnabled: true,
      invertImage: false,
      autoZoom: true,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode Scanner')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () async {

              ref.read(barcodeDataProvider.notifier).state  = await SimpleBarcodeScanner.scanBarcode(
                context,
                barcodeAppBar: const BarcodeAppBar(
                  appBarTitle: 'Test',
                  centerTitle: false,
                  enableBackButton: true,
                  backButtonIcon: Icon(Icons.arrow_back_ios),
                ),
                isShowFlashIcon: true,
                delayMillis: 2000,
                cameraFace: CameraFace.back,
              );

            },
            child: const Text('Open Scanner'),
          ),
          /*Container(
            alignment: Alignment.center,
            margin: EdgeInsets.symmetric(horizontal: 10),
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.4,
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                Barcode barcode = barcodes.first;
                debugPrint('Barcode found! ${barcode.rawValue}');
                ref.read(barcodeDataProvider.notifier).state =
                    barcode.rawValue;
              },
            ),
          ),*/
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Scanned Barcode: ${ref.watch(barcodeDataProvider) ?? 'None'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }}