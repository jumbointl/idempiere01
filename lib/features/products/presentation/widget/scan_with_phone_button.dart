import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../shared/data/messages.dart';
import '../providers/product_screen_provider.dart';
class ScanWithPhoneButton extends ConsumerStatefulWidget {
  const ScanWithPhoneButton({super.key});

  @override
  ConsumerState<ScanWithPhoneButton> createState() => _ScanProductBarcodeButtonState();
}


class _ScanProductBarcodeButtonState extends ConsumerState<ScanWithPhoneButton> {
  final FocusNode _focusNode = FocusNode();
  String scannedData = "";
  int scannedTimes = 0;

  @override
  void initState() {
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

    print('event.character ${event.character}');
    print('event.logicalKey ${event.logicalKey.keyLabel}');
    print('event.keyName ${event.logicalKey.keyId}');

    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey.keyId== 8589935383) {

      addBarcode();
      return;
    }

  }

  void addBarcode() async {
    print('------------------------------addBarcode');
    ref.watch(isScanningProvider.notifier).state = true;
    String? result = await SimpleBarcodeScanner.scanBarcode(
      context,
      barcodeAppBar: BarcodeAppBar(
        appBarTitle: Messages.SCANNING,
        centerTitle: false,
        enableBackButton: true,
        backButtonIcon: Icon(Icons.arrow_back_ios),
      ),
      isShowFlashIcon: true,
      delayMillis: 300,
      cameraFace: CameraFace.back,
    );
    if(result!=null){
      if(result.length==12){
        result='0$result';
      }
      ref.read(scannedCodeProvider.notifier).state = result;
    }
    ref.watch(scannedCodeTimesProvider.notifier).update((state) => state+1);
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
    });
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: ref.watch(isScanningProvider) ? null : _handleKeyEvent,
      child: GestureDetector(
        onTap: () async {
          await Future.delayed(const Duration(seconds: 1));
          addBarcode();
          if (mounted) _focusNode.requestFocus();
        },
        child: Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: !ref.watch(isScanningProvider) ? Colors.cyan[200] : Colors.grey,
            borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.white),
              SizedBox(width: 10),
              Flexible(
                child: Text( // Use ref.watch here to react to state changes
                  ref.watch(isScanningProvider) ? Messages.SCANNING
                  : Messages.OPEN_CAMERA
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
