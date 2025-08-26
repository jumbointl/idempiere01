import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier.dart';

import '../../domain/idempiere/idempiere_product.dart';

final scanStateNotifierProvider = StateNotifierProvider.autoDispose<ProductsScanNotifier, List<IdempiereProduct>>((ref) {
  return ProductsScanNotifier(ref);

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
final isScanningFromDialogProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
final usePhoneCameraToScanProvider = StateProvider.autoDispose<bool>((ref) {
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



