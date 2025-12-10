
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/persitent_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../common/scan_button_by_action_fixed_short.dart';
import '../../../../domain/idempiere/idempiere_locator.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/idempiere_warehouse.dart';
import '../../../../domain/sql/sql_data_movement_line.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/locator_provider_for_Line.dart';
import '../../../providers/products_scan_notifier_for_line.dart';
import '../../locator/search_locator_dialog.dart';
import '../provider/new_movement_provider.dart';
import '../provider/products_home_provider.dart';
import '../../store_on_hand/memory_products.dart';
import 'custom_app_bar.dart';
class UnsortedStorageOnHandScreenForLine extends ConsumerStatefulWidget implements InputDataProcessor{

  final IdempiereStorageOnHande storage;
  final int index;
  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  double width;
  int pageIndex = Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND;
  final int actionScanType = Memory.ACTION_GET_LOCATOR_TO_VALUE ;
  MovementAndLines movementAndLines ;
  String argument;
  UnsortedStorageOnHandScreenForLine({required this.index,
    required this.movementAndLines,
    required this.storage,
    required this.width,
    super.key, required this.argument,
    });


  @override
  ConsumerState<UnsortedStorageOnHandScreenForLine> createState() =>UnsortedStorageOnHandScreenForLineState();

  @override
  Future<void> handleInputString({required WidgetRef ref, required String inputData,required int actionScan}) async {
    late ProductsScanNotifierForLine scanHandleNotifier =  ref.read(scanStateNotifierForLineProvider.notifier);
     scanHandleNotifier.handleInputString(ref: ref, inputData: inputData, actionScan: actionScan);
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

class UnsortedStorageOnHandScreenForLineState extends ConsumerState<UnsortedStorageOnHandScreenForLine> {
  late List<IdempiereStorageOnHande> unsortedStorageList = [];
  late List<IdempiereStorageOnHande> storageList = [];
  late double widthLarge ;
  late double widthSmall ;
  late AsyncValue findLocatorTo ;

  late var quantityToMove;
  late double dialogHeight ;
  late double dialogWidth ;
  List<bool> isCardsSelected = [];
  double fontSizeMedium = 16;
  double fontSizeLarge = 22;
  late var actionScan ;
  late var isLocatorScreenShowed;
  late  IdempiereLocator? allowedLocatorFrom;
  bool showErrorDialog = false;
  final ScrollController _scrollController = ScrollController();
  late var scrollToTop  ;
  double goToPosition =0.0;
  //late var locatorTo;
  //var localLocatorTo;
  late var isScanning;
  late var isDialogShowed;
  late var locatorTo;
  late var lines ;
  bool showScanButton = false;
  String? productId ;


  MovementAndLines get movementAndLines {

    if(widget.argument.isNotEmpty && widget.argument!='-1') {
      return MovementAndLines.fromJson(jsonDecode(widget.argument));
    } else {
      return widget.movementAndLines;
    }
  }
  @override
  void initState() {
    if(movementAndLines.hasMovement) {

      if (movementAndLines.hasMovementLines) {
        allowedLocatorFrom = movementAndLines.lastLocatorFrom;
        allowedLocatorFrom?.value ??= allowedLocatorFrom?.identifier;
        locatorTo = movementAndLines.lastLocatorTo;
        locatorTo.value ??= locatorTo.identifier;
      } else {
        findLocatorTo = ref.watch(findLocatorToForLineProvider);
        locatorTo = ref.watch(persistentLocatorToProvider);
        showScanButton = true;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_){
        Future.delayed(const Duration(seconds: 1));
        ref.read(isScanningForLineProvider.notifier).update((state) => false);
        ref.read(isDialogShowedProvider.notifier).update((state) => false);
        if(movementAndLines.hasMovement) {
          if (movementAndLines.hasMovementLines) {
            Future.delayed(Duration(microseconds: 50), () {
              ref.read(actionScanProvider.notifier).update((state) =>
              Memory.ACTION_NO_ACTION);
              ref
                  .read(productsHomeCurrentIndexProvider.notifier)
                  .state =
                  Memory.PAGE_INDEX_NO_REQUERED_SCAN_SCREEN;
            });
          } else {
            Future.delayed(Duration(microseconds: 50), () {
              showScanButton = true;
              ref.read(actionScanProvider.notifier).update((state) =>
              widget.actionScanType);
            });

            showScanButton = true;
          }
        }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    productId = widget.movementAndLines.nextProductIdUPC ;
    allowedLocatorFrom = widget.storage.mLocatorID;

    lines = ref.watch(movementLinesProvider(widget.movementAndLines));
    actionScan = ref.watch(actionScanProvider);
    final showScan = ref.watch(showScanFixedButtonProvider(widget.actionScanType));
    isDialogShowed = ref.watch(isDialogShowedProvider);
    isScanning = ref.watch(isScanningLocatorToForLineProvider);
    widget.width = MediaQuery.of(context).size.width;
    quantityToMove = ref.watch(quantityToMoveProvider);

    scrollToTop = ref.watch(scrollToUpProvider);

    widthLarge = widget.width/3*2;
    widthSmall = widget.width/3;
    unsortedStorageList = ref.read(unsortedStoreOnHandListProvider);

    dialogHeight = MediaQuery.of(context).size.height;
    dialogWidth = MediaQuery.of(context).size.width;
    isLocatorScreenShowed = ref.watch(isLocatorScreenShowedForLineProvider);
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
          backgroundColor: movementAndLines.hasMovement ? Colors.yellow[200] : Colors.white,
          leading:IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => {
              popScopeAction(context,ref),

            },
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
        bottomNavigationBar: canShowBottomBar ? bottomAppBar(context, ref) :null,

        body: SafeArea(
          child: PopScope(
              canPop: false ,
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
                      movementAndLines.hasMovement ? SliverPadding(
                          padding: EdgeInsets.only(top: 5),
                          sliver: SliverToBoxAdapter(child: getMovementInfo(context, ref)))
                          : SliverPadding(
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
                            child: Text((widget.storage.mProductID?.identifier ?? '--').split('_').last,style: TextStyle(
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

                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(Memory.numberFormatter0Digit.format(quantityToMove),
                                          style: TextStyle(
                                            fontSize: fontSizeMedium,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple,
                                          ),),
                                      ),

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


                                            String? result = await openInputDialogWithResult(context, ref, false ,text: lines.toString());
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

        if(!movementAndLines.hasLastLocatorFrom){
            showErrorMessage(context, ref, Messages.ERROR_LOCATOR_FROM);
            return;
        }

        if(!movementAndLines.hasWarehouseFrom){
            showErrorMessage(context, ref, Messages.ERROR_WAREHOUSE_FROM);
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
    Future.delayed(const Duration(microseconds: 100));
    if (!context.mounted) {
      Future.delayed(const Duration(microseconds: 100));
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
    ref.read(isDialogShowedProvider.notifier).state = true;
    setState(() {

    });
    await Future.delayed(Duration(milliseconds: 100));
    TextEditingController quantityController = TextEditingController();
    double qtyOnHand = storageList[index].qtyOnHand ?? 0;
    quantityController.text = Memory.numberFormatter0Digit.format(storageList[index].qtyOnHand);
    if(context.mounted) {
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
      btnOkOnPress: () async {
        ref.read(isDialogShowedProvider.notifier).state = false;
        setState(() {

        });
        await Future.delayed(Duration(milliseconds: 100));
        String quantity = quantityController.text;
        if(quantity.isEmpty){
          String message =  '${Messages.ERROR_QUANTITY} ${Messages.EMPTY}';
          if(context.mounted)showErrorMessage(context, ref, message);
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
        ref.read(isDialogShowedProvider.notifier).state = false;
        setState(() {

        });
      },
      btnCancelColor: Colors.red,
      btnOkText: Messages.OK,
    ).show();
    }
  }

  Widget getMovementInfo(BuildContext context, WidgetRef ref) {

    if(!movementAndLines.hasMovementLines){
      return getMovementCard(context, ref);
    }

    if(locatorTo.id == null || locatorTo.id! <=0)
    {
      return getMovementCard(context, ref);
    }

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: themeColorPrimary,
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
                SizedBox(height: 10,),
                Text('${Messages.FROM} ${Messages.LOCATOR}',style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,),textAlign: TextAlign.start,),
                SizedBox(height: 10,),
                Text('${Messages.TO} ${Messages.LOCATOR}',style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,),textAlign: TextAlign.start,),


              ],
            ),
          ),
          Expanded(
            flex: 2, // Use widthLarge for this column's width
            child: Column(
              spacing: 5,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10,),
                Text(allowedLocatorFrom?.value ?? '',style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,),textAlign: TextAlign.start,),
                SizedBox(height: 10,),
                 isScanning ?
                  LinearProgressIndicator(minHeight: 22,)
                    :Text(locatorTo?.value ?? '',style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,),textAlign: TextAlign.start,),


              ],
            ),
          ),

        ],
      ),
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
              title: Text(allowedLocatorFrom!= null
                  ? allowedLocatorFrom!.value ?? allowedLocatorFrom!.identifier ?? ''
                  : Messages.LOCATOR_FROM,style: TextStyle(
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
      data: (locatorFromFuture) {
        IdempiereLocator locator ;
        if(locatorTo.id == null || locatorTo.id! !=Memory.INITIAL_STATE_ID){
          locator = locatorTo ;
          locatorTo = movementAndLines.lastLocatorTo;
          locatorTo.value ??= locatorTo.identifier;
        } else {
          locator = locatorFromFuture;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) async {
           Future.delayed(const Duration(milliseconds: 50),(){
           });

        });

        return Column(
          children: [
            ListTile(
              leading: GestureDetector(
                onTap: (){

                  Memory.pageFromIndex = ref.read(productsHomeCurrentIndexProvider);
                  ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_NO_REQUERED_SCAN_SCREEN);
                  isLocatorScreenShowed.update((state) => true);
                  ref.read(isDialogShowedProvider.notifier).state = true ;
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return SearchLocatorDialog(
                        searchLocatorFrom :false,
                        forCreateLine: true,
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
              title: Text(locatorTo != null ? locatorTo!.value ??''
                  : locatorTo!.identifier ?? '',style:TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.purple,)),
              trailing:locator.id != null
                  && locator.id! > 0 ?
              Icon(Icons.check_circle,color: Colors.green,) :
              Icon(Icons.error,color: Colors.red,),

            ),
            ListTile(
              leading: GestureDetector(
                onTap: (){
            
                  Memory.pageFromIndex = ref.read(productsHomeCurrentIndexProvider.notifier).state;
                  ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_NO_REQUERED_SCAN_SCREEN);
                  isLocatorScreenShowed.update((state) => true);
                  ref.read(isDialogShowedProvider.notifier).state = true ;
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return SearchLocatorDialog(
                        searchLocatorFrom :false,
                        forCreateLine: true,
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
              title: Text(locatorTo != null ? locatorTo!.value ??''
                  : locatorTo!.identifier ?? '',style:TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.purple,)),
              trailing:locator.id != null
                  && locator.id! > 0 ?
              Icon(Icons.check_circle,color: Colors.green,) :
              Icon(Icons.error,color: Colors.red,),
            
            ),
          ],
        );
      },
      error: (error, stackTrace) {
        return Text(Messages.ERROR,style:TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.bold,
          color: Colors.red,));
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: LinearProgressIndicator(minHeight: 16,),
      ),
    );


  }

  void createMovementLineOnly() {
    int movementId =movementAndLines.id ?? -1;
    if(movementId<=0){
      showErrorMessage(context, ref, Messages.MOVEMENT_ID);
      return ;
    }

    int locatorFrom = allowedLocatorFrom?.id ?? -1;
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
      movementLine.mLocatorID = allowedLocatorFrom ;
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
      if(widget.argument.isNotEmpty){
        m = MovementAndLines.fromJson(jsonDecode(widget.argument));
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
  void showAutoCloseErrorDialog(BuildContext context, WidgetRef ref, String message,int seconds) {
    while (!context.mounted) {
      Future.delayed(const Duration(milliseconds: 500));

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
      autoHide: Duration(seconds: seconds),
      btnOkOnPress: () {},
      btnOkColor: Colors.amber,
      btnCancelText: Messages.CANCEL,
      btnOkText: Messages.OK,
    ).show();
    return;
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




  String getProductId() {
    String productId ='-1';
    if(unsortedStorageList.isNotEmpty){
      IdempiereStorageOnHande storage = unsortedStorageList.first;
      String aux = storage.mProductID?.identifier ?? '-1';
      if(aux.isNotEmpty){
        productId = aux.split('_').first;
      }
    } else if(storageList.isNotEmpty) {
      IdempiereStorageOnHande storage = unsortedStorageList.first;
      String aux = storage.mProductID?.identifier ?? '-1';
      if (aux.isNotEmpty) {
        productId = aux
            .split('_')
            .first;
      }
    }
    return productId;
  }

  void popScopeAction(BuildContext context, WidgetRef ref) {
    FocusScope.of(context).unfocus();
    //String productId = getProductId();
    ref.read(quantityToMoveProvider.notifier).update((state) => 0);
    ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_STORE_ON_HAND);
    ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND);
    String productUPC = widget.storage.mProductID?.identifier ?? '-1';
    productUPC = productUPC.split('_').first;

    print('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/$productUPC');
    context.go('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/$productUPC',
        extra: movementAndLines);

  }

}


