
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/scan_barcode_multipurpose_button.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/movement_card2.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/products_home_provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_locator.dart';
import '../../../domain/idempiere/idempiere_warehouse.dart';
import '../../../domain/sql/sql_data_movement.dart';
import '../../providers/locator_provider.dart';
import '../../providers/movement_provider.dart';
import '../../widget/no_data_card.dart';
import 'memory_products.dart';
class MovementCreateScreen2 extends ConsumerStatefulWidget {

  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  double width = double.infinity;

  ProductsScanNotifier notifier;
  final int pageIndex = Memory.PAGE_INDEX_MOVEMENTE_CREATE_SCREEN;



  MovementCreateScreen2({required this.notifier, required this.width, super.key});


  @override
  ConsumerState<MovementCreateScreen2> createState() =>MovementCreateScreenState2();
}

class MovementCreateScreenState2 extends ConsumerState<MovementCreateScreen2> {
  bool willPop = false;
  late double widthLarge ;
  late double widthSmall ;
  late AsyncValue findLocatorTo ;
  late AsyncValue findLocatorFrom ;
  late var isLocatorScreenShowed;
  late var scannedLocatorTo;
  late var scannedLocatorFrom;
  late var usePhoneCamera ;
  late var ning;
  late double dialogHeight ;
  late double dialogWidth ;
  List<bool> isCardsSelected = [];

  double fontSizeMedium = 16;
  double fontSizeLarge = 22;
  late var actionScan ;
  late Widget buttonScan;
  late AsyncValue createMovement;
  List<IdempiereWarehouse> warehouses = [];
  List<IdempiereLocator> userLocators = [];

  late var canCreate ;



  @override
  Widget build(BuildContext context) {
    createMovement = ref.watch(createNewMovementProvider);
    findLocatorTo = ref.watch(findLocatorToProvider);
    findLocatorFrom = ref.watch(findLocatorFromProvider);
    scannedLocatorTo = ref.watch(scannedLocatorToProvider.notifier);
    scannedLocatorFrom = ref.watch(scannedLocatorFromProvider.notifier);
    isLocatorScreenShowed = ref.watch(isLocatorScreenShowedProvider.notifier);
    actionScan = ref.watch(actionScanProvider.notifier);
    canCreate = ref.watch(canCreateMovementProvider.notifier);
    widget.width = MediaQuery.of(context).size.width;
    usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(isDialogShowedProvider.notifier).state = true;
      ref.read(isScanningFromDialogProvider.notifier).state = false;
    });



    Color buttonToBackgroundColor = themeColorPrimary;
    Color buttonFromBackgroundColor = themeColorPrimary;

    widthLarge = widget.width/3*2;
    widthSmall = widget.width/3;
    dialogHeight = MediaQuery.of(context).size.height;
    dialogWidth = MediaQuery.of(context).size.width;
    buttonScan = _buttonScanWithPhone(context, ref);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading:IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => {
            FocusScope.of(context).unfocus(),
            ref.read(isDialogShowedProvider.notifier).update((state) => false),
            ref.read(isScanningFromDialogProvider.notifier).update((state) => false),
            ref.read(scannedLocatorToProvider.notifier).update((state) => ''),
            ref.read(scannedLocatorFromProvider.notifier).update((state) => ''),
            ref.read(quantityToMoveProvider.notifier).update((state) => 0),
            ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => 0),
            ref.read(isMovementCreateScreenShowedProvider.notifier).update((state) => false),
            ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_HEARDER_VIEW,),
            Navigator.pop(context),
            },
        ),
        title: Text(Messages.MOVEMENT),
        actions: [
          IconButton(onPressed: (){
            if(usePhoneCamera.state){
               usePhoneCamera.state = false;
              setState(() {});
            } else {
               usePhoneCamera.state = true;
              setState(() {});
            }
          }, icon: Icon(usePhoneCamera.state?
          Icons.barcode_reader : Icons.qr_code_scanner , color: Colors.purple,)),
        ],


      ),
      bottomNavigationBar: PreferredSize(
        preferredSize: Size(double.infinity, 50), // Adjust height as needed
        child: getButtonScanWithPhone(context, ref),
      ),
      //bottomNavigationBar: getButtonScanWithPhone(context,ref),
      body: PopScope(
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;
          }
          ref.read(isDialogShowedProvider.notifier).update((state) => false);
          ref.read(isScanningFromDialogProvider.notifier).update((state) => false);
          ref.read(scannedLocatorToProvider.notifier).update((state) => '');
          ref.read(scannedLocatorFromProvider.notifier).update((state) => '');
          ref.read(quantityToMoveProvider.notifier).update((state) => 0);
          ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_HEARDER_VIEW,);
          ref.read(isMovementCreateScreenShowedProvider.notifier).update((state) => false);
          Navigator.pop(context);
        },
        child: SingleChildScrollView(
          child: Container(
             height: dialogHeight,
            width: dialogWidth,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing:  15 ,
              children: [

                SizedBox(height: 20,),
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
                        flex: 1,
                        child: IntrinsicWidth(
                          child: Column(
                            spacing: 5,
                            crossAxisAlignment: CrossAxisAlignment.stretch, // Make children take full width
                            children: [
                              Text(Messages.WAREHOUSE_FROM_SHORT,style: TextStyle(
                              fontSize: fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,),textAlign: TextAlign.start,),
                              Text(Messages.WAREHOUSE_TO_SHORT,style: TextStyle(
                                fontSize: fontSizeMedium,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,),textAlign: TextAlign.start,),
                              SizedBox(height: 20,),
                              Container(
                                margin: EdgeInsets.only(right: 20),
                                color: actionScan.state==Memory.ACTION_GET_LOCATOR_FROM_VALUE ? themeColorPrimary : Colors.grey,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: (){
                                     actionScan.update((state) => Memory.ACTION_GET_LOCATOR_FROM_VALUE);
                                      setState(() {

                                      });
                                    },

                                    child: Text('${Messages.FROM} ${Messages.LOCATOR}',style: TextStyle(
                                      fontSize: fontSizeMedium,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,),textAlign: TextAlign.start,),
                                ),
                              ),),
                              SizedBox(height: 20,),
                              Container(
                                margin: EdgeInsets.only(right: 20),
                                color: ref.read(actionScanProvider.notifier).state==Memory.ACTION_GET_LOCATOR_TO_VALUE ? themeColorPrimary : Colors.grey,
                                child: GestureDetector(
                                  onTap: (){
                                    actionScan.update((state) =>  Memory.ACTION_GET_LOCATOR_TO_VALUE);
                                    setState(() {

                                    });
                                  },

                                  child: Center(
                                    child: Text('${Messages.TO} ${Messages.LOCATOR}',style: TextStyle(
                                      fontSize: fontSizeMedium,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,),textAlign: TextAlign.start,),
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2, // Use widthLarge for this column's width
                        child: Column(
                          spacing: 5,
                          crossAxisAlignment: CrossAxisAlignment.stretch, // Make children take full width
                          children: [

                            findLocatorFrom.when(data: (data){
                              IdempiereLocator? dataFrom = ref.read(selectedLocatorFromProvider.notifier).state;
                              String warehouseName = Messages.DESTINATION;
                              if(dataFrom.mWarehouseID?.identifier !=null){
                                warehouseName = dataFrom.mWarehouseID?.identifier! ?? '';
                              }

                              return Text(warehouseName, overflow: TextOverflow.ellipsis,style: TextStyle(
                                fontSize: fontSizeMedium,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,),textAlign: TextAlign.start,);
                            },
                                error:(Object error, StackTrace stackTrace) => Text('Error: $error')
                                , loading: ()=>LinearProgressIndicator(minHeight: 22,)),

                            findLocatorTo.when(data: (data){
                              IdempiereLocator? dataTo = ref.read(selectedLocatorToProvider.notifier).state;
                              String warehouseName = Messages.DESTINATION;
                              if(dataTo.mWarehouseID?.identifier !=null){
                                warehouseName = dataTo.mWarehouseID?.identifier! ?? '';
                              }

                              return Text(warehouseName, overflow: TextOverflow.ellipsis,style: TextStyle(
                                fontSize: fontSizeMedium,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,),textAlign: TextAlign.start,);
                            },
                                error:(Object error, StackTrace stackTrace) => Text('Error: $error')
                                , loading: ()=>LinearProgressIndicator(minHeight: 22,)),
                            SizedBox(height: 20,),
                            findLocatorFrom.when(data: (data){
                              return GestureDetector(
                                onTap: () async {
                                  ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_NO_REQUERED_SCAN_SCREEN);
                                  isLocatorScreenShowed.update((state) => true);
                                  Memory.pageFromIndex = 5;
                                  context.push(AppRouter.PAGE_SEARCH_LOCATOR_FROM);


                                },

                                child: Text(ref.read(selectedLocatorFromProvider.notifier).state.value != null
                                    ? ref.read(selectedLocatorFromProvider.notifier).state.value!
                                    : Messages.TOUCH_TO_FIND,style: TextStyle(
                                  fontSize: fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,),textAlign: TextAlign.start,),
                              );
                            },
                                error:(Object error, StackTrace stackTrace) => Text('Error: $error')
                                , loading: ()=>LinearProgressIndicator(minHeight: 22,)),
                            SizedBox(height: 20,),

                            findLocatorTo.when(data: (data){
                              return GestureDetector(
                                onTap: () async {
                                  ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_NO_REQUERED_SCAN_SCREEN);
                                  isLocatorScreenShowed.update((state) => true);
                                  Memory.pageFromIndex = 5;
                                  context.push(AppRouter.PAGE_SEARCH_LOCATOR_TO);

                                },
                                child: Text(ref.read(selectedLocatorToProvider.notifier).state.value != null
                                    ? ref.read(selectedLocatorToProvider.notifier).state.value!
                                    : Messages.TOUCH_TO_FIND,style: TextStyle(
                                  fontSize: fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,),textAlign: TextAlign.start,),
                              );
                            },
                                error:(Object error, StackTrace stackTrace) => Text('Error: $error')
                                , loading: ()=>LinearProgressIndicator(minHeight: 22,)),
                          ],
                        ),
                      ),
          
                    ],
                  ),
                ),


                SizedBox(height: 20,),
                if(canCreate.state) getCrateButton(context, ref),
                if(canCreate.state) createMovement.when(data: (data) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if(context.mounted && willPop && Navigator.canPop(context)){
                      Future.delayed(const Duration(milliseconds:3000), () {

                      });


                    }
                  });
                  return getMovementCard(context, ref, data);


                },
                error: (error, stackTrace) => Text(error.toString()),
                loading: () => LinearProgressIndicator(minHeight: 200,)),


              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget getButtonScanWithPhone(BuildContext context,WidgetRef ref) {

    final pageIndex = ref.watch(productsHomeCurrentIndexProvider);
    if (pageIndex == widget.pageIndex) {
      return SizedBox(width: MediaQuery.of(context).size.width,
            child: ref.watch(usePhoneCameraToScanProvider) ?_buttonScanWithPhone(context, ref)
             : ScanBarcodeMultipurposeButton(widget.notifier));
    } else {
      return SizedBox.shrink(); // Return an empty widget if not the current page
    }

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
  /*Widget _dropDownHosts() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      //margin: EdgeInsets.only(top: 10),
      child: DropdownButton(
        underline: Container(
          alignment: Alignment.centerRight,
          child: Icon(
            Icons.arrow_drop_down_circle,
            color: Colors.amber,
          ),
        ),
        elevation: 3,
        isExpanded: true,
        hint: Text(
          Messages.SELECT_A_HOST,

          style: TextStyle(

              color: Colors.black
          ),
        ),
        items: _dropDownItemsHost(MemorySol.listHost),
        value: controller.idHost.value == '' ? null : controller.idHost.value,
        onChanged: (option) {
          controller.setHost(option.toString());
        },
      ),
    );
  }

  List<DropdownMenuItem<String>> _dropDownItemsHost(List<Host> hosts) {
    List<DropdownMenuItem<String>> list = [];
    for (var host in hosts) {
      list.add(DropdownMenuItem(
        value: host.id.toString(),
        child: Text(host.name ?? ''),
      ));
    }

    return list;
  }*/
  Widget getAddButton(BuildContext context,WidgetRef ref) {
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
          ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.PAGE_INDEX_STORE_ON_HAND;
          //context.push(AppRouter.PAGE_PRODUCT_STORE_ON_HAND,extra: widget.notifier);

        },
        child: Text(Messages.ADD_MOVEMENT_LINE),
      ),
    );
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
            switch(ref.read(actionScanProvider.notifier).state){
              case Memory.ACTION_GET_LOCATOR_FROM_VALUE:
                widget.notifier.setLocatorFromValue(scanBarcode);
                break;
              case Memory.ACTION_GET_LOCATOR_TO_VALUE:
                widget.notifier.setLocatorToValue(scanBarcode);
                break;
            }

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
      final movement = data;
      willPop = true;
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

  Widget getCrateButton(BuildContext context, WidgetRef ref) {

    return SizedBox(
      width: widget.width,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.green,
        ),
        onPressed: () {

          final locatorTo = ref.read(selectedLocatorToProvider);
          final locatorFrom = ref.read(selectedLocatorFromProvider);

          if (locatorTo.value != null && locatorTo.value!.isNotEmpty && locatorFrom.value != null && locatorFrom.value!.isNotEmpty) {

            if(locatorTo.id == locatorFrom.id){
              showErrorMessage(context, ref, Messages.ERROR_SAME_LOCATOR);
              return;
            }
            MemoryProducts.locatorTo = locatorTo;
            MemoryProducts.locatorFrom = locatorFrom;
            // Perform the movement logic here
            // For example, call a function from your notifier:
            SqlDataMovement sqlData = SqlDataMovement();
            Memory.sqlUsersData.copyToSqlData(sqlData);
            sqlData.locatorFromId = locatorFrom.id;
            IdempiereWarehouse? warehouseTo = locatorTo.mWarehouseID;
            IdempiereWarehouse? warehouseFrom = locatorFrom.mWarehouseID;
            if(warehouseTo != null && warehouseTo.id != null){
              sqlData.setIdempiereWarehouseTo(warehouseTo.id!);
            }
            if(warehouseFrom != null && warehouseFrom.id != null){
              sqlData.setIdempiereWarehouse(warehouseFrom.id!);
            }
            // creado para borrar
            MemoryProducts.newSqlDataMovementToCreate = sqlData ;
            /*SqlDataMovementLine movementLine = SqlDataMovementLine();
                        Memory.sqlUsersData.copyToSqlData(movementLine);
                        movementLine.mMovementID = movement;
                        movementLine.mLocatorID = widget.storage.mLocatorID;
                        movementLine.mProductID = widget.storage.mProductID;
                        movementLine.mLocatorToID = ref.read(idempiereLocatorToProvider);
                        movementLine.movementQty = ref.read(quantityToMoveProvider);
                        movementLine.mAttributeSetInstanceID = widget.storage.mAttributeSetInstanceID;
                        MemoryProducts.newSqlDataMovementLinesToCreate.add(movementLine);*/
            //Navigator.pop(context);
            widget.notifier.createMovement(sqlData);


          }
        },
        child: Text(Messages.CREATE, style: TextStyle(color: Colors.white),),
      ),
    );

  }




}



