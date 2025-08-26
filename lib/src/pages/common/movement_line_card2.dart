// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_line.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';
import 'package:monalisa_app_001/src/core/constants/app_constants.dart';

import '../../../features/shared/data/memory.dart';

class MovementLineCard2 extends ConsumerStatefulWidget {
  final double radius;
  final double width;
  final IdempiereMovementLine movementLine;
  const MovementLineCard2({super.key, this.radius = 16, required this.movementLine, required this.width});

  @override
  ConsumerState<MovementLineCard2> createState() => _MovementLineCardState2();
}

class _MovementLineCardState2 extends ConsumerState<MovementLineCard2> {
  @override
  Widget build(BuildContext context) {
    String id = widget.movementLine.id?.toString() ?? '';
    String quantity = Memory.numberFormatter0Digit.format(widget.movementLine.movementQty ?? 0);
    String name = widget.movementLine.productName ?? '';
    String uPC = widget.movementLine.uPC ?? '';
    String sKU = widget.movementLine.sKU ?? '';
    String locatorFom=widget.movementLine.mLocatorID?.identifier ?? '';
    String locatorTo=widget.movementLine.mLocatorToID?.identifier ?? '';
    Icon icon = Icon(Icons.send, color: Colors.amber, size: 22.sp);
    return Container(
      width:double.infinity,
      padding: kPadding.p,
      decoration: BoxDecoration(
        color: context.cardBackground.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${Messages.ID} $id',
                      style: context.bodyMedium.bold.copyWith(
                        color: context.secondaryContent,
                      ),
                    ),
                    Text(
                      quantity,
                      style: context.bodyMedium.bold.copyWith(
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${Messages.FROM} : ${Messages.LOCATOR} : $locatorFom',
                  style: context.bodyMedium.bold.copyWith(
                    color: context.secondaryContent,
                  ),
                ),
                Text(
                  '${Messages.TO} : ${Messages.LOCATOR} : $locatorTo',
                  style: context.bodyMedium.bold.copyWith(
                    color: Colors.purple,
                  ),
                ),
                Text(name, style: context.bodyMedium.bold),
                SizedBox(height: 4.h),
                Text(
                  '${Messages.UPC} $uPC',
                  style: context.bodyMedium.copyWith(
                    color: context.secondaryContent,
                  ),),
                Text(
                  '${Messages.SKU} $sKU',
                  style: context.bodyMedium.copyWith(
                    color: context.secondaryContent,
                  ),),

              ],
            ),
          ),
          SizedBox(width: 14.w),
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: Colors.white, //tx.backgroundColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: icon,
          ),

        ],
      )
    );
  }
}

