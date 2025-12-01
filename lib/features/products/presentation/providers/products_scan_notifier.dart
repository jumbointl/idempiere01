


import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/barcode_utils.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_search_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_update_upc_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/store_on_hand_for_put_away_movement.dart';
import '../../../../config/router/app_router.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../common/input_data_processor.dart';
import '../../domain/idempiere/idempiere_product.dart';
import '../../domain/idempiere/movement_and_lines.dart';
import '../screens/store_on_hand/memory_products.dart';
import 'locator_provider.dart';
import 'movement_provider.dart';
import 'movement_provider_for_line.dart';
import 'store_on_hand_provider.dart';

class ProductsScanNotifier  extends StateNotifier<List<IdempiereProduct>> implements InputDataProcessor{
  static const int SQL_QUERY_CREATE =1;
  static const int SQL_QUERY_UPDATE =2;
  static const int SQL_QUERY_DELETE =3;
  static const int SQL_QUERY_SELECT =4;

  ProductsScanNotifier(this.ref) : super([]);
  final Ref ref;
  // override addBarcode method when the scannedCodeProvider changes
  void addBarcodeByUPCOrSKUForStoreOnHande(String scannedData) {
    print('findProductByUPCOrSKUForStoreOnHandProvider $scannedData');
    ref.read(searchByMOLIConfigurableSKUProvider.notifier).state = false;
    Memory.lastSearch = scannedData;
    _addBarcode(scannedData);

  }
  void addBarcodeByMOLISKU(String scannedData) {
    ref.read(searchByMOLIConfigurableSKUProvider.notifier).state = true;

    _addBarcode(scannedData);

  }
  void _addBarcode(String scannedData) {
    if(scannedData.length==12){
      String aux = '0$scannedData';
      if(isValidEAN13(aux)){
        scannedData = aux;
      }
    }
    ref.read(scannedCodeForPutAwayMovementProvider.notifier).update((state) => scannedData);
    ref.read(scannedCodeTimesProvider.notifier).update((state) => state+1);
    ref.read(isScanningProvider.notifier).update((state) => true);

  }
  bool getIsScanning(){
      return ref.read(isScanningProvider);
  }

  void updateIsScanning(bool bool) {

    ref.read(isScanningProvider.notifier).update((state) => bool);
  }

  void addNewUPCCode(String scannedData){
    ref.read(newUPCToUpdateProvider.notifier).update((state) => scannedData);
    ref.read(scannedCodeTimesProvider.notifier).update((state) => state+1);
    ref.read(isScanningProvider.notifier).update((state) => false);
  }

  void updateProductUPC(BuildContext context) async {
    String id = ref.read(productForUpcUpdateProvider.notifier).state.id!.toString();
    String newUPC = ref.read(newUPCToUpdateProvider.notifier).state;

    if(id == '' || int.tryParse(id)==null || int.tryParse(id)! <= 0 || newUPC=='' ||
        int.tryParse(newUPC)==null || int.tryParse(newUPC)! <= 0)
    {
      await AwesomeDialog(
        context: context,
        animType: AnimType.scale,
        dialogType: DialogType.error,
        body: Center(child: Text(
          Messages.DATA_NOT_VALID,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),), // correct here
        title: 'ID: $id ,UPC: $newUPC' ,
        desc:   'ID: $id ,UPC: $newUPC' ,
        autoHide: const Duration(seconds: 5),
        btnOkOnPress: () {},
        btnOkColor: Colors.amber,
        btnCancelText: Messages.CANCEL,
        btnOkText: Messages.OK,
      ).show();
      return;
    }
    List<String> updateData =[id,newUPC];
      ref.read(dataToUpdateUPCProvider.notifier).update((state) => updateData);
  }

  void addBarcodeByUPCOrSKUForSearch(String data) {
    ref.read(isScanningProvider.notifier).update((state) => true);
    ref.read(dataToUpdateUPCProvider.notifier).state = [];
    Memory.lastSearch = data;
    ref.read(scannedCodeForSearchByUPCOrSKUProvider.notifier).update((state) => data);
    ref.read(scannedCodeTimesProvider.notifier).update((state) => state+1);

  }

  void findLocatorToByValue(WidgetRef ref, String data) {
    ref.read(isScanningFromDialogProvider.notifier).update((state) => true);
    ref.read(isScanningLocatorToProvider.notifier).update((state) => true);
    ref.read(scannedLocatorToProvider.notifier).update((state) => data);

  }
  void findLocatorFromByValue(WidgetRef ref, String data) {
    ref.read(isScanningFromDialogProvider.notifier).update((state) => true);
    ref.read(scannedLocatorFromProvider.notifier).update((state) => data);
  }


  void dialogDispose() {
    ref.read(isDialogShowedProvider.notifier).update((state) =>false);
  }

  void addBarcodeToSearchMovement(String result) {
    print('----------------------------------start searchMovementByIdOrDocumentNo $result');
    //ref.read(isScanningProvider.notifier).update((state) => true);
    ref.read(scannedMovementIdForSearchProvider.notifier).update((state) => result);
  }

  void confirmMovement(int? id) {
    ref.read(movementIdForConfirmProvider.notifier).update((state) => id ?? -1);
  }
  void showErrorMessage(BuildContext context, WidgetRef ref, String message) {
    if (!context.mounted) {
      Future.delayed(const Duration(milliseconds: 500));
      if(!context.mounted) return;
    }
    AwesomeDialog(
      context: context,
      animType: AnimType.scale,
      dialogType: DialogType.error,
      body: Center(child: Column(
        children: [
          Text(message,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),),
      title:  message,
      desc:   '',
      autoHide: const Duration(seconds: 5),
      btnOkOnPress: () {},
      btnOkColor: Colors.amber,
      btnCancelText: Messages.CANCEL,
      btnOkText: Messages.OK,
    ).show();
    return;
  }
  void createPutAwayMovement(WidgetRef ref,PutAwayMovement movement){
    ref.read(startedCreateNewPutAwayMovementProvider.notifier).update((state) => true);
    print('----------------------------------newSqlDataPutAwayMovementProvider.notifier');
    ref.read(putAwayMovementCreateProvider.notifier).update((state) => movement);
    /*ref.read(newSqlDataPutAwayMovementProvider.notifier).update((state) =>
    MemoryProducts.newSqlDataMovementToCreate);*/
  }
  void prepareToCreatePutawayMovement(WidgetRef ref,PutAwayMovement putAwayMovement){
    int check = putAwayMovement.canCreatePutAwayMovement();
    print('----------------------------------ERROR = $check');
    switch (check) {
      case PutAwayMovement.ERROR_START_CREATE:
        showErrorMessage(ref.context, ref, Messages.ERROR_START_CREATE);
        return;
      case PutAwayMovement.ERROR_LOCATOR_TO:
        showErrorMessage(ref.context, ref, Messages.ERROR_LOCATOR_TO);
        return;
      case PutAwayMovement.ERROR_LOCATOR_FROM:
        showErrorMessage(ref.context, ref, Messages.ERROR_LOCATOR_FROM);
        return;
      case PutAwayMovement.ERROR_SAME_LOCATOR:
        showErrorMessage(ref.context, ref, Messages.ERROR_SAME_LOCATOR);
        return;
      case PutAwayMovement.ERROR_QUANTITY:
        showErrorMessage(ref.context, ref, Messages.ERROR_QUANTITY);
        return;
      case PutAwayMovement.ERROR_WAREHOUSE_FROM:
        showErrorMessage(ref.context, ref, Messages.ERROR_WAREHOUSE_FROM);
        return;
      case PutAwayMovement.ERROR_WAREHOUSE_TO:
        showErrorMessage(ref.context, ref, Messages.ERROR_WAREHOUSE_TO);
        return;
      case PutAwayMovement.ERROR_PRODUCT:
        showErrorMessage(ref.context, ref, Messages.ERROR_PRODUCT);
        return;
      case PutAwayMovement.ERROR_MOVEMENT:
        showErrorMessage(ref.context, ref, Messages.ERROR_MOVEMENT);
        return;
      case PutAwayMovement.ERROR_MOVEMENT_LINE:
        showErrorMessage(ref.context, ref, Messages.ERROR_MOVEMENT_LINE);
        return;
      case PutAwayMovement.SUCCESS:
        break;
      default:
        showErrorMessage(ref.context, ref, Messages.ERROR);
        return;

    }

    GoRouter.of(ref.context).go(AppRouter.PAGE_CREATE_PUT_AWAY_MOVEMENT,
        extra: putAwayMovement);

  }

  @override
  Future<void> handleInputString(BuildContext context, WidgetRef ref, String data) async {
    int actionTypeInt = ref.read(actionScanProvider.notifier).state;

    if (data.isNotEmpty) {
      switch(actionTypeInt){
        case Memory.ACTION_UPDATE_UPC:
          addNewUPCCode(data);
          break;
        case Memory.ACTION_CALL_UPDATE_PRODUCT_UPC_PAGE:
          addBarcodeByUPCOrSKUForSearch(data);
          break;
        case Memory.ACTION_FIND_BY_UPC_SKU:
          addBarcodeByUPCOrSKUForSearch(data);
          break;
        case Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND:
          addBarcodeByUPCOrSKUForStoreOnHande(data);
          break;
        case Memory.ACTION_GET_LOCATOR_TO_VALUE:
          Memory.awesomeDialog?.dismiss();
          findLocatorToByValue(ref,data);
          break;
        case Memory.ACTION_GET_LOCATOR_FROM_VALUE:
          Memory.awesomeDialog?.dismiss();
          findLocatorFromByValue(ref,data);
          break;
        case Memory.ACTION_FIND_MOVEMENT_BY_ID:
          addBarcodeToSearchMovement(data);
          break;
        case Memory.ACTION_GO_TO_STORAGE_ON_HAND_PAGE_WITH_UPC:
          MemoryProducts.movementAndLines.nextProductIdUPC = data;
          MovementAndLines movementAndLines = MovementAndLines();
          movementAndLines.cloneMovementAndLines(MemoryProducts.movementAndLines);
          await GetStorage().write(Memory.KEY_MOVEMENT_AND_LINES, movementAndLines);
          int? movementId = movementAndLines.id ?? -1;
          if(movementId <= 0){
            if(context.mounted) showErrorMessage(context, ref, Messages.ERROR_MOVEMENT_NOT_FOUND);
            return;
          }
          movementAndLines.nextProductIdUPC = data;
          ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND);
          if(context.mounted) {
            ref.context.go(
                '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/$data',
                extra: movementAndLines);
          }
          break;
        default:
          addBarcodeByUPCOrSKUForSearch(data);
          break;

      }

      data = "";
    }
  }

  @override
  void addQuantityText(BuildContext context, WidgetRef ref, TextEditingController quantityController, int i) {
    // TODO: implement addQuantityText
  }


}


