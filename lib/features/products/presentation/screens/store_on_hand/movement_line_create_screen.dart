
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/movement_card2.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/idempiere/idempiere_warehouse.dart';
import '../../../domain/sql/sql_data_movement.dart';
import '../../../domain/sql/sql_data_movement_line.dart';
import '../../providers/locator_provider.dart';
import '../../providers/movement_provider.dart';
import '../../widget/no_data_card.dart';
import 'memory_products.dart';
class MovementLineCreateScreen extends ConsumerStatefulWidget {

  final IdempiereStorageOnHande storage;
  //final int index;
  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  double width;

  ProductsScanNotifier notifier;

  MovementLineCreateScreen({required this.storage, required this.notifier, required this.width, super.key});


  @override
  ConsumerState<MovementLineCreateScreen> createState() =>MovementLineCreateScreenState();
}

class MovementLineCreateScreenState extends ConsumerState<MovementLineCreateScreen> {
  late List<IdempiereStorageOnHande> unsortedStorageList = [];
  late List<IdempiereStorageOnHande> storageList = [];
  late double widthLarge ;
  late double widthSmall ;
  late var locatorTo ;
  late var isScanningFromDialog;
  late var usePhoneCamera ;
  late var ning;
  late var quantityToMove;
  late double dialogHeight ;
  late double dialogWidth ;
  List<bool> isCardsSelected = [];
  double fontSizeMedium = 16;
  late AsyncValue createMovementLine;
  late var movement ;

  @override
  Widget build(BuildContext context) {
    movement = ref.read(resultOfSqlQueryMovementProvider.notifier);
    createMovementLine = ref.watch(createNewMovementLineProvider);

    widget.width = MediaQuery.of(context).size.width;
    quantityToMove = ref.watch(quantityToMoveProvider);
    usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => isScanningFromDialog.state = false);
    isScanningFromDialog = ref.watch(isScanningFromDialogProvider.notifier);
    locatorTo = ref.watch(selectedLocatorToProvider);
    widthLarge = widget.width/3*2;
    widthSmall = widget.width/3;
    unsortedStorageList = ref.read(unsortedStoreOnHandListProvider);
    dialogHeight = MediaQuery.of(context).size.height;
    dialogWidth = MediaQuery.of(context).size.width;
    IdempiereWarehouse? warehouseStorage = widget.storage.mLocatorID?.mWarehouseID;
    storageList = unsortedStorageList
        .where((element) =>
            element.mLocatorID?.mWarehouseID?.id ==
            widget.storage.mLocatorID?.mWarehouseID?.id &&
            element.mProductID?.id == widget.storage.mProductID?.id &&
            element.mLocatorID?.id == widget.storage.mLocatorID?.id )
        .toList();


    if (isCardsSelected.isEmpty && storageList.isNotEmpty) {
      isCardsSelected = List<bool>.filled(storageList.length, false);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('${Messages.MOVEMENT} 5'),


      ),

      body: PopScope(
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;

          }
          ref.read(isDialogShowedProvider.notifier).update((state) => false);
          ref.read(isScanningFromDialogProvider.notifier).update((state) => false);
          ref.read(scannedLocatorToProvider.notifier).update((state) => '');
          ref.read(quantityToMoveProvider.notifier).update((state) => 0);
          Navigator.pop(context);
        },
        child: SingleChildScrollView(
          child: Container(
             height: dialogHeight,
            width: dialogWidth,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing:  5 ,
              children: [
                SizedBox(height: 20,),
                getMovementCard(context, ref, movement),

                SizedBox(height:dialogHeight/2-20,
                  child:  createMovementLine.when(
                    data: (data){
                      return getMovementCard(context, ref, data);
                    }
                  ,error: (error, stackTrace) => Text('Error: $error'),
                  loading: () => LinearProgressIndicator(),
                ),),
                SizedBox(height: 20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.amber,
                        ),
                        child: Text(Messages.FIND, style: TextStyle(color: Colors.white),),
                        onPressed: () async {
                          ref.read(isDialogShowedProvider.notifier).update((state) => false);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 8), // Add some spacing between buttons
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text(Messages.CREATE, style: TextStyle(color: Colors.white),),
                        onPressed: () {
                          if (locatorTo.value != null && locatorTo.value!.isNotEmpty) {
                            // Perform the movement logic here
                            // For example, call a function from your notifier:
                            SqlDataMovement sqlData = SqlDataMovement();
                            Memory.sqlUsersData.copyToSqlData(sqlData);
                            IdempiereWarehouse? warehouseTo = widget.storage.mLocatorID?.mWarehouseID;
                            if(warehouseTo != null && warehouseTo.id != null){
                              sqlData.setIdempiereWarehouseTo(warehouseTo.id!);
                            }
                            // creado para borrar
                            MemoryProducts.newSqlDataMovementToCreate = sqlData ;
                            SqlDataMovementLine movementLine = SqlDataMovementLine();
                            Memory.sqlUsersData.copyToSqlData(movementLine);
                            movementLine.mMovementID = sqlData;
                            movementLine.mLocatorID = widget.storage.mLocatorID;
                            movementLine.mProductID = widget.storage.mProductID;
                            movementLine.mLocatorToID = ref.read(selectedLocatorToProvider);
                            movementLine.movementQty = ref.read(quantityToMoveProvider);
                            movementLine.mAttributeSetInstanceID = widget.storage.mAttributeSetInstanceID;
                            MemoryProducts.newSqlDataMovementLinesToCreate.add(movementLine);
                            widget.notifier.createMovement(sqlData);

                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showErrorMessage(BuildContext context, WidgetRef ref, String message) {
    if (!context.mounted) {
      Future.delayed(const Duration(seconds: 1));
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
      autoHide: const Duration(seconds: 3),
      btnOkOnPress: () {},
      btnOkColor: Colors.amber,
      btnCancelText: Messages.CANCEL,
      btnOkText: Messages.OK,
    ).show();
    return;
  }

  Widget getMovementCard(BuildContext context, WidgetRef ref, data) {

    if(data==null){
      return NoDataCard();
    } else {
      return Container(

          decoration: BoxDecoration(
            color: Colors.black, // Change background color based on isSelected
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(8.0),
          child: MovementCard2(productsNotifier: widget.notifier, movement: movement,
            width: widget.width-30, isDarkMode: true,));
    }

  }


}