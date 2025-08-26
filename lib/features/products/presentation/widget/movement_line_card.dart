import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_movement_line.dart';
import '../providers/products_scan_notifier.dart';
class MovementLineCard extends ConsumerStatefulWidget {
  final IdempiereMovementLine movementLine;
  final ProductsScanNotifier productsNotifier ;
  final double width;
  final int index;
  final int totalLength;
  const MovementLineCard( {required this.width,required this.productsNotifier, required this.movementLine, super.key,
    required this.index, required this.totalLength});


  @override
  ConsumerState<MovementLineCard> createState() => MovementCardState();
}

class MovementCardState extends ConsumerState<MovementLineCard> {


  @override
  Widget build(BuildContext context) {

    String quantity = Memory.numberFormatter0Digit.format(widget.movementLine.movementQty ?? 0);
    Color backGroundColor = themeColorPrimaryLight2;
    return Container(
      decoration: BoxDecoration(
        color: backGroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5,
        children: [
          Text(widget.movementLine.productName ?? '--'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [


            ],
          ),

          Row(
            spacing: 5,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: widget.width / 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Messages.ID),
                    Text(Messages.QUANTITY_SHORT),
                    Text(Messages.UPC),
                    Text(Messages.SKU),
                    Text(Messages.FROM),
                    Text(Messages.TO),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${widget.movementLine.id ?? '--'}'),
                    Text(quantity),
                    Text(widget.movementLine.uPC ?? '--'),
                    Text(widget.movementLine.sKU ?? '--'),
                    Text(widget.movementLine.mLocatorID?.identifier ?? '--'),
                    Text(widget.movementLine.mLocatorToID?.identifier ?? '--'),
                  ],
                ),
              ),


            ],
          ),


        ],
      ),
    );
  }
}