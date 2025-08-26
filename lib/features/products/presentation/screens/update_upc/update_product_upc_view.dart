import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/product_search_provider.dart';
import '../../providers/product_update_upc_provider.dart';
import '../../providers/products_scan_notifier.dart';
import '../../widget/no_data_card.dart';


class UpdateProductUpcView extends ConsumerStatefulWidget {
  int countScannedCamera =0;
  late ProductsScanNotifier productsNotifier ;
  final int actionTypeInt = Memory.ACTION_UPDATE_UPC ;

  UpdateProductUpcView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => UpdateProductUpcViewState();


}

class UpdateProductUpcViewState extends ConsumerState<UpdateProductUpcView> {
  late var newUPCProvider ;
  @override
  Widget build(BuildContext context){

    widget.productsNotifier = ref.watch(scanStateNotifierProvider.notifier);
    final double width = MediaQuery.of(context).size.width - 30;
    final double bodyHeight = MediaQuery.of(context).size.height - 200;
    final isScanning = ref.watch(isScanningProvider);
    final product = ref.watch(productForUpcUpdateProvider.notifier);
    double singleProductDetailCardHeight = bodyHeight/4*3;
    Memory.SIZE_PRODUCT_IMAGE_WIDTH = bodyHeight/4;
    Memory.SIZE_PRODUCT_IMAGE_HEIGHT = bodyHeight/4;
    String imageUrl =Memory.IMAGE_HTTP_SAMPLE_1; // Example image URL
    widget.countScannedCamera = ref.watch(scannedCodeTimesProvider.notifier).state;
    if(widget.countScannedCamera.isEven){
       imageUrl = Memory.IMAGE_HTTP_SAMPLE_2;
    } else {
      imageUrl = Memory.IMAGE_HTTP_SAMPLE_1;
    }
    Color foreGroundProgressBar = Colors.amber[600]!;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Add Your Code here.
      //ref.read(isScanningProvider.notifier).state = false;

    });
    return Scaffold(

      body: ListView(
        children: [
            isScanning
            ? LinearProgressIndicator(
          backgroundColor: Colors.cyan,
          color: foreGroundProgressBar,
          minHeight: 36,
        )
            : Center(child: Text(Messages.UPDATE_IMAGE)),
        SizedBox(height: 5,),
        Container(
          width: width,
          //height: singleProductDetailCardHeight,
          margin: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: (product.state.id!=null && product.state.id! > 0) ?
            _getUpdateUPCCard(context,
               product.state.copyWith(imageURL: imageUrl,uPC: null)) : NoDataCard(),
          ),
        ],
      ),
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
              'UPC: ${product.uPC ?? '--'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'SKU: ${product.sKU ?? '--'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'M_SKU: ${product.mOLIConfigurableSKU ?? '--'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (){
                    // ACTUALOZAR UPC
                    print('----------------------------ACTION_UPDATE_UPC UPC> ${ref.read(newUPCToUpdateProvider)}');

                  },
                  child: Text(Messages.UPDATE_IMAGE)),
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
          //widget.productsNotifier.setNewUPCCode(result);
        },
        btnCancelOnPress: (){
          return ;
        }
    ).show();
  }

}