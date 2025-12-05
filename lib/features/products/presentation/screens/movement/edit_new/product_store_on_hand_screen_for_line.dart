import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action_fixed.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/storage_on__hand_card_for_line.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_records_card.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_storage_on_hand_records_card.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../common/app_initializer_overlay.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/products_scan_notifier_for_line.dart';
import 'product_detail_card_for_line.dart';
import '../products_home_provider.dart';
import '../../../../../auth/domain/entities/warehouse.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/store_on_hand_provider.dart';
import '../../../widget/no_data_card.dart';
import '../../store_on_hand/product_resume_card.dart';


class ProductStoreOnHandScreenForLine extends ConsumerStatefulWidget implements InputDataProcessor{


  int countScannedCamera =0;
  late ProductsScanNotifierForLine productsNotifier ;
  final int actionTypeInt = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND ;
  final int pageIndex = Memory.PAGE_INDEX_STORE_ON_HAND;
  String argument;
  bool isMovementSearchedShowed = false;
  String productId;
  MovementAndLines movementAndLines;
  ProductStoreOnHandScreenForLine({
    required this.productId,
    required this.argument,
    required this.movementAndLines,
    super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => ProductStoreOnHandScreenForLineState();

  @override
  void addQuantityText(BuildContext context, WidgetRef ref,
      TextEditingController quantityController,int quantity) {
    if(quantity==-1){
      quantityController.text = '';
      return;
    }
    String s =  quantityController.text;
    String s1 = s;
    String s2 ='';
    if(s.contains('.')) {
      s1 = s.split('.').first;
      s2 = s.split('.').last;
    }

    String r ='';
    if(s.contains('.')){
      r='$s1$quantity.$s2';
    } else {
      r='$s1$quantity';
    }

    int? aux = int.tryParse(r);
    if(aux==null || aux<=0){
      String message =  '${Messages.ERROR_QUANTITY} $quantity';
      showErrorMessage(context, ref, message);
      return;
    }
    quantityController.text = aux.toString();

  }


  void confirmMovementButtonPressed(BuildContext context, WidgetRef ref, String string) {

  }

  void lastMovementButtonPressed(BuildContext context, WidgetRef ref, String lastSearch) {}

  void findMovementButtonPressed(BuildContext context, WidgetRef ref, String s) {}

  void newMovementButtonPressed(BuildContext context, WidgetRef ref, String s) {}

  @override
  Future<void> handleInputString(BuildContext context, WidgetRef ref, String inputData) async {

    productsNotifier.handleInputString(context, ref, inputData);
  }


}

class ProductStoreOnHandScreenForLineState
    extends ConsumerState<ProductStoreOnHandScreenForLine> {
  Color colorBackgroundHasMovementId = Colors.yellow[200]!;
  Color colorBackgroundNoMovementId = Colors.white;

  //int sameLocator = 0;
  final ScrollController _scrollController = ScrollController();
  late var scrollToTop  ;
  double goToPosition =0.0;
  late var isDialogShowed;
  late var usePhoneCamera;
  late var isScanning;
  late var showResultCard;
  int movementId =-1;
  MovementAndLines get movementAndLines {

    if(widget.argument.isNotEmpty && widget.argument!='-1') {
      return MovementAndLines.fromJson(jsonDecode(widget.argument));
    } else {
      return widget.movementAndLines;
    }
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await setDefaultValues(context, ref);

    });

  }
  void showErrorMessage(BuildContext context, WidgetRef ref, String message) {
    if (!context.mounted) {
      Future.delayed(const Duration(seconds: 1));
      if(!context.mounted) return;
    }
    AwesomeDialog(
      context: context,
      animType: AnimType.scale,
      dialogType: DialogType.error,
      body: Center(child: Column(
        children: [
          Text(message,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),),
      title:  message,
      desc:   '',
      autoHide: const Duration(seconds: 3),
      btnOkOnPress: () {},
      btnOkColor: Colors.amber,
      btnCancelText: Messages.CANCEL,
      btnOkText: Messages.OK,
    ).show();
    return;
  }

  @override
  Widget build(BuildContext context){
    widget.productsNotifier = ref.watch(scanStateNotifierForLineProvider.notifier);
    isScanning = ref.watch(isScanningForLineProvider);
    showResultCard = ref.watch(showResultCardProvider);
    String lines = '0';
    lines = movementAndLines.movementLines?.length.toString() ?? '0';
    movementId = movementAndLines.id ?? -1;
    isDialogShowed = ref.watch(isDialogShowedProvider);
    final productAsync = ref.watch(findProductByUPCOrSKUForStoreOnHandProvider);
    final productsStoredAsync = ref.watch(findProductsStoreOnHandProvider);

    final double width = MediaQuery.of(context).size.width - 30;
    Warehouse? userWarehouse = ref.read(authProvider).selectedWarehouse;
    int userWarehouseId = userWarehouse?.id ?? 0;
    String userWarehouseName = userWarehouse?.name ?? '';
    usePhoneCamera = ref.watch(usePhoneCameraToScanForLineProvider);
    scrollToTop = ref.watch(scrollToUpProvider);
    String title = movementAndLines.documentNo ?? '';
    TextStyle textStyle = TextStyle(fontSize: themeFontSizeLarge);
    if(title.length>20) textStyle = TextStyle(fontSize: themeFontSizeSmall);


    return Scaffold(

      appBar: AppBar(
        backgroundColor: movementAndLines.hasMovement
            ? colorBackgroundHasMovementId : colorBackgroundNoMovementId,
        automaticallyImplyLeading: true,
        leading:IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async =>
            {
              popScopeAction(context, ref),
            }
          //
        ),

        title: ListTile(
            title: Text(title,style: textStyle, ),
            subtitle: Text('${Messages.LINES} : $lines'),
        ),
        actions: [
          IconButton(
            icon: Icon(usePhoneCamera ? Icons.barcode_reader : Icons.camera),
            onPressed: () {
              // 🧠 Riverpod se encarga del rebuild, sin setState
              print('usePhoneCamera: $usePhoneCamera');
              ref
                  .read(usePhoneCameraToScanForLineProvider.notifier)
                  .state = !usePhoneCamera;

              ref.read(isDialogShowedProvider.notifier).state = false;
            },
          ),

        ],

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          double positionAdd=_scrollController.position.maxScrollExtent;
          /*if(MediaQuery.of(context).orientation == Orientation.portrait){
            positionAdd=250;
          }*/
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
      ) :bottomAppBar(context),
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) {
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
                  productAsync.when(
                    data: (products) {
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        ref.read(isScanningForLineProvider.notifier).update((state) => false);
                        if(products.isNotEmpty && products[0].id != null && products[0].id! > 0){
                          ref.read(showResultCardProvider.notifier).update((state) => true);
                        } else {
                          ref.read(showResultCardProvider.notifier).update((state) => false);
                        }
                      });
                      if(products.isEmpty || products[0].id == null || products[0].id! <= 0) return NoDataCard();

                      return ProductDetailCardForLine(
                          productsNotifier: widget.productsNotifier, product: products[0]);


                    },error: (error, stackTrace) => Text('Error: $error'),
                    loading: () => const LinearProgressIndicator(),
                  ),

                  productsStoredAsync.when(
                    data: (storages) {
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        // deley 1 secund
                        ref.read(isScanningForLineProvider.notifier).update((state) => false);
                        ref.read(isScanningProvider.notifier).update((state) => false);

                        double quantity = 0;
                        for (var data in storages) {
                          int warehouseID = data.mLocatorID?.mWarehouseID?.id ?? 0;

                          if (warehouseID == userWarehouseId) {
                            quantity += data.qtyOnHand ?? 0;
                          }
                        }

                        String aux = Memory.numberFormatter0Digit.format(quantity);
                        ref.read(resultOfSameWarehouseProvider.notifier).update((state) =>  [aux,userWarehouseName]);
                      });
                      return getStoragesOnHand(storages, width);

                    },
                    error: (error, stackTrace) => Text('Error: $error'),
                    loading: () => const LinearProgressIndicator(
                      minHeight: 36,
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getStoragesOnHand(List<IdempiereStorageOnHande> storages, double width) {

    if(!showResultCard){
      return Text(Messages.NO_DATA_FOUND);
    }

    if(storages.isEmpty){
      return isScanning ? Text(Messages.PLEASE_WAIT)
          : Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[600],
          borderRadius: BorderRadius.circular(10),
        ),
        //child: ProductResumeCard(storages,width-10)
        child: movementAndLines.hasMovement ? NoStorageOnHandRecordsCard(width: width)
            : NoRecordsCard(width: width),
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
          return showResultCard
              ? Container(
              width: width,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: ProductResumeCard(storages, width))
              : Text(Messages.NO_RESUME_SHOWED);
        }

        return StorageOnHandCardForLine(
          widget.productsNotifier,
          storages[index - add],
          index + 1 - add,
          storages.length,
          width: width - 10,
          argument: widget.argument,
          movementAndLines: MovementAndLines.fromJson(jsonDecode(widget.argument)),
          allowedWarehouseFrom: movementAndLines.lastLocatorFrom?.mWarehouseID,
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
          await Future.delayed(Duration(milliseconds: 100));

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
              btnOkOnPress: () async {
              },
              btnOkColor: Colors.amber,
              btnCancelText: Messages.CANCEL,
              btnOkText: Messages.OK,
            ).show();
            return;
          }
          widget.productsNotifier.addBarcodeByUPCOrSKUForSearch(result);
        },
        btnCancelOnPress: () async {
          isDialogShowed = false;
          setState(() {});
          await Future.delayed(Duration(milliseconds: 100));
          return ;
        }
    ).show();

  }

  BottomAppBar bottomAppBar(BuildContext context) {

    return BottomAppBar(
        height: Memory.BOTTOM_BAR_HEIGHT,
        color: themeColorPrimary ,
        child: usePhoneCamera ? buttonScanWithPhone(context, ref,widget.productsNotifier)
            : ScanButtonByActionFixed(
          processor: widget,
          actionTypeInt: widget.actionTypeInt,)

    );


  }

  Widget getProductDetails(List<IdempiereProduct> products, double width) {

    return SliverList.separated(
        separatorBuilder: (context, index) => SizedBox(height: 5,),
        itemCount: products.length,
        itemBuilder: (context, index) => ProductDetailCardForLine(
            productsNotifier: widget.productsNotifier, product: products[index]));




  }

  void popScopeAction(BuildContext context, WidgetRef ref) {
    ref.read(productsHomeCurrentIndexProvider.notifier).state =
        Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN;
    ref.read(actionScanProvider.notifier).state = Memory.ACTION_FIND_MOVEMENT_BY_ID;
    context.go('${AppRouter.PAGE_MOVEMENTS_SEARCH}/$movementId');

  }
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) async {

    ref.read(isScanningFromDialogProvider.notifier).update((state) => false);
    ref.read(isScanningProvider.notifier).update((state) => false);
    ref.read(isScanningForLineProvider.notifier).update((state) => false);
    ref.read(isDialogShowedProvider.notifier).update((state) => false);

    MemoryProducts.movementAndLines.clearData() ;

  }

}
