import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/search/product_detail_with_photo_card.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/product_search_provider.dart';
import '../../providers/products_scan_notifier.dart';
import '../../widget/no_data_card.dart';
import '../../widget/product_detail_card.dart';
import '../../../../shared/data/data_utils.dart';


class ProductSearchForUpdateUpcScreen extends ConsumerStatefulWidget {
  int countScannedCamera =0;
  late ProductsScanNotifier productsNotifier ;
  final int actionTypeInt = Memory.ACTION_UPDATE_UPC ;
  late IdempiereProduct product ;
  late bool usePhoneCamera = false;

  ProductSearchForUpdateUpcScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProductSearchForUpdateUpcScreenState();




}

class _ProductSearchForUpdateUpcScreenState extends ConsumerState<ProductSearchForUpdateUpcScreen> {
  AwesomeDialog? dialog;
  late AsyncValue updateAsync;
  _ProductSearchForUpdateUpcScreenState(){
      getSavedData();
  }
  Future<void> getSavedData() async {
    IdempiereProduct product = await DataUtils.getSavedIdempiereProduct();
    if(product.id!=null && product.id!>0){
      if(product.sKU!=null){
        Memory.lastSearch = product.sKU!;
      }
    }
  }
  @override
  void initState() {
    super.initState();
    widget.usePhoneCamera = ref.read(usePhoneCameraToScanProvider.notifier).state;
  }
  @override
  void dispose() {

    super.dispose();
    dialog?.dismiss();
  }
  @override
  Widget build(BuildContext context){

    final productAsync = ref.watch(findProductByUPCOrSKUProvider);
    widget.productsNotifier = ref.watch(scanHandleNotifierProvider.notifier);
    final double width = MediaQuery.of(context).size.width - 30;
    final double bodyHeight = MediaQuery.of(context).size.height - 100;
    final isScanning = ref.watch(isScanningProvider);
    double singleProductDetailCardHeight = Memory.SIZE_PRODUCT_IMAGE_HEIGHT*2+20;
    if(singleProductDetailCardHeight>bodyHeight){
      singleProductDetailCardHeight = bodyHeight;
    }

    String imageUrl =Memory.IMAGE_HTTP_SAMPLE_1; // Example image URL
    widget.countScannedCamera = ref.watch(scannedCodeTimesProvider.notifier).state;
    if(widget.countScannedCamera.isEven){
       imageUrl = Memory.IMAGE_HTTP_SAMPLE_2;
    } else {
      imageUrl = Memory.IMAGE_HTTP_SAMPLE_1;
    }
    Color foreGroundProgressBar = Colors.purple;
    return Scaffold(
      resizeToAvoidBottomInset : false,

      appBar: AppBar(
        leading:IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => {
            FocusScope.of(context).unfocus(),
            context.go(AppRouter.PAGE_HOME)},
        ),
        title: Text(Messages.PRODUCTS),
        actions: [
          IconButton(onPressed:() async {getBarCode(context,false);},
              icon: Icon( Icons.search, color:isScanning?Colors.grey: Colors.purple,)),
          IconButton(onPressed:() async {getBarCode(context,true);},
              icon: Icon( Icons.history, color:isScanning?Colors.grey: Colors.purple,)),
        ],
      ),

      body: PopScope(
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;
          }
          ref.read(usePhoneCameraToScanProvider.notifier).state = widget.usePhoneCamera;
          Navigator.pop(context);
        },
        child: Container(
          color: Colors.white,
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
                  : Text(Messages.FIND_PRODUCT_BY_SKU),

              Container(
                  width: width,
                  height: singleProductDetailCardHeight,
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    //color: Colors.grey[200],
                    color: Colors.white,
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
                    loading: () => LinearProgressIndicator(),
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
                        FocusScope.of(context).unfocus();
                        DataUtils.saveIdempiereProduct(ref.read(productForUpcUpdateProvider));

                        context.push(AppRouter.PAGE_UPDATE_PRODUCT_UPC);
                      },
                      child: Text(Messages.UPDATE_UPC)),
                ),),

              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> getBarCode(BuildContext context, bool history) async{
    ref.read(usePhoneCameraToScanProvider.notifier).state = true;
    TextEditingController controller = TextEditingController();
    if(history){
      String lastSearch = Memory.lastSearch;
      if(lastSearch.isEmpty){
        controller.text = Messages.NO_RECORDS_FOUND;
      } else {
        controller.text = lastSearch;
      }

    }
    dialog = await AwesomeDialog(
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
        dialog?.dismiss();
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
          ref.read(usePhoneCameraToScanProvider.notifier).state = false;
          return;
        }
        Memory.lastSearch = result;
        widget.productsNotifier.addBarcodeByUPCOrSKUForSearch(result);
      },
      btnCancelOnPress: (){
        ref.read(usePhoneCameraToScanProvider.notifier).state = false;
        dialog?.dismiss();
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
        return ProductDetailCard(productsNotifier: productsNotifier, product: product);

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

  void goToNextPage(IdempiereProduct products) {
    Future.delayed(Duration(milliseconds: 1500), () async {
      await DataUtils.saveIdempiereProduct(ref.read(productForUpcUpdateProvider));
      context.go(AppRouter.PAGE_UPDATE_PRODUCT_UPC);
    });
  }

}