
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';

import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/products_update_notifier.dart';
class ScanBarcodeForUpdateUpcButton extends ConsumerStatefulWidget {
  final ProductsUpdateNotifier notifier;
  final int actionTypeInt;

  String scannedData = "";
  ScanBarcodeForUpdateUpcButton(this.notifier,{ required this.actionTypeInt,super.key});
  void handleResult(WidgetRef ref, String data) {
    if (data.isNotEmpty) {
      notifier.addNewUPCCode(data);
      scannedData = "";
    }
  }
  @override
  ConsumerState<ScanBarcodeForUpdateUpcButton> createState() => _ScanBarcodeForUpdateUpcButtonState();
}


class _ScanBarcodeForUpdateUpcButtonState extends ConsumerState<ScanBarcodeForUpdateUpcButton> {
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

        if (ref.read(isScanningProvider.notifier).state) {
          _focusNode.unfocus();
        } else {
          _focusNode.requestFocus();
          if (!_focusNode.hasFocus) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _focusNode.requestFocus();

            });
          }
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
