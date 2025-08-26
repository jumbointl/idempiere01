
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier.dart';
import 'package:monalisa_app_001/src/pages/common/scanner.dart';

import '../../../features/products/presentation/providers/product_provider_common.dart';
class ScanButton extends ConsumerStatefulWidget {
  static const int SCAN_TO_SEARCH = 1;
  static const int SCAN_TO_STORE_ON_HAND = 2;
  static const int SCAN_TO_UPDATE_UPC = 3;
  static const int SCAN_TO_LOCATOR_TO = 4;
  static const int SCAN_TO_HEARDER_VIEW = 5;
  String scannedData = "";
  final Scanner scanner;
  int scanAction;
  final ProductsScanNotifier notifier;


  ScanButton({required this.notifier, required this.scanAction, required this.scanner,super.key});

  @override
  ConsumerState<ScanButton> createState() => ScanBarcodeButtonState();

  void sendScannedData(int actionTypeInt, String data) {
    if (data.isNotEmpty) {
      switch(actionTypeInt){
        case SCAN_TO_UPDATE_UPC:
          notifier.addNewUPCCode(data);
          break;
        /*case Memory.ACTION_CALL_UPDATE_PRODUCT_UPC_PAGE:
          notifier.addBarcodeByUPCOrSKUForSearch(data);
          break;*/
        case SCAN_TO_SEARCH:
          notifier.addBarcodeByUPCOrSKUForSearch(data);
          break;
        case SCAN_TO_STORE_ON_HAND:
          notifier.addBarcodeByUPCOrSKUForStoreOnHande(data);
          break;
        /*default:
          notifier.addBarcodeByUPCOrSKUForSearch(data);
          break;*/
    }

    scannedData = "";

    }

  }
}


class ScanBarcodeButtonState extends ConsumerState<ScanButton> {
  final FocusNode _focusNode = FocusNode();
  int scannedTimes = 0;
  @override
  initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _focusNode.requestFocus();
  }
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) async {

    print('--w--event.character ${event.character}');
    print('--w--event.logicalKey ${event.logicalKey.keyLabel}');
    print('--w--event.keyName ${event.logicalKey.keyId}');
    print('--w--scannedData ${widget.scannedData}');

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      //widget.scanner.inputFromScanner(widget.scannedData);
      widget.sendScannedData(ref.read(actionScanProvider.notifier).state, widget.scannedData);
      widget.scannedData ="";
      return;
    }

    if (event.character != null && event.character!.isNotEmpty) {
      widget.scannedData += event.character!;
    }

  }


  @override
  Widget build(BuildContext context) {
    final isScanning = ref.watch(isScanningProvider.notifier);
    final actionScan = ref.watch(actionScanProvider.notifier);


    WidgetsBinding.instance.addPostFrameCallback((_) {


      print('focusnode ${_focusNode.hasFocus}');
      if (mounted) {

        if (ref.read(isScanningProvider.notifier).state) {
          _focusNode.unfocus();
        } else {
          _focusNode.requestFocus();
          if (!_focusNode.hasFocus) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _focusNode.requestFocus();
              print('focusnode ${_focusNode.hasFocus}');

            });
          }
        }
      }
    });
    return KeyboardListener(
      focusNode:_focusNode,
      onKeyEvent: ref.read(isScanningProvider) ? null : _handleKeyEvent,
      child: IconButton(onPressed:() async {widget.scanner.scanButtonPressed(context, ref);},
          icon: Icon( Icons.barcode_reader, color: isScanning.state ? Colors.grey: Colors.purple,)),
    );
  }
}
