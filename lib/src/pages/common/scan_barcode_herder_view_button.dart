
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../features/products/presentation/providers/product_provider_common.dart';
import '../../../features/products/presentation/providers/products_scan_notifier.dart';
import '../../../features/products/presentation/screens/movement/old/movement_headers_view.dart';
import '../../../features/products/presentation/screens/movement/products_home_provider.dart';
import '../../../features/shared/data/messages.dart';
import '../../../features/shared/data/memory.dart';
class ScanBarcodeHerderViewButton extends ConsumerStatefulWidget {
  final ProductsScanNotifier notifier;
  final MovementHeadersView view ;
  late var pageHasFocus;
  late var usePhoneCamera;
  String scannedData = "";
  final int pageIndex ;
  ScanBarcodeHerderViewButton(this.notifier,{required this.view,super.key, required this.pageIndex});
  void handleResult(WidgetRef ref, String data,int actionTypeInt) {
    print('-----------------------$actionTypeInt');

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
        case Memory.ACTION_FIND_MOVEMENT_BY_ID:
          Memory.awesomeDialog?.dismiss();
          notifier.searchMovementById(data);
          break;
      }
      scannedData = "";
    }
  }
  @override
  ConsumerState<ScanBarcodeHerderViewButton> createState() => _ScanBarcodeHerderViewButtonState();
}


class _ScanBarcodeHerderViewButtonState extends ConsumerState<ScanBarcodeHerderViewButton> {
  final FocusNode _focusNode = FocusNode();
  int scannedTimes = 0;
  @override
  initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        //setState(() {});
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

    widget.usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    if(!widget.pageHasFocus.state){
      return Container();
    }

    if(widget.usePhoneCamera.state){
      FocusScope.of(context).unfocus();
      return Container(
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(
          color:  Colors.cyan[200],
        ),
        child: TextButton(
          onPressed: () async {
            //widget.view.usePhoneCameraToScan(context, ref);
            print('------------------------pressed');
              //bool isScanning = ref.watch(isScanningProvider);
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
                if (result != null) {
                  //widget.notifier.searchMovementById(result);
                  widget.scannedData = result;
                  widget.handleResult(ref, widget.scannedData,ref.read(actionScanProvider.notifier).state);
                }

          },
          child: Text(Messages.OPEN_CAMERA,
            style: TextStyle(
                color: Colors.purple, fontSize: themeFontSizeLarge,
                fontWeight: FontWeight.bold
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }


    WidgetsBinding.instance.addPostFrameCallback((_) {






      if (mounted) {


        if (ref.read(isScanningProvider.notifier).state) {
          _focusNode.unfocus();
        } else {

          if(widget.pageIndex!=ref.read(productsHomeCurrentIndexProvider)){
            _focusNode.unfocus();
          } else {
            _focusNode.requestFocus();
          }

        }
      }
    });
    return KeyboardListener(
      focusNode:_focusNode,
      onKeyEvent: ref.read(isScanningProvider) ? null : _handleKeyEvent,
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
    );
  }

}
