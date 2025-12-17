// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_line.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/memory.dart';

class MovementLineCardForCreate extends ConsumerStatefulWidget {
  final double width;
  final IdempiereMovementLine movementLine;
  const MovementLineCardForCreate({super.key, required this.movementLine, required this.width});

  @override
  ConsumerState<MovementLineCardForCreate> createState() => _MovementLineCardForCreateState();
}

class _MovementLineCardForCreateState extends ConsumerState<MovementLineCardForCreate> {
  TextStyle style = TextStyle(fontSize: themeFontSizeLarge ,color: Colors.white,
      fontWeight: FontWeight.bold);
  @override
  Widget build(BuildContext context) {
    print('print Movement Line Create MovementLineCardForCreate');
    IdempiereProduct product = widget.movementLine.mProductID ?? IdempiereProduct();
    String id = widget.movementLine.mProductID?.identifier.toString() ?? '';
    String quantity = Memory.numberFormatter0Digit.format(widget.movementLine.movementQty ?? 0);
    quantity = '${Messages.QUANTITY} : $quantity';
    String name = widget.movementLine.mProductID?.name ?? '';
    String locatorFom=widget.movementLine.mLocatorID?.value ?? '';
    String locatorTo=widget.movementLine.mLocatorToID?.value ?? '';
    Icon icon = Icon(Icons.new_releases, color: Colors.green, size: 40);
    print('print Movement Line Create MovementLineCardForCreate');
    return Container(
      padding: const EdgeInsets.all(10),
      height: 170,
      width:double.infinity,
        decoration: BoxDecoration(
          color: Colors.cyan[800],
          borderRadius: BorderRadius.circular(15),

        ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Messages.ID} $id',
                  style: style
                ),
                Text(
                  quantity,
                  style: style,overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${Messages.FROM} : ${Messages.LOCATOR} : $locatorFom',
                  style: style,overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${Messages.TO} : ${Messages.LOCATOR} : $locatorTo',
                  style: style,overflow: TextOverflow.ellipsis,
                ),
                Text(
                  name,
                    style: style
                ),

              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white, //tx.backgroundColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: icon,
          ),

        ],
      )
    );
  }
}

