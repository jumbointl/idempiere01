import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_movement.dart';
import '../providers/products_scan_notifier.dart';
class MovementCard extends ConsumerStatefulWidget {
  final IdempiereMovement movement;
  final ProductsScanNotifier productsNotifier ;
  final double width;
  const MovementCard({required this.productsNotifier, required this.movement, required this.width, super.key});


  @override
  ConsumerState<MovementCard> createState() => MovementCardState();
}

class MovementCardState extends ConsumerState<MovementCard> {


  @override
  Widget build(BuildContext context) {
    Color backGroundColor = themeColorPrimaryLight2;
    return SingleChildScrollView(
      child: Container(
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
            Text('${Messages.ID}: ${widget.movement.id ?? '--'}'),
            Text('${Messages.DOC_STATUS}: ${widget.movement.docStatus?.identifier ?? '--'}'),
            Text('${Messages.FROM}: ${widget.movement.mWarehouseID?.identifier ?? '--'}'),
            Text('${Messages.TO}: ${widget.movement.mWarehouseToID?.identifier ?? '--'}'),
          ],
        ),
      ),
    );
  }
}