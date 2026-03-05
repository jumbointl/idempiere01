import '../../../domain/sql/sql_data_inventory_line.dart';
import '../../screens/inventory/edit/inventory_provider_for_line.dart';
import '../common/set_and_fire_action_notifier.dart';

class CreateInventoryLineAction
    extends SetAndFireActionNotifier<SqlDataInventoryLine> {
  CreateInventoryLineAction({required super.ref})
      : super(
    payloadProvider: newSqlDataInventoryLineProvider,
    fireCounterProvider: fireCreateInventoryLineProvider,
  );
}