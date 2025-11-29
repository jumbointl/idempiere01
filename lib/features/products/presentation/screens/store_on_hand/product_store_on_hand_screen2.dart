import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_records_card.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../auth/domain/entities/warehouse.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/products_scan_notifier.dart';
import '../../providers/store_on_hand_provider.dart';
import '../../widget/no_data_card.dart';
import 'product_detail_card.dart';
import 'product_resume_card.dart';
import '../../widget/scan_product_barcode_button.dart';
import 'storage_on__hand_card.dart';


class ProductStoreOnHandScreen2 extends ConsumerStatefulWidget {


  int countScannedCamera =0;
  late ProductsScanNotifier productsNotifier ;
  final int actionTypeInt = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND ;
  late var allowedLocatorId;
  final int pageIndex = Memory.PAGE_INDEX_STORE_ON_HAND_2;

  ProductStoreOnHandScreen2({super.key,});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => ProductStoreOnHandScreenState2();


}

class ProductStoreOnHandScreenState2 extends ConsumerState<ProductStoreOnHandScreen2> {


  @override
  Widget build(BuildContext context){
    final productAsync = ref.watch(findProductByUPCOrSKUForStoreOnHandProvider);
    final productsStoredAsync = ref.watch(findProductsStoreOnHandProvider);
    widget.productsNotifier = ref.watch(scanHandleNotifierProvider.notifier);
    final double width = MediaQuery.of(context).size.width - 30;
    final double bodyHeight = MediaQuery.of(context).size.height - 200;
    final resultOfSameWarehouse = ref.watch(resultOfSameWarehouseProvider.notifier);
    Warehouse? userWarehouse = ref.read(authProvider).selectedWarehouse;
    int userWarehouseId = userWarehouse?.id ?? 0;
    String userWarehouseName = userWarehouse?.name ?? '';
    final isScanning = ref.watch(isScanningProvider);
    final usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    final searchByMOLIConfigurableSKU = ref.watch(searchByMOLIConfigurableSKUProvider.notifier);
    final double singleProductDetailCardHeight = 145;
    Color foreGroundProgressBar = Colors.purple;
    if(searchByMOLIConfigurableSKU.state){
      foreGroundProgressBar = Colors.amber[600]!;
    } else {
      foreGroundProgressBar = Colors.purple;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(isScanningProvider.notifier).update((state) => false);
    });
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading:IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
          {
            context.go(AppRouter.PAGE_HOME),
          },
        ),
        title: Text(Messages.PRODUCT),
          actions: [

            usePhoneCamera.state ? IconButton(
              icon: const Icon(Icons.barcode_reader),
              onPressed: () => {
              ref.watch(isDialogShowedProvider.notifier).state = false,
                usePhoneCamera.state = false},
            ) :  IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => {
            ref.watch(isDialogShowedProvider.notifier).state = false,
              usePhoneCamera.state = true},

          ),

        ],

      ),

      body: PopScope(
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {

            return;
          }
          context.go(AppRouter.PAGE_HOME);
        },
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 5,
            children: [
                isScanning
                ? LinearProgressIndicator(
              backgroundColor: Colors.cyan,
              color: foreGroundProgressBar,
              minHeight: 36,
            )
                : getSearchBar(context),

            SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width - 30,
                height: productAsync.when(
                    data: (products) => products.length <= 1 ? singleProductDetailCardHeight : bodyHeight,
                    error: (error, stackTrace) => singleProductDetailCardHeight,
                    loading: () => singleProductDetailCardHeight),
                margin: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: productAsync.when(
                  data: (products) {
                     return products.length ==1 ? (products[0].id != null && products[0].id! > 0) ?
                      ProductDetailCard(productsNotifier: widget.productsNotifier, product: products[0]) : NoDataCard()
                       : ListView.separated(
                      separatorBuilder: (context, index) => SizedBox(height: 5,),
                      shrinkWrap: true, // Important to prevent unbounded height
                      itemCount: products.length,
                      itemBuilder: (context, index) => ProductDetailCard(productsNotifier: widget.productsNotifier, product: products[index]),
                    );
                  },error: (error, stackTrace) => Text('Error: $error'),
                  loading: () => Container(),
                ),
              ),
            ),
              Expanded(
                  child: productsStoredAsync.when(
                    data: (storages) {
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        // deley 1 secund
                        if(storages.isEmpty){
                          return ;
                        }

                        double quantity = 0;
                        for (var data in storages) {
                          int warehouseID = data.mLocatorID?.mWarehouseID?.id ?? 0;

                          if (warehouseID == userWarehouseId) {
                            quantity += data.qtyOnHand ?? 0;
                          }
                        }

                        String aux = Memory.numberFormatter0Digit.format(quantity);
                        resultOfSameWarehouse.update((state) =>  [aux,userWarehouseName]);
                        if(ref.read(searchByMOLIConfigurableSKUProvider.notifier).state){
                          ref.read(showResultCardProvider.notifier).state = false;
                        } else {
                          final productAsync = ref.watch(findProductByUPCOrSKUForStoreOnHandProvider);
                          productAsync.when(
                              data: (products) {
                                if(products.isNotEmpty && products[0].id != null && products[0].id! > 0){
                                  ref.watch(showResultCardProvider.notifier).update((state) => true);
                                } else {
                                  ref.watch(showResultCardProvider.notifier).update((state) => false);
                                }
                              },
                              error: (error, stackTrace) => {ref.watch(showResultCardProvider.notifier).update((state) => false)},
                              loading: () => {ref.watch(showResultCardProvider.notifier).update((state) => false)}
                          );
                          //ref.watch(isScanningProvider.notifier).update((state) => false);
                        }
                        //await Future.delayed(Duration(milliseconds: Memory.DELAY_TO_REFRESH_PROVIDER_MILLISECOND));



                      });
                      return getStoragesOnHand(storages, width);
                    },
                    error: (error, stackTrace) => Text('Error: $error'),
                    loading: () => const LinearProgressIndicator(),
                  )),
              //getScanButton(context),

            ],
          ),
        ),
      ),
    );
  }

  Widget buttonScanWithPhone(BuildContext context,WidgetRef ref) {
    bool isScanning = ref.watch(isScanningProvider);
    return TextButton(

      style: TextButton.styleFrom(
        backgroundColor: isScanning ? Colors.grey : Colors.cyan[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),

      ),
      onPressed: isScanning ? null :  () async {
        ref.watch(isScanningProvider.notifier).state = true;

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

          ref.read(scanHandleNotifierProvider.notifier).addBarcodeByUPCOrSKUForStoreOnHande(result);
          //ref.read(scannedCodeProvider.notifier).state = result;
        }

      },
      child: Text(Messages.OPEN_CAMERA),
    );
  }

  Widget getStoragesOnHand(List<IdempiereStorageOnHande> storages, double width) {
    bool isScanning = ref.watch(isScanningProvider);
    bool showResultCard = ref.watch(showResultCardProvider);
    if(!showResultCard){
      return Container();
    }

    if(storages.isEmpty){
      return isScanning ?Container(): Container(
          width: MediaQuery.of(context).size.width - 30,
          margin: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          //child: ProductResumeCard(storages,width-10)
          child: NoRecordsCard(width:width-10)

      );
    }

    return Column(
      children: [
        isScanning ?Container(): Container(
            width: MediaQuery.of(context).size.width - 30,
            margin: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: showResultCard ? ProductResumeCard(storages,width-10) : Container()
            //child: ProductResumeCard(storages,width-10)

        ),
        isScanning? Container() :
             Expanded(
              child: ListView.builder(
                        itemCount: storages.length,
                        padding: const EdgeInsets.all(10),
                        itemBuilder: (context, index) {
              final product = storages[index];
              return StorageOnHandCard(widget.productsNotifier, product, index + 1,
                  storages.length, width: width - 10,);
                        },
                      ),
            ),
      ],
    ) ;


  }
  Widget getSearchBar(BuildContext context){
    var isScanning = ref.watch(isScanningProvider);
    var usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    return
      SizedBox(
        //width: double.infinity,
        width: MediaQuery.of(context).size.width - 30,
        height: 36,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 5,
          children: [
            IconButton(onPressed: (){
              ref.watch(isDialogShowedProvider.notifier).state = false;
            }, icon: Icon(usePhoneCamera.state?
            Icons.qr_code_scanner : Icons.barcode_reader, color:
            ref.watch(isDialogShowedProvider.notifier).state? Colors.red : Colors.purple,)),
            Expanded(
              child: Text(
                Messages.FIND_PRODUCT_BY_UPC_SKU,
                textAlign: TextAlign.center,
              ),
            ) ,
            IconButton(onPressed:() async {getBarCode(context,false);},
              icon: Icon( Icons.search, color:isScanning?Colors.grey: Colors.purple,)),
            IconButton(onPressed:() async {getBarCode(context,true);},
                icon: Icon( Icons.history, color:isScanning?Colors.grey: Colors.purple,)),

          ],
        ),
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
    bool stateActual = ref.watch(usePhoneCameraToScanProvider.notifier).state;
    ref.watch(usePhoneCameraToScanProvider.notifier).state = true;
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
      btnOkOnPress: () {
        ref.watch(usePhoneCameraToScanProvider.notifier).state = stateActual;
        final result = controller.text;
        if(result==''){
          AwesomeDialog(
            context: context,
            animType: AnimType.scale,
            dialogType: DialogType.error,
            body: Center(child: Text(
              Messages.ERROR_UPC_EMPTY,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),), // correct here
            title: Messages.ERROR_UPC_EMPTY,
            desc:   '',
            autoHide: const Duration(seconds: 3),
            btnOkOnPress: () {},
            btnOkColor: Colors.amber,
            btnCancelText: Messages.CANCEL,
            btnOkText: Messages.OK,
          ).show();
          return;
        }
        widget.productsNotifier.addBarcodeByUPCOrSKUForStoreOnHande(result);
      },
      btnCancelOnPress: (){
        ref.watch(usePhoneCameraToScanProvider.notifier).state = stateActual;
        return ;
      }
    ).show();

  }

  Widget getScanButton(BuildContext context) {

      return PreferredSize(
          preferredSize: Size(double.infinity,30),
          child: SizedBox(width: MediaQuery.of(context).size.width, child:
          ref.watch(isDialogShowedProvider)? Container() :
          ref.watch(usePhoneCameraToScanProvider) ?buttonScanWithPhone(context, ref):
          //ScanBarcodeMultipurposeButton(widget.productsNotifier)));
          ScanProductBarcodeButton(
              notifier: widget.productsNotifier,
              actionTypeInt: widget.actionTypeInt,pageIndex: widget.pageIndex),
          ));

  }




}