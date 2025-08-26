
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/scan_barcode_multipurpose_button.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/movement_card2.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_locator.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/idempiere/idempiere_warehouse.dart';
import '../../../domain/sql/sql_data_movement.dart';
import '../../../domain/sql/sql_data_movement_line.dart';
import '../../providers/locator_provider.dart';
import '../../providers/movement_provider.dart';
import '../../widget/no_data_card.dart';
import 'memory_products.dart';
class MovementCreateScreen extends ConsumerStatefulWidget {

  final IdempiereStorageOnHande storage;
  //final int index;
  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  double width;

  ProductsScanNotifier notifier;

  MovementCreateScreen({required this.storage, required this.notifier, required this.width, super.key});


  @override
  ConsumerState<MovementCreateScreen> createState() =>MovementCreateScreenState();
}

class MovementCreateScreenState extends ConsumerState<MovementCreateScreen> {
  late List<IdempiereStorageOnHande> unsortedStorageList = [];
  late List<IdempiereStorageOnHande> storageList = [];
  late double widthLarge ;
  late double widthSmall ;
  late AsyncValue findLocatorTo ;
  late var locatorTo ;
  late var isScanningFromDialog;
  late var usePhoneCamera ;
  late var ning;
  late var quantityToMove;
  late double dialogHeight ;
  late double dialogWidth ;
  List<bool> isCardsSelected = [];
  late var scannedLocatorTo;
  double fontSizeMedium = 16;
  double fontSizeLarge = 22;
  late Widget buttonScan;
  late AsyncValue createMovement;
  late var startedCreateNewPutAwayMovement;

  @override
  Widget build(BuildContext context) {
    createMovement = ref.watch(createNewMovementProvider);
    startedCreateNewPutAwayMovement = ref.watch(startedCreateNewPutAwayMovementProvider.notifier);

    findLocatorTo = ref.watch(findLocatorToProvider);
    widget.width = MediaQuery.of(context).size.width;
    quantityToMove = ref.watch(quantityToMoveProvider);
    usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => isScanningFromDialog.state = false);
    isScanningFromDialog = ref.watch(isScanningFromDialogProvider.notifier);
    locatorTo = ref.watch(selectedLocatorToProvider);
    scannedLocatorTo = ref.watch(scannedLocatorToProvider.notifier);
    widthLarge = widget.width/3*2;
    widthSmall = widget.width/3;
    unsortedStorageList = ref.read(unsortedStoreOnHandListProvider);
    dialogHeight = MediaQuery.of(context).size.height;
    dialogWidth = MediaQuery.of(context).size.width;
    buttonScan = _buttonScanWithPhone(context, ref);
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
        title: Text(Messages.MOVEMENT),


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
                if(!usePhoneCamera.state) ScanBarcodeMultipurposeButton(widget.notifier,),
                SizedBox(height: 20,),
                Text(Messages.CREATE),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey, // Choose your border color
                      width: 1.0,        // Choose your border width
                    ),
                    borderRadius: BorderRadius.circular(10.0), // Optional: if you want rounded corners
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    spacing: 5,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1, // Use widthSmall for this column's width
                        child: Column(
                          spacing: 5,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Messages.WAREHOUSE_FROM_SHORT,style: TextStyle(
                            fontSize: fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,),),
                            Text(Messages.WAREHOUSE_TO_SHORT,style: TextStyle(
                              fontSize: fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,),),
                            Text(Messages.FROM,style: TextStyle(
                              fontSize: fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,),),
                            Text(Messages.TO
                              ,style: TextStyle(
                              fontSize: fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,),),

                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2, // Use widthLarge for this column's width
                        child: Column(
                          spacing: 5,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text( warehouseStorage?.identifier ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                              fontSize: fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),),

                            findLocatorTo.when(data: (data){
                              IdempiereLocator? locatorTo = ref.read(selectedLocatorToProvider.notifier).state;
                              String warehouseName = Messages.DESTINATION;
                              if(locatorTo.mWarehouseID?.identifier !=null){
                                warehouseName = locatorTo.mWarehouseID?.identifier! ?? '';
                              }

                              return Text(warehouseName, overflow: TextOverflow.ellipsis,style: TextStyle(
                                fontSize: fontSizeMedium,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,),);
                            },
                                error:(Object error, StackTrace stackTrace) => Text('Error: $error')
                                , loading: ()=>LinearProgressIndicator(minHeight: 22,)),
                            Text(widget.storage.mLocatorID?.value ?? '--', overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: fontSizeMedium,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                                ),),
                            findLocatorTo.when(data: (data){
                                return Text(ref.read(selectedLocatorToProvider.notifier).state.value != null
                                    ? ref.read(selectedLocatorToProvider.notifier).state.value!
                                    : Messages.DESTINATION,style: TextStyle(
                                fontSize: fontSizeMedium,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,),);
                               },
                                error:(Object error, StackTrace stackTrace) => Text('Error: $error')
                                , loading: ()=>LinearProgressIndicator(minHeight: 22,)),

          
                          ],
                        ),
                      ),
          
                    ],
                  ),
                ),



                if(usePhoneCamera.state) _buttonScanWithPhone(context, ref) ,
          
                startedCreateNewPutAwayMovement.state == null ? getLastMovement(context,ref) :  SizedBox(height:dialogHeight/2-20,
                  child:  createMovement.when(
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

  Future<void> getBarcode(BuildContext context, WidgetRef ref) async {
    ref.read(isScanningFromDialogProvider.notifier).update((state) => true);
    String? scanBarcode = await SimpleBarcodeScanner.scanBarcode(
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
    String locatorFrom = widget.storage.mLocatorID?.value ?? '';
    if(scanBarcode!=null && scanBarcode!= locatorFrom){
      widget.notifier.setLocatorToValue(scanBarcode);
    }else {
      String message =  '${Messages.ERROR_LOCATOR} $locatorFrom = $scanBarcode';

      if(!context.mounted){
        Future.delayed(const Duration(seconds: 1));
        if(!context.mounted){
          return;
        } else {
          showErrorMessage(context, ref, message);
        }
      } else {
        showErrorMessage(context, ref, message);
      }

      return;
    }

  }
  Widget _buttonScanWithPhone(BuildContext context,WidgetRef ref) {
    var isScanningFromDialog = ref.watch(isScanningFromDialogProvider.notifier);
    return SizedBox(
      width: widget.width-30,
      child: TextButton(

        style: TextButton.styleFrom(
          backgroundColor: isScanningFromDialog.state ? Colors.grey : Colors.cyan[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),

        ),
        onPressed: isScanningFromDialog.state ? null :  () async {
          isScanningFromDialog.state = true;
          usePhoneCamera.state = true;

          String? scanBarcode = await SimpleBarcodeScanner.scanBarcode(
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
          if(scanBarcode!=null){
            widget.notifier.setLocatorToValue(scanBarcode);
          }

        },
        child: Text(Messages.OPEN_CAMERA),
      ),
    );
  }

  Widget getMovementCard(BuildContext context, WidgetRef ref, data) {

    if(data==null){
      return NoDataCard();
    } else {
      final movement = MemoryProducts.newSqlDataMovementToCreate;
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

  Widget getLastMovement(BuildContext context, WidgetRef ref) {

    final movement = MemoryProducts.newSqlDataMovementToCreate;
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