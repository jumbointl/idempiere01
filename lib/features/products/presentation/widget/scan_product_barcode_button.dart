import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monalisa_app_001/config/config.dart';

import '../../../shared/data/messages.dart';
import '../providers/idempiere_products_notifier.dart';

class ScanProductBarcodeButton extends StatefulWidget {
  final IdempiereScanNotifier notifier;
  const ScanProductBarcodeButton(this.notifier,{super.key});

  @override
  ScanProductBarcodeButtonState createState() => ScanProductBarcodeButtonState();
}



class ScanProductBarcodeButtonState extends State<ScanProductBarcodeButton> {
  final FocusNode _focusNode = FocusNode();
  String scannedData = "";

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      addBarcode();
      return;
    }
    /*else if (event.logicalKey.keyId== 8589935383) {

      AwesomeDialog(
        context: context,
        animType: AnimType.scale,
        dialogType: DialogType.info,
        body: Center(child: Text(
          Messages.PLEASE_CONFIGURE_SCANNER_BUTTON,
        ),),
        title: Messages.INFORMATION,
        desc:   '',
        btnOkOnPress: () {},
      ).show();

      return;
    }*/

    if (event.character != null && event.character!.isNotEmpty) {
      setState(() {
        scannedData += event.character!;
      });
    }

  }

  void addBarcode() {
    if (scannedData.isNotEmpty) {
      widget.notifier.addBarcode(scannedData);
      setState(() {
        scannedData = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () {
          addBarcode();
          _focusNode.requestFocus();
        },
        child: Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _focusNode.hasFocus ? themeColorPrimary : Colors.grey,
            borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.barcode_reader, color: Colors.white),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  _focusNode.hasFocus
                      ? scannedData.isNotEmpty
                          ? scannedData
                          : Messages.READY_TO_SCAN
                      : Messages.PRESS_TO_SCAN,
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
