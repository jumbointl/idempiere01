
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';

import '../../shared/data/memory.dart';
import 'input_data_processor.dart';
import '../presentation/providers/common_provider.dart';
import '../presentation/providers/scan_provider.dart';
import '../../shared/data/messages.dart';
import '../presentation/providers/product_provider_common.dart';
class ScanButton extends ConsumerStatefulWidget {

  int actionTypeInt;
  final int pageIndex;
  final InputDataProcessor processor;

  ScanButton({
    required this.processor,
    required this.pageIndex,
    required this.actionTypeInt,super.key});

  @override
  ConsumerState<ScanButton> createState() => ScanButtonState();
}


class ScanButtonState extends ConsumerState<ScanButton> {
  TextStyle style = const TextStyle(fontSize: themeFontSizeLarge,
      fontWeight: FontWeight.bold,
      color: Colors.white);
  final FocusNode _focusNode = FocusNode();
  late var notifier;
  late var inputString;
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
        widget.processor.handleInputString(context, ref, scannedData);

      }

      setState(() {

      });
      scannedData ="";
      return;
    }

    if (event.character != null && event.character!.isNotEmpty) {
      scannedData += event.character!;
    }

  }
  late var isScanning;
  late var scanText;

  @override
  Widget build(BuildContext context) {
    notifier = ref.watch(scanStateNotifierForLineProvider.notifier);
    inputString = ref.watch(inputStringProvider.notifier);
    scanText = ref.watch(scanTextControllerProvider.notifier);

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

      return Center(child: Text(Messages.NOT_CURRENT_PAGE,style: style,),) ;
    }
    if(isDialogShowed.state){
      return Center(child: Text(Messages.DIALOG_SHOWED,style: style,),) ;
    }
    /*if(usePhoneCamera.state){
      return Center(child: Text(Messages.OPEN_CAMERA,style: style,),) ;
    }*/

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
                      ? Messages.PRESS_TO_SCAN+getTip()
                      : Messages.READY_TO_SCAN+getTip()
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

  void onSubmitted() {}

  String getTip() {
    int action = ref.read(actionScanProvider);
      switch(action){
        case Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND:
          return ' (UPC)';
        case Memory.ACTION_GET_LOCATOR_TO_VALUE:
          return ' (LOC)';
        case Memory.ACTION_FIND_MOVEMENT_BY_ID:
          return ' (MV)';
        case Memory.ACTION_GO_TO_STORAGE_ON_HAND_PAGE_WITH_UPC:
          return ' (GO UPC)';
        default:
          return '';


    }

  }
  /*void handleResult(WidgetRef ref, String data) {

    if (data.isNotEmpty) {
      switch(widget.actionTypeInt){
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
        case Memory.ACTION_GET_LOCATOR_TO_VALUE:
          Memory.awesomeDialog?.dismiss();
          notifier.findLocatorToByValue(ref,data);
          break;
        case Memory.ACTION_GET_LOCATOR_FROM_VALUE:
          Memory.awesomeDialog?.dismiss();
          notifier.findLocatorFromByValue(ref,data);
          break;
        case Memory.ACTION_FIND_MOVEMENT_BY_ID:
          notifier.addBarcodeToSearchMovement(data);
          break;
        case Memory.ACTION_GO_TO_STORAGE_ON_HAND_PAGE_WITH_UPC:
          GoRouter.of(ref.context).go('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/$data');
          break;
        default:
          notifier.addBarcodeByUPCOrSKUForSearch(data);
          break;

      }

      scannedData = "";
    }
  }*/

}
