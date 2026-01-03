


import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/common/barcode_utils.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_search_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_update_upc_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/store_on_hand_for_put_away_movement.dart';
import '../../../shared/data/memory.dart';
import '../../domain/sql/sql_data_movement_line.dart';
import '../screens/movement/provider/new_movement_provider.dart';
import 'actions/find_locator_to_action_provider.dart';
import 'actions/find_movement_by_id_action_provider.dart';
import 'locator_provider.dart';
import 'movement_provider_for_line.dart';
import 'common/app_action_notifier.dart';
import 'common_provider.dart';
import 'store_on_hand_provider.dart';


class ProductsScanNotifier
    extends AppActionNotifier<void> {

  ProductsScanNotifier(super.ref, super.initialState,);


  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    final value = normalizeUPC(inputData);
    setScanning(true);
    increaseScanCounter();
    debugPrint('handleInputString inputData: $inputData');
    debugPrint('handleInputString value: $value');
    debugPrint('handleInputString actionScan: $actionScan');

    switch (actionScan) {

      case Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND:

        //addBarcodeByUPCOrSKUForStoreOnHande(value);
        break;

      case Memory.ACTION_GET_LOCATOR_TO_VALUE:
        findLocatorTo(value);
        break;

      case Memory.ACTION_GET_LOCATOR_FROM_VALUE:
        findLocatorFrom(value);
        break;

      case Memory.ACTION_FIND_MOVEMENT_BY_ID:
        ref.read(newScannedMovementIdForSearchProvider.notifier).state = value;
        ref.read(fireFindMovementByIdProvider.notifier).state++;
        break;

      case Memory.ACTION_UPDATE_UPC:
        ref.read(newUPCToUpdateProvider.notifier).state = value;
        break;
      default:
        ref.read(scannedCodeForSearchByUPCOrSKUProvider.notifier).state = value;
        ref.read(fireSearchByUPCOrSKUProvider.notifier).state++;
        break;
    }

    setScanning(false);
  }
  void findLocatorTo(String value) {
    ref.read(isScanningFromDialogProvider.notifier).state = true;
    ref.read(isScanningLocatorToProvider.notifier).state = true;
    ref.read(scannedLocatorToProvider.notifier).state = value;
    ref.read(fireFindLocatorProvider.notifier).update((state) => state + 1);
  }
  void createMovementLine(SqlDataMovementLine sqlData){
    ref.read(newSqlDataMovementLineProvider.notifier).update((state) => sqlData);
    ref.read(fireCreateMovementLineProvider.notifier).update((state) => state+1);
  }
  void createPutAwayMovement(WidgetRef ref,PutAwayMovement movement){
    int docType = ref.read(allowedMovementDocumentTypeProvider);
    if(docType==Memory.MM_ELECTRONIC_DELIVERY_NOTE_ID){
      movement.movementToCreate!.cDocTypeID = Memory.electronicDeliveryNote;
    }
    ref.read(putAwayMovementCreateProvider.notifier).update((state) => movement);
  }


  void addBarcodeToSearchMovementNew(String result) {
    ref.read(newScannedMovementIdForSearchProvider.notifier).update((state) => result);
    ref.read(fireFindMovementByIdProvider.notifier).update((state) => state+1);

  }

  /*void addBarcodeByUPCOrSKUForStoreOnHande(String scannedData) {
    ref.invalidate(productStoreOnHandCacheProvider);
    ref.read(searchByMOLIConfigurableSKUProvider.notifier).state = false;
    Memory.lastSearch = scannedData;
    _addBarcode(scannedData);

  }
*/
  void addBarcodeByMOLISKU(String scannedData) {
    ref.read(searchByMOLIConfigurableSKUProvider.notifier).state = true;
    //_addBarcode(scannedData);
  }
 /* void _addBarcode(String scannedData) {
    if(scannedData.length==12){
        String aux = '0$scannedData';
        if(isValidEAN13(aux)){
          scannedData = aux;
        }
    }
    ref.read(scannedCodeForPutAwayMovementProvider.notifier).update((state) => scannedData);
    ref.read(fireSearchStoreOnHandeForPAMProvider.notifier).update((state) => state+1);

    ref.read(scannedCodeTimesProvider.notifier).update((state) => state+1);
    ref.read(isScanningProvider.notifier).update((state) => true);

  }*/

  void addNewUPCCode(String scannedData){
    ref.read(newUPCToUpdateProvider.notifier).update((state) => scannedData);
    ref.read(scannedCodeTimesProvider.notifier).update((state) => state+1);
    ref.read(isScanningProvider.notifier).update((state) => false);
  }


}





