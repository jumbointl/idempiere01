import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';

import '../common/code_and_fire_action_notifier.dart';
import '../product_provider_common.dart';
import '../product_search_provider.dart';
import '../product_update_upc_provider.dart';

final searchByUpcOrSkuActionProvider =
Provider.autoDispose<SearchByUpcOrSkuAction>((ref) {
  return SearchByUpcOrSkuAction(ref: ref);
});


class SearchByUpcOrSkuAction extends CodeAndFireActionNotifier {
  SearchByUpcOrSkuAction({required super.ref})
      : super(
    scannedCodeProvider: scannedCodeForSearchByUPCOrSKUProvider,
    fireCounterProvider: fireSearchByUPCOrSKUProvider,

    // tu behavior original
    saveLastSearch: true,
    enableScanningFlag: true,
    trimAndUppercase: true,
    enableNormalizeUpc: true,

    extraSetting: (ref, value) {
      // reset UPC update temp state
      ref.read(dataToUpdateUPCProvider.notifier).state = [];

      // tu contador
      ref.read(scannedCodeTimesProvider.notifier).state++;
    },
  );

  @override
  FutureProvider<ResponseAsyncValue> get responseAsyncValueProvider => throw UnimplementedError();
}
