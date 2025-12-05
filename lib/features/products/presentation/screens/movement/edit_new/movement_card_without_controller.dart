// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';


import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/locator_provider.dart';

class MovementCardWithoutController extends ConsumerStatefulWidget {
  Color? bgColor = Colors.cyan[800]!;
  late IdempiereMovement? movement;
  double height = 300.0;
  double width = double.infinity;
  MovementCardWithoutController({
    super.key,
    this.bgColor,
    required this.height,
    required this.width,
    this.movement,
  });

  @override
  ConsumerState<MovementCardWithoutController> createState() => MovementCardWithoutControllerState();
}


class MovementCardWithoutControllerState extends ConsumerState<MovementCardWithoutController> {
  TextStyle style = TextStyle(fontSize: themeFontSizeNormal, color: Colors.white,
      fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    print('-------------------------MovementCardWithoutControllerState');
    String titleLeft='';
    String titleRight='';
    String subtitleLeft='';
    String subtitleRight='';
    String documentNo='';
    String date='';
    String id='';
    IdempiereMovement movement = widget.movement ?? IdempiereMovement();
    final locatorFrom = ref.read(selectedLocatorFromProvider.notifier);
    final locatorTo = ref.read(selectedLocatorToProvider.notifier);

    if(movement.id != null && movement.id!>0){
      id = movement.id?.toString() ?? '';
      date = movement.movementDate?.toString() ?? '';
      titleLeft = '${Messages.FROM}:${movement.mWarehouseID?.identifier ?? movement.mWarehouseID?.value ?? ''}';
      titleRight = '${Messages.TO}:${movement.mWarehouseToID?.identifier ?? movement.mWarehouseToID?.value ?? ''}';
      subtitleLeft = '${Messages.DOC_STATUS}: ${movement.docStatus?.identifier ?? ''}';
      subtitleRight = '';
      documentNo = movement.documentNo ?? '';

    } else {
      id = movement.name ?? Messages.EMPTY;
      titleLeft =movement.identifier ?? Messages.EMPTY;
    }

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.bgColor,
          /*image: DecorationImage(
            image: AssetImage('assets/images/success.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topRight,
          ),*/
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.bgColor!,
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],

        ),
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Text(
              documentNo ?? '' ,
              textAlign: TextAlign.end,
              style: style ,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  id,
                  style: style ,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  date,
                  style: style ,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titleLeft,
                  style: style ,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  titleRight,
                  style: style ,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitleLeft ,
                  style: style ,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitleRight ,
                  textAlign: TextAlign.end,
                  style: style ,
                  overflow: TextOverflow.ellipsis,
                ),

              ],
            ),

          ],
        ),
      ),
    );
  }

}
