// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_line.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

import '../../../../shared/data/memory.dart';

class MovementLineCardWithoutController extends ConsumerStatefulWidget {
  final double radius;
  final double width;
  final double height = 200;
  final IdempiereMovementLine movementLine;
  const MovementLineCardWithoutController({super.key,
    this.radius = 16, required this.movementLine, required this.width});

  @override
  ConsumerState<MovementLineCardWithoutController> createState() => _MovementLineCardWithoutControllerState();
}

class _MovementLineCardWithoutControllerState extends ConsumerState<MovementLineCardWithoutController> {
  TextStyle style = TextStyle(fontSize: themeFontSizeNormal, color: Colors.white,
      fontWeight: FontWeight.bold);
  @override
  Widget build(BuildContext context) {
    print('-------------------------MMovementLineCardWithoutController');
    String id = widget.movementLine.id?.toString() ?? '';
    String quantity = '${Messages.QUANTITY} : ${Memory.numberFormatter0Digit.format(widget.movementLine.movementQty ?? 0)}';
    String name = widget.movementLine.productName ?? '';
    String uPC = widget.movementLine.uPC ?? '';
    String sKU = widget.movementLine.sKU ?? '';
    String locatorFom=widget.movementLine.mLocatorID?.identifier ?? '';
    String locatorTo=widget.movementLine.mLocatorToID?.identifier ?? '';
    return Container(
      width:MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green[800],
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Text(
            '${Messages.ID} $id',
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            quantity,
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
          /*Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Messages.ID} $id',
                style: style,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                quantity,
                style: style,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),*/
          Text(
            '${Messages.FROM} : ${Messages.LOCATOR} : $locatorFom',
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${Messages.TO} : ${Messages.LOCATOR} : $locatorTo',
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            name,
            style: style,
            //overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${Messages.UPC} $uPC',
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${Messages.SKU} $sKU',
            style: style,
            overflow: TextOverflow.ellipsis,
          ),

        ],
      )
    );
  }
}

