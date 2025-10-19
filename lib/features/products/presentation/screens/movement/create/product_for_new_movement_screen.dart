import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/common_screen_state.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/products_home_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_records_card.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../auth/domain/entities/warehouse.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/idempiere_warehouse.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/persitent_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/store_on_hand_provider.dart';
import '../../../widget/no_data_card.dart';
import '../../../widget/product_detail_card.dart';
import '../../store_on_hand/product_resume_card.dart';
import 'mevement_storage_on__hand_card.dart';


class ProductForNewMovementScreen extends ConsumerStatefulWidget {

  int countScannedCamera =0;
  late var productsNotifier ;
  final int actionTypeInt = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;
  late var allowedLocatorFromId;
  final int pageIndex = Memory.PAGE_INDEX_STORE_ON_HAND;
  String? productUPC;
  bool isMovementSearchedShowed = false;
  bool isSearched = false ;
  ProductForNewMovementScreen({this.productUPC,super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => ProductForMovementScreenState();

  void confirmMovementButtonPressed(BuildContext context, WidgetRef ref, String string) {

  }

  void lastMovementButtonPressed(BuildContext context, WidgetRef ref, String lastSearch) {}

  void findMovementButtonPressed(BuildContext context, WidgetRef ref, String s) {}

  void newMovementButtonPressed(BuildContext context, WidgetRef ref, String s) {}


}

class ProductForMovementScreenState extends CommonConsumerState<ProductForNewMovementScreen> {
  Color colorBackgroundHasMovementId = Colors.cyan[200]!;
  Color colorBackgroundNoMovementId = Colors.white;
  int sameLocator = 0;
  final ScrollController _scrollController = ScrollController();
  late var resultOfSameWarehouse;
  AsyncValue? mainDataListLocalAsync;
  AsyncValue? mainDataLocalAsync;



  Widget getStoragesOnHand(List<IdempiereStorageOnHande> storages, double width) {
    print('----------------getStoragesOnHand ${storages.length} ');
    bool isScanning = ref.read(isScanningProvider);
    bool showResultCard = ref.read(showResultCardProvider);
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
            child: NoRecordsCard(width: width),
      );
    }
    int length = storages.length;
    int add =1 ;
    print(storages.length);
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
        return MovementStorageOnHandCard(
            widget.productsNotifier,
            storages[index - add],
            index + 1 - add,
            storages.length,
            width: width - 10,
          );
        },
      );

  }

  @override
  void executeAfterShown() {
    //ref.read(isScanningProvider.notifier).update((state) => false);

    /*if(!widget.isSearched && widget.productUPC!= null && widget.productUPC!.isNotEmpty && widget.productUPC!='-1'){
      widget.isSearched = true;
      handleInputString(context, ref, widget.productUPC!);


    }*/
  }

  @override
  double getWidth(){ return MediaQuery.of(context).size.width - 30;}




  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return Colors.white;
  }

  @override
  AsyncValue get mainDataAsync => ref.watch(findProductByUPCOrSKUForStoreOnHandProvider);

  @override
  Widget getMainDataCard(BuildContext context, WidgetRef ref) {

     return mainDataAsync.when(
      data: (products) {
        print('-----------------find-----mainDataAsync--------------');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          isScanning.update((state) => false);
        });

        if(products==null || products.isEmpty || products[0].id == null
            || products[0].id! <= 0 ){
          return NoDataCard();
        }

        return ProductDetailCard(
            productsNotifier: widget.productsNotifier, product: products[0]);


      },error: (error, stackTrace) => Text('Error: $error'),
      loading: () => const LinearProgressIndicator(),
    );
  }

  @override
  Widget getMainDataList(BuildContext context, WidgetRef ref) {
    int userWarehouseId = 0;
    String userWarehouseName = '';
    Warehouse? userWarehouse = ref.read(authProvider).selectedWarehouse;
    userWarehouseId = userWarehouse?.id ?? 0;
    userWarehouseName = userWarehouse?.name ?? '';

     return mainDataListAsync.when(

      data: (storages) {
        print('-----------------find-----mainDataAsync------------find--');

        if(storages==null || storages.isEmpty){
          return Container();
        }


        WidgetsBinding.instance.addPostFrameCallback((_) async {
          isScanning.update((state) => false);
          if(storages==null || storages.isEmpty){
            return ;
          }
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

        });
        print('----------------getStoragesOnHand ${storages.length} ');
        return getStoragesOnHand(storages, getWidth());

      },
      error: (error, stackTrace) => Text('Error: $error'),
      loading: () => const LinearProgressIndicator(
        minHeight: 36,
      ),
    );
  }

  @override
  AsyncValue get mainDataListAsync => ref.watch(findProductsStoreOnHandProvider);


  @override
  Future<void> initialSetting(BuildContext context, WidgetRef ref) async {
    ref.invalidate(persistentLocatorToProvider);
    isScanning = ref.watch(isScanningProvider.notifier);
    usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    isDialogShowed = ref.watch(isDialogShowedProvider.notifier);
    scrollToTop = ref.watch(scrollToUpProvider.notifier);
    scrollController = ScrollController();
    resultOfSameWarehouse = ref.watch(resultOfSameWarehouseProvider.notifier);
    widget.productsNotifier = ref.watch(scanHandleNotifierProvider.notifier);
    inputString = ref.watch(inputStringProvider.notifier);
    pageIndexProdiver = ref.watch(productsHomeCurrentIndexProvider.notifier);
    actionScan = ref.watch(actionScanProvider.notifier);


    Future.delayed(Duration(milliseconds: 100), () {
      pageIndexProdiver.update((state) => widget.pageIndex);
      actionScan.update((state) => widget.actionTypeInt);
    });


  }

  @override
  Future<void> handleInputString(BuildContext context, WidgetRef ref, String inputData) async {
    if(inputData.isEmpty){
      return;
    }
    var notifier = ref.read(scanStateNotifierForLineProvider.notifier);
    notifier.handleInputString(context,ref,inputData);
    inputString.update((state) => inputData);

  }

  @override
  void iconBackPressed(BuildContext context, WidgetRef ref) {
    if(widget.productUPC!=null && widget.productUPC!='-1'){
      ref.read(actionScanProvider.notifier).update((state) =>
      Memory.ACTION_FIND_MOVEMENT_BY_ID);
      ref.read(productsHomeCurrentIndexProvider.notifier).update((state) =>
      Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN);

      Navigator.pop(context);
    } else {
    context.go(AppRouter.PAGE_HOME);
    }
  }

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) {
    if(widget.productUPC!=null && widget.productUPC!='-1'){
      ref.read(actionScanProvider.notifier).update((state) =>
      Memory.ACTION_FIND_MOVEMENT_BY_ID);
      ref.read(productsHomeCurrentIndexProvider.notifier).update((state) =>
      Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN);

      Navigator.pop(context);
    } else {
    context.go(AppRouter.PAGE_HOME);
    }
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    return Text(Messages.STORE_ON_HAND,style: textStyleTitle);
  }

  @override
  void addQuantityText(BuildContext context, WidgetRef ref, TextEditingController quantityController, int i) {
    // TODO: implement addQuantityText
  }

  @override
  String get hinText {
    if(actionScan.state == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
      return Messages.FIND_MOVEMENT;
    } else if(actionScan.state == Memory.ACTION_GET_LOCATOR_TO_VALUE) {
      return Messages.FIND_LOCATOR;
    }  else  if(actionScan.state == Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND) {
      return Messages.SKU_UPC;
    }  else {
      return Messages.INPUT_DATA;
    }

  }
}