import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../domain/idempiere/movement_minout_check.dart';
import '../../../domain/idempiere/response_async_value.dart';
import '../common/code_and_fire_action_notifier.dart';
import 'find_movement_minout_by_doc_no.dart';

/// Selected source (Movement / MInOut) for the SegmentedButton.
final movMInOutCheckSourceProvider =
    StateProvider<MovementMInOutCheckSource>(
        (ref) => MovementMInOutCheckSource.movement);

final scannedCodeForMovMInOutCheckProvider =
    StateProvider<String?>((ref) => null);

final fireSearchMovMInOutByDocNoProvider =
    StateProvider.autoDispose<int>((ref) => 0);

final progressMovMInOutCheckProvider =
    StateProvider<double>((ref) => 0.0);

final findMovMInOutByDocNoProvider =
    FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  final count = ref.watch(fireSearchMovMInOutByDocNoProvider);
  if (count == 0) {
    return ResponseAsyncValue(
      isInitiated: false,
      success: false,
      data: null,
    );
  }

  final code = ref.read(scannedCodeForMovMInOutCheckProvider);
  if (code == null || code.trim().isEmpty) {
    return ResponseAsyncValue(
      isInitiated: false,
      success: false,
      data: null,
    );
  }

  final source = ref.read(movMInOutCheckSourceProvider);

  return findMovementMInOutByDocNo(
    ref: ref,
    scannedCode: code.trim(),
    source: source,
    progressProvider: progressMovMInOutCheckProvider,
  );
});

class FindMovementMInOutByDocNoAction extends CodeAndFireActionNotifier {
  FindMovementMInOutByDocNoAction({required super.ref})
      : super(
          scannedCodeProvider: scannedCodeForMovMInOutCheckProvider,
          fireCounterProvider: fireSearchMovMInOutByDocNoProvider,
          saveLastSearch: true,
          enableScanningFlag: true,
          trimAndUppercase: true,
          enableNormalizeUpc: false,
        );

  @override
  FutureProvider<ResponseAsyncValue> get responseAsyncValueProvider =>
      findMovMInOutByDocNoProvider;
}

final findMovMInOutByDocNoActionProvider =
    Provider<FindMovementMInOutByDocNoAction>((ref) {
  return FindMovementMInOutByDocNoAction(ref: ref);
});
