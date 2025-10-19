

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_movement.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_search_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_update_upc_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_product.dart';
import '../../domain/sql/sql_data_movement_line.dart';
import '../screens/store_on_hand/memory_products.dart';
import 'locator_provider.dart';
import 'movement_provider_old.dart';
import 'movement_provider_for_line.dart';
import 'store_on_hand_provider.dart';

class ProductsScanNotifier2  extends StateNotifier<List<IdempiereProduct>>{
  static const int SQL_QUERY_CREATE =1;
  static const int SQL_QUERY_UPDATE =2;
  static const int SQL_QUERY_DELETE =3;
  static const int SQL_QUERY_SELECT =4;

  ProductsScanNotifier2(this.ref) : super([]);
  final Ref ref;
  // override addBarcode method when the scannedCodeProvider changes
  void addBarcodeByUPCOrSKUForStoreOnHande(String scannedData) {
    ref.watch(searchByMOLIConfigurableSKUProvider.notifier).state = false;
    Memory.lastSearch = scannedData;
    _addBarcode(scannedData);

  }
  void addBarcodeByMOLISKU(String scannedData) {
    ref.watch(searchByMOLIConfigurableSKUProvider.notifier).state = true;

    _addBarcode(scannedData);

  }
  void _addBarcode(String scannedData) {
    if(scannedData.length==12){
      scannedData='0$scannedData';
    }
    ref.watch(resultOfSameWarehouseProvider.notifier).state = [];
    ref.watch(scannedCodeForStoredOnHandProvider.notifier).update((state) => scannedData);
    ref.watch(scannedCodeTimesProvider.notifier).update((state) => state+1);
    ref.watch(isScanningProvider.notifier).update((state) => true);

  }
  bool getIsScanning(){
      return ref.read(isScanningProvider);
  }

  void updateIsScanning(bool bool) {

    ref.watch(isScanningProvider.notifier).update((state) => bool);
  }

  void addNewUPCCode(String scannedData){
    ref.watch(newUPCToUpdateProvider.notifier).update((state) => scannedData);
    ref.watch(scannedCodeTimesProvider.notifier).update((state) => state+1);
    ref.watch(isScanningProvider.notifier).update((state) => false);
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
    ref.watch(isScanningProvider.notifier).update((state) => true);
    ref.watch(dataToUpdateUPCProvider.notifier).state = [];
    Memory.lastSearch = data;
    ref.watch(scannedCodeForSearchByUPCOrSKUProvider.notifier).update((state) => data);
    ref.watch(scannedCodeTimesProvider.notifier).update((state) => state+1);

  }

  void findLocatorToByValue(WidgetRef ref, String data) {
    ref.watch(isScanningFromDialogProvider.notifier).update((state) => true);
    ref.watch(isScanningLocatorToProvider.notifier).update((state) => true);
    ref.watch(scannedLocatorToProvider.notifier).update((state) => data);

  }
  void findLocatorFromByValue(WidgetRef ref, String data) {
    ref.watch(isScanningFromDialogProvider.notifier).update((state) => true);
    ref.watch(scannedLocatorFromProvider.notifier).update((state) => data);
  }


  void dialogDispose() {
    ref.watch(isDialogShowedProvider.notifier).update((state) =>false);
  }
  void createMovement(SqlDataMovement sqlData){
    ref.watch(newSqlDataMovementProvider.notifier).update((state) => sqlData);
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
    //ref.watch(isScanningProvider.notifier).update((state) => true);
    ref.read(scannedMovementIdForSearchProvider.notifier).update((state) => result);
  }

  void confirmMovement(int? id) {
    ref.read(movementIdForConfirmProvider.notifier).update((state) => id ?? -1);
  }


}


