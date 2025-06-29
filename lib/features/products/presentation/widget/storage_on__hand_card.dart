import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_storage_on_hande.dart';
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
    Color background = widget.storage.mLocatorID?.id == warehouseID ? widget.colorSameWarehouse : widget.colorDifferentWarehouse;
    double widthLarge = widget.width/5*2;
    double widthSmall = widget.width/5;
    print('----------user warehouse id $warehouseID');
    // solo prueba
    if(widget.index==1){
      background = widget.colorSameWarehouse;
    }

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
              flex: widthLarge.toInt(), // Use widthLarge for this column's width
              child: Column(
                spacing: 5,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Messages.LOCATORS),
                  Text(widget.storage.mLocatorID?.identifier ?? '--', overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Expanded(
              flex: widthLarge.toInt(), // Use widthLarge for this column's width
              child: Column(
                spacing: 5,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(Messages.QUANTITY),
                  Text('${widget.storage.qtyOnHand ?? '--'}'),
                ],
              ),
            ),
            Expanded(
              flex: widthSmall.toInt(), // Use widthLarge for this column's width
              child: Column(
                spacing: 5,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  //Text(Messages.REGISTERS),
                  Text('${widget.index} / ${widget.listLength}'),
                  Text(''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}