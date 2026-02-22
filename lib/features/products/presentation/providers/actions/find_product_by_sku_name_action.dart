
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';


import '../common/code_and_fire_action_notifier.dart';
import '../product_provider_common.dart';
import '../store_on_hand_for_put_away_movement.dart';
import 'find_product_by_sku_name_action_provider.dart';

class FindProductBySkuNameAction extends CodeAndFireActionNotifier {
  FindProductBySkuNameAction({required super.ref})
      : super(
    scannedCodeProvider: scannedCodeForSearchBySKUNameProvider,
    fireCounterProvider: fireSearchBySKUNameProvider,
    saveLastSearch: true,
    enableScanningFlag: true,
    trimAndUppercase: true,
    enableNormalizeUpc: true,
    extraSetting: (ref, value) {
      ref.read(isScanningProvider.notifier).state = true;
      ref.invalidate(productStoreOnHandCacheProvider);
    },
  );

  @override
  FutureProvider<ResponseAsyncValue> get responseAsyncValueProvider =>
      findProductBySKUNameProvider;
}
