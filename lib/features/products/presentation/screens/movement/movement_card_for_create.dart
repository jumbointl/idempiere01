// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';


import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/messages.dart';

class MovementCardForCreate extends ConsumerStatefulWidget {
  Color bgColor;
  late IdempiereMovement? movement;
  double height = 100.0;
  double width = double.infinity;
  MovementCardForCreate({
    super.key,
    required this.bgColor,
    required this.height,
    required this.width,
    this.movement,
  });

  @override
  ConsumerState<MovementCardForCreate> createState() => MovementCardForCreateState();
}


class MovementCardForCreateState extends ConsumerState<MovementCardForCreate> {
  @override
  Widget build(BuildContext context) {
    String from='';
    String to='';
    //String subtitleLeft='';
    //String subtitleRight='';
    //String documentNo='';
    //String date='';
    //String id='';
    IdempiereMovement movement = widget.movement ?? IdempiereMovement();

    from = '${Messages.FROM}:${movement.mWarehouseID?.identifier?? ''}';
    to = '${Messages.TO}:${movement.mWarehouseToID?.identifier ?? ''}';
    if(from=='${Messages.FROM}:'){
      from = '${Messages.FROM}:${movement.mWarehouseID?.id?? 'To do'}';
    }
    if(to=='${Messages.TO}:'){
      to = '${Messages.TO}:${movement.mWarehouseToID?.id ?? 'To do'}';
    }
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.bgColor,
          // image: DecorationImage(

          //   image: AssetImage('assets/images/supply-chain.png'),
          //   fit: BoxFit.cover,
          //   alignment: Alignment.topRight,
          // ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.shadow.withValues(alpha: 0.08),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
          border: Border.all(
            color: context.outline.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(alignment: Alignment.topRight,
            child: Icon(Icons.add_circle, color: themeColorPrimary, size: 40,)),
            Text(
              from ,
              textAlign: TextAlign.end,
              style: context.bodyMedium.bold
                  .k(context.titleInverse)
                  .copyWith(letterSpacing: 0.6),
            ),
            6.s,
            Text(
              to ,
              textAlign: TextAlign.end,
              style: context.bodyMedium.bold
                  .k(context.titleInverse)
                  .copyWith(letterSpacing: 0.6),
            ),
            6.s,



          ],
        ),
      ),
    );
  }

}
