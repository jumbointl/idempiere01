import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';

import '../../../../shared/data/memory.dart';
import '../../../common/barcode_utils.dart';
import '../../../common/input_data_processor.dart';
import '../actions/find_locator_to_action_provider.dart';
import '../locator_provider.dart';

abstract class AppActionNotifier<T>
    extends StateNotifier<T>
    implements InputDataProcessor {

  AppActionNotifier(this.ref, T initialState) : super(initialState);

  final Ref ref;

  // ---------- Shared helpers ----------

  String normalizeUPC(String value) {
    if (value.length == 12) {
      final aux = '0$value';
      if (isValidEAN13(aux)) return aux;
    }
    return value;
  }

  void setScanning(bool value) {
    ref.read(isScanningProvider.notifier).state = value;
  }

  void increaseScanCounter() {
    ref.read(scannedCodeTimesProvider.notifier).state++;
  }

  void setLastSearch(String value) {
    Memory.lastSearch = value;
  }



  void findLocatorFrom(String value) {
    //To do
  }

  // ---------- To be specialized ----------
  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  });
}

