
import '../../../domain/sql/sql_data_movement_line.dart';
import '../common/set_and_fire_action_notifier.dart';
import '../movement_provider_for_line.dart';

class CrateMovementLineAction extends SetAndFireActionNotifier<SqlDataMovementLine> {
  CrateMovementLineAction({required super.ref})
      : super(
    payloadProvider: newSqlDataMovementLineProvider,
    fireCounterProvider: fireCreateMovementLineProvider,

  );
}
