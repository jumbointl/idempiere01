
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';


import '../common/code_and_fire_action_notifier.dart';
import '../product_provider_common.dart';
import '../store_on_hand_for_put_away_movement.dart';
import '../store_on_hand_provider.dart';
import 'find_store_on_hand_by_upc_sku_action_provider.dart';

class FindStoreOnHandByUpcSkuAction extends CodeAndFireActionNotifier {
  FindStoreOnHandByUpcSkuAction({required super.ref})
      : super(
    scannedCodeProvider: scannedCodeForPutAwayMovementProvider,
    fireCounterProvider: fireSearchStoreOnHandeForPAMProvider,
    saveLastSearch: true,
    enableScanningFlag: true,
    trimAndUppercase: true,
    enableNormalizeUpc: false,
    extraSetting: (ref, value) {
      ref.invalidate(productStoreOnHandCacheProvider);
      ref.read(searchByMOLIConfigurableSKUProvider.notifier).state = false;

      // tu código hacía esto también:
      ref.read(scannedCodeTimesProvider.notifier).state++;
      ref.read(isScanningProvider.notifier).state = true;
    },
  );

  @override
  FutureProvider<ResponseAsyncValue> get responseAsyncValueProvider =>
      findProductForPutAwayMovementProvider;
}
