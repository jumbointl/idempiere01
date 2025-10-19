

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/idempiere/idempiere_warehouse.dart';
import '../../providers/locator_provider.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/products_scan_notifier.dart';
class StorageOnHandCard extends ConsumerStatefulWidget {
  final ProductsScanNotifier notifier;
  final IdempiereStorageOnHande storage;
  final int index;
  final int listLength;
  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  final double width;
  final double height = 120;
  IdempiereLocator? locatorFilter;



  StorageOnHandCard(this.notifier, this.storage, this.index, this.listLength, {

    required this.width,this.locatorFilter, super.key,});


  @override
  ConsumerState<StorageOnHandCard> createState() =>StorageOnHandCardState();
}

class StorageOnHandCardState extends ConsumerState<StorageOnHandCard> {
  late var usePhoneCamera ;
  late var isScanning ;
  late var allowedLocatorId;
  @override
  Widget build(BuildContext context) {
    usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    isScanning = ref.watch(isScanningProvider.notifier);

    allowedLocatorId = widget.locatorFilter?.id ?? -1;
    final warehouse = ref.read(authProvider).selectedWarehouse;
    int warehouseID = warehouse?.id ?? 0;
    IdempiereWarehouse? warehouseStorage = widget.storage.mLocatorID?.mWarehouseID;
    bool canMove = false ;
    Color background = widget.colorDifferentWarehouse;

    if(allowedLocatorId > 0){
      if(widget.storage.mLocatorID?.id != allowedLocatorId){
        background = widget.colorDifferentWarehouse;
      } else {
        background = widget.colorSameWarehouse;
        canMove = true;
      }

    } else {
      if(warehouseStorage?.id == warehouseID){
        background = widget.colorSameWarehouse;
        canMove = true;
      }
    }

    double widthLarge = (widget.width-15)/3*2;
    double widthSmall = (widget.width-15)/3;
    String warehouseName = warehouseStorage?.identifier ?? '';
    double qtyOnHand = widget.storage.qtyOnHand ?? 0;
    String quantity = Memory.numberFormatter0Digit.format(qtyOnHand) ;
    return  GestureDetector(
      onTap: () async {
        if(!canMove){
          showErrorMessage(context, ref, Messages.ERROR_CANNOT_MOVE_STORAGE);
          return;
        }
        ref.read(isDialogShowedProvider.notifier).update((state)=>true);
        ref.read(isScanningFromDialogProvider.notifier).update((state)=>false);
        _selectLocatorDialog(ref);

      },
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            spacing: 5,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: widthSmall,
                child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Messages.WAREHOUSE_SHORT),
                    Text(Messages.LOCATOR_SHORT),
                    Text(Messages.QUANTITY_SHORT),
                    Text(Messages.ATTRIBUET_INSTANCE),

                  ],
                ),
              ),
              SizedBox(
                width: widthLarge,
                child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(warehouseName),
                    Text(widget.storage.mLocatorID?.value ?? '', overflow: TextOverflow.ellipsis),
                    Text(
                      quantity,
                      style: TextStyle(
                        color: qtyOnHand < 0 ? Colors.redAccent : Colors.black,
                      ),
                    ),
                    Text(widget.storage.mAttributeSetInstanceID?.identifier ?? '', overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
  Future<void> _selectLocatorDialog(WidgetRef ref) async {

    MemoryProducts.index = widget.index;
    MemoryProducts.listLength = widget.listLength;
    MemoryProducts.storage = widget.storage;
    MemoryProducts.width = widget.width;


    if(widget.storage.mLocatorID != null){
      ref.read(selectedLocatorFromProvider.notifier).update((state) => widget.storage.mLocatorID!);
      ref.read(isDialogShowedProvider.notifier).update((state)=>false);
      ref.invalidate(scannedLocatorToProvider);
      ref.invalidate(selectedLocatorToProvider);

      Future.delayed(Duration(microseconds: 100),(){
        ref.read(actionScanProvider.notifier).state = Memory.ACTION_GET_LOCATOR_TO_VALUE;
      });
      print('------------------action ${ref.read(actionScanProvider.notifier).state}');
      String productUPC = widget.storage.mProductID?.identifier ?? '-1';
      productUPC = productUPC.split('_').first;
      if(ref.context.mounted) {

        ref.context.go(
            '${AppRouter.PAGE_UNSORTED_STORAGE_ON_HAND}/$productUPC',
            extra: widget.notifier);
      }
    } else {
      showErrorMessage(context, ref, Messages.ERROR_LOCATOR_FROM);
      return;
    }

  }
  void showErrorMessage(BuildContext context, WidgetRef ref, String message) {
    if (!context.mounted) {
      Future.delayed(const Duration(milliseconds: 500));
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

}