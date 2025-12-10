
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';

import '../../../../../../config/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/idempiere/idempiere_warehouse.dart';
import '../movement/provider/products_home_provider.dart';
class UnsortedStorageOnHandReadOnlyScreen extends ConsumerStatefulWidget{

  final IdempiereStorageOnHande storage;
  final int index;
  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  double width;
  String? productUPC ;
  late var notifier;



  UnsortedStorageOnHandReadOnlyScreen({
    required this.index,
    required this.storage,
    required this.width,
    this.productUPC,
    super.key});


  @override
  ConsumerState<UnsortedStorageOnHandReadOnlyScreen> createState() =>UnsortedStorageOnHandReadOnlyScreenState();

 

}

class UnsortedStorageOnHandReadOnlyScreenState extends ConsumerState<UnsortedStorageOnHandReadOnlyScreen> {
  late List<IdempiereStorageOnHande> unsortedStorageList = [];
  late List<IdempiereStorageOnHande> storageList = [];
  late double widthLarge ;
  late double widthSmall ;


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
  bool searched = false ;
  double goToPosition =0.0;
  late String title;
  late String productName;


  @override
  void initState() {


    WidgetsBinding.instance.addPostFrameCallback((_){

    });
    super.initState();

  }

  @override
  Widget build(BuildContext context) {


    widget.width = MediaQuery.of(context).size.width;
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
    String titleAux = widget.storage.mProductID?.identifier ?? '-_-';
    title = titleAux.split('_').first ;
    productName = titleAux.split('_').last ;

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
          
          title: Text(title,style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,),),


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
                        sliver: SliverToBoxAdapter(
                            child: Text(productName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(fontSize: themeFontSizeLarge,color: Colors.purple),)),
                      ),
                      getStockList(context,ref),
                    ]),
              )
          ),
        )
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
    return Container(
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
    ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_STORE_ON_HAND);
    ref.read(actionScanProvider.notifier).state = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;
    Navigator.pop(context);
  

  }

}