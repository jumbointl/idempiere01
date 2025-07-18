
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';

import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../providers/product_provider_common.dart';
import '../providers/products_scan_notifier.dart';
class ScanProductBarcodeButton extends ConsumerStatefulWidget {
  final ProductsScanNotifier notifier;
  int actionTypeInt;

  String scannedData = "";
  ScanProductBarcodeButton(this.notifier,{required this.actionTypeInt,super.key});
  void handleResult(WidgetRef ref, String data) {
    print('----------------------------SCANNED $actionTypeInt');
    if (data.isNotEmpty) {
      switch(actionTypeInt){
        case Memory.ACTION_UPDATE_UPC:
          notifier.addNewUPCCode(data);
          break;
        case Memory.ACTION_CALL_UPDATE_PRODUCT_UPC_PAGE:
          notifier.addBarcodeByUPCOrSKUForSearch(data);
          break;
        case Memory.ACTION_FIND_BY_UPC_SKU:
          notifier.addBarcodeByUPCOrSKUForSearch(data);
          break;
        case Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND:
          notifier.addBarcodeByUPCOrSKUForStoreOnHande(data);
          break;
        default:
          notifier.addBarcodeByUPCOrSKUForSearch(data);
          break;
      }

      scannedData = "";
    }
  }
  @override
  ConsumerState<ScanProductBarcodeButton> createState() => _ScanProductBarcodeButtonState();
}


class _ScanProductBarcodeButtonState extends ConsumerState<ScanProductBarcodeButton> {
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

   /* print('event.character ${event.character}');
    print('event.logicalKey ${event.logicalKey.keyLabel}');
    print('event.keyName ${event.logicalKey.keyId}');
    print('scannedData ${widget.scannedData}');*/
    print('event.logicalKey ${event.logicalKey.keyLabel}');

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      widget.handleResult(ref, widget.scannedData);
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
        if (ref.watch(isScanningProvider)) {
          _focusNode.unfocus();
        } else {
          _focusNode.requestFocus();
        }
      }

      _focusNode.requestFocus();
    });
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: ref.watch(isScanningProvider) ? null : _handleKeyEvent,
      child: GestureDetector(
        onTap: (){},
        /*onTap: () async {
          await Future.delayed(const Duration(seconds: 1));
          addBarcode();
          if (mounted) _focusNode.requestFocus();
        },*/
        child: Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _focusNode.hasFocus ? themeColorPrimary : Colors.grey,
            //borderRadius: BorderRadius.circular(themeBorderRadius),
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
                      : Messages.PRESS_TO_SCAN
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
