
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../screens/movement/products_home_provider.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/product_provider_common.dart';
class ScanMovementProductButtonWithProcessor extends ConsumerStatefulWidget {

  int actionTypeInt;
  final int pageIndex;

  ScanMovementProductButtonWithProcessor({
    required this.pageIndex,
    required this.actionTypeInt,super.key});

  @override
  ConsumerState<ScanMovementProductButtonWithProcessor> createState() => ScanMovementProductButtonWithProcessorState();
}


class ScanMovementProductButtonWithProcessorState extends ConsumerState<ScanMovementProductButtonWithProcessor> {
  final FocusNode _focusNode = FocusNode();
  late var notifier;
  int scannedTimes = 0;
  String scannedData = "";
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

      if(context.mounted){
        handleInputString(context, ref, scannedData);
      }
      scannedData ="";
      return;
    }

    if (event.character != null && event.character!.isNotEmpty) {
      scannedData += event.character!;
    }

  }
  late var isScanning;

  @override
  Widget build(BuildContext context) {
    notifier = ref.watch(scanStateNotifierForLineProvider.notifier);
    /*bool show = false;
    if(ref.read(productsHomeCurrentIndexProvider.notifier).state==widget.pageIndex){
      show = true ;
    }*/
    final pageIndex = ref.watch(productsHomeCurrentIndexProvider.notifier);
    final isDialogShowed = ref.watch(isDialogShowedProvider.notifier);
    isScanning = ref.watch(isScanningProvider.notifier);
    final usePhoneCamera = ref.watch(usePhoneCameraToScanForLineProvider.notifier);
    bool scannerActivate = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (mounted) {
        if (scannerActivate) {
          _focusNode.requestFocus();
        } else {
          _focusNode.unfocus();
        }
      }

    });
    /*if(isScanning.state){
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: LinearProgressIndicator(minHeight: 25,),
      );
    }*/
    if(pageIndex.state!=widget.pageIndex){
      return Center(child: Text(Messages.NOT_CURRENT_PAGE),) ;
    }
    if(isDialogShowed.state){
      return Center(child: Text(Messages.DIALOG_SHOWED),) ;
    }
    if(usePhoneCamera.state){
      return buttonScanWithPhone(context,ref);
    }

    scannerActivate = true;
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: ref.watch(isScanningProvider) ? null : _handleKeyEvent,
      child: GestureDetector(
        onTap: (){


        },

        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _focusNode.hasFocus ? themeColorPrimary : Colors.grey,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.barcode_reader, color: Colors.white),
              SizedBox(width: 10),
              Flexible(
                child: Text( // Use ref.watch here to react to state changes

                   _focusNode.hasFocus
                      ? Messages.PRESS_TO_SCAN
                      : Messages.READY_TO_SCAN
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
  void handleInputString(BuildContext context,WidgetRef ref, String data) {

    if (data.isNotEmpty) {
      notifier.handleInputString(context, ref, data);
      scannedData = "";
    }
  }
  Widget buttonScanWithPhone(BuildContext context,WidgetRef ref) {

    return TextButton(

      style: TextButton.styleFrom(
        backgroundColor: isScanning.state ? Colors.grey : themeColorPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),

      ),
      onPressed: isScanning.state ? null :  () async {
        ref.watch(isScanningProvider.notifier).state = true;
        String? result= await SimpleBarcodeScanner.scanBarcode(
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
          isScanning.state = false;
          if(context.mounted){
            handleInputString(context, ref, result);
          }
        } else {
          isScanning.state = false;
        }
      },
      child: Text(Messages.OPEN_CAMERA,style: TextStyle(fontSize: themeFontSizeLarge,
          color: Colors.white),),

    );
  }
}
