import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';

import '../../screens/movement/provider/new_movement_provider.dart';
import '../common/code_and_fire_action_notifier.dart';
import 'find_movement_by_id_action_provider.dart';

class FindMovementByIdAction extends CodeAndFireActionNotifier {
  FindMovementByIdAction({required Ref ref})
      : super(
    ref: ref,
    scannedCodeProvider: newScannedMovementIdForSearchProvider,
    fireCounterProvider: fireFindMovementByIdProvider,
    saveLastSearch: false,
    enableScanningFlag: true,
    trimAndUppercase: true,
  );

  @override
  FutureProvider<ResponseAsyncValue> get responseAsyncValueProvider
          => newFindMovementByIdOrDocumentNOProvider;
}


