// ----------------------------------------------------------------------
// Silent print payload + trigger
// ----------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';

import '../../products/domain/idempiere/response_async_value.dart';
import '../../products/domain/models/label_profile.dart';
import 'niimbot_page.dart';

class NiimbotSilentPrintPayload {
  final dynamic dataToPrint;
  final LabelProfile? profile;
  final String bluetoothAddress;

  const NiimbotSilentPrintPayload({
    required this.dataToPrint,
    required this.profile,
    required this.bluetoothAddress,
  });
}

/// Payload (dataToPrint + address + profile)
final niimbotSilentPayloadProvider =
StateProvider<NiimbotSilentPrintPayload?>((ref) => null);

/// Trigger (incrementar para disparar impresión)
final niimbotSilentTriggerProvider =
StateProvider<int>((ref) => 0);

/// AsyncValue del proceso silencioso
final niimbotSilentPrintControllerProvider = StateNotifierProvider.autoDispose<
    NiimbotSilentPrintController, AsyncValue<ResponseAsyncValue?>>((ref) {
  return NiimbotSilentPrintController(ref);
});

class NiimbotSilentPrintController
    extends StateNotifier<AsyncValue<ResponseAsyncValue?>> {
  final Ref ref;
  bool _lock = false;

  NiimbotSilentPrintController(this.ref) : super(const AsyncValue.data(null));

  Future<void> run(BuildContext context) async {
    if (_lock) return;
    _lock = true;

    state = const AsyncValue.loading();
    ref.read(resultStatusProvider.notifier).state = null;

    final payload = ref.read(niimbotSilentPayloadProvider);
    if (payload == null) {
      _lock = false;
      state = AsyncValue.data(
        ResponseAsyncValue(
          isInitiated: true,
          success: false,
          message: 'Payload not set',
        ),
      );
      return;
    }

    final ctrl = ref.read(niimbotControllerProvider.notifier);

    try {
      // 1) Connect if needed
      final addr = payload.bluetoothAddress.trim();
      if (!ctrl.isConnected()) {
        if (addr.isEmpty) {
          throw Exception('Bluetooth address is empty');
        }
        final ok = await ctrl.connectToAddressSilence(
          context,
          address: addr,
        );
        if (!ok || !ctrl.isConnected()) {
          throw Exception('Failed to connect to Niimbot');
        }
      }

      // 2) Prepare job (pendingJob) based on dataToPrint
      final profile = payload.profile ?? ctrl.defaultProfile();
      await ctrl.queuePendingJobForDataSilence(
        data: payload.dataToPrint,
        profile: profile,
      );

      // 3) Execute print
      final res = await ctrl.executePrintSilence(ref,
          profile: profile,overrideCopies: false);

      // status icon
      ref.read(resultStatusProvider.notifier).state = (res.success == true);

      state = AsyncValue.data(res);
    } catch (e, st) {
      ref.read(resultStatusProvider.notifier).state = false;
      state = AsyncValue.error(e, st);
    } finally {
      // 4) Disconnect always (silence)
      try {
        await ctrl.handleDisconnectSilence();
      } catch (_) {}

      _lock = false;
    }
  }

}

const String _kExitPrintPageOnSuccessKey = 'niimbot_exit_print_page_on_success';

final exitPrintPageOnSuccessProvider =
StateNotifierProvider<ExitPrintPageOnSuccessNotifier, bool>((ref) {
  final box = GetStorage();
  return ExitPrintPageOnSuccessNotifier(box);
});

class ExitPrintPageOnSuccessNotifier extends StateNotifier<bool> {
  final GetStorage box;

  ExitPrintPageOnSuccessNotifier(this.box)
      : super(box.read(_kExitPrintPageOnSuccessKey) as bool? ?? true);

  void setValue(bool v) {
    if (state == v) return;
    state = v;
    box.write(_kExitPrintPageOnSuccessKey, v);
  }

  void toggle() => setValue(!state);
}


class NiimbotPacketIntervalStorage {
  static const _prefix = 'niimbot.packetIntervalMs.'; // + addr normalizada

  static String _key(String btAddress) =>
      '$_prefix${btAddress.trim().toUpperCase()}';

  static int? load(GetStorage box, String btAddress) {
    final v = box.read(_key(btAddress));
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse('$v');
  }

  static Future<void> save(GetStorage box, String btAddress, int value) async {
    final safe = value < 0 ? 0 : value;
    await box.write(_key(btAddress), safe);
  }
}


final niimbotPacketIntervalEditProvider =
StateProvider.autoDispose<int>((ref) => 0);

final niimbotPacketIntervalSavedProvider =
StateProvider.autoDispose<int?>((ref) => null);

// helper para inicializar ambos (saved + edit)
Future<void> initPacketIntervalForAddress({
  required WidgetRef ref,
  required String bluetoothAddress,
  required GetStorage box,
}) async {
  final saved = NiimbotPacketIntervalStorage.load(box, bluetoothAddress);
  ref.read(niimbotPacketIntervalSavedProvider.notifier).state = saved;

  // edit arranca con saved si existe, si no 0 (o lo que vos prefieras)
  ref.read(niimbotPacketIntervalEditProvider.notifier).state = saved ?? 0;
}

Future<void> savePacketIntervalForAddress({
  required WidgetRef ref,
  required String bluetoothAddress,
  required GetStorage box,
}) async {
  final v = ref.read(niimbotPacketIntervalEditProvider);
  await NiimbotPacketIntervalStorage.save(box, bluetoothAddress, v);
  ref.read(niimbotPacketIntervalSavedProvider.notifier).state = v;
}