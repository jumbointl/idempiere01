import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/search/product_result_with_photo_card.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/search/scan_barcode_for_update_upc_button.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/product_search_provider.dart';
import '../../providers/product_update_upc_provider.dart';
import '../../providers/products_update_notifier.dart';


class UpdateProductUpcScreen3 extends ConsumerStatefulWidget {
  int countScannedCamera =0;
  late ProductsUpdateNotifier productsNotifier ;
  final int actionTypeInt = Memory.ACTION_UPDATE_UPC ;

  UpdateProductUpcScreen3({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => UpdateProductUpcScreen3State();


}

class UpdateProductUpcScreen3State extends ConsumerState<UpdateProductUpcScreen3> {
   late IdempiereProduct product;
   late var newUPCProvider ;
   late AsyncValue updateAsync;
   late var dataToUpdateUPC;
   AwesomeDialog? dialog;
   final hinTextUpdateUPC = Messages.UPDATE_UPC;
   @override
  initState(){
     super.initState();
   }
   @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    dialog?.dismiss();
  }
  @override
  Widget build(BuildContext context){
    dataToUpdateUPC = ref.watch(dataToUpdateUPCProvider.notifier);
    product = ref.watch(productForUpcUpdateProvider);
    updateAsync = ref.watch(updateProductUPCProvider);
    widget.productsNotifier = ref.watch(productUpdateStateNotifierProvider.notifier);
    final double width = MediaQuery.of(context).size.width - 30;
    final double bodyHeight = MediaQuery.of(context).size.height - 100;
    final isScanning = ref.watch(isScanningProvider);
    final usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    double singleProductDetailCardHeight = Memory.SIZE_PRODUCT_IMAGE_HEIGHT+20;
    newUPCProvider = ref.watch(newUPCToUpdateProvider);
    String imageUrl =Memory.IMAGE_HTTP_SAMPLE_1; // Example image URL
    widget.countScannedCamera = ref.watch(scannedCodeTimesProvider.notifier).state;
    if(widget.countScannedCamera.isEven){
       imageUrl = Memory.IMAGE_HTTP_SAMPLE_2;
    } else {
      imageUrl = Memory.IMAGE_HTTP_SAMPLE_1;
    }
    Color foreGroundProgressBar = Colors.amber[600]!;

    return Scaffold(


      appBar: AppBar(
        title: Text(Messages.PRODUCT),
          leading:IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => {
              FocusScope.of(context).unfocus(),
              dialog?.dismiss(),
              Navigator.of(context).pop()
             },
          ),
          actions: [

            usePhoneCamera.state ? IconButton(
              icon: const Icon(Icons.barcode_reader),
              onPressed: () => { usePhoneCamera.state = false},
            ) :  IconButton(
            icon: const Icon(Icons.camera),
            onPressed: () => { usePhoneCamera.state = true},

          ),

        ],

      ),

      body: SizedBox(
        height: bodyHeight,
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

          Expanded(
            child: dataToUpdateUPC.state.length==2 ? updateAsync.when(
              data: (product) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  ref.read(isScanningProvider.notifier).state = false;
                });
                return getProductDetailCard(productsNotifier: widget.productsNotifier,
                    product: product) ;

              },error: (error, stackTrace) => Text('Error: $error'),
              loading: () => LinearProgressIndicator(),
            ) :
            _getUpdateUPCCard(context, product),
          ),

            PreferredSize(
                preferredSize: Size(double.infinity,30),
                child: SizedBox(width: MediaQuery.of(context).size.width, child:
                ref.watch(usePhoneCameraToScanProvider) ? _buttonScanWithPhone(context, ref):
                ScanBarcodeForUpdateUpcButton(widget.productsNotifier, actionTypeInt: widget.actionTypeInt,))),
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
        //ref.watch(isScanningProvider.notifier).state = true;

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
          ref.read(scanHandleNotifierProvider.notifier).addNewUPCCode(result);
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
          spacing: 5,
          children: [
            IconButton(onPressed: null, icon: Icon(usePhoneCamera.state?
            Icons.camera : Icons.barcode_reader, color: Colors.purple,)),
            Expanded(
              child: Text(
                Messages.PLEASE_SCAN_NEW_UPC,
                textAlign: TextAlign.center,
              ),
            ) ,

          ],
        ),
      );

  }

  Widget getProductDetailCard({required ProductsUpdateNotifier productsNotifier, required product}) {
    return ProductResultWithPhotoCard(
      product: product,
      actionTypeInt: widget.actionTypeInt,
    );


  }
   Widget _getUpdateUPCCard(BuildContext context, IdempiereProduct product) {
     String att = product.mAttributeSetInstanceID?.identifier  ?? '';
     if(att==''){
       att = '${Messages.ATTRIBUET_INSTANCE}: ${product.mAttributeSetInstanceID?.identifier  ?? '--'}';
     }
     String imageUrl = product.imageURL ?? '' ;
     bool testMode = true;
     if(testMode){
       imageUrl =Memory.IMAGE_HTTP_SAMPLE_1; // Example image URL
       int countScannedCamera = ref.watch(scannedCodeTimesProvider.notifier).state;
       if(countScannedCamera.isEven){
         imageUrl = Memory.IMAGE_HTTP_SAMPLE_2;
       } else {
         imageUrl = Memory.IMAGE_HTTP_SAMPLE_1;
       }
     }
     return SingleChildScrollView(
       child: Container(
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(10),
         ),
         padding: const EdgeInsets.all(10),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           spacing: 5,
           children: [

             Center(
               child: SizedBox(
                 width: Memory.SIZE_PRODUCT_IMAGE_WIDTH,
                 height: Memory.SIZE_PRODUCT_IMAGE_HEIGHT,
                 child: FadeInImage(
                   placeholder: AssetImage(Memory.IMAGE_LOADING), // Placeholder for loading
                   image:NetworkImage(imageUrl),

                   fit: BoxFit.cover, // Adjust as needed
                   imageErrorBuilder: (context, error, stackTrace) {
                     return Image.asset(Memory.IMAGE_NO_IMAGE, fit: BoxFit.cover); // Display on error
                   },
                 ),
               ),
             ),
             Text(
               product.name ?? '${Messages.NAME}--',
               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
             ),
             Text(
               'SKU: ${product.sKU ?? 'SKU--'}',
               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
             ),
             Text(
               'M_SKU: ${product.mOLIConfigurableSKU ?? 'M_SKU--'}',
               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
             ),
             Center(
               child: Container(
                 margin: EdgeInsets.symmetric(vertical: 10),
                 child: Text( newUPCProvider=='' ? Messages.SCAN_UPC :
                 newUPCProvider,
                   style: const TextStyle(fontStyle: FontStyle.italic,
                       fontSize: 22,
                       fontWeight: FontWeight.bold,color: Colors.purple),
                 ),),
             ),


             SizedBox(
               width: double.infinity,
               child: TextButton(
                   style: TextButton.styleFrom(
                     backgroundColor: isCanEditUPC() ? Colors.purple : Colors.grey[600],
                     foregroundColor: Colors.white,
                   ),
                   onPressed: () async {
                     if(!isCanEditUPC()){
                       return;
                     }
                     dataToUpdateUPC = true ;
                     String id = ref.read(productForUpcUpdateProvider.notifier).state.id!.toString();
                     String newUPC = ref.read(newUPCToUpdateProvider.notifier).state;

                     if(id == '' || int.tryParse(id)==null || int.tryParse(id) == 0 || newUPC=='' ||
                         int.tryParse(newUPC)==null || int.tryParse(newUPC) == 0)
                     {
                       await AwesomeDialog(
                       context: context,
                       animType: AnimType.scale,
                       dialogType: DialogType.error,
                       body: Center(child: Text(
                         Messages.DATA_NOT_VALID,
                         style: TextStyle(fontStyle: FontStyle.italic),
                         ),),
                       title: 'ID: $id ,UPC: $newUPC' ,
                       desc:   'ID: $id ,UPC: $newUPC' ,
                       autoHide: const Duration(seconds: 5),
                       btnOkOnPress: () {},
                       btnOkColor: Colors.amber,
                       btnCancelText: Messages.CANCEL,
                       btnOkText: Messages.OK,
                       ).show();
                       return;
                     }
                     List<String> updateData =[id,newUPC];
                     //ref.watch(isScanningProvider.notifier).update((state) => true);

                     ref.read(dataToUpdateUPCProvider.notifier).update((state) => updateData);
                   },
                   child: Text(hinTextUpdateUPC)),
             ),

           ],
         ),
       ),
     );
   }
   Future<void> showConfirmationDialog(BuildContext context) async {
     TextEditingController controller = TextEditingController();
     controller.text = ref.read(newUPCToUpdateProvider.notifier).state;
     bool stateActual = ref.watch(usePhoneCameraToScanProvider.notifier).state;
     ref.watch(usePhoneCameraToScanProvider.notifier).state = true;
     FocusNode focusNode = FocusNode();
     focusNode.requestFocus();
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
                   focusNode: focusNode,
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
           //widget.productsNotifier.setNewUPCCode(result);
         },
         btnCancelOnPress: (){
           return ;
         }
     ).show();
   }
   bool isCanEditUPC() {
     if(ref.read(productForUpcUpdateProvider).id==null || ref.read(productForUpcUpdateProvider).id==0){
       return false ;

     }
     if(ref.read(productForUpcUpdateProvider).uPC==null || ref.read(productForUpcUpdateProvider).uPC=='' ){
       String aux = ref.read(newUPCToUpdateProvider.notifier).state;
       if(aux==hinTextUpdateUPC || int.tryParse(aux)==null || int.tryParse(aux)==0 ){
         return false;
       }

       return true;
     }
     return false;

   }

  /*Future<void> showResultMessage(product) async {
      String title = product.id<=0 ? Messages.ERROR_UPDATE_PRODUCT_UPC : Messages.UPDATE_UPC_WITH_SUCCESS;
      String subtitle = product.id<=0 ? 'name: ${product.name ?? ''} , UPC: ${product.uPC ??''}' :
      'SKU: ${product.sKU ?? ''} , UPC: ${product.uPC ??''}' ;
      String title2 =  'ID: ${product.sKU ?? ''} ,UPC: ${product.uPC ?? ''}';
      String subtitle2 =  '${product.name ??''}' ;

      dialog = await AwesomeDialog(
        context: context,
        animType: AnimType.scale,
        dialogType: product.id<=0 ? DialogType.error :  DialogType.success,
        body: Center(child: ListTile(
          title: Text(title,
                style: TextStyle(fontStyle: FontStyle.italic),),
          subtitle: Text(subtitle) ,

        ),),
        title: title2,
        desc:  subtitle2,
        autoHide: const Duration(seconds: 5),
        btnOkOnPress: () {
          ref.read(dataToUpdateUPCProvider.notifier).state = [];
          DataUtils.removeIdempiereProduct();
          dialog?.dismiss();
          context.go(AppRouter.PAGE_HOME);
        },
        btnOkColor: Colors.amber,
        btnCancelText:Messages.FIND_OTHER,
        btnOkText:  Messages.FINISHED ,
        btnCancelOnPress: (){
          ref.read(dataToUpdateUPCProvider.notifier).state = [];
          if(product.id>0) {
            DataUtils.saveIdempiereProduct(product);
          }
          dialog?.dismiss();
          context.go(AppRouter.PAGE_PRODUCT_SEARCH_UPDATE_UPC);
        }
        ).show();
  }*/

}