import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/search/product_detail_with_photo_card.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/update_upc/update_product_upc_view.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/product_search_provider.dart';
import '../../providers/products_scan_notifier.dart';
import '../../widget/no_data_card.dart';
import '../../widget/scan_product_barcode_button.dart';
import '../../../../shared/data/data_utils.dart';


class ProductSearchScreen extends ConsumerStatefulWidget {
  int countScannedCamera =0;
  late ProductsScanNotifier productsNotifier ;
  final int actionTypeInt = Memory.ACTION_FIND_BY_UPC_SKU ;

  ProductSearchScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProductSearchScreenState();


}

class _ProductSearchScreenState extends ConsumerState<ProductSearchScreen> {

  @override
  Widget build(BuildContext context){

    final productAsync = ref.watch(findProductByUPCOrSKUProvider);
    widget.productsNotifier = ref.watch(scanStateNotifierProvider.notifier);
    final double width = MediaQuery.of(context).size.width - 30;
    final double bodyHeight = MediaQuery.of(context).size.height - 200;
    final isScanning = ref.watch(isScanningProvider);
    double singleProductDetailCardHeight = Memory.SIZE_PRODUCT_IMAGE_HEIGHT*2+20;
    final usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);

    String imageUrl =Memory.IMAGE_HTTP_SAMPLE_1; // Example image URL
    widget.countScannedCamera = ref.watch(scannedCodeTimesProvider.notifier).state;
    if(widget.countScannedCamera.isEven){
       imageUrl = Memory.IMAGE_HTTP_SAMPLE_2;
    } else {
      imageUrl = Memory.IMAGE_HTTP_SAMPLE_1;
    }
    Color foreGroundProgressBar = Colors.purple;
    //print('Bearer ${Environment.token}');
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          resizeToAvoidBottomInset : false,

          appBar: AppBar(
            leading:IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => {
                FocusScope.of(context).unfocus(),
                context.go(AppRouter.PAGE_HOME)},
            ),
            title: Row(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: Messages.FIND),
                    Tab(text: Messages.UPDATE),
                  ],
                  isScrollable: true,
                  indicatorWeight: 4,
                  indicatorColor: themeColorPrimary,
                  dividerColor: themeColorPrimary,
                  tabAlignment: TabAlignment.start,
                  labelStyle: TextStyle(
                      fontSize: themeFontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: themeColorPrimary),
                  unselectedLabelStyle: TextStyle(fontSize: themeFontSizeLarge),
                ),
                Spacer(),
                IconButton(onPressed: (){
                  if(usePhoneCamera.state){
                    usePhoneCamera.state = false;
                  } else {
                    usePhoneCamera.state = true;

                  }
                }, icon: Icon(usePhoneCamera.state?
                Icons.barcode_reader : Icons.qr_code_scanner , color: Colors.black,)),
              ],
            ),

          ),

          body: TabBarView(

            children: [
              SizedBox(
                height: bodyHeight,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    //spacing: 5,
                    children: [
                        isScanning
                        ? LinearProgressIndicator(
                      backgroundColor: Colors.cyan,
                      color: foreGroundProgressBar,
                      minHeight: 36,
                    )
                        : getSearchBar(context),

                    Container(
                        width: width,
                        height: singleProductDetailCardHeight,
                        margin: EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: productAsync.when(
                          data: (products) {
                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              ref.read(isScanningProvider.notifier).state = false;
                            });
                             return  (products.id != null && products.id! > 0) ?
                             getProductDetailCard(productsNotifier: widget.productsNotifier,
                                 product: products.copyWith(imageURL: imageUrl,uPC: null)) : NoDataCard();

                          },error: (error, stackTrace) => Text('Error: $error'),
                          loading: () =>  LinearProgressIndicator(),
                        ),
                      ),
                      if(isCanEditUPC() )PreferredSize(
                        preferredSize: Size(double.infinity,30),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: (){
                              // ACTUALOZAR UPC
                              FocusScope.of(context).unfocus();
                              DataUtils.saveIdempiereProduct(ref.read(productForUpcUpdateProvider));
                              context.go(AppRouter.PAGE_UPDATE_PRODUCT_UPC);

                            },
                            child: Text(Messages.UPDATE_UPC)),
                      ),),

                      PreferredSize(
                          preferredSize: Size(double.infinity,30),
                          child: SizedBox(width: MediaQuery.of(context).size.width, child:
                          ref.watch(usePhoneCameraToScanProvider) ?_buttonScanWithPhone(context, ref):
                          ScanProductBarcodeButton(widget.productsNotifier, actionTypeInt: widget.actionTypeInt,))),
                    ],
                  ),
                ),
              ),
              // Add more TabBarView children if you have more tabs
              UpdateProductUpcView(),
            ],
          ),
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

          ref.read(scanStateNotifierProvider.notifier).addBarcodeByUPCOrSKUForSearch(result);
        }

      },
      child: Text(Messages.OPEN_CAMERA),
    );
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
          children: [
            SizedBox(width: 5), //spacing: 5 equivalent
            IconButton(onPressed: (){
                if(usePhoneCamera.state){
                  usePhoneCamera.state = false;
                } else {
                  usePhoneCamera.state = true;

                }
            }, icon: Icon(usePhoneCamera.state?
            Icons.qr_code_scanner :Icons.barcode_reader , color: Colors.purple,)),
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
            SizedBox(width: 5), //spacing: 5 equivalent

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

            children: [
              Text(Messages.FIND_PRODUCT_BY_UPC_SKU),
              SizedBox(height: 10), //spacing: 10 equivalent
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
        print('-------------------------result $result');
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
        widget.productsNotifier.addBarcodeByUPCOrSKUForSearch(result);
      },
      btnCancelOnPress: (){
        ref.watch(usePhoneCameraToScanProvider.notifier).state = stateActual;
        return ;
      }
    ).show();

  }
  Widget getProductDetailCard({required ProductsScanNotifier productsNotifier, required product}) {
    switch(widget.actionTypeInt){
      case Memory.ACTION_CALL_UPDATE_PRODUCT_UPC_PAGE:
        return ProductDetailWithPhotoCard(
          product: product,
          actionTypeInt: widget.actionTypeInt,
        );
      default:
        return ProductDetailWithPhotoCard(
          product: product,
          actionTypeInt: widget.actionTypeInt,
        );

    }


  }

  isCanEditUPC() {
    if(ref.read(productForUpcUpdateProvider).id==null || ref.read(productForUpcUpdateProvider).id==0){
      return false ;

    }
    if(ref.read(productForUpcUpdateProvider).uPC==null || ref.read(productForUpcUpdateProvider).uPC=='' ){
       return true;
    }
    return false;

  }

}