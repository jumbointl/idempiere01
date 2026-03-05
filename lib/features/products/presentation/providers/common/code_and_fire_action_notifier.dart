import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/data/memory.dart';
import '../../../domain/idempiere/response_async_value.dart';
import '../actions/find_product_by_sku_name_action_provider.dart';
import 'app_action_notifier.dart';

typedef ExtraSetting = void Function(Ref ref, String value);
typedef StringNormalizer = String Function(String value);

abstract class CodeAndFireActionNotifier extends AppActionNotifier<void> {
  CodeAndFireActionNotifier({
    required Ref ref,
    required this.scannedCodeProvider,
    required this.fireCounterProvider,

    this.saveLastSearch = true,
    this.enableScanningFlag = true,
    this.trimAndUppercase = true,

    /// NEW
    this.enableNormalizeUpc = true,
    this.normalizer,

    this.extraSetting,
    this.extraSettingBeforeFire = true,
  }) : super(ref, null);

  final StateProvider<String?> scannedCodeProvider;
  final StateProvider<int>? fireCounterProvider;

  final bool saveLastSearch;
  final bool enableScanningFlag;
  final bool trimAndUppercase;

  /// NEW
  final bool enableNormalizeUpc;
  final StringNormalizer? normalizer;

  final ExtraSetting? extraSetting;
  final bool extraSettingBeforeFire;
  FutureProvider<ResponseAsyncValue> get responseAsyncValueProvider;
  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    var value = inputData;

    // 1) saneamiento básico
    if (trimAndUppercase) value = value.trim().toUpperCase();

    // 2) normalización (opcional)
    if (normalizer != null) {
      value = normalizer!(value);
    } else if (enableNormalizeUpc) {
      value = normalizeUPC(value);
    }

    if (value.isEmpty) return;
    final searchMode = ref.read(productSearchModeProvider);
    switch (actionScan) {
      case Memory.ACTION_FIND_MOVEMENT_BY_ID:
        Memory.lastSearchMovement = value;
        break;
      case Memory.ACTION_GET_LOCATOR_TO_VALUE:
      case Memory.ACTION_GET_LOCATOR_VALUE:
        Memory.lastSearchLocator = value;
        break;
      case Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND:
      case Memory.ACTION_FIND_BY_UPC_SKU:
        switch (searchMode) {
          case ProductSearchMode.upc:
            Memory.lastSearchUpc = value;
            break;
          case ProductSearchMode.sku:
            Memory.lastSearchSku = value;

            break;
          case ProductSearchMode.name:
            Memory.lastSearchName = value;
            break;
        }
        break;
      default:
        Memory.lastSearch = value;
        break;

    }

    if (enableScanningFlag) setScanning(true);
    if (saveLastSearch) setLastSearch(value);

    if (extraSettingBeforeFire) extraSetting?.call(this.ref, value);

    this.ref.read(scannedCodeProvider.notifier).state = value;

    if (fireCounterProvider != null) {
      this.ref.read(fireCounterProvider!.notifier).state++;
    }
    if (!extraSettingBeforeFire) extraSetting?.call(this.ref, value);

  }
}
