import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_movement.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_movement_line.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/unsorted_storage_on__hand_card.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/idempiere/idempiere_warehouse.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/products_scan_notifier.dart';
import '../../providers/store_on_hand_provider.dart';
class StorageOnHandCard extends ConsumerStatefulWidget {
  final ProductsScanNotifier notifier;
  final IdempiereStorageOnHande storage;
  final int index;
  final int listLength;
  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  final double width;

  const StorageOnHandCard(this.notifier, this.storage, this.index, this.listLength, {required this.width, super.key});


  @override
  ConsumerState<StorageOnHandCard> createState() =>StorageOnHandCardState();
}

class StorageOnHandCardState extends ConsumerState<StorageOnHandCard> {
  late var usePhoneCamera ;
  late var isScanning ;
  late var locatorTo;

  @override
  Widget build(BuildContext context) {
    usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    isScanning = ref.watch(isScanningProvider.notifier);
    locatorTo = ref.watch(scannedLocatorToProvider);
    final warehouse = ref.read(authProvider).selectedWarehouse;
    int warehouseID = warehouse?.id ?? 0;
    IdempiereWarehouse? warehouseStorage = widget.storage.mLocatorID?.mWarehouseID;
    Color background = warehouseStorage?.id == warehouseID ? widget.colorSameWarehouse : widget.colorDifferentWarehouse;
    double widthLarge = (widget.width-15)/3*2;
    double widthSmall = (widget.width-15)/3;
    String warehouseName = warehouseStorage?.identifier ?? '--';
    double qtyOnHand = widget.storage.qtyOnHand ?? 0;
    String quantity = Memory.numberFormatter0Digit.format(qtyOnHand) ;
    return GestureDetector(
      onTap: () async {
        if(warehouseStorage?.id != warehouseID){
          return;
        }

        ref.read(isDialogShowedProvider.notifier).update((state)=>true);
        ref.read(isScanningFromDialogProvider.notifier).update((state)=>false);
        _createMovementDialog(context,ref);

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


  Future<Future<String?>> _createMovementDialog(BuildContext context, WidgetRef ref) async {
    ref.read(scannedLocatorToProvider.notifier).update((state)=>'');
    ref.read(isDialogShowedProvider.notifier).update((state)=>true);
    return showDialog<String>(
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
            child: UnsortedStorageOnHandCard(widget.notifier, widget.storage, widget.index, width: widget.width,),

          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
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
                const SizedBox(width: 8), // Add some spacing between buttons
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green[300],
                    ),
                    child: Text(Messages.CREATE),
                    onPressed: () {
                      if (locatorTo.isNotEmpty) {
                        // Perform the movement logic here
                        // For example, call a function from your notifier:
                        SqlDataMovement movement = SqlDataMovement();
                        Memory.sqlUsersData.copyToSqlData(movement);
                        //In this case locatorTo and  locatorFrom are the same warehouse
                        if(movement.mWarehouseID != null && movement.mWarehouseID!.id != null){
                          movement.setIdempiereWarehouseTo(movement.mWarehouseID!.id!);
                        }
                        print('---------------------------------- ${jsonEncode(movement.getInsertJson())}');
                        // creado para borrar
                        Memory.newSqlDataMovement = movement ;
                        movement.id = 1018275;

                        SqlDataMovementLine movementLine = SqlDataMovementLine();
                        Memory.sqlUsersData.copyToSqlData(movementLine);
                        movementLine.mMovementID = movement;
                        movementLine.mLocatorID = widget.storage.mLocatorID;
                        movementLine.mProductID = widget.storage.mProductID;
                        movementLine.mLocatorToID = ref.read(idempiereLocatorToProvider);
                        movementLine.movementQty = ref.read(quantityToMoveProvider);
                        movementLine.mAttributeSetInstanceID = widget.storage.mAttributeSetInstanceID;
                        Memory.newSqlDataMovementLines.add(movementLine);

                        print('----------------------------------  ${jsonEncode(movementLine.getInsertJson())}');
                        widget.notifier.createMovement();

                      }
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
}