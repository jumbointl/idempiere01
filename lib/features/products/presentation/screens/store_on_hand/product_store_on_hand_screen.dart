import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
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
  final int actionTypeInt = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;
  late var allowedLocatorId;
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
  late AsyncValue productsStoredAsync;
  late var resultOfSameWarehouse;
  late var isScanning;

  double? width;
  Warehouse? userWarehouse;
  void popScopeAction(BuildContext context, WidgetRef ref) async {
    print('popScopeAction----------------------------');
    ref.invalidate(homeScreenTitleProvider);
    context.go(AppRouter.PAGE_HOME);
  }

  @override
  void initState() {

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //ref.read(isScanningProvider.notifier).update((state) => false);
      print('-------widget productId ${widget.productId}');
      if(widget.productId!=null && widget.productId!.isNotEmpty && widget.productId!='-1'){
        print('-------widget productId start search ${widget.productId}');
        widget.productsNotifier.addBarcodeByUPCOrSKUForStoreOnHande(widget.productId!);
      }


    });
    super.initState();
  }
  /*void _safeGoHome(BuildContext context) {
    // Cerrar diálogos si hubiera alguno abierto
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);

    // Navegar fuera del ciclo actual (evita deadlocks en Android viejos)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go(AppRouter.PAGE_HOME);
      }
    });
  }*/
  @override
  Widget build(BuildContext context){
    ref.invalidate(persistentLocatorToProvider);
    isDialogShowed = ref.watch(isDialogShowedProvider);
    isScanning = ref.watch(isScanningProvider);
    productAsync = ref.watch(findProductForPutAwayMovementProvider);
    productsStoredAsync = ref.watch(findStoreOnHandForPutAwayMovementProvider);
    widget.productsNotifier = ref.watch(scanHandleNotifierProvider.notifier);
    width = MediaQuery.of(context).size.width - 30;
    resultOfSameWarehouse = ref.watch(resultOfSameWarehouseProvider);
    userWarehouse = ref.read(authProvider).selectedWarehouse;


    final usePhoneCamera = ref.watch(usePhoneCameraToScanProvider);
    scrollToTop = ref.watch(scrollToUpProvider);



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
              IconButton(
              icon: Icon(usePhoneCamera ? Icons.barcode_reader : Icons.camera),
              onPressed: () {
                // 🧠 Riverpod se encarga del rebuild, sin setState
                ref.read(usePhoneCameraToScanProvider.notifier).state = !usePhoneCamera;
                ref.read(isDialogShowedProvider.notifier).state = false;
              },
            ),
        ],

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          double positionAdd=_scrollController.position.maxScrollExtent;
          if(scrollToTop){
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
        child: Icon(scrollToTop ? Icons.arrow_upward :Icons.arrow_downward),
      ),
      bottomNavigationBar: isDialogShowed ? Container(
        height: Memory.BOTTOM_BAR_HEIGHT,
        color: themeColorPrimary,
        child: Center(
          child: Text(Messages.DIALOG_SHOWED,
            style: TextStyle(color: Colors.white,fontSize: themeFontSizeLarge
                ,fontWeight: FontWeight.bold),),
        ),
      ) :getScanButton(context),
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
            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                spacing: 10,
                children: [
                  getSearchBar(context,ref,Messages.FIND_PRODUCT_BY_UPC_SKU,
                      widget.productsNotifier),
                  getDataContainer(context),

              
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buttonScanWithPhone(BuildContext context,WidgetRef ref) {
    bool isScanning = ref.watch(isScanningProvider);
    return TextButton(

      style: TextButton.styleFrom(
        backgroundColor: isScanning ? Colors.grey : themeColorPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),

      ),
      onPressed: isScanning ? null :  () async {
          ref.read(isScanningProvider.notifier).state = true;
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
          if(result!=null){
            print('findProductByUPCOrSKUForStoreOnHandProvider $result');
            widget.productsNotifier.addBarcodeByUPCOrSKUForStoreOnHande(result);
          }
        },
      child: Text(Messages.OPEN_CAMERA,style: TextStyle(fontSize: themeFontSizeLarge,
          color: Colors.white),),

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
        return StorageOnHandCard(
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

  BottomAppBar getScanButton(BuildContext context) {
      return BottomAppBar(
          height: Memory.BOTTOM_BAR_HEIGHT,
          color: themeColorPrimary ,
          child: ref.watch(usePhoneCameraToScanProvider) ?
          buttonScanWithPhone(context, ref) :
          ScanButtonByAction(processor: widget.productsNotifier,
              actionTypeInt: Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND,)
          /*ScanProductBarcodeButton(
             notifier: widget.productsNotifier,
              actionTypeInt: widget.actionTypeInt,pageIndex: widget.pageIndex)*/
      );


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
           resultOfSameWarehouse.update((state) =>  [aux,userWarehouseName]);

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




}