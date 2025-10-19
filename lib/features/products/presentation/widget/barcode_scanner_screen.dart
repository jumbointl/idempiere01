import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../providers/locator_provider.dart'; // Or ai_barcode_scanner

class BarcodeScannerScreen extends ConsumerWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue result = ref.watch(findLocatorToForBarcodeScreenProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      bottomNavigationBar: BottomAppBar(
        height: Memory.BOTTOM_BAR_HEIGHT + 40,
        color: Colors.cyan[800],
        child: Column(
          spacing: 10,
          children: [
            result.when(data: (data) {
              if(data.id==Memory.INITIAL_STATE_ID){
                return Column(
                  children: [
                    Icon(Icons.lock_clock,color: Colors.white,),
                    Text(
                      Messages.WAITING_TO_FIND,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                );

              } else {
              bool success = data.id >0 ?? false;
              return Column(
                children: [
                  Icon(success ? Icons.check_circle : Icons.error,color: success ? Colors.green : Colors.red,),
                  Text(
                  data.value ??'EMPTY',
                  style: const TextStyle(color: Colors.white),),
                ],
              );
              }}, error:(error,stackTrace) => Text(stackTrace.toString(),style:
            const TextStyle(color: Colors.white),),
                loading: ()=>LinearProgressIndicator(minHeight: 36,)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Background color
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the scanner
                  },
                  child: Text(
                    Messages.CANCEL,
                    style: TextStyle(color: Colors.white), // Font color
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Background color
                  ),
                  onPressed: () {
                    // Logic to retry scanning, could involve resetting state or re-initializing scanner
                    // For now, let's just reset the scanned barcode and the locator provider
                    ref.invalidate(scannedBarcodeProvider);
                    ref.invalidate(findLocatorToForBarcodeScreenProvider);
                  },
                  child: Text(
                    Messages.RETRY,
                    style: TextStyle(color: Colors.white), // Font color
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Background color
                  ),
                  onPressed: () {
                    // Accept the current scan (if any) or navigate
                    // This button's action might depend on whether a barcode has been scanned
                    // For now, let's assume it might pop or use the scanned value
                    if (ref.read(scannedBarcodeProvider.notifier).state != null) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(Messages.ACCEPT, style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          final barcode = capture.barcodes.first.rawValue;
          if (barcode != null) {

            ref.read(scannedBarcodeProvider.notifier).state = barcode;
            // Optionally, navigate back or perform other actions
            //Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}