import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
class NewMovementLineCard extends ConsumerStatefulWidget {
  final IdempiereMovementLine movementLine;
  final double width;
  final int index;
  final int totalLength;
  bool? showLocators = false;
  NewMovementLineCard( {required this.width, required this.movementLine, super.key,
    required this.index, required this.totalLength, this.showLocators});


  @override
  ConsumerState<NewMovementLineCard> createState() => NewMovementLineCardState();
}

class NewMovementLineCardState extends ConsumerState<NewMovementLineCard> {

  double? height =200;
  @override
  Widget build(BuildContext context) {
    if(widget.showLocators??false){
      height = 210;
    } else {
      height = 160;
    }
    String quantity = Memory.numberFormatter0Digit.format(widget.movementLine.movementQty ?? 0);
    Color backGroundColor = Colors.cyan[800]!;
    TextStyle textStyleTitle = TextStyle(fontSize: themeFontSizeLarge, color: Colors.white,fontWeight: FontWeight.bold);
    TextStyle textStyle = TextStyle(fontSize: themeFontSizeNormal, color: Colors.white,fontWeight: FontWeight.bold);
    return Container(
      height: height,
      width: widget.width,
      decoration: BoxDecoration(
        color: backGroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5,
        children: [
          Text(widget.movementLine.productName ?? '--',style: textStyle,),
          Row(
            spacing: 5,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: widget.width / 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Messages.ID,style: textStyleTitle),
                    Text(Messages.QUANTITY_SHORT,style: textStyleTitle),
                    Text(Messages.UPC,style: textStyleTitle),
                    Text(Messages.SKU,style: textStyleTitle),
                    if(widget.showLocators ?? false)Text(Messages.FROM,style: textStyleTitle),
                    if(widget.showLocators ?? false)Text(Messages.TO,style: textStyleTitle),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${widget.movementLine.id ?? '--'}',style: textStyleTitle),
                    Text(quantity,style: textStyleTitle),
                    Text(widget.movementLine.uPC ?? '--',style: textStyleTitle),
                    Text(widget.movementLine.sKU ?? '--',style: textStyleTitle),
                    if(widget.showLocators ?? false)Text(widget.movementLine.mLocatorID?.identifier ?? '--',style: textStyleTitle),
                    if(widget.showLocators ?? false)Text(widget.movementLine.mLocatorToID?.identifier ?? '--',style: textStyleTitle),
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