
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../common/messages_dialog.dart';
import '../../../domain/idempiere/idempiere_locator.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/idempiere/idempiere_warehouse.dart';
import '../../../domain/idempiere/put_away_movement.dart';
import '../../providers/common_provider.dart';
import '../../providers/locator_provider.dart';
import '../../providers/movement_provider.dart';
import '../locator/search_locator_dialog.dart';
class UnsortedStorageOnHandScreen extends ConsumerStatefulWidget implements InputDataProcessor{

  final IdempiereStorageOnHande storage;
  final int index;
  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  double width;
  final int pageIndex = Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND;
  final int actionScanType = Memory.ACTION_GET_LOCATOR_TO_VALUE;
  String? productUPC ;
  late var notifier;



  UnsortedStorageOnHandScreen({
    required this.index,
    required this.storage,
    required this.width,
    this.productUPC,
    super.key});


  @override
  ConsumerState<UnsortedStorageOnHandScreen> createState() =>UnsortedStorageOnHandScreenState();

  @override
  Future<void> handleInputString(BuildContext context, WidgetRef ref, String inputData) async {
     notifier.handleInputString(context, ref, inputData);

  }
  @override
  void addQuantityText(BuildContext context, WidgetRef ref,
      TextEditingController quantityController,int quantity) {
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


}

class UnsortedStorageOnHandScreenState extends ConsumerState<UnsortedStorageOnHandScreen> {
  late List<IdempiereStorageOnHande> unsortedStorageList = [];
  late List<IdempiereStorageOnHande> storageList = [];
  late double widthLarge ;
  late double widthSmall ;

  late AsyncValue findLocatorTo ;

  late var usePhoneCamera ;
  late var quantityToMove;
  late double dialogHeight ;
  late double dialogWidth ;
  List<bool> isCardsSelected = [];
  double fontSizeMedium = 16;
  double fontSizeLarge = 22;
  late var actionScan ;
  bool goToMovementsScreenWithMovementId = false;
  bool showErrorDialog = false;
  final ScrollController _scrollController = ScrollController();
  late var scrollToTop  ;
  late var locatorTo;
  late var locatorFrom ;
  late var isScanning ;
  late var isDialogShowed;
  bool searched = false ;
  double goToPosition =0.0;
  PutAwayMovement? putAwayMovement;


  @override
  void initState() {


    WidgetsBinding.instance.addPostFrameCallback((_){



    });
    super.initState();

  }

  @override
  Widget build(BuildContext context) {

    putAwayMovement = PutAwayMovement();
    putAwayMovement!.setUser(Memory.sqlUsersData);
    putAwayMovement!.movementLineToCreate!.mProductID = widget.storage.mProductID;
    putAwayMovement!.movementLineToCreate!.mLocatorID = widget.storage.mLocatorID;
    locatorFrom = widget.storage.mLocatorID;
    putAwayMovement!.movementToCreate!.locatorFromId = locatorFrom.id;
    putAwayMovement!.movementToCreate!.mWarehouseID = locatorFrom.mWarehouseID;

    widget.notifier = ref.read(scanHandleNotifierProvider.notifier);
    locatorFrom = widget.storage.mLocatorID;
    locatorTo = ref.watch(selectedLocatorToProvider.notifier);
    findLocatorTo = ref.watch(findLocatorToProvider);
     actionScan = ref.watch(actionScanProvider.notifier);
     isScanning = ref.watch(isScanningLocatorToProvider.notifier);
     isDialogShowed = ref.watch(isDialogShowedProvider.notifier);
     widget.width = MediaQuery.of(context).size.width;
     quantityToMove = ref.watch(quantityToMoveProvider);
     usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
     scrollToTop = ref.watch(scrollToUpProvider.notifier);


    widthLarge = widget.width/3*2;
    widthSmall = widget.width/3;
    unsortedStorageList = ref.read(unsortedStoreOnHandListProvider);
    dialogHeight = MediaQuery.of(context).size.height;
    dialogWidth = MediaQuery.of(context).size.width;

    storageList = unsortedStorageList
        .where((element) =>
            element.mLocatorID?.mWarehouseID?.id ==
            widget.storage.mLocatorID?.mWarehouseID?.id &&
            element.mProductID?.id == widget.storage.mProductID?.id &&
            element.mLocatorID?.id == widget.storage.mLocatorID?.id )
        .toList();
    String title ='${Messages.MOVEMENT} : ${Messages.CREATE}';
    if (isCardsSelected.isEmpty && storageList.isNotEmpty) {
      isCardsSelected = List<bool>.filled(storageList.length, false);
    }
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
        leading:IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
          {
            popScopeAction(context,ref),

          }
        ),
        actions: [
          usePhoneCamera.state ? IconButton(
            icon: const Icon(Icons.barcode_reader),
            onPressed: () => {

              usePhoneCamera.state = false,
              isDialogShowed.state = false,
              setState(() {}),
            },
          ) :  IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => {
              usePhoneCamera.state = true,
              isDialogShowed.state = false,
              setState(() {}),
            },

          ),

        ],
        title: Text(title),


      ),
        bottomNavigationBar: isDialogShowed.state ? Container(
          height: Memory.BOTTOM_BAR_HEIGHT,
          color: themeColorPrimary,
          child: Center(
            child: Text(Messages.DIALOG_SHOWED,
              style: TextStyle(color: Colors.white,fontSize: themeFontSizeLarge
                  ,fontWeight: FontWeight.bold),),
          ),) :bottomAppBar(context, ref),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            double positionAdd=_scrollController.position.maxScrollExtent;
            if(scrollToTop.state){
              goToPosition -= positionAdd;
              if(goToPosition <= 0){
                goToPosition = 0;
                ref.read(scrollToUpProvider.notifier).update((state) => !state);
              }
            } else {
              goToPosition+= positionAdd;
              if(goToPosition >= _scrollController.position.maxScrollExtent){
                goToPosition = _scrollController.position.maxScrollExtent;
                ref.read(scrollToUpProvider.notifier).update((state) => !state);
              }
            }

            setState(() {});
            _scrollController.animateTo(
              goToPosition,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          },
          child: Icon(scrollToTop.state ? Icons.arrow_upward :Icons.arrow_downward),
        ),
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) {

              return;
            }
            popScopeAction(context,ref);

          },
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                      padding: EdgeInsets.only(top: 5),
                      sliver: SliverToBoxAdapter(child: getMovementCard(context, ref))),
                  SliverPadding(
                    padding: EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(widget.storage.mProductID?.identifier ?? '--',style: TextStyle(
                          fontSize: fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,),),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(
                            color: Colors.black, // Specify the border color
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                    ),
                  ),
                  getStockList(context,ref),


              ]),
          )
        ),
        )
      );
  }

  Widget bottomAppBar(BuildContext context, WidgetRef ref) {
    return BottomAppBar(
      height: 130,
      color: themeColorPrimary,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 6,
        children: [
          getScanButton(context),
          if(ref.read(quantityToMoveProvider.notifier).state>0)getConfirmationSliderButton(context, ref),

        ],
      ),
    );
  }
  Widget storageOnHandCard(IdempiereStorageOnHande storage,int index) {
    final warehouse = ref.read(authProvider).selectedWarehouse;
    int warehouseID = warehouse?.id ?? 0;
    IdempiereLocator warehouseLocator = storage.mLocatorID!;
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
                onPressed: () => widget.addQuantityText(context,ref,quantityController,0),
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
                onPressed: () => widget.addQuantityText(context,ref,quantityController,1),
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
                onPressed: () => widget.addQuantityText(context,ref,quantityController,2),
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
                onPressed: () => widget.addQuantityText(context,ref,quantityController,3),
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
                onPressed: () => widget.addQuantityText(context,ref,quantityController,4),
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
                onPressed: () => widget.addQuantityText(context,ref,quantityController,5),
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
                onPressed: () => widget.addQuantityText(context,ref,quantityController,6),
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
                onPressed: () => widget.addQuantityText(context,ref,quantityController,7),
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
                onPressed: () => widget.addQuantityText(context,ref,quantityController,4),
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
                onPressed: () => widget.addQuantityText(context,ref,quantityController,9),
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
              onPressed: () => widget.addQuantityText(context,ref,quantityController,-1),
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
        height: 300,
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

  Widget getScanButton(BuildContext context) {
      return usePhoneCamera.state ? buttonScanWithPhone(context, ref):
      ScanButtonByAction(processor: widget,
          actionTypeInt: widget.actionScanType);

  }
  Widget buttonScanWithPhone(BuildContext context,WidgetRef ref) {
    int a = widget.actionScanType;
    int b = actionScan.state;
    String tip = '(Loc)';
    if(a!=b){
      tip ='(X)';
    }
    return TextButton(

      style: TextButton.styleFrom(
        backgroundColor: themeColorPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),

      ),
      onPressed:  () async {

        isScanning.state = true;
          String? result= await SimpleBarcodeScanner.scanBarcode(
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

        result = result?.trim();
        if(result!=null && result.isNotEmpty){
          isScanning.state = true;
          ref.read(scannedLocatorToProvider.notifier).update((state) => result!);
        } else {
          Future.delayed(const Duration(milliseconds: 500));
          isScanning.state = false;
        }

      },
      child: Text('${Messages.OPEN_CAMERA}$tip',style: TextStyle(color: Colors.white,
          fontSize: themeFontSizeLarge),),
    );
  }
  Widget getMovementCard(BuildContext context, WidgetRef ref) {

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(
          color: Colors.black, // Specify the border color
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
            spacing: 5,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: SizedBox(
                  width: 60,
                  child: Text('${Messages.FROM} ${Messages.LOCATOR}',
                    style: TextStyle(
                      fontSize: fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,),textAlign: TextAlign.start,),
                ),
                title: Text(locatorFrom.value ??
                     Messages.LOCATOR_FROM,style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,),),
                trailing: Icon(Icons.check_circle,color:
                  widget.storage.mLocatorID != null ?
                  Colors.green : Colors.red,)
              ),
              getLocatorTo(context, ref),

            ],
          ),


    );
  }

  Widget getLocatorTo(BuildContext context, WidgetRef ref) {

    return findLocatorTo.when(
      data: (locator) {

        if(locator!=null && locator.id!=null && locator.id!>0){

          putAwayMovement!.movementLineToCreate!.mLocatorToID = locator;
          putAwayMovement!.movementToCreate!.mWarehouseToID = locator?.mWarehouseID ;
        }


        WidgetsBinding.instance.addPostFrameCallback((_) async {
        });
        return ListTile(
          leading: GestureDetector(
            onTap: (){

              Memory.pageFromIndex = ref.read(productsHomeCurrentIndexProvider.notifier).state;
              ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_NO_REQUERED_SCAN_SCREEN);
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SearchLocatorDialog(
                    searchLocatorFrom :false,
                    forCreateLine: false,
                  );
                },
              );

            },
            child: SizedBox(
              width: 60,
              child: Text('${Messages.TO} ${Messages.LOCATOR}',
                style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,),textAlign: TextAlign.start,),
            ),
          ),
          title: Text(locator.id != null ?locator.value ??''
              : locator.identifier ?? '',style:TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: FontWeight.bold,
            color: Colors.purple,)),
          trailing:locator.id != null
              && locator.id! > 0 ?
          Icon(Icons.check_circle,color: Colors.green,) :
          Icon(Icons.error,color: Colors.red,),

        );
      },
      error: (error, stackTrace) {
        return Text(Messages.ERROR,style:TextStyle(
        fontSize: fontSizeMedium,
        fontWeight: FontWeight.bold,
        color: Colors.red,));
      },
      loading: () => LinearProgressIndicator(minHeight: 16,),
    );


  }
  Widget getConfirmationSliderButton(BuildContext context, WidgetRef ref) {
    return ConfirmationSlider(
      height: 50,
      backgroundColor: Colors.green[100]!,
      backgroundColorEnd: Colors.green[800]!,
      foregroundColor: Colors.green,
      text: Messages.SLIDE_TO_CREATE,
      textStyle: TextStyle(fontSize: themeFontSizeLarge, color: Colors.purple,fontWeight: FontWeight.bold),
      onConfirmation: () {
        print('----------------------------ConfirmationSlide');
        if (putAwayMovement!=null && putAwayMovement!.movementLineToCreate!=null) {
          putAwayMovement!.movementLineToCreate!.movementQty = ref.read(quantityToMoveProvider);
          widget.notifier.prepareToCreatePutawayMovement(ref, putAwayMovement);
        } else {
          showErrorMessage(context, ref, Messages.MOVEMENT_ALREADY_CREATED);

        }
      }

    );
  }

  Widget getStockList(BuildContext context, WidgetRef ref) {

    return SliverPadding(
      padding: EdgeInsets.only(top: 5),
      sliver: SliverList.separated(
        itemBuilder: (BuildContext context, int index) {
            return storageOnHandCard(storageList[index], index);
          },
        itemCount: storageList.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 5,),
      ),
    );
  }

  void popScopeAction(BuildContext context, WidgetRef ref) {
    FocusScope.of(context).unfocus();
    ref.read(isScanningProvider.notifier).update((state) => false);
    ref.read(quantityToMoveProvider.notifier).update((state) => 0);
    ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_STORE_ON_HAND);
    ref.read(actionScanProvider.notifier).state = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;
    context.go('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/${widget.productUPC?? '-1'}');

  }

}