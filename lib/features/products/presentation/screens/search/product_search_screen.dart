import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/search/product_detail_with_photo_card.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/update_upc/update_product_upc_screen3.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/update_upc/update_product_upc_view.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/common/scan_button.dart';
import '../../../../shared/common/scanner.dart';
import '../movement/products_home_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/product_search_provider.dart';
import '../../providers/products_scan_notifier.dart';
import '../../widget/no_data_card.dart';
import '../../widget/scan_product_barcode_button.dart';


class ProductSearchScreen extends ConsumerStatefulWidget implements Scanner {
  int countScannedCamera =0;
  late ProductsScanNotifier productsNotifier ;
  final int actionTypeInt = Memory.ACTION_FIND_BY_UPC_SKU ;
  int scanAction = ScanButton.SCAN_TO_SEARCH;
  late bool usePhoneCamera = false;
  late int pageIndex = Memory.PAGE_INDEX_SEARCH;

  ProductSearchScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProductSearchScreenState();

  @override
  void inputFromScanner(String scannedData) {
    // TODO: implement inputFromScanner
  }

  @override
  void scanButtonPressed(BuildContext context, WidgetRef ref) {
    ref.read(usePhoneCameraToScanProvider.notifier).update((state) => !state);
  }


}

class _ProductSearchScreenState extends ConsumerState<ProductSearchScreen> {
  @override
  void initState() {
    widget.usePhoneCamera = ref.read(usePhoneCameraToScanProvider.notifier).state;
    super.initState();
  }
  @override
  Widget build(BuildContext context){
    widget.pageIndex = ref.read(productsHomeCurrentIndexProvider.notifier).state;
    final productAsync = ref.watch(findProductByUPCOrSKUProvider);
    widget.productsNotifier = ref.watch(scanHandleNotifierProvider.notifier);
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          resizeToAvoidBottomInset : false,

          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading:IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => {
                FocusScope.of(context).unfocus(),
                //ref.read(productsHomeCurrentIndexProvider.notifier).state = 0,

                context.go(AppRouter.PAGE_HOME)},
            ),
            title: Row(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: Messages.FIND),
                    Tab(text: Messages.IMAGE),
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

                /*usePhoneCamera.state ? UnfocusedScanButton(scanner: widget) :
                    ScanButton(notifier: widget.productsNotifier, scanner: widget,scanAction: widget.scanAction,),
                */

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
          bottomNavigationBar: BottomAppBar(
            color: themeColorPrimary,
            height: Memory.BOTTOM_BAR_HEIGHT,
            child: getScanButton(context),
          ),
          body: PopScope(
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              if (didPop) {
                return;
              }
              ref.read(usePhoneCameraToScanProvider.notifier).state = widget.usePhoneCamera;
              context.go(AppRouter.PAGE_HOME);
              Navigator.pop(context);
            },
            child: TabBarView(

              children: [

                SizedBox(
                  height: bodyHeight,
                  child: ListView.separated(
                    itemCount: 6, // Adjust the number of items as needed
                    separatorBuilder: (context, index) => SizedBox(height: 5), // Spacing between items
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        //return getScanButton(context);
                        return Container();
                      } else if (index == 1) {
                        return isScanning
                            ? LinearProgressIndicator(
                          backgroundColor: Colors.cyan,
                          color: foreGroundProgressBar,
                          minHeight: 36,
                        )
                            : getSearchBar(context);
                      }
                      else if (index == 2) {
                        return Container(
                            width: width,
                            //height: singleProductDetailCardHeight,
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
                          );
                      } else if (index == 3) {
                        return isCanEditUPC() ? Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: (){
                                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => UpdateProductUpcScreen3()));
                                },
                                child: Text(Messages.UPDATE_UPC)),
                          )): Container();
                      } else if (index == 4) {
                        return SizedBox(height: 40);
                      }

                      /*else if (index == 5) {
                        return ref.watch(usePhoneCameraToScanProvider) ?_buttonScanWithPhone(context, ref):
                               Container() ;
                      }*/

                      return SizedBox.shrink(); // Should not happen with proper itemCount
                    },

                  ),
                ),
                // Add more TabBarView children if you have more tabs
                UpdateProductUpcView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buttonScanWithPhone(BuildContext context,WidgetRef ref) {
    bool isScanning = ref.watch(isScanningProvider);
    return GestureDetector(
      onTap: isScanning ? null :  () async {
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

          ref.read(scanHandleNotifierProvider.notifier).addBarcodeByUPCOrSKUForSearch(result);
        }

      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          Icon(Icons.camera, color: isScanning ? Colors.grey : Colors.white),
          Text(Messages.OPEN_CAMERA,style: TextStyle(color: Colors.white,
              fontSize: themeFontSizeLarge,),
              ),
        ],
      ));
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

  bool isCanEditUPC() {
    if(ref.read(productForUpcUpdateProvider).id==null || ref.read(productForUpcUpdateProvider).id==0){
      return false ;

    }
    if(ref.read(productForUpcUpdateProvider).uPC==null || ref.read(productForUpcUpdateProvider).uPC=='' ){
       return true;
    }
    return false;

  }
  void showUpdateUPCDialog(BuildContext context,WidgetRef ref){
    showDialog<String>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder:  (BuildContext context) =>Consumer(builder: (_, ref, __) {

        return AlertDialog(
          backgroundColor:Colors.grey[200],
          content: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200], // Change background color based on isSelected
              borderRadius: BorderRadius.circular(10),
            ),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: UpdateProductUpcScreen3(),

          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 5,
              children: <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red[300],
                    ),
                    child: Text(Messages.CONTINUE),
                    onPressed: () async {

                      Navigator.of(context).pop();

                    },
                  ),

                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red[300],
                    ),
                    child: Text(Messages.CANCEL),
                    onPressed: () async {
                      ref.read(isDialogShowedProvider.notifier).update((state) => false);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green[300],
                    ),
                    child: Text(Messages.CREATE),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        );
      }),
    );
  }
  Widget getScanButton(BuildContext context) {

    if(ref.read(productsHomeCurrentIndexProvider.notifier).state==widget.pageIndex){
      return ref.watch(isDialogShowedProvider)? Container() :
      ref.watch(usePhoneCameraToScanProvider) ?_buttonScanWithPhone(context, ref):
      ScanProductBarcodeButton(
          notifier: widget.productsNotifier,
          actionTypeInt: widget.actionTypeInt,pageIndex: widget.pageIndex);
    } else {
      return Container();
    }
  }
}