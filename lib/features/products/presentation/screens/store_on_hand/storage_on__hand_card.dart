
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/products_home_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/idempiere/idempiere_warehouse.dart';
import '../../providers/locator_provider.dart';
import '../../providers/movement_provider.dart';
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

  const StorageOnHandCard(this.notifier, this.storage, this.index, this.listLength, {required this.width, super.key,});


  @override
  ConsumerState<StorageOnHandCard> createState() =>StorageOnHandCardState();
}

class StorageOnHandCardState extends ConsumerState<StorageOnHandCard> {
  late var usePhoneCamera ;
  late var isScanning ;
  late var locatorTo;
  late var allowedLocatorId;

  @override
  Widget build(BuildContext context) {
    usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    isScanning = ref.watch(isScanningProvider.notifier);
    locatorTo = ref.watch(scannedLocatorToProvider);
    allowedLocatorId = ref.watch(allowedLocatorFromIdProvider.notifier);
    final warehouse = ref.read(authProvider).selectedWarehouse;
    int warehouseID = warehouse?.id ?? 0;
    IdempiereWarehouse? warehouseStorage = widget.storage.mLocatorID?.mWarehouseID;
    bool canMove = false ;
    Color background = widget.colorDifferentWarehouse;

    if(allowedLocatorId.state != null && allowedLocatorId.state! > 0){
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
    String warehouseName = warehouseStorage?.identifier ?? '--';
    double qtyOnHand = widget.storage.qtyOnHand ?? 0;
    String quantity = Memory.numberFormatter0Digit.format(qtyOnHand) ;
    return GestureDetector(
      onTap: () async {
        if(!canMove){
          return;
        }
        ref.read(isDialogShowedProvider.notifier).update((state)=>true);
        ref.read(isScanningFromDialogProvider.notifier).update((state)=>false);
        _selectLocatorDialog(context,ref);

      },
      child: Container(
        margin: const EdgeInsets.all(5),
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
                    Text(widget.storage.mLocatorID?.value ?? '--', overflow: TextOverflow.ellipsis),
                    Text(
                      quantity,
                      style: TextStyle(
                        color: qtyOnHand < 0 ? Colors.redAccent : Colors.black,
                      ),
                    ),
                    Text(widget.storage.mAttributeSetInstanceID?.identifier ?? '--', overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
  void _selectLocatorDialog(BuildContext context, WidgetRef ref) {

    MemoryProducts.index = widget.index;
    MemoryProducts.listLength = widget.listLength;
    MemoryProducts.storage = widget.storage;
    MemoryProducts.width = widget.width;
    MemoryProducts.createNewMovement = true;
    if(widget.storage.mLocatorID != null){
      MemoryProducts.locatorFrom = widget.storage.mLocatorID!;
      ref.read(selectedLocatorFromProvider.notifier).update((state) => widget.storage.mLocatorID!);
      ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_GET_LOCATOR_TO_VALUE);
      ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND;
      context.push(AppRouter.PAGE_UNSORTED_STORAGE_ON_HAND,extra:widget.notifier);
    }

  }


}