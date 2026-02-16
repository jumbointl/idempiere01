import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier.dart';

import '../../domain/idempiere/idempiere_product.dart';
import 'movement_confirm_state_notifier.dart';

final scanHandleProvider = StateNotifierProvider.autoDispose<ProductsScanNotifier, void>((ref) {
  return ProductsScanNotifier(ref,null);

});

final movementConfirmStateNotifierProvider = StateNotifierProvider.autoDispose<MovementConfirmStateNotifier, List<IdempiereProduct>>((ref) {
  return MovementConfirmStateNotifier(ref);

});

final isDialogShowedProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final actionScanProvider = StateProvider<int>((ref) {
  return 0;
});

final scannedCodeTimesProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
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








