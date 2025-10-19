
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';

import '../../../providers/products_scan_notifier_for_line.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/product_provider_common.dart';
import '../products_home_provider.dart';
class ScanProductBarcodeButtonForLine extends ConsumerStatefulWidget {
  final ProductsScanNotifierForLine notifier;
  int actionTypeInt;
  final int pageIndex;



  String scannedData = "";
  ScanProductBarcodeButtonForLine(this.notifier, {required this.pageIndex, required this.actionTypeInt, super.key});
  void handleResult(WidgetRef ref, String data) {
    if (data.isNotEmpty) {
       notifier.handleInputString(ref.context, ref, data);
     /* switch(actionTypeInt){


        case Memory.ACTION_FIND_BY_UPC_SKU:
          notifier.addBarcodeByUPCOrSKUForSearch(data);
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
  ConsumerState<ScanProductBarcodeButtonForLine> createState() => ScanProductBarcodeButtonForLineState();

}


class ScanProductBarcodeButtonForLineState extends ConsumerState<ScanProductBarcodeButtonForLine> {
  final FocusNode focusNode = FocusNode();
  void unFocus() {
    focusNode.unfocus();
  }
  void requestFocus() {
    focusNode.requestFocus();
  }
  int scannedTimes = 0;
  @override
  initState() {
    super.initState();
    focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    focusNode.requestFocus();
  }
  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) async {


    if (event.logicalKey == LogicalKeyboardKey.enter) {
      widget.handleResult(ref, widget.scannedData);
      //widget.scannedData ="";
      return;
    }

    if (event.character != null && event.character!.isNotEmpty) {
      widget.scannedData += event.character!;
    }
  }

  late var isScanning;
  late var usePhoneCamera;
  TextEditingController textEditingController = TextEditingController();
  late var currentPageIndex;
  bool show = false;
  @override
  Widget build(BuildContext context) {
      /*scanTextField = TextField(
      autofocus: true,
      controller: textEditingController,
    );*/
    isScanning = ref.watch(isScanningForLineProvider.notifier);

    usePhoneCamera = ref.watch(usePhoneCameraToScanForLineProvider.notifier);
    currentPageIndex = ref.watch(productsHomeCurrentIndexProvider.notifier);
    if(currentPageIndex.state==widget.pageIndex){
      show = true ;
    } else {
      show = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        /*if (isScanning.state || currentPageIndex.state!=widget.pageIndex) {
          widget.focusNode.unfocus();
        } else {
          print('---------index ${ref.read(productsHomeCurrentIndexProvider.notifier).state}');
          print('---------index ${widget.pageIndex}');
          print('---------isScanning ${isScanning.state}');
          widget.focusNode.requestFocus();
        }*/
        if(show){
          usePhoneCamera.state ?focusNode.unfocus() :  focusNode.requestFocus();
        }

      }

    });
    if(!show) return Center(child: Text(Messages.NOT_CURRENT_PAGE),);
    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: isScanning.state ? null :(event) => _handleKeyEvent(event),
      child: GestureDetector(
        onTap: (){
          if(show){
            focusNode.requestFocus();
          }


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

                  focusNode.hasFocus
                      ? widget.scannedData != '' ? widget.scannedData : Messages.PRESS_TO_SCAN
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
