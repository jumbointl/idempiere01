

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/idempiere/idempiere_product.dart';
import 'product_screen_provider.dart';

class IdempiereScanNotifier  extends StateNotifier<List<IdempiereProduct>>{
  IdempiereScanNotifier(this.ref) : super([]);
  final Ref ref;
  // override updateProductCode method when the productCodeProvider changes
  void updateProductCode(String newCode){
    ref.read(scannedCodeProvider.notifier).update((state) => newCode);

  }
  void addBarcode(String scannedData) {
    //updateProductCode(scannedData);
    ref.watch(scannedCodeProvider.notifier).update((state) => scannedData);
    var count = ref.watch(scannedCodeTimesProvider.notifier).update((state) => state+1);
    print('-----------------------------count: $count');

  }
}