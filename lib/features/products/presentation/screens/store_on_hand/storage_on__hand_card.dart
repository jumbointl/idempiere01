

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/unsorte_storage_on_hand_provider.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../common/messages_dialog.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/idempiere/idempiere_warehouse.dart';
import '../../providers/actions/find_locator_to_action_provider.dart';
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
  final bool readStockOnly;
  final bool isInventory;
  IdempiereLocator? locatorFilter;



  StorageOnHandCard(this.notifier, this.storage, this.index, this.listLength, {

    required this.width,this.locatorFilter, required this.readStockOnly,
    required this.isInventory,
    super.key,});


  @override
  ConsumerState<StorageOnHandCard> createState() =>StorageOnHandCardState();
}

class StorageOnHandCardState extends ConsumerState<StorageOnHandCard> {
  late var isScanning ;
  late var allowedLocatorId;
  bool readStockOnly = false ;
  @override
  Widget build(BuildContext context) {
    readStockOnly = widget.readStockOnly;
    isScanning = ref.watch(isScanningProvider.notifier);
    String a = Messages.FIND_PRODUCT_BY_UPC_SKU;
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

    ref.read(isDialogShowedProvider.notifier).update((state)=>true);
    ref.read(isScanningFromDialogProvider.notifier).update((state)=>false);
    if(widget.storage.mLocatorID != null){
      ref.read(selectedLocatorFromProvider.notifier).update((state) => widget.storage.mLocatorID!);
      ref.read(isDialogShowedProvider.notifier).update((state)=>false);
      ref.invalidate(scannedLocatorToProvider);
      ref.invalidate(selectedLocatorToProvider);

      String productUPC = widget.storage.mProductID?.identifier ?? '-1';
      productUPC = productUPC.split('_').first;
      if (ref.context.mounted) {
        //context.push('${AppRouter.PAGE_UNSORTED_STORAGE_ON_HAND}/$productUPC');
        await showUnsortedStorageSheet(
          context: ref.context,
          ref: ref,
          productUPC: productUPC,
          readStockOnly: readStockOnly,
          isInventory: widget.isInventory,
        );
      }

    } else {
      await showErrorMessage(context, ref, Messages.ERROR_LOCATOR_FROM);
      return;
    }

  }


}