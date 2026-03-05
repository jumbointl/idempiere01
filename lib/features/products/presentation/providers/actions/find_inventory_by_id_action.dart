import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';

import '../common/code_and_fire_action_notifier.dart';
import 'find_inventory_by_id_action_provider.dart';

final findInventoryByIdActionProvider = Provider<FindInventoryByIdAction>((ref) {
  return FindInventoryByIdAction(ref: ref);
});

class FindInventoryByIdAction extends CodeAndFireActionNotifier {
  FindInventoryByIdAction({required super.ref})
      : super(
    scannedCodeProvider: newScannedInventoryIdForSearchProvider,
    fireCounterProvider: fireFindInventoryByIdProvider,
    saveLastSearch: false,
    enableScanningFlag: true,
    trimAndUppercase: true,
  );

  @override
  FutureProvider<ResponseAsyncValue> get responseAsyncValueProvider =>
      newFindInventoryByIdOrDocumentNOProvider;
}