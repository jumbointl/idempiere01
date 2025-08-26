
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/movement_card2.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/idempiere/idempiere_warehouse.dart';
import '../../providers/locator_provider.dart';
import '../../providers/movement_provider.dart';
import '../../widget/no_data_card.dart';
import 'memory_products.dart';
class SelectLocatorScreen extends ConsumerStatefulWidget {

  final IdempiereStorageOnHande storage;
  final int index;
  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  double width;

  ProductsScanNotifier notifier;

  SelectLocatorScreen({required this.index, required this.storage, required this.notifier, required this.width, super.key});


  @override
  ConsumerState<SelectLocatorScreen> createState() =>SelectLocatorScreenState();
}

class SelectLocatorScreenState extends ConsumerState<SelectLocatorScreen> {
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
  late IdempiereMovement movement;
  @override
  Widget build(BuildContext context) {
    createMovement = ref.watch(newPutAwayMovementProvider);
    movement = ref.watch(resultOfSqlQueryMovementProvider.notifier).state;
    ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_GET_LOCATOR_TO_VALUE);
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
        title: Text(Messages.SELECT_LOCATOR_TO),


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
            //color: Colors.grey[200],
            /*decoration: BoxDecoration(
              color: Colors.grey[200], // Change background color based on isSelected
              borderRadius: BorderRadius.circular(10),
            ),*/
             height: dialogHeight,
            width: dialogWidth,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing:  5 ,
              children: [
                getMovementCard(context, ref),
                Padding(
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
                            Text(Messages.QUANTITY_SHORT,style: TextStyle(
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
                            Text(Memory.numberFormatter0Digit.format(quantityToMove),
                              style: TextStyle(
                              fontSize: fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),),
          
                          ],
                        ),
                      ),
          
                    ],
                  ),
                ),
                SizedBox(height:dialogHeight/2-20,
                  child: ListView.separated(
                    itemCount: storageList.length,
                    itemBuilder: (context, index) {
                      return storageOnHandCard(storageList[index], index);
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const SizedBox(height: 10);
                    },
                  ),
                ) ,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 5,
                  children: <Widget>[
                    //if(MemoryProducts.newSqlDataMovement.id!=null && MemoryProducts.newSqlDataMovement.id!>0)
                      Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.amber,
                        ),
                        child: Text(Messages.CONTINUE,
                          style: TextStyle(
                              color: Colors.white
                          ),),
                        onPressed: () async {
                          if(MemoryProducts.newSqlDataMovementToCreate.id!=null && MemoryProducts.newSqlDataMovementToCreate.id!>0){
                            MemoryProducts.createNewMovement = false;
                            ref.read(isDialogShowedProvider.notifier).update((state)=>true);
                            ref.read(scannedLocatorToProvider.notifier).update((state)=>'');
                            Navigator.of(context).pop();
                            context.push(AppRouter.PAGE_UNSORTED_STORAGE_ON_HAND,extra:widget.notifier);
                          } else {
                            Navigator.of(context).pop();
                            print('----------findmovementTo');
                          }

                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text(Messages.CANCEL,
                          style: TextStyle(
                              color: Colors.white
                          ),),
                        onPressed: () async {
                          ref.read(isDialogShowedProvider.notifier).update((state) => false);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text(Messages.CREATE,
                          style: TextStyle(
                              color: Colors.white
                          ),),
                        onPressed: () {
                          MemoryProducts.createNewMovement = true;
                          ref.read(isDialogShowedProvider.notifier).update((state)=>true);
                          ref.read(scannedLocatorToProvider.notifier).update((state)=>'');
                          Navigator.of(context).pop();
                          context.push(AppRouter.PAGE_UNSORTED_STORAGE_ON_HAND,extra:widget.notifier);
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
  Widget storageOnHandCard(IdempiereStorageOnHande storage,int index) {
    final warehouse = ref.read(authProvider).selectedWarehouse;
    int warehouseID = warehouse?.id ?? 0;
    IdempiereWarehouse? warehouseStorage = storage.mLocatorID?.mWarehouseID;
    Color background = warehouseStorage?.id == warehouseID ? widget.colorSameWarehouse : widget.colorDifferentWarehouse;
    String warehouseName = warehouseStorage?.identifier ?? '--';
    double qtyOnHand = storage.qtyOnHand ?? 0;
    String quantity = Memory.numberFormatter0Digit.format(qtyOnHand) ;
    return GestureDetector(
      onTap: () {
        if( qtyOnHand<=0){
          String message =  '${Messages.ERROR_QUANTITY} $quantity';
          showErrorMessage(context, ref, message);
          return;

        }
        // Handle tap event here
        setState(() { // Use setState to trigger a rebuild when isSelected changes
          isCardsSelected = List<bool>.filled(storageList.length, false);
           isCardsSelected[index] = !isCardsSelected[index]; // Update the corresponding index in isCardsSelected
        });
        FocusScope.of(context).unfocus();
        _getQuantityToMoveDialog(context, ref, index);
        //print('Card tapped: ${storage.mProductID?.identifier}, isSelected: ${isCardsSelected[index]} index $index');
      },
      child: Container(
        //margin: EdgeInsets.all(5),
        width: widget.width,
        decoration: BoxDecoration(
          color: isCardsSelected[index] ? background : Colors.grey[200], // Change background color based on isSelected
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            spacing: 5,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1, // Use widthLarge for this column's width
                child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Messages.WAREHOUSE_SHORT),
                    Text(Messages.LOCATOR_SHORT),
                    Text(Messages.QUANTITY_SHORT),
                    Text(Messages.ATTRIBUET_INSTANCE),
                  ],
                ),
              ),
              Expanded(
                flex: 2, // Use widthLarge for this column's width
                child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(warehouseName),
                    Text(widget.storage.mLocatorID?.value ?? '--', overflow: TextOverflow.ellipsis),
                    Text(
                      quantity,
                      style: TextStyle(
                        color: qtyOnHand < 0 ? Colors.redAccent : Colors.black,
                      ),
                    ),
                    Text(widget.storage.mAttributeSetInstanceID?.identifier ?? '--', overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  void addQuantityText(BuildContext context, WidgetRef ref,TextEditingController quantityController,int quantity) {
    if(quantity==-1){
      quantityController.text = '';
      return;
    }
    String s =  quantityController.text;
    String s1 = s;
    String s2 ='';
    if(s.contains('.')) {
      s1 = s.split('.').first;
      s2 = s.split('.').last;
    }

    String r ='';
    if(s.contains('.')){
      r='$s1$quantity.$s2';
    } else {
      r='$s1$quantity';
    }

    int? aux = int.tryParse(r);
    if(aux==null || aux<=0){
      String message =  '${Messages.ERROR_QUANTITY} $quantity';
      showErrorMessage(context, ref, message);
      return;
    }
    quantityController.text = aux.toString();

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



  Widget _numberButtons(BuildContext context, WidgetRef ref,TextEditingController quantityController){
    double widthButton = 40 ;
    return Center(

      //margin: EdgeInsets.only(left: 10, right: 10,),
      child: Column(
        children: [
          Row(
            spacing: 4,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => addQuantityText(context,ref,quantityController,0),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '0',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
              TextButton(
                onPressed: () => addQuantityText(context,ref,quantityController,1),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '1',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
              TextButton(
                onPressed: () => addQuantityText(context,ref,quantityController,2),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),

                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '2',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
              TextButton(
                onPressed: () => addQuantityText(context,ref,quantityController,3),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '3',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
              TextButton(
                onPressed: () => addQuantityText(context,ref,quantityController,4),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '4',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),

            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 4,
            children: [


              TextButton(
                onPressed: () => addQuantityText(context,ref,quantityController,5),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '5',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
              TextButton(
                onPressed: () => addQuantityText(context,ref,quantityController,6),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '6',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
              TextButton(
                onPressed: () => addQuantityText(context,ref,quantityController,7),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '7',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
              TextButton(
                onPressed: () => addQuantityText(context,ref,quantityController,4),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '8',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),

              TextButton(
                onPressed: () => addQuantityText(context,ref,quantityController,9),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '9',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),

            ],
          ),
          SizedBox(height: 20,),
          SizedBox(
            width: widthButton*5 + 4*4,
            height: 37,
            child: TextButton(
              onPressed: () => addQuantityText(context,ref,quantityController,-1),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(widthButton*5 + 4*4, 37), // width of 5 buttons + 4 spacing
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),

              child: Text(
                Messages.CLEAR,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
          ),

        ],
      ),
    );


  }
  Future<void> _getQuantityToMoveDialog(BuildContext context, WidgetRef ref,int index) async {
    TextEditingController quantityController = TextEditingController();
    double qtyOnHand = storageList[index].qtyOnHand ?? 0;
    quantityController.text = Memory.numberFormatter0Digit.format(storageList[index].qtyOnHand);
    AwesomeDialog(
      context: context,
      animType: AnimType.scale,
      dialogType: DialogType.noHeader,
      body: SizedBox(
        height: 260,
        width: 350,//Set the desired height for the AlertDialog
        child: Column(
          spacing: 5,
          children: [
            Text(Messages.QUANTITY_TO_MOVE,style: TextStyle(
              fontSize: fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: TextField(
                autofocus: false,
                enabled: false,
                controller: quantityController,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: fontSizeLarge,
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10,),
            _numberButtons(context, ref,quantityController),
          ],
        ),
      ),
      title:  Messages.QUANTITY_TO_MOVE,
      desc:   '',
      btnOkOnPress: () {
        String quantity = quantityController.text;
        if(quantity.isEmpty){
          String message =  '${Messages.ERROR_QUANTITY} ${Messages.EMPTY}';
          showErrorMessage(context, ref, message);
          return;
        }

        double? aux = double.tryParse(quantity);
        if(aux!=null && aux>0){
          if(aux<=qtyOnHand){
            ref.read(quantityToMoveProvider.notifier).state = aux;
          } else {
            String message =  aux>0 ? '${Messages.ERROR_QUANTITY} ${Memory.numberFormatter0Digit.format(aux)}>${Memory.numberFormatter0Digit.format(qtyOnHand)}' :
            '${Messages.ERROR_QUANTITY} $quantity';
            showErrorMessage(context, ref, message);
            quantityController.text = Memory.numberFormatter0Digit.format(qtyOnHand);
            return;
          }
        } else {
          String message =  '${Messages.ERROR_QUANTITY} ${aux==null ? Messages.EMPTY : quantity}';
          showErrorMessage(context, ref, message);
          return;
        }

      },
      btnOkColor: Colors.green,
      buttonsTextStyle: const TextStyle(color: Colors.white),
      btnCancelText: Messages.CANCEL,
      btnCancelOnPress: (){
        ref.read(quantityToMoveProvider.notifier).state = 0;
      },
      btnCancelColor: Colors.red,
      btnOkText: Messages.OK,
    ).show();
  }
  /*Future<Future<String?>> _getQuantityToMoveDialog2(BuildContext context, WidgetRef ref,int index) async {

    return showDialog<String>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder:  (BuildContext context) =>Consumer(builder: (_, ref, __) {
        TextEditingController quantityController = TextEditingController();
        double qtyOnHand = storageList[index].qtyOnHand ?? 0;
        quantityController.text = Memory.numberFormatter0Digit.format(storageList[index].qtyOnHand);
        return AlertDialog(

          title: Center(
            child: Text(Messages.QUANTITY_TO_MOVE,
              style: TextStyle(
                fontSize: fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),),
          ),
          content: SizedBox(
            height: 250,
            width: 350,//Set the desired height for the AlertDialog
            child: Column(
              spacing: 5,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: TextField(
                    autofocus: false,
                    enabled: false,
                    //keyboardType: TextInputType.number,
                    controller: quantityController,
                    textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                  ),
                    ),
                SizedBox(height: 10,),
                _numberButtons(context, ref,quantityController),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(Messages.CANCEL),
              onPressed: () async {
                ref.read(quantityToMoveProvider.notifier).state = 0;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(Messages.OK),
              onPressed: () {

                String quantity = quantityController.text;
                if(quantity.isEmpty){
                  String message =  '${Messages.ERROR_QUANTITY} ${Messages.EMPTY}';
                  showErrorMessage(context, ref, message);
                  return;
                }

                int? aux = int.tryParse(quantity);
                if(aux!=null && aux>0){
                  if(aux<=qtyOnHand){
                    ref.read(quantityToMoveProvider.notifier).state = aux;
                    Navigator.of(context).pop();
                  } else {
                    String message =  aux>0 ? '${Messages.ERROR_QUANTITY} ${Memory.numberFormatter0Digit.format(aux)}>${Memory.numberFormatter0Digit.format(qtyOnHand)}' :
                    '${Messages.ERROR_QUANTITY} $quantity';
                    showErrorMessage(context, ref, message);
                    quantityController.text = Memory.numberFormatter0Digit.format(qtyOnHand);
                    return;
                  }
                } else {
                  String message =  '${Messages.ERROR_QUANTITY} ${aux==null ? Messages.EMPTY : quantity}';
                  showErrorMessage(context, ref, message);
                  return;
                }
              },
            ),
          ],
        );
      }),
    );
  }*/
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


  Widget getMovementCard(BuildContext context, WidgetRef ref) {

    if(movement.id==null || movement.id!<=0){
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