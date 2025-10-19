import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier_for_line.dart';

import '../../domain/idempiere/idempiere_product.dart';
import 'movement_confirm_state_notifier.dart';

final scanHandleNotifierProvider = StateNotifierProvider.autoDispose<ProductsScanNotifier, List<IdempiereProduct>>((ref) {
  return ProductsScanNotifier(ref);

});
final scanStateNotifierForLineProvider = StateNotifierProvider.autoDispose<ProductsScanNotifierForLine, List<IdempiereProduct>>((ref) {
  return ProductsScanNotifierForLine(ref);

});
final movementConfirmStateNotifierProvider = StateNotifierProvider.autoDispose<MovementConfirmStateNotifier, List<IdempiereProduct>>((ref) {
  return MovementConfirmStateNotifier(ref);

});

final actionScanProvider = StateProvider<int>((ref) {
  return 0;
});

final scannedCodeTimesProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});

final searchStringProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});


final isScanningProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
final isScanningForLineProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});


final isScanningFromDialogProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
final usePhoneCameraToScanProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
final usePhoneCameraToScanForLineProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final usePhoneCameraToScanProvider2 = StateProvider.autoDispose<bool>((ref) {
  return false;
});
final productSKUProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});







final productIdProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});
final productIdProvider2 = StateProvider.autoDispose<int>((ref) {
  return 0;
});
final productIdProvider3 = StateProvider.autoDispose<int>((ref) {
  return 0;
});

final cameraScanBarcodeDataProvider = StateProvider<String?>((ref) => null);
final isDialogShowedProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});



