

import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_movement.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_search_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_update_upc_provider.dart';
import '../../../../config/router/app_router.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../common/input_data_processor.dart';
import '../../domain/idempiere/idempiere_product.dart';
import '../../domain/sql/sql_data_movement_line.dart';
import '../screens/movement/provider/new_movement_provider.dart';
import '../screens/store_on_hand/memory_products.dart';
import 'locator_provider.dart';
import 'locator_provider_for_Line.dart';
import 'movement_provider_old.dart';
import 'movement_provider_for_line.dart';
import 'store_on_hand_provider.dart';

class ProductsScanNotifierForLine  extends StateNotifier<List<IdempiereProduct>> implements InputDataProcessor{
  static const int SQL_QUERY_CREATE =1;
  static const int SQL_QUERY_UPDATE =2;
  static const int SQL_QUERY_DELETE =3;
  static const int SQL_QUERY_SELECT =4;

  ProductsScanNotifierForLine(this.ref) : super([]);
  final Ref ref;
  // override addBarcode method when the scannedCodeProvider changes
  void _addBarcodeByUPCOrSKUForStoreOnHande(String scannedData) {
    ref.watch(searchByMOLIConfigurableSKUProvider.notifier).state = false;
    Memory.lastSearch = scannedData;
    _addBarcode(scannedData);

  }

  void _addBarcode(String scannedData) {
    if(scannedData.length==12){
      scannedData='0$scannedData';
    }
    ref.read(resultOfSameWarehouseProvider.notifier).state = [];
    print('------------------scannedCodeForStoredOnHandProvider');
    ref.read(scannedCodeForStoredOnHandProvider.notifier).update((state) => scannedData);
    ref.read(scannedCodeTimesProvider.notifier).update((state) => state+1);
    ref.read(isScanningProvider.notifier).update((state) => true);

  }

  void addBarcodeByUPCOrSKUForSearch(String data) {
    print('-----------------------------------search addBarcodeByUPCOrSKUForSearch');
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
    ref.read(scannedLocatorFromForLineProvider.notifier).update((state) => data);
  }


  void dialogDispose() {
    ref.read(isDialogShowedProvider.notifier).update((state) =>false);
  }
  void createMovement(SqlDataMovement sqlData){
    ref.read(newSqlDataMovementProvider.notifier).update((state) => sqlData);
  }
  void createMovementLine(SqlDataMovementLine sqlData){
    ref.read(newSqlDataMovementLineProvider.notifier).update((state) => sqlData);
  }

  void createPutAwayMovement(WidgetRef ref){
    ref.read(startedCreateNewPutAwayMovementProvider.notifier).update((state) => true);
    ref.read(newSqlDataPutAwayMovementProvider.notifier).update((state) => MemoryProducts.newSqlDataMovementToCreate);


  }
  void addBarcodeToSearchMovement(String result) {
    print('----------------------------------start searchMovementByIdOrDocumentNo $result');
    //ref.read(isScanningProvider.notifier).update((state) => true);
    ref.read(scannedMovementIdForSearchProvider.notifier).update((state) => result);
  }
  void addBarcodeToSearchMovementNew(String result) {
    print('----------------------------------start New SearchMovementByIdOrDocumentNo $result');
    //ref.read(isScanningProvider.notifier).update((state) => true);
    ref.read(newScannedMovementIdForSearchProvider.notifier).update((state) => result);
  }
  void confirmMovement(int? id) {
    ref.read(movementIdForConfirmProvider.notifier).update((state) => id ?? -1);
  }

  Future<void> handleInputString(BuildContext context,WidgetRef ref, String inputData) async {

    int action  = ref.read(actionScanProvider);
    print('handleInputString $action');
    switch(action){
      case Memory.ACTION_FIND_MOVEMENT_BY_ID:
        addBarcodeToSearchMovementNew(inputData);
        break;

      case Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND:
        _addBarcodeByUPCOrSKUForStoreOnHande(inputData);
        break;

      case Memory.ACTION_GET_LOCATOR_TO_VALUE:
        findLocatorToByValue(ref,inputData);
        break;
      case Memory.ACTION_GO_TO_MOVEMENT_EDIT_PAGE_WITH_ID:
        if(context.mounted) ref.context.go('${AppRouter.PAGE_MOVEMENTS_SEARCH}/$inputData');

        break;
      case Memory.ACTION_GO_TO_STORAGE_ON_HAND_PAGE_WITH_UPC:

        MemoryProducts.movementAndLines.nextProductIdUPC = inputData;
        MovementAndLines movementAndLines = MovementAndLines();
        movementAndLines.cloneMovementAndLines(MemoryProducts.movementAndLines);
        await GetStorage().write(Memory.KEY_MOVEMENT_AND_LINES, movementAndLines);

        int? movementId = movementAndLines.id ?? -1;
        if(movementId <= 0){
          if(context.mounted) showErrorMessage(context, ref, Messages.ERROR_MOVEMENT_NOT_FOUND);
          return;
        }
        ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND);

        if(context.mounted) {
          ref.context.go(
              '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/$inputData}',
              extra: movementAndLines);
        }
        break;



    }
    ref.read(inputStringProvider.notifier).update((state) => inputData);



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

  @override
  void addQuantityText(BuildContext context, WidgetRef ref,
      TextEditingController quantityController, int i) {
    // TODO: implement addQuantityText
  }


}


