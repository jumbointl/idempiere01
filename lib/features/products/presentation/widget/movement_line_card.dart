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
  const MovementLineCard({required this.productsNotifier, required this.movementLine, super.key});


  @override
  ConsumerState<MovementLineCard> createState() => MovementCardState();
}

class MovementCardState extends ConsumerState<MovementLineCard> {


  @override
  Widget build(BuildContext context) {

    String quantity = Memory.numberFormatter0Digit.format(widget.movementLine.movementQty ?? 0);
    Color backGroundColor = themeColorPrimaryLight2;
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: backGroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            Text('${Messages.ID}: ${widget.movementLine.id ?? '--'}'),
            Text('${Messages.NAME}: ${widget.movementLine.productName ?? '--'}'),
            Text('${Messages.UPC}: ${widget.movementLine.uPC ?? '--'}'),
            Text('${Messages.FROM}: ${widget.movementLine.mLocatorID?.identifier ?? '--'}'),
            Text('${Messages.TO}: ${widget.movementLine.mLocatorToID?.identifier ?? '--'}'),
            Text('${Messages.QUANTITY_SHORT}: $quantity'),
          ],
        ),
      ),
    );
  }
}