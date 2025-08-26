
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';

import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/products_scan_notifier.dart';
class ScanBarcodeMultipurposeButton extends ConsumerStatefulWidget {
  final ProductsScanNotifier notifier;

  String scannedData = "";
  ScanBarcodeMultipurposeButton(this.notifier,{super.key});
  void handleResult(WidgetRef ref, String data,int actionTypeInt) {
    if (data.isNotEmpty) {
      switch (actionTypeInt) {
        case Memory.ACTION_GET_LOCATOR_TO_VALUE:
          Memory.awesomeDialog?.dismiss();
          notifier.setLocatorToValue(data);
          break;
        case Memory.ACTION_GET_LOCATOR_FROM_VALUE:
          Memory.awesomeDialog?.dismiss();
          notifier.setLocatorFromValue(data);
          break;
      }
      scannedData = "";
    }
  }
  @override
  ConsumerState<ScanBarcodeMultipurposeButton> createState() => _ScanBarcodeMultipurposeButtonState();
}


class _ScanBarcodeMultipurposeButtonState extends ConsumerState<ScanBarcodeMultipurposeButton> {
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

    print('--x--event.character ${event.character}');
    print('--x--event.logicalKey ${event.logicalKey.keyLabel}');
    print('--x--event.keyName ${event.logicalKey.keyId}');
    print('--x--scannedData ${widget.scannedData}');

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      widget.handleResult(ref, widget.scannedData,ref.read(actionScanProvider.notifier).state);
      widget.scannedData ="";
      return;
    }

    if (event.character != null && event.character!.isNotEmpty) {
      widget.scannedData += event.character!;
    }

  }


  @override
  Widget build(BuildContext context) {


    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (mounted) {

        if (ref.read(isScanningProvider.notifier).state) {
          _focusNode.unfocus();
        } else {
          _focusNode.requestFocus();

        }
      }
    });
    return KeyboardListener(
      focusNode:_focusNode,
      onKeyEvent: ref.read(isScanningProvider) ? null : _handleKeyEvent,
      child: GestureDetector(
        onTap: (){},
        child: Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _focusNode.hasFocus ? themeColorPrimary : Colors.grey,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.barcode_reader, color: Colors.white),
              SizedBox(width: 10),
              Flexible(
                child: Text( // Use ref.watch here to react to state changes
                  ref.watch(isScanningProvider) ? Messages.SCANNING :
                  _focusNode.hasFocus
                      ? widget.scannedData.isNotEmpty
                          ? widget.scannedData
                          : Messages.READY_TO_SCAN
                      : Messages.SCAN
                  ,
                  style: TextStyle(
                      color: Colors.white, fontSize: themeFontSizeLarge),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
