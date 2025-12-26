import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/storage_on__hand_card_for_line.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_records_card.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/no_storage_on_hand_records_card.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/scan_button_by_action_fixed_short.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/products_scan_notifier_for_line.dart';
import '../../../widget/message_card.dart';
import 'custom_app_bar.dart';
import 'product_detail_card_for_line.dart';
import '../provider/products_home_provider.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/store_on_hand_provider.dart';
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
  bool asyncResultHandled = false ;
  ProductStoreOnHandScreenForLine({
    required this.productId,
    required this.argument,
    required this.movementAndLines,
    super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => ProductStoreOnHandScreenForLineState();


  @override
  Future<void> handleInputString({required WidgetRef ref,required  String inputData,required int actionScan}) async {
    asyncResultHandled = false ;
    print('handleInputString result scan: $inputData');
    productsNotifier.handleInputString(ref: ref, inputData: inputData,
        actionScan: actionTypeInt);
  }

}

class ProductStoreOnHandScreenForLineState
    extends ConsumerState<ProductStoreOnHandScreenForLine> {
  Color colorBackgroundHasMovementId = Colors.yellow[200]!;
  Color colorBackgroundNoMovementId = Colors.white;

  double goToPosition =0.0;
  late var isDialogShowed;
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
      print('----------product Id ${widget.productId}');
      if(widget.productId.isNotEmpty && widget.productId!='-1'){
        widget.handleInputString(ref: ref, inputData: widget.productId,
            actionScan: widget.actionTypeInt);
      }

    });

  }

  @override
  Widget build(BuildContext context){
    widget.productsNotifier = ref.watch(scanStateNotifierForLineProvider.notifier);
    isScanning = ref.watch(isScanningForLineProvider);
    showResultCard = ref.watch(showResultCardProvider);
    movementId = movementAndLines.id ?? -1;
    isDialogShowed = ref.watch(isDialogShowedProvider);
    final productAsync = ref.watch(findProductByUPCOrSKUForStoreOnHandProvider);

    final showScan = ref.watch(showScanFixedButtonProvider(widget.actionTypeInt));

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
        ),

        title: movementAppBarTitle(movementAndLines: movementAndLines,
            onBack: ()=> popScopeAction,
            showBackButton: false,
            subtitle: '${Messages.LINES} : (${movementAndLines.movementLines?.length ?? 0})'
        ),
        actions: [
          if(showScan) ScanButtonByActionFixedShort(
            actionTypeInt: widget.actionTypeInt,
            onOk: widget.handleInputString,),
          IconButton(
            icon: const Icon(Icons.keyboard,color: Colors.purple),
            onPressed: () => {
              openInputDialogWithAction(ref: ref, history: false,
                  onOk: widget.handleInputString, actionScan:  widget.actionTypeInt)
            },
          ),

        ],

      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
            child: SingleChildScrollView(
              child: productAsync.when(
                data: (result) {
                  if(result.id==null || result.id! ==-1){
                    return MessageCard(
                      title: Messages.CONTINUE_TO_ADD_LINE,
                      message: Messages.BACK_BUTTON_TO_SEE_MOVEMENT,
                      subtitle: Messages.SCAN_PRODUCT_TO_CREATE_LINE,
                    );
                  }
                  final double width = MediaQuery.of(context).size.width - 30;

                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if(!widget.asyncResultHandled) {
                        widget.asyncResultHandled = true;
                        print('result from search ----------');
                      }
                    });

                  MemoryProducts.productWithStock = result;
                  return Column(
                    spacing: 10,
                    children: [
                      ProductDetailCardForLine(
                          productsNotifier: widget.productsNotifier, product: result),
                      if(result.hasListStorageOnHande) getStoragesOnHand(result.sortedStorageOnHande!, width),
                    ],
                  );
                },error: (error, stackTrace) => Text('Error: $error'),
                loading: () {
                  final p = ref.watch(storeOnHandProgressProvider);
                  return LinearProgressIndicator(
                    minHeight: 36,
                    value: (p > 0 && p < 1) ? p : null,
                  );
                },
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
      physics: const NeverScrollableScrollPhysics(),
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



  void popScopeAction(BuildContext context, WidgetRef ref) {

    // Restaurar configuración de navegación del Home
    ref.read(productsHomeCurrentIndexProvider.notifier).state =
        Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN;

    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_MOVEMENT_BY_ID;

    // Redirigir
    context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$movementId/1');
  }

  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) async {

    ref.read(isScanningFromDialogProvider.notifier).update((state) => false);
    ref.read(isScanningProvider.notifier).update((state) => false);
    ref.read(isScanningForLineProvider.notifier).update((state) => false);
    ref.read(isDialogShowedProvider.notifier).update((state) => false);

    MemoryProducts.movementAndLines.clearData() ;

  }

}
