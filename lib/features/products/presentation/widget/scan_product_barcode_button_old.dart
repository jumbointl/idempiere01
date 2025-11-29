
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';

import '../screens/movement/products_home_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../providers/product_provider_common.dart';
import '../providers/products_scan_notifier.dart';
import '../screens/store_on_hand/memory_products.dart';
class ScanProductBarcodeButtonOld extends ConsumerStatefulWidget {
  final ProductsScanNotifier notifier;
  int actionTypeInt;
  final int pageIndex;

  String scannedData = "";
  ScanProductBarcodeButtonOld(this.notifier, {required this.pageIndex, required this.actionTypeInt, super.key});
  void handleResult(WidgetRef ref, String data) {
    print('--------------------------------------------handleResult $data');
    print('--------------------------------------------handleResult $actionTypeInt');
    print('--------------------------------------------handleResult ${Memory.ACTION_GET_LOCATOR_TO_VALUE}');
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
          if(MemoryProducts.movementAndLines.id!= null){
            if(!MemoryProducts.movementAndLines.canComplete){
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

      }

      scannedData = "";
    }
  }
  @override
  ConsumerState<ScanProductBarcodeButtonOld> createState() => ScanProductBarcodeButtonOldState();
}


class ScanProductBarcodeButtonOldState extends ConsumerState<ScanProductBarcodeButtonOld> {
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
      bool show = false;
      if(ref.read(productsHomeCurrentIndexProvider.notifier).state==widget.pageIndex){
      show = true ;
      }
      if (mounted) {
        if (ref.watch(isScanningProvider) || !show) {
          _focusNode.unfocus();
        } else {
          _focusNode.requestFocus();
        }
      }
      _focusNode.requestFocus();

    });
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: ref.watch(isScanningProvider) ? null :(event) => _handleKeyEvent(event),
      child: GestureDetector(
        onTap: (){


        },

        child: Container(
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
}
