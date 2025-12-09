import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_records_card.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../home/presentation/screens/home_screen.dart';
import '../../../common/input_dialog.dart';
import '../../../common/scan_button_by_action_fixed_short.dart';
import '../../providers/common_provider.dart';
import '../../providers/persitent_provider.dart';
import '../../../../auth/domain/entities/warehouse.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/products_scan_notifier.dart';
import '../../providers/store_on_hand_for_put_away_movement.dart';
import '../../providers/store_on_hand_provider.dart';
import '../../widget/no_data_card.dart';
import 'product_detail_card.dart';
import 'product_resume_card.dart';
import 'storage_on__hand_card.dart';


class ProductStoreOnHandScreen extends ConsumerStatefulWidget {


  int countScannedCamera =0;
  late ProductsScanNotifier productsNotifier ;
  final int actionScanType = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;
  final int pageIndex = Memory.PAGE_INDEX_STORE_ON_HAND;
  String? productId;
  bool isMovementSearchedShowed = false;
  ProductStoreOnHandScreen({this.productId,super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => ProductStoreOnHandScreenState();

}

class ProductStoreOnHandScreenState extends ConsumerState<ProductStoreOnHandScreen> {
  IdempiereMovement? movement ;
  Color colorBackgroundHasMovementId = Colors.cyan[200]!;
  Color colorBackgroundNoMovementId = Colors.white;

  int sameLocator = 0;
  final ScrollController _scrollController = ScrollController();
  late var scrollToTop  ;
  double goToPosition =0.0;
  late var isDialogShowed;
  late AsyncValue productAsync ;
  late var resultOfSameWarehouse;
  late var isScanning;
  late var showScan;

  double? width;
  Warehouse? userWarehouse;

   String productUPC ='-1';
  void popScopeAction(BuildContext context, WidgetRef ref) async {
    ref.invalidate(homeScreenTitleProvider);
    context.go(AppRouter.PAGE_HOME);
  }

  @override
  void initState() {

    WidgetsBinding.instance.addPostFrameCallback((_) async {

      actionAfterShow(ref);


    });
    super.initState();
  }
  @override
  Widget build(BuildContext context){
    ref.invalidate(persistentLocatorToProvider);
    isDialogShowed = ref.watch(isDialogShowedProvider);
    isScanning = ref.watch(isScanningProvider);
    productAsync = ref.watch(findProductForPutAwayMovementProvider);
    widget.productsNotifier = ref.watch(scanHandleNotifierProvider.notifier);
    width = MediaQuery.of(context).size.width - 30;
    resultOfSameWarehouse = ref.watch(resultOfSameWarehouseProvider);
    userWarehouse = ref.read(authProvider).selectedWarehouse;
    scrollToTop = ref.watch(scrollToUpProvider);
    final showScan = ref.watch(showScanFixedButtonProvider(widget.actionScanType));


    return Scaffold(

      appBar: AppBar(
        backgroundColor: colorBackgroundNoMovementId,
        automaticallyImplyLeading: true,
        leading:IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async =>
          {
            print('iconBackPressed----------------------------'),
            popScopeAction(context, ref),
          }
            //
        ),

        title: Text(Messages.PRODUCT),
          actions: [
            if(showScan) ScanButtonByActionFixedShort(
              actionTypeInt: widget.actionScanType,
              onOk: widget.productsNotifier.handleInputString,),
            IconButton(
              icon: const Icon(Icons.keyboard,color: Colors.purple),
              onPressed: () => {
                openInputDialogWithAction(ref: ref, history: false,
                    onOk: widget.productsNotifier.handleInputString,
                    actionScan:  widget.actionScanType)
              },
            ),
        ],

      ),
      body: SafeArea(
        child: PopScope(
          canPop: false, // el back físico no hace pop automático
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) {
              // Si por alguna razón ya poppeó, no hagas nada.
              return;
            }
            popScopeAction(context, ref);

          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
            child: SingleChildScrollView(
              child: getDataContainer(context),
            ),
          ),
        ),
      ),
    );
  }



  Widget getStoragesOnHand(List<IdempiereStorageOnHande>? storages, double width) {

    if(storages== null || storages.isEmpty){
      return isScanning ? Text(Messages.PLEASE_WAIT)
          : Container(
            width: width,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(10),
            ),
            //child: ProductResumeCard(storages,width-10)
            child: NoRecordsCard(width: width),
      );
    }
    int length = storages.length;
    int add =1 ;

    return ListView.separated(
      controller: _scrollController,
      shrinkWrap: true,
      itemCount: length+add,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
              width: width,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: ProductResumeCard(storages, width));
        }
        return getStorageOnHandCard(
            widget.productsNotifier,
            storages[index - add],
            index + 1 - add,
            storages.length,
            width: width - 10,
          );
        },
      );

  }
  Future<void> getBarCode(BuildContext context, bool history) async{
    TextEditingController controller = TextEditingController();
    if(history){
      String lastSearch = Memory.lastSearch;
      if(lastSearch.isEmpty){
        controller.text = Messages.NO_RECORDS_FOUND;
      } else {
        controller.text = lastSearch;
      }

    }
    AwesomeDialog(
      context: context,
      headerAnimationLoop: false,
      dialogType: DialogType.noHeader,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Center(
          child: Column(
            spacing: 10,
            children: [
              Text(Messages.FIND_PRODUCT_BY_UPC_SKU),
              TextField(
                controller: controller,
                style: const TextStyle(fontStyle: FontStyle.italic),
                keyboardType: TextInputType.text,
              ),
            ],
          ),
        ),
      ),
      title: Messages.FIND_PRODUCT_BY_UPC_SKU,
      desc: Messages.FIND_PRODUCT_BY_UPC_SKU,
      btnCancelText: Messages.CANCEL,
      btnOkText: Messages.OK,
      btnOkOnPress: () async {
        isDialogShowed = false;
        setState(() {});

        final result = controller.text;
        if(result==''){
          showErrorMessage(context, ref, Messages.ERROR_UPC_EMPTY);
          return;
        }
        print('findProductByUPCOrSKUForStoreOnHandProvider $result');
        widget.productsNotifier.addBarcodeByUPCOrSKUForStoreOnHande(result);
      },
      btnCancelOnPress: (){
        isDialogShowed = false;
        setState(() {});
        return ;
      }
    ).show();

  }

  Widget getProductDetails(List<IdempiereProduct> products, double width) {

    return SliverList.separated(
        separatorBuilder: (context, index) => SizedBox(height: 5,),
        itemCount: products.length,
        itemBuilder: (context, index) => ProductDetailCard(
            productsNotifier: widget.productsNotifier, product: products[index]));

  }

  Widget getDataContainer(BuildContext context) {
     return  productAsync.when(
       data: (result) {
         if(result==null || !result.searched){
           return NoDataCard();
         }
         final double width = MediaQuery.of(context).size.width - 30;

         WidgetsBinding.instance.addPostFrameCallback((_) async {
           //ref.read(isScanningProvider.notifier).update((state) => false);
           //ref.read(productIdForPutAwayMovementProvider.notifier) = products[0].id!;
           int userWarehouseId = userWarehouse?.id ?? 0;
           String userWarehouseName = userWarehouse?.name ?? '';
           double quantity = 0;

           for (var data in result.sortedStorageOnHande) {
             int warehouseID = data.mLocatorID?.mWarehouseID?.id ?? 0;

             if (warehouseID == userWarehouseId) {
               quantity += data.qtyOnHand ?? 0;
             }
           }

           String aux = Memory.numberFormatter0Digit.format(quantity);
           ref.read(resultOfSameWarehouseProvider.notifier).update((state) =>  [aux,userWarehouseName]);

         });
         MemoryProducts.productWithStock = result;
         return Column(
           spacing: 10,
           children: [
             ProductDetailCard(
               productsNotifier: widget.productsNotifier, product: result),
             getStoragesOnHand(result.sortedStorageOnHande, width),
           ],
         );
       },error: (error, stackTrace) => Text('Error: $error'),
       loading: () => const LinearProgressIndicator(),
     );


  }

  void actionAfterShow(WidgetRef ref) {
    //ref.read(isScanningProvider.notifier).update((state) => false);
    if(widget.productId!=null && widget.productId!.isNotEmpty && widget.productId!='-1'){
      print('-------widget productId start search ${widget.productId}');
      widget.productsNotifier.addBarcodeByUPCOrSKUForStoreOnHande(widget.productId!);
    }
  }

  Widget getStorageOnHandCard(ProductsScanNotifier productsNotifier,
      IdempiereStorageOnHande storage,
      int index, int length, {required double width}) {
    return StorageOnHandCard(productsNotifier,storage, index, length, width: width,);



  }


}