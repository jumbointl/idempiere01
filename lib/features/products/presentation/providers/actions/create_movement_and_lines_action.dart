import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/memory.dart';
import '../../../domain/idempiere/put_away_movement.dart';
import '../../screens/movement/provider/new_movement_provider.dart';
import '../common/set_and_fire_action_notifier.dart';
import '../common_provider.dart';

class CrateMovementAndLinesAction extends SetAndFireActionNotifier<PutAwayMovement> {
  CrateMovementAndLinesAction({required Ref ref})
      : super(
    ref: ref,
    payloadProvider: putAwayMovementCreateProvider,
    fireCounterProvider: fireCreateMovementProvider,
    extraSetting: (ref, movement) {
      final docType = ref.read(allowedMovementDocumentTypeProvider);
      if (docType == Memory.MM_ELECTRONIC_DELIVERY_NOTE_ID) {
        movement.movementToCreate!.cDocTypeID = Memory.electronicDeliveryNote;
      }
    },
  );
}
