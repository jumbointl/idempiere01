import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'app_action_notifier.dart';

typedef ExtraSettingT<T> = void Function(Ref ref, T value);

class SetAndFireActionNotifier<T> extends AppActionNotifier<void> {
  SetAndFireActionNotifier({
    required Ref ref,
    required this.payloadProvider,
    required this.fireCounterProvider,
    this.extraSetting,
    this.extraSettingBeforeFire = true,
  }) : super(ref, null);

  final StateProvider<T?> payloadProvider;
  final StateProvider<int> fireCounterProvider;

  final ExtraSettingT<T>? extraSetting;
  final bool extraSettingBeforeFire;

  Future<void> setAndFire(T value) async {
    debugPrint('setAndFire executed');
    if (extraSettingBeforeFire) extraSetting?.call(ref, value);

    ref.read(payloadProvider.notifier).state = value;
    ref.read(fireCounterProvider.notifier).state++;

    if (!extraSettingBeforeFire) extraSetting?.call(ref, value);
  }

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    // Este notifier no procesa String directo (a propósito).
    // Si lo necesitás, usa el notifier especializado de String.
  }
}
