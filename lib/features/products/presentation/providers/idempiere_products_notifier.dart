

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/idempiere/idempiere_product.dart';
import 'product_screen_provider.dart';

class IdempiereScanNotifier  extends StateNotifier<List<IdempiereProduct>>{
  IdempiereScanNotifier(this.ref) : super([]);
  final Ref ref;
  // override addBarcode method when the scannedCodeProvider changes
  void addBarcode(String scannedData) {
    if(scannedData.length==12){
      scannedData='0$scannedData';
    }
    ref.watch(scannedCodeProvider.notifier).update((state) => scannedData);
    ref.watch(scannedCodeTimesProvider.notifier).update((state) => state+1);
    ref.watch(isScanningProvider.notifier).update((state) => true);

  }
  bool getIsScanning(){
      return ref.read(isScanningProvider);
  }

  void updateIsScanning(bool bool) {

    ref.watch(isScanningProvider.notifier).update((state) => bool);
  }
}