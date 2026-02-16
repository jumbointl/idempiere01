import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../domain/idempiere/response_async_value.dart';
import '../store_on_hand/find_product_store_on_hand_provider_refactor.dart';
import '../store_on_hand_for_put_away_movement.dart';

final scannedCodeForPutAwayMovementProvider = StateProvider<String?>((ref) {
  return null;
});

final fireSearchStoreOnHandeForPAMProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});
final findProductForPutAwayMovementProvider =
FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  final count = ref.watch(fireSearchStoreOnHandeForPAMProvider);
  if (count == 0) {
    return ResponseAsyncValue(isInitiated: false, success: false, data: null);
  }

  final code = ref.read(scannedCodeForPutAwayMovementProvider)?.toUpperCase();
  if (code == null || code.isEmpty) {
    return ResponseAsyncValue(isInitiated: false, success: false, data: null);
  }
  return findProductWithStorageOnHand(
    ref: ref,
    scannedCode: code,
    progressProvider: putAwayOnHandProgressProvider,
    cacheResult: true,
  );
});

