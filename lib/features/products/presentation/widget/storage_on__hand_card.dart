import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../domain/idempiere/idempiere_warehouse.dart';
class StorageOnHandCard extends ConsumerStatefulWidget {

  final IdempiereStorageOnHande storage;
  final int index;
  final int listLength;
  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  final double width;
  const StorageOnHandCard(this.storage, this.index, this.listLength, {required this.width, super.key});


  @override
  ConsumerState<StorageOnHandCard> createState() =>StorageOnHandCardState();
}

class StorageOnHandCardState extends ConsumerState<StorageOnHandCard> {
  @override
  Widget build(BuildContext context) {
    final warehouse = ref.read(authProvider).selectedWarehouse;
    int warehouseID = warehouse?.id ?? 0;
    IdempiereWarehouse? warehouseStorage = widget.storage.mLocatorID?.mWarehouseID;

    Color background = warehouseStorage?.id == warehouseID ? widget.colorSameWarehouse : widget.colorDifferentWarehouse;
    double widthLarge = widget.width/3*2;
    double widthSmall = widget.width/3;
    String warehouseName = warehouseStorage?.identifier ?? '--';
    double qtyOnHand = widget.storage.qtyOnHand ?? 0;
    String quantity = Memory.numberFormatter0Digit.format(qtyOnHand) ;

    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: widthSmall.toInt(), // Use widthLarge for this column's width
              child: Column(
                spacing: 5,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Messages.WAREHOUSE),
                  Text(Messages.LOCATOR),
                  Text(Messages.QUANTITY),
                  Text(Messages.ATTRIBUET_INSTANCE),

                ],
              ),
            ),
            Expanded(
              flex: widthLarge.toInt(), // Use widthLarge for this column's width
              child: Column(
                spacing: 5,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(warehouseName),
                  Text(widget.storage.mLocatorID?.value ?? '--', overflow: TextOverflow.ellipsis),
                  Text(quantity),
                  Text(widget.storage.mAttributeSetInstanceID?.identifier ?? '--', overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}