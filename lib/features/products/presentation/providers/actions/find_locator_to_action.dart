import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';

import '../common/code_and_fire_action_notifier.dart';
import '../locator_provider.dart';
import '../product_provider_common.dart';
import 'find_locator_to_action_provider.dart';

class FindLocatorToAction extends CodeAndFireActionNotifier {
  FindLocatorToAction({required super.ref})
      : super(
    scannedCodeProvider: scannedLocatorToProvider,
    fireCounterProvider: fireFindLocatorProvider, // no dispara búsqueda
    saveLastSearch: false,
    enableScanningFlag: false,
    trimAndUppercase: true,
    enableNormalizeUpc: false,

    extraSetting: (ref, value) {
      ref.read(isScanningFromDialogProvider.notifier).state = true;
      ref.read(isScanningLocatorToProvider.notifier).state = true;
    },
  );

  @override
  // TODO: implement responseAsyncValueProvider
  FutureProvider<ResponseAsyncValue> get responseAsyncValueProvider =>
      findLocatorToProvider;
}
