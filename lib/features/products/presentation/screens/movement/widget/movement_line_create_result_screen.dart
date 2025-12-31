import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_line.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../../shared/data/memory.dart';
import '../../../providers/data_create_screen.dart';

class MovementLineCreateResultScreen extends ConsumerWidget {
  final MovementAndLines movementAndLines;
  final DataCreateCloseMode closeMode;

  const MovementLineCreateResultScreen({
    super.key,
    required this.movementAndLines,
    required this.closeMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = movementAndLines;
    final IdempiereMovementLine? line =
    data.movementLines != null && data.movementLines!.isNotEmpty
        ? data.movementLines!.first
        : null;

    if (data.nothingCreated) {
      return _noData(context);
    }

    if (data.onlyMovementCreated) {
      return _onlyMovement(context, data);
    }

    return _movementAndLine(context, data, line);
  }

  Widget _noData(BuildContext context) {
    return Center(
      child: Text(
        Messages.ERROR,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _onlyMovement(BuildContext context, MovementAndLines data) {
    final id = data.id ?? 0;

    return SingleChildScrollView(
      child: Column(
        spacing: 10,
        children: [
          const Icon(Icons.error_rounded, size: 50, color: Colors.orange),
          Text(
            '${Messages.ID} : $id',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          Text(
            Messages.MOVEMENT_LINE_NOT_CREATED,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _movementAndLine(
      BuildContext context,
      MovementAndLines data,
      IdempiereMovementLine? line,
      ) {
    final id = data.id ?? 0;

    return SingleChildScrollView(
      child: Column(
        spacing: 10,
        children: [
          const Icon(Icons.check_circle, size: 100, color: Colors.green),
          Text(
            '${Messages.ID} : $id',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${Messages.DOCUMENT_NO}: ${data.documentNumber}'),
                  Text('${Messages.DATE}: ${data.movementDate ?? '--'}'),
                  Text('${Messages.QUANTITY}: ${Memory.numberFormatter0Digit.format(data.totalMovementQty)}'),
                ],
              ),
            ),
          ),
          if (line != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  spacing: 8,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.productNameWithLine),
                    Text('${Messages.LOCATOR_FROM}: ${line.locatorFromName}'),
                    Text('${Messages.LOCATOR_TO}: ${line.locatorToName}'),
                    Text('${Messages.QUANTITY}: ${line.movementQtyString}'),
                    if (line.attributeName != null)
                      Text('${Messages.ATTRIBUET_INSTANCE}: ${line.attributeName}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
