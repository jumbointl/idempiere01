// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';


import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import 'movements_screen.dart';

class MovementCard extends ConsumerStatefulWidget {
  Color bgColor;
  late IdempiereMovement? movement;
  double height = 200.0;
  double width = double.infinity;
  MovementsScreen movementScreen;
  MovementCard({
    super.key,
    required this.bgColor,
    required this.height,
    required this.width,
    this.movement,
    required this.movementScreen,
  });

  @override
  ConsumerState<MovementCard> createState() => MovementHeaderCardState2();
}


class MovementHeaderCardState2 extends ConsumerState<MovementCard> {
  @override
  Widget build(BuildContext context) {
    String titleLeft='';
    String titleRight='';
    String subtitleLeft='';
    String subtitleRight='';

    String date='';
    String id='';
    IdempiereMovement movement = widget.movement ?? IdempiereMovement();
    bool canConfirm = Memory.canConformMovement(movement) ;

    if(movement.id != null && movement.id!>0){
      id = movement.id?.toString() ?? '';
      date = movement.movementDate?.toString() ?? '';
      titleLeft = '${Messages.FROM}:${movement.mWarehouseID?.identifier ?? ''}';
      titleRight = '${Messages.TO}:${movement.mWarehouseToID?.identifier ?? ''}';
      subtitleLeft = '${Messages.DOC_STATUS}: ${movement.docStatus?.identifier ?? ''}';
      subtitleRight = canConfirm ? Messages.CONFIRM : '';
    } else {
      id = movement.name ?? Messages.EMPTY;
      titleLeft =movement.identifier ?? Messages.EMPTY;
    }

    widget.bgColor = themeColorPrimary;
    return GestureDetector(
      onTap: () {
        //openSearchDialog(context,true);
      },
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: widget.bgColor,
            image: DecorationImage(
              image: AssetImage('assets/images/supply-chain.png'),
              fit: BoxFit.cover,
              alignment: Alignment.topRight,
            ),
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
          padding: EdgeInsets.only(left: 16,right:16, top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Top row: brand & card type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    id,
                    style: context.bodyMedium.bold
                        .k(context.titleInverse)
                        .copyWith(letterSpacing: 0.6),
                  ),
                  Text(
                    date,
                    style: context.bodyMedium.bold.k(
                      context.titleInverse.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              //const Spacer(),

              6.s,
              /// Name & balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    titleLeft,
                    style: context.bodyMedium.bold
                        .k(context.titleInverse)
                        .copyWith(letterSpacing: 0.6),
                  ),
                  Text(
                    titleRight,
                    style: context.bodyMedium.bold
                        .k(context.titleInverse)
                        .copyWith(letterSpacing: 0.6),
                  ),
                ],
              ),
              6.s,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    subtitleLeft ,
                    style: context.bodyMedium.bold
                        .k(context.titleInverse)
                        .copyWith(letterSpacing: 0.6),
                  ),
                  GestureDetector(
                    onTap: (){
                      if(!canConfirm || movement.id == null || movement.id! <= 0) return;
                      widget.movementScreen.confirmButtonPressed(context, ref, movement.id.toString());
                    },
                    child: Container(
                      color: canConfirm ? Colors.green : themeColorPrimary,
                      child: Text(
                        subtitleRight ,
                        textAlign: TextAlign.end,
                        style: context.bodyMedium.bold
                            .k(context.titleInverse)
                            .copyWith(letterSpacing: 0.6),
                      ),
                    ),
                  ),

                ],
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        widget.movementScreen.lastButtonPressed(context, ref, Memory.lastSearch);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: themeColorPrimary,
                        //padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      ),
                      child: Text(Messages.LAST, style: context.bodySmall.k(context.titleInverse)),),
                  ),
                  4.s,
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        widget.movementScreen.findButtonPressed(context, ref, '');
                        //openSearchDialog(context, ref, false);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: themeColorPrimary,
                        //padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      ),
                      child: Text(Messages.FIND, style: context.bodySmall.k(context.titleInverse)),
                    ),
                  ),
                  4.s,
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        widget.movementScreen.newButtonPressed(context, ref, '');
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: themeColorPrimary,
                        //padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      ),
                      child: Text(Messages.NEW, style: context.bodySmall.k(context.titleInverse)),
                    ),
                  ),

                  /*4.s,
                  Expanded(
                    child: TextButton(
                      onPressed: ()  {
                        if(!canConfirm){
                          return;
                        }
                        widget.headersViewModel.confirmButtonPressed(context, ref, '');
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: canConfirm ? Colors.green : Colors.grey,
                        //padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      ),
                      child: Text(Messages.CONFIRM_SHORT, style: context.bodySmall.k(context.titleInverse)),
                    ),
                  ),*/
                ],
              ),
              6.s,
            ],
          ),
        ),
      ),
    );
  }

}
