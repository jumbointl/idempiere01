import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../auth/domain/entities/warehouse.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../providers/idempiere_products_notifier.dart';
import '../providers/product_screen_provider.dart';
import '../widget/no_data_card.dart';
import '../widget/product_detail_card.dart';
import '../widget/scan_product_barcode_button.dart';
import '../widget/storage_on__hand_card.dart';


class ProductScreen2 extends ConsumerStatefulWidget {
  int countScannedCamera =0;
  late IdempiereScanNotifier productsNotifier ;

  ProductScreen2({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProductScreenState();

}

class _ProductScreenState extends ConsumerState<ProductScreen2> {


  @override
  Widget build(BuildContext context){
    final productAsync = ref.watch(findProductByUPCProvider);
    final productsStoredAsync = ref.watch(findProductsStoreOnHandProvider);
    widget.productsNotifier = ref.watch(scanStateNotifierProvider.notifier);
    final double width = MediaQuery.of(context).size.width - 30;
    //print('Bearer ${Environment.token}');
    return Scaffold(


      appBar: AppBar(
        title: Text(Messages.PRODUCT),
          actions: [

            ref.watch(usePhoneCameraToScanProvider.notifier).state ? IconButton(
              icon: const Icon(Icons.barcode_reader),
              onPressed: () => { ref.watch(usePhoneCameraToScanProvider.notifier).state = false},
            ) :  IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => { ref.watch(usePhoneCameraToScanProvider.notifier).state = true},

          ),

        ],

      ),

      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 5,
          children: [
              ref.watch(isScanningProvider)
              ? LinearProgressIndicator(
            backgroundColor: Colors.cyan,
            color: Colors.purple,
            minHeight: 36,
          )
              : Container(
            width: double.infinity,
            height: 36,
            color:  ref.watch(isScanningProvider)? Colors.grey[200] :  Colors.green[400],
            child: IconButton(onPressed: null, icon: ref.watch(usePhoneCameraToScanProvider.notifier).state?
            Icon(Icons.qr_code_scanner) : Icon(Icons.barcode_reader)),
          ),

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
            /*ref.watch(isScanningProvider) ?Container(): Container(
              width: MediaQuery.of(context).size.width - 30,
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: ref.watch(showResultCardProvider.notifier).state ? ProductResumeCard(width-10) : Container() ,
            ),*/

            Expanded(
                child: productsStoredAsync.when(
              data: (storages) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  // deley 1 secund

                  Warehouse? w = ref.read(authProvider).selectedWarehouse;
                  int warehouseUser = w?.id ?? 0;
                  String warehouseName = w?.name ?? '';
                  double quantity = 0;
                  for (var data in storages) {
                    int warehouseID = data.mLocatorID?.mWarehouseID?.id ?? 0;

                    if (warehouseID == warehouseUser) {
                      quantity += data.qtyOnHand ?? 0;
                    }
                  }

                  String aux = Memory.numberFormatter0Digit.format(quantity);
                  ref.read(resultOfSameWarehouseProvider.notifier).state = [aux,warehouseName];

                  if(storages.isNotEmpty){
                    ref.read(showResultCardProvider.notifier).state = true;
                  } else {
                    ref.read(showResultCardProvider.notifier).state = false;
                  }
                  await Future.delayed(Duration(milliseconds: Memory.DELAY_TO_REFRESH_PROVIDER_MILLISECOND));

                  ref.watch(isScanningProvider.notifier).update((state) => false);
                });
                return storages.isEmpty
                    ? Container()
                    : ListView.builder(
                        itemCount: storages.length,
                        padding: const EdgeInsets.all(10),
                        itemBuilder: (context, index) {
                          final product = storages[index];
                          return StorageOnHandCard(product, index + 1, storages.length, width: width - 10);
                        },
                      );
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
    return TextButton(

      style: TextButton.styleFrom(
        backgroundColor: ref.watch(isScanningProvider) ? Colors.grey : Colors.cyan[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),

      ),
      onPressed: ref.watch(isScanningProvider) ? null :  () async {
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


}