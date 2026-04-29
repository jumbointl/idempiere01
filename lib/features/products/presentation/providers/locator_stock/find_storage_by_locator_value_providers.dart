import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../domain/idempiere/response_async_value.dart';
import '../common/code_and_fire_action_notifier.dart';
import 'find_storage_by_locator_value.dart';

final scannedCodeForLocatorStockProvider =
    StateProvider<String?>((ref) => null);

final fireSearchByLocatorValueProvider =
    StateProvider.autoDispose<int>((ref) => 0);

final progressLocatorStockProvider = StateProvider<double>((ref) => 0.0);

final findProductsByLocatorValueProvider =
    FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  final count = ref.watch(fireSearchByLocatorValueProvider);
  if (count == 0) {
    return ResponseAsyncValue(
      isInitiated: false,
      success: false,
      data: null,
    );
  }

  final code = ref.read(scannedCodeForLocatorStockProvider)?.toUpperCase();
  if (code == null || code.isEmpty) {
    return ResponseAsyncValue(
      isInitiated: false,
      success: false,
      data: null,
    );
  }

  // The `M_Product_ID` filter is **NOT** applied here — the query always
  // returns every product on-hand for the locator. The screen filters
  // client-side and only highlights / flags the matching product.

  return findStorageByLocatorValue(
    ref: ref,
    scannedCode: code,
    progressProvider: progressLocatorStockProvider,
  );
});

class FindStorageByLocatorValueAction extends CodeAndFireActionNotifier {
  FindStorageByLocatorValueAction({required super.ref})
      : super(
          scannedCodeProvider: scannedCodeForLocatorStockProvider,
          fireCounterProvider: fireSearchByLocatorValueProvider,
          saveLastSearch: true,
          enableScanningFlag: true,
          trimAndUppercase: true,
          enableNormalizeUpc: false,
        );

  @override
  FutureProvider<ResponseAsyncValue> get responseAsyncValueProvider =>
      findProductsByLocatorValueProvider;
}

final findStorageByLocatorValueActionProvider =
    Provider<FindStorageByLocatorValueAction>((ref) {
  return FindStorageByLocatorValueAction(ref: ref);
});
