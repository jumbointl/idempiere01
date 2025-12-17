
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/persitent_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../common/scan_button_by_action_fixed.dart';
import '../../../../common/scan_button_by_action_fixed_short.dart';
import '../../../../domain/idempiere/idempiere_locator.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/idempiere_warehouse.dart';
import '../../../../domain/sql/sql_data_movement_line.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/locator_provider.dart';
import '../../locator/search_locator_dialog.dart';
import '../../store_on_hand/memory_products.dart';
import '../provider/products_home_provider.dart';
import '../provider/new_movement_provider.dart';
import 'custom_app_bar.dart';
class UnsortedStorageOnHandSelectLocatorScreen extends ConsumerStatefulWidget implements InputDataProcessor{

  final IdempiereStorageOnHande storage;
  final MovementAndLines movementAndLines;
  final int index;
  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  double width;
  final int pageIndex = Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND;
  final int actionScanType = Memory.ACTION_GET_LOCATOR_TO_VALUE;
  String? productUPC ;
  String? argument;


  UnsortedStorageOnHandSelectLocatorScreen({
    required this.index,
    required this.storage,
    required this.width,
    this.productUPC,
    required this.movementAndLines,

    super.key, required String argument});


  @override
  ConsumerState<UnsortedStorageOnHandSelectLocatorScreen> createState() =>UnsortedStorageOnHandScreenSelectLocatorState();

  @override
  Future<void> handleInputString({required WidgetRef ref, required String inputData,required int actionScan}) async {
    final scanHandleNotifier = ref.read(scanHandleNotifierProvider.notifier);
    scanHandleNotifier.handleInputString(ref:ref, inputData: inputData,actionScan:actionScan);

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

class UnsortedStorageOnHandScreenSelectLocatorState extends ConsumerState<UnsortedStorageOnHandSelectLocatorScreen> {
  late List<IdempiereStorageOnHande> unsortedStorageList = [];
  late List<IdempiereStorageOnHande> storageList = [];
  late double widthLarge ;
  late double widthSmall ;

  late AsyncValue findLocatorTo ;
  late var isLocatorScreenShowed;
  late var usePhoneCamera ;
  late var quantityToMove;
  late double dialogHeight ;
  late double dialogWidth ;
  List<bool> isCardsSelected = [];
  double fontSizeSmall = 12;
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
  late MovementAndLines movementAndLines;
  late var lines ;
  bool showScanButton = false;
  String? productId ;
  late var copyLastLocatorTo ;
  late var documentColor;
  double trailingWidth = 60;
  late var movementColor ;

  @override
  void initState() {
    super.initState();
    movementAndLines = widget.movementAndLines;



    WidgetsBinding.instance.addPostFrameCallback((_) async {

      final from = widget.storage.mLocatorID;

      final int id = from?.id ?? -1;

      await Future.delayed(const Duration(milliseconds: 100),(){
        ref.read(actualLocatorFromProvider.notifier).state = id;
        ref.read(actionScanProvider.notifier).state = 5;
        ref.read(isDialogShowedProvider.notifier).state = false;
        int warehouseToID = movementAndLines.mWarehouseToID?.id ?? 0;
        ref.read(actualWarehouseToProvider.notifier).state = warehouseToID;
        if(copyLastLocatorTo){
          if(movementAndLines.hasLastLocatorTo){
            ref.read(selectedLocatorToProvider.notifier).state = movementAndLines.lastLocatorTo!;
          }
        }

      });




    });
  }


  @override
  Widget build(BuildContext context) {
    actionScan = ref.watch(actionScanProvider);
    copyLastLocatorTo = ref.watch(copyLastLocatorToProvider);


    locatorFrom = widget.storage.mLocatorID ;

    productId = widget.movementAndLines.nextProductIdUPC ;

    lines = ref.watch(movementLinesProvider(widget.movementAndLines));

    findLocatorTo = ref.watch(findLocatorToProvider);
    locatorTo = ref.watch(selectedLocatorToProvider);
    isDialogShowed = ref.watch(isDialogShowedProvider);
    isScanning = ref.watch(isScanningProvider);

    widget.width = MediaQuery.of(context).size.width;
    quantityToMove = ref.watch(quantityToMoveProvider);
    usePhoneCamera = ref.watch(usePhoneCameraToScanForLineProvider);
    scrollToTop = ref.watch(scrollToUpProvider);

    widthLarge = widget.width/3*2;
    widthSmall = widget.width/3;
    unsortedStorageList = ref.read(unsortedStoreOnHandListProvider);
    final showScan = ref.watch(showScanFixedButtonProvider(widget.actionScanType));
    dialogHeight = MediaQuery.of(context).size.height;
    dialogWidth = MediaQuery.of(context).size.width;
    isDialogShowed = ref.watch(isDialogShowedProvider);
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

    final canShowBottomBar = ref.watch(canShowCreateLineBottomBarProvider);
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
          if(showScan) ScanButtonByActionFixedShort(
            actionTypeInt: widget.actionScanType,
            onOk: widget.handleInputString,),
          if(showScan) IconButton(
            icon: const Icon(Icons.keyboard,color: Colors.purple),
            onPressed: () => {
              openInputDialogWithAction(ref: ref, history: false,
                  onOk: widget.handleInputString, actionScan:  widget.actionScanType)
            },
          ),
        ],
        title: movementAppBarTitle(movementAndLines: movementAndLines,
            onBack: ()=> popScopeAction,
            showBackButton: false,
            subtitle: '${Messages.LINES} : (${movementAndLines.movementLines?.length ?? 0})'
        ),


      ),
        bottomNavigationBar:  canShowBottomBar ?  bottomAppBar(context, ref) :null,
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
                  SliverToBoxAdapter(child: getMovementCard(context, ref)),
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

                                  Text(Messages.LINES,style: TextStyle(
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

                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                          side: BorderSide(color: Colors.black, width: 1), // Add border here
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5)),
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size(50, 30),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          alignment: Alignment.centerLeft),
                                      onPressed: () async {

                                        String? result = await openInputDialogWithResult(
                                            context, ref, false,value: lines,
                                          title: Messages.LINES,numberOnly: true);
                                        double aux = double.tryParse(result ??'') ?? 0;
                                        if (aux > 0) {
                                          ref.read(movementLinesProvider(widget.movementAndLines).notifier)
                                              .state = aux;
                                        } else {
                                          if(context.mounted)showErrorMessage(context, ref, Messages.ERROR_LINES);
                                        }

                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(Memory.numberFormatter0Digit.format(lines),
                                          style: TextStyle(
                                            fontSize: fontSizeMedium,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple,
                                          ),),
                                      ),
                                    ),
                                  ),

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
      height: 70,
      color: themeColorPrimary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ConfirmationSlider(
          height: 45,
          backgroundColor: Colors.green[100]!,
          backgroundColorEnd: Colors.green[800]!,
          foregroundColor: Colors.green,
          text: Messages.SLIDE_TO_CREATE,
          textStyle: TextStyle(
            fontSize: themeFontSizeLarge,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
          onConfirmation: () {
            if (!movementAndLines.hasMovement) {
              showErrorMessage(context, ref, Messages.NO_MOVEMENT_SELECTED);
              return;
            }
            createMovementLineOnly();
          },
        ),
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
        getDoubleDialog(ref:  ref,
            quantity: storage.qtyOnHand ?? 0,
            targetProvider: quantityToMoveProvider,
        );
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

  Widget getScanButton(BuildContext context) {
      return usePhoneCamera ? buttonScanWithPhone(context, ref):
      ScanButtonByActionFixed(
          processor: widget,
          actionTypeInt: widget.actionScanType);

  }
  Widget buttonScanWithPhone(BuildContext context,WidgetRef ref) {
    int a = widget.actionScanType;
    int b = actionScan;
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

        isScanning = true;
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
          isScanning = true;
          ref.read(scannedLocatorToProvider.notifier).update((state) => result!);
        } else {
          Future.delayed(const Duration(milliseconds: 500));
          isScanning = false;
        }

      },
      child: Text('${Messages.OPEN_CAMERA}$tip',style: TextStyle(color: Colors.white,
          fontSize: themeFontSizeLarge),),
    );
  }

  Widget getMovementCard(BuildContext context, WidgetRef ref) {

    IdempiereLocator? lastLocatorTo = movementAndLines.lastLocatorTo;
    if(lastLocatorTo != null){
      lastLocatorTo.value ??= lastLocatorTo.identifier;
    }
    Color color = ref.watch(colorLocatorProvider);

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Colors.black, // Specify the border color
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
            //spacing: 5,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              ListTile(
                dense: true,

                leading: SizedBox(
                  width: trailingWidth,
                  child: Text('${Messages.FROM} ${Messages.LOCATOR}',
                    style: TextStyle(
                      fontSize: fontSizeSmall,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,),textAlign: TextAlign.start,),
                ),
                title: Text(locatorFrom.value ??
                     Messages.LOCATOR_FROM,style: TextStyle(
                  fontSize: fontSizeSmall,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,),),
                trailing: SizedBox(
                  width: 48.0, // Ancho estándar de un IconButton
                  height: 48.0, // Alto estándar de un IconButton
                  child: Center(
                    child: Icon(Icons.check_circle, color: widget.storage.mLocatorID != null ? Colors.green : Colors.red),
                  ),
                ),
              ),

              if(lastLocatorTo != null)
                ListTile(
                  dense: true,
                  leading: SizedBox(
                    width: trailingWidth,
                    child: Center(
                      child: Checkbox(
                        value: copyLastLocatorTo,
                        onChanged: (value) {
                          if (value == null) return;
                          ref.read(copyLastLocatorToProvider.notifier).state = value;

                          /*if (value) {
                            // copiar último locator al seleccionado
                            ref.read(selectedLocatorToProvider.notifier).state =
                                lastLocatorTo;
                          } else {
                            // resetear locator seleccionado
                            ref.read(selectedLocatorToProvider.notifier).state =
                                IdempiereLocator(
                                  id: Memory.INITIAL_STATE_ID,
                                  value: Messages.FIND,
                                );
                          }*/
                        },
                      ),
                    ),

                  ),
                  title: Text(Messages.COPY_LAST_DATA,
                    style: TextStyle(
                      fontSize: fontSizeSmall,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    lastLocatorTo.value ?? lastLocatorTo.identifier ?? '',
                    style: TextStyle(
                      fontSize: fontSizeSmall,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  trailing: IconButton(
                    padding: EdgeInsets.zero, // Eliminar padding para alinear
                    icon: const Icon(Icons.download, color: Colors.purple),
                    onPressed: () {
                      // acción opcional extra si quieres forzar copia manual
                      ref.read(selectedLocatorToProvider.notifier).state =
                          lastLocatorTo;
                      setState(() {

                      });
                    },
                  ),
                ),
              getLocatorTo(context, ref),

            ],
          ),


    );
  }

  Widget getLocatorTo(BuildContext context, WidgetRef ref) {


    return findLocatorTo.when(
      data: (locatorFromFuture) {
        IdempiereLocator locator;
        if (locatorTo.id != Memory.INITIAL_STATE_ID) {
          print('Hay locator elegido manualmente');
          // Hay locator elegido manualmente (LocatorCard)
          locator = locatorTo;
        } else {
          print('No Hay locator elegido manualmente locatorFromFuture');
          // Usar el que viene del escaneo / FutureProvider
          locator = locatorFromFuture;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) async {

        });
        return ListTile(
          dense: true,
          leading: GestureDetector(
            onTap: (){
              bool forCreateLine = false ;
              ref.read(findingCreateLinLocatorToProvider.notifier).state = forCreateLine;
              Memory.pageFromIndex = ref.read(productsHomeCurrentIndexProvider.notifier).state;
              ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_NO_REQUERED_SCAN_SCREEN);
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SearchLocatorDialog(
                    searchLocatorFrom :false,
                    forCreateLine: forCreateLine,
                  );
                },
              );

            },
            child: SizedBox(
              width: trailingWidth,
              child: Text('${Messages.TO} ${Messages.LOCATOR}',
                style: TextStyle(
                  fontSize: fontSizeSmall,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,),textAlign: TextAlign.start,),
            ),
          ),
          /*title: Text(this.locatorTo.id != null ? this.locatorTo.value ??''
              : this.locatorTo.identifier ?? '',style:TextStyle(
            fontSize: fontSizeSmall,
            fontWeight: FontWeight.bold,
            color: Colors.purple,)),*/
          title: Text(locator.id != null ?locator.value ??''
              : locator.identifier ?? '',style:TextStyle(
            fontSize: fontSizeSmall,
            fontWeight: FontWeight.bold,
            color: Colors.purple,)),
          trailing:locator.id != null
              && locator.id! > 0
              ? const SizedBox(width: 48.0, height: 48.0, child: Center(child: Icon(Icons.check_circle, color: Colors.green)))
              : const SizedBox(
                  width: 48.0,
                  height: 48.0,
                  child: Center(child: Icon(Icons.error, color: Colors.red)),
                ),

        );
      },
      error: (error, stackTrace) {
        return Text(Messages.ERROR,style:TextStyle(
        fontSize: fontSizeSmall,
        fontWeight: FontWeight.bold,
        color: Colors.red,));
      },
      loading: () => LinearProgressIndicator(minHeight: 16,),
    );


  }
  /*Widget getConfirmationSliderButton(BuildContext context, WidgetRef ref) {
    return ConfirmationSlider(
      height: 50,
      backgroundColor: Colors.green[100]!,
      backgroundColorEnd: Colors.green[800]!,
      foregroundColor: Colors.green,
      text: Messages.SLIDE_TO_CREATE,
      textStyle: TextStyle(fontSize: themeFontSizeLarge, color: Colors.purple,fontWeight: FontWeight.bold),
      onConfirmation: () {

        if(movementAndLines.hasMovement){
          createMovementLineOnly();
          return;
        } else {
          showErrorMessage(context, ref, Messages.NO_MOVEMENT_SELECTED);
        }

      }

    );
  }*/
  void createMovementLineOnly() {
    print('----------------------------ConfirmationSlide');
    int movementId =movementAndLines.id ?? -1;
    if(movementId<=0){
      showErrorMessage(context, ref, Messages.MOVEMENT_ID);
      return ;
    }

    int locatorFrom = widget.storage.mLocatorID?.id ?? -1;
    if(locatorFrom<=0){
      showAutoCloseErrorDialog(context,ref,Messages.ERROR_LOCATOR_FROM,3);
      return;
    }
    int locatorTo = this.locatorTo?.id ?? -1;
    if(locatorTo<=0){
      showAutoCloseErrorDialog(context,ref,Messages.ERROR_LOCATOR_TO,3);
      return;
    }
    if(movementId>0 && locatorFrom>0 && locatorTo>0){
      SqlDataMovementLine movementLine = SqlDataMovementLine();
      Memory.sqlUsersData.copyToSqlData(movementLine);
      movementLine.mMovementID = movementAndLines;
      if(movementLine.mMovementID==null || movementLine.mMovementID!.id==null){
        showErrorMessage(context, ref, Messages.ERROR_MOVEMENT);
        return;
      }
      movementLine.mLocatorID = widget.storage.mLocatorID ;
      if(movementLine.mLocatorID==null || movementLine.mLocatorID!.id==null){
        showErrorMessage(context, ref, Messages.ERROR_LOCATOR_FROM);
        return;
      }
      movementLine.mProductID = widget.storage.mProductID;
      if(movementLine.mProductID==null || movementLine.mProductID!.id==null){
        showErrorMessage(context, ref, Messages.ERROR_PRODUCT);
        return;
      }
      movementLine.mLocatorToID = this.locatorTo;
      if(movementLine.mLocatorToID==null || movementLine.mLocatorToID!.id==null){
        showErrorMessage(context, ref, Messages.ERROR_LOCATOR_TO);
        return;
      }
      movementLine.movementQty = ref.read(quantityToMoveProvider);
      if(movementLine.movementQty==null && movementLine.movementQty!<=0){
        showErrorMessage(context, ref, Messages.ERROR_QUANTITY);
        return;
      }
      movementLine.mAttributeSetInstanceID = widget.storage.mAttributeSetInstanceID;
      MemoryProducts.newSqlDataMovementLineToCreate = movementLine;
      movementLine.line = lines;
      MemoryProducts.movementAndLines.movementLineToCreate = movementLine;


      MovementAndLines m = MovementAndLines();
      if(widget.argument!= null && widget.argument!.isNotEmpty){
        m = MovementAndLines.fromJson(jsonDecode(widget.argument!));
        if(!m.hasMovement){
          showErrorMessage(context, ref, Messages.ERROR_MOVEMENT);
          return;
        }
      } else {
        m = movementAndLines;
        if(!m.hasMovement){
          showErrorMessage(context, ref, Messages.ERROR_MOVEMENT);
          return;
        }
      }
      m.movementLineToCreate = movementLine;
      MemoryProducts.movementAndLines = m;
      String argument = m.id.toString() ?? '-1';
      context.go('${AppRouter.PAGE_CREATE_MOVEMENT_LINE}/$argument',
          extra: m);

    }




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
    String productUPC = widget.storage.mProductID?.identifier ?? '-1';
    productUPC = productUPC.split('_').first;
    print('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/$productUPC');
    context.go('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/$productUPC',
      extra: movementAndLines
    );


  }

}

