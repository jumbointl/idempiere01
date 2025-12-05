
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';

import '../../../providers/locator_provider_for_Line.dart';
import '../../../providers/movement_provider_for_line.dart';
import '../../../providers/product_search_provider.dart';
import '../../../providers/products_scan_notifier_for_line.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/product_provider_common.dart';
class ScanProductBarcodeButtonForLineOld extends ConsumerStatefulWidget {
  final ProductsScanNotifierForLine notifier;
  int actionTypeInt;
  final int pageIndex;
  final FocusNode focusNode = FocusNode();

  String scannedData = "";
  ScanProductBarcodeButtonForLineOld(this.notifier, {required this.pageIndex, required this.actionTypeInt, super.key});
  void handleResult(WidgetRef ref, String data) {

    if (data.isNotEmpty) {
      notifier.handleInputString(ref.context, ref, data);
      /*switch(actionTypeInt){


        *//*case Memory.ACTION_FIND_BY_UPC_SKU:
          notifier.addBarcodeByUPCOrSKUForSearch(data);
          break;*//*
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
        case Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND:
          notifier.addBarcodeByUPCOrSKUForStoreOnHande(data);
          break;
        case Memory.ACTION_GO_TO_STORAGE_ON_HAND_PAGE_WITH_UPC:
          if(MemoryProducts.movementAndLines!=null && MemoryProducts.movementAndLines!.id!= null){
            if(!MemoryProducts.movementAndLines!.canComplete){
              AwesomeDialog(
                context: ref.context,
                animType: AnimType.scale,
                dialogType: DialogType.error,
                body: Center(child: Text(
                  Messages.MOVEMENT_ALREADY_COMPLETED,
                  //style: TextStyle(fontStyle: FontStyle.italic),
                ),), // correct here
                title: Messages.MOVEMENT_ALREADY_COMPLETED,
                desc:   '',
                autoHide: const Duration(seconds: 3),
                btnOkOnPress: () {},
                btnOkColor: themeColorSuccessful,
                btnCancelColor: themeColorError,
                btnCancelText: Messages.CANCEL,
                btnOkText: Messages.OK,
              ).show();
              return;
            }

          }
          GoRouter.of(ref.context).push('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/$data');
          break;
        default:
          notifier.addBarcodeByUPCOrSKUForSearch(data);
          break;

      }*/

      scannedData = "";
    }
  }
  @override
  ConsumerState<ScanProductBarcodeButtonForLineOld> createState() => ScanProductBarcodeButtonForLineOldState();

  void unFocus() {
    focusNode.unfocus();
  }
  void requestFocus() {
    focusNode.requestFocus();
  }
}


class ScanProductBarcodeButtonForLineOldState extends ConsumerState<ScanProductBarcodeButtonForLineOld> {


  int scannedTimes = 0;
  @override
  initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    widget.focusNode.requestFocus();
  }
  @override
  void dispose() {
    widget.focusNode.dispose();
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

  late var isScanning;
  late var scannerResult;
  late var usePhoneCamera;
  //late var currentPageIndex;
  //bool show = false;
  @override
  Widget build(BuildContext context) {
    isScanning = ref.watch(isScanningForLineProvider.notifier);
    switch(widget.actionTypeInt){
      case Memory.ACTION_FIND_BY_UPC_SKU:
        scannerResult = ref.watch(scannedCodeForSearchByUPCOrSKUProvider.notifier);
        break;

      case Memory.ACTION_GET_LOCATOR_TO_VALUE:
        scannerResult = ref.watch(scannedLocatorToForLineProvider.notifier);
        break;
      case Memory.ACTION_GET_LOCATOR_FROM_VALUE:
        scannerResult = ref.watch(scannedLocatorFromForLineProvider.notifier);
        break;
      case Memory.ACTION_FIND_MOVEMENT_BY_ID:
        scannerResult = ref.watch(scannedMovementIdForSearchProvider.notifier);
        break;
      default:
        scannerResult = ref.watch(scannedCodeForSearchByUPCOrSKUProvider.notifier);
        break;
    }
    usePhoneCamera = ref.watch(usePhoneCameraToScanForLineProvider.notifier);
    /*
    currentPageIndex = ref.watch(productsHomeCurrentIndexProvider.notifier);
    if(currentPageIndex.state==widget.pageIndex){
      show = true ;
    } else {
      show = false;
    }*/
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bool show = false;
      if (mounted) {
        /*if (isScanning.state || currentPageIndex.state!=widget.pageIndex) {
          widget.focusNode.unfocus();
        } else {
          print('---------index ${ref.read(productsHomeCurrentIndexProvider.notifier).state}');
          print('---------index ${widget.pageIndex}');
          print('---------isScanning ${isScanning.state}');
          widget.focusNode.requestFocus();
        }*/
        usePhoneCamera.state ? widget.focusNode.unfocus() :  widget.focusNode.requestFocus();
      }

    });
    return KeyboardListener(
      focusNode: widget.focusNode,
      onKeyEvent: isScanning.state ? null :(event) => _handleKeyEvent(event),
      child: GestureDetector(
        onTap: (){
           widget.focusNode.requestFocus();

        },

        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isScanning.state ?  Colors.grey : themeColorPrimary ,
            //color: themeColorPrimary,
            //borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.barcode_reader, color: Colors.white),
              SizedBox(width: 10),
              Flexible(
                child: Text( // Use ref.watch here to react to state changes

                  widget.focusNode.hasFocus
                      ? scannerResult.state != '' ? scannerResult.state : Messages.PRESS_TO_SCAN
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
