import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:input_dialog/input_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../auth/domain/entities/warehouse.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../providers/idempiere_products_notifier.dart';
import '../providers/product_screen_provider.dart';
import '../widget/no_data_card.dart';
import '../widget/product_detail_card.dart';
import '../widget/product_resume_card.dart';
import '../widget/scan_product_barcode_button.dart';
import '../widget/storage_on__hand_card.dart';


class ProductScreen extends ConsumerStatefulWidget {
  int countScannedCamera =0;
  late IdempiereScanNotifier productsNotifier ;

  ProductScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProductScreenState();

}

class _ProductScreenState extends ConsumerState<ProductScreen> {

  @override
  Widget build(BuildContext context){
    final productAsync = ref.watch(findProductByUPCProvider);
    final productsStoredAsync = ref.watch(findProductsStoreOnHandProvider);
    widget.productsNotifier = ref.watch(scanStateNotifierProvider.notifier);
    final double width = MediaQuery.of(context).size.width - 30;
    final resultOfSameWarehouse = ref.watch(resultOfSameWarehouseProvider.notifier);
    Warehouse? userWarehouse = ref.read(authProvider).selectedWarehouse;
    int userWarehouseId = userWarehouse?.id ?? 0;
    String userWarehouseName = userWarehouse?.name ?? '';
    final isScanning = ref.watch(isScanningProvider);
    final usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    //print('Bearer ${Environment.token}');
    return Scaffold(


      appBar: AppBar(
        title: Text(Messages.PRODUCT),
          actions: [

            usePhoneCamera.state ? IconButton(
              icon: const Icon(Icons.barcode_reader),
              onPressed: () => { usePhoneCamera.state = false},
            ) :  IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => { usePhoneCamera.state = true},

          ),

        ],

      ),

      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 5,
          children: [
              isScanning
              ? LinearProgressIndicator(
            backgroundColor: Colors.cyan,
            color: Colors.purple,
            minHeight: 36,
          )
              : getSearchBar(context),

          Container(
            width: MediaQuery.of(context).size.width - 30,
            margin: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: productAsync.when(
              data: (product) => (product.id != null && product.id! > 0) ? ProductDetailCard(product) : const NoDataCard(),
              error: (error, stackTrace) => Text('Error: $error'),
              loading: () => Container(),
            ),
          ),
            Expanded(
                child: productsStoredAsync.when(
                  data: (storages) {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      // deley 1 secund


                      double quantity = 0;
                      for (var data in storages) {
                        int warehouseID = data.mLocatorID?.mWarehouseID?.id ?? 0;

                        if (warehouseID == userWarehouseId) {
                          quantity += data.qtyOnHand ?? 0;
                        }
                      }

                      String aux = Memory.numberFormatter0Digit.format(quantity);
                      resultOfSameWarehouse.update((state) =>  [aux,userWarehouseName]);
                      if(storages.isNotEmpty){
                        ref.read(showResultCardProvider.notifier).state = true;
                      } else {
                        ref.read(showResultCardProvider.notifier).state = false;
                      }
                      await Future.delayed(Duration(milliseconds: Memory.DELAY_TO_REFRESH_PROVIDER_MILLISECOND));

                      ref.watch(isScanningProvider.notifier).update((state) => false);
                    });
                    return getStoragesOnHand(storages, width);
                  },
                  error: (error, stackTrace) => Text('Error: $error'),
                  loading: () => const LinearProgressIndicator(),
                )),

            PreferredSize(
                preferredSize: Size(double.infinity,30),
                child: SizedBox(width: MediaQuery.of(context).size.width, child:
                ref.watch(usePhoneCameraToScanProvider) ?_buttonScanWithPhone(context, ref): ScanProductBarcodeButton(widget.productsNotifier))),
          ],
        ),
      ),
    );
  }

  Widget _buttonScanWithPhone(BuildContext context,WidgetRef ref) {
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

          ref.read(scanStateNotifierProvider.notifier).addBarcode(result);
          //ref.read(scannedCodeProvider.notifier).state = result;
        }

      },
      child: Text(Messages.OPEN_CAMERA),
    );
  }

  Widget getStoragesOnHand(List<IdempiereStorageOnHande> storages, double width) {
    bool isScanning = ref.watch(isScanningProvider);
    bool showResultCard = ref.watch(showResultCardProvider);

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
        isScanning? Container() : storages.isEmpty
            ? Container()
            : Expanded(
              child: ListView.builder(
                        itemCount: storages.length,
                        padding: const EdgeInsets.all(10),
                        itemBuilder: (context, index) {
              final product = storages[index];
              return StorageOnHandCard(product, index + 1, storages.length, width: width - 10);
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
            IconButton(onPressed: null, icon: Icon(usePhoneCamera.state?
            Icons.qr_code_scanner : Icons.barcode_reader, color: Colors.purple,)),
            Expanded(
              child: Text(
                Messages.FIND_PRODUCT_BY_UPC_SKU,
                textAlign: TextAlign.center,
              ),
            ) ,
            IconButton(onPressed:() async {getBarCode(context);},
              icon: Icon( Icons.search, color:isScanning?Colors.grey: Colors.purple,)),

          ],
        ),
      );

  }
  Future<void> getBarCode(BuildContext context) async {
    bool stateActual = ref.watch(usePhoneCameraToScanProvider.notifier).state;
    ref.watch(usePhoneCameraToScanProvider.notifier).state = true;
    final result = await InputDialog.show(
      context: context,
      title: Messages.FIND_PRODUCT_BY_UPC_SKU,
      cancelText: Messages.CANCEL,
      okText: Messages.OK,
    );
    ref.watch(usePhoneCameraToScanProvider.notifier).state = stateActual;
    if(result!=null){
      print(result);
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
          btnOkOnPress: () {},
          btnOkColor: Colors.amber,
        ).show();
        return;
      }
      widget.productsNotifier.addBarcode(result);
    }
  }


}