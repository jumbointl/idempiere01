import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_movement.dart';
import '../providers/products_scan_notifier.dart';
class MovementCard2 extends ConsumerStatefulWidget {
  final IdempiereMovement movement;
  final ProductsScanNotifier productsNotifier ;
  final double width;
  double? height = 150;
  bool? isDarkMode = false;
  MovementCard2({this.isDarkMode, required this.productsNotifier,
    required this.movement, required this.width, super.key, this.height});


  @override
  ConsumerState<MovementCard2> createState() => MovementCardState2();
}

class MovementCardState2 extends ConsumerState<MovementCard2> {

  double fontSizeMedium = 16;
  double fontSizeLarge = 22;


  @override
  Widget build(BuildContext context) {
    Color backGroundColor = themeColorPrimaryLight2;
    Color foreGroundColor = Colors.black;
    if(widget.isDarkMode ?? true){
      backGroundColor = themeColorPrimaryDark;
      foreGroundColor = Colors.white;
    }
    if(widget.movement.id == null || widget.movement.id! <= 0){
      return Container(
        width: widget.width,
        height: 150,
        decoration: BoxDecoration(
          color: backGroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Center(
          child: Column(
            children: [
              Text(Messages.CREATE_OR_FIND_A_MOVEMENT,style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: foreGroundColor,),),
              Text(Messages.SCAN_TO_GET_LOCATOR_TO,style: TextStyle(
                fontSize: themeFontSizeSmall,
                fontWeight: FontWeight.bold,
                color: foreGroundColor,),),
            ],
          ),
        ),
      );
    }

    return Container(
      width: widget.width,
      height: 200,
      decoration: BoxDecoration(
        color: backGroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5,
        children: [
          Row(

            children: [
              Expanded(
                flex: 1, // Use widthSmall for this column's width
                child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Messages.ID,style: TextStyle(
                      fontSize: fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: foreGroundColor,),),
                    Text(Messages.WAREHOUSE_TO_SHORT,style: TextStyle(
                      fontSize: fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: foreGroundColor,),),
                    Text(Messages.FROM,style: TextStyle(
                      fontSize: fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: foreGroundColor,),),
                    Text(Messages.TO
                      ,style: TextStyle(
                        fontSize: fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: foreGroundColor,),),
                    Text(Messages.DATE
                      ,style: TextStyle(
                        fontSize: fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: foreGroundColor,),),

                  ],
                ),
              ),
              Expanded(
                flex: 2, // Use widthSmall for this column's width
                child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${widget.movement.id ?? '--'}',style: TextStyle(
                      fontSize: fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: foreGroundColor,),),
                    Text(widget.movement.docStatus?.identifier ?? '--',style: TextStyle(
                      fontSize: fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: foreGroundColor,),),
                    Text(widget.movement.mWarehouseID?.identifier ?? '--',style: TextStyle(
                      fontSize: fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: foreGroundColor,),),
                    Text(widget.movement.mWarehouseToID?.identifier ?? '--'
                      ,style: TextStyle(
                        fontSize: fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: foreGroundColor,),),
                    Text(widget.movement.movementDate ?? '--'
                      ,style: TextStyle(
                        fontSize: fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: foreGroundColor,),),

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