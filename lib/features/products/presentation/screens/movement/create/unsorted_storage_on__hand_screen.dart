
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/constants/roles_app.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/common/input_dialog.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action_fixed_short.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_organization.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/idempiere_locator.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/idempiere_warehouse.dart';
import '../../../../domain/idempiere/put_away_movement.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/locator_provider.dart';
import '../../locator/search_locator_dialog.dart';
import '../provider/products_home_provider.dart';
import '../provider/new_movement_provider.dart';
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
  Future<void> handleInputString({required WidgetRef ref, required String inputData,
    required int actionScan}) async {
    notifier.handleInputString(ref:ref, inputData:inputData,actionScan:actionScan);

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
      final id = locatorFrom?.id ?? -1;
      ref.read(actualLocatorFromProvider.notifier).state = id;
      //ref.read(allowedWarehouseToProvider.notifier).state = 0;
    });
    super.initState();
    putAwayMovement = PutAwayMovement();
    putAwayMovement!.setUser(Memory.sqlUsersData);
    putAwayMovement!.movementLineToCreate!.mProductID = widget.storage.mProductID;
    IdempiereOrganization org = widget.storage.mLocatorID!.aDOrgID!;
    widget.storage.mLocatorID!.mWarehouseID!.aDOrgID = org;
    putAwayMovement!.movementLineToCreate!.mLocatorID = widget.storage.mLocatorID;

    locatorFrom = widget.storage.mLocatorID;

    putAwayMovement!.movementToCreate!.locatorFromId = locatorFrom.id;
    putAwayMovement!.movementToCreate!.mWarehouseID = locatorFrom.mWarehouseID;




  }

  @override
  Widget build(BuildContext context) {

    final allowedMovementDocumentType = ref.read(allowedMovementDocumentTypeProvider);

    print('allowedMovementDocumentType $allowedMovementDocumentType');
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
    final String title = ref.read(movementCreateScreenTitleProvider);

    if (isCardsSelected.isEmpty && storageList.isNotEmpty) {
      isCardsSelected = List<bool>.filled(storageList.length, false);
    }
    final canCreate = RolesApp.canCreateMovementInSameOrganization || RolesApp.canCreateDeliveryNote;
    final canShowBottomBar = ref.watch(canShowCreateLineBottomBarProvider);
    final showScan = ref.watch(showScanFixedButtonProvider(widget.actionScanType));
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
            if(showScan && canCreate) ScanButtonByActionFixedShort(actionTypeInt: widget.actionScanType,
              onOk: widget.handleInputString,),
            if(showScan && canCreate) IconButton(
              icon: const Icon(Icons.keyboard,color: Colors.purple),
              onPressed: () => {
                openInputDialogWithAction(ref: ref, history: false, actionScan: widget.actionScanType,
                    onOk: widget.handleInputString)
              },
            ),

          ],
          title: Text(title,style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,),),


        ),
        bottomNavigationBar: canShowBottomBar ? bottomAppBar(context, ref): null,

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
                      if(canCreate)SliverToBoxAdapter(child: getMovementCard(context, ref)),
                      if(canCreate)SliverPadding(
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

                      if(canCreate)SliverPadding(
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
      height: 70,
      color: themeColorPrimary,
      child: ConfirmationSlider(
          height: 45,
          backgroundColor: Colors.green[100]!,
          backgroundColorEnd: Colors.green[800]!,
          foregroundColor: Colors.green,
          text: Messages.SLIDE_TO_CREATE,
          textStyle: TextStyle(fontSize: themeFontSizeLarge, color: Colors.purple,fontWeight: FontWeight.bold),
          onConfirmation: () {
            print('----------------------------ConfirmationSlide');
            final allowedDocumentType = ref.read(allowedMovementDocumentTypeProvider);
            if(allowedDocumentType!=Memory.MM_ELECTRONIC_DELIVERY_NOTE_ID &&
                allowedDocumentType!=Memory.NO_MM_ELECTRONIC_DELIVERY_NOTE_ID){
              showErrorMessage(context, ref, '${Messages.ERROR_DOCUMENT_TYPE} : $allowedDocumentType');
              return;

            }
            print('allowedDocumentType--to create----------$allowedDocumentType');


            if (putAwayMovement!=null && putAwayMovement!.movementLineToCreate!=null) {
              putAwayMovement!.movementLineToCreate!.movementQty = ref.read(quantityToMoveProvider);
              widget.notifier.prepareToCreatePutawayMovement(ref, putAwayMovement);
            } else {
              showErrorMessage(context, ref, Messages.MOVEMENT_ALREADY_CREATED);

            }
          }

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
        getDoubleDialog(ref:  ref, quantity:  qtyOnHand ?? 0,
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


  Widget getMovementCard(BuildContext context, WidgetRef ref) {

    // 👇 Provider recebe o locatorFrom fixo
    final color       = ref.watch(movementColorProvider(locatorFrom));


    return Container(
      decoration: BoxDecoration(
        color: color,
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
    print('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/$productUPC');
    context.go('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/$productUPC');

  }

}


// Clasecita interna solo para organizar datos de los botones
