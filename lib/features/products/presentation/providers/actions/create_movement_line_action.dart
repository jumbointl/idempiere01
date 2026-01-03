import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/memory.dart';
import '../../../domain/idempiere/put_away_movement.dart';
import '../../../domain/sql/sql_data_movement_line.dart';
import '../../screens/movement/provider/new_movement_provider.dart';
import '../common/set_and_fire_action_notifier.dart';
import '../common_provider.dart';
import '../movement_provider_for_line.dart';

class CrateMovementLineAction extends SetAndFireActionNotifier<SqlDataMovementLine> {
  CrateMovementLineAction({required Ref ref})
      : super(
    ref: ref,
    payloadProvider: newSqlDataMovementLineProvider,
    fireCounterProvider: fireCreateMovementLineProvider,

  );
}
