// ----------------------------------------------------------------------
// Silent print payload + trigger
// ----------------------------------------------------------------------

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/features/printer/screen/niimbot_page_helper.dart';
import 'package:niim_blue_flutter/niim_blue_flutter.dart';

import '../../products/common/messages_dialog.dart';
import '../../products/domain/idempiere/response_async_value.dart';
import 'package:riverpod_printer/riverpod_printer.dart';
import '../../products/presentation/providers/product_provider_common.dart';
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
    final profile = payload.profile ?? ctrl.defaultProfile();
    ctrl.setProfile(profile);
    bool disconnect = false ;


    debugPrint('run: profile=${profile.copies}');
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
        debugPrint('run: connectToAddressSilence ok=$ok');
        debugPrint('run: connectToAddressSilence ok=${ctrl.isConnected()}');
        ref.read(printingMessageProvider.notifier).state = ctrl.state.status;
        if (!ok) {
           throw Exception('Failed to connect to Niimbot');
        }
      }

      final client = ctrl.state.client!;
      if(!client.isConnected()){
        throw Exception('Client is null');
      }
      refreshPrinterInfoFromClientRef(ref, client);
      PrinterInfo info =client.getPrinterInfo();
      PrinterModelMeta? model = client.getModelMetadata();
      ref.read(printingMessageProvider.notifier).state = 'Printing at ${model?.model ?? 'no model'}';

      ctrl.state = ctrl.state.copyWith(status: 'Printing at ${model?.model ?? 'no model'}');

      // 2) Prepare job (pendingJob) based on dataToPrint



      await ctrl.queuePendingJobForDataSilence(
        data: payload.dataToPrint,
        profile: profile,
      );



      int? saved = ref.read(niimbotPacketIntervalSavedProvider);
      int packageInterval = 0;
      if (saved != null) {
        packageInterval =  saved;

      } else {
        if (Platform.isAndroid) {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          final sdk = androidInfo.version.sdkInt;

          if (sdk < 32) {
            packageInterval = 30;
            debugPrint('[NIIMBOT] Android < 13 detected (sdk=$sdk) → base interval 20ms');
          } else if(sdk<28){
            packageInterval = 40;
          }
          ref.read(niimbotPacketIntervalSavedProvider.notifier).state = packageInterval ;
        }

      }


      client.packetIntervalMs = packageInterval;
      client.packetIntervalMs = ctrl.getPacketIntervalMs(copies: profile.copies);
      debugPrint('executePrintSilence packetIntervalMs ${client.packetIntervalMs}');

      int poll = ctrl.getStatusPollIntervalMs();
      int timeout = ctrl.getStatusTimeoutMs(copies: profile.copies);
      String msg ='packet interval(ms) = ${client.packetIntervalMs},'
          ' poll(ms) = $poll, timeout(ms) = $timeout , mtu = ${ctrl.savedMtu}';
      ref.read(printingMessageProvider.notifier).state = msg;
      // 3) Execute print
      if(!context.mounted)return ;
      final res = await ctrl.executePrintSilence(ref,
          profile: profile,overrideCopies: false,context: context);
      res.message = '${res.message?? ''} , $msg';


      // status icon
      ref.read(resultStatusProvider.notifier).state = (res.success == true);
      debugPrint('[NIIMBOT] disconnect: $disconnect');
      state = AsyncValue.data(res);
    } catch (e, st) {
      debugPrint('[NIIMBOT] ERROR: $e');
      debugPrint('$st');
      disconnect = false;
      debugPrint('[NIIMBOT] disconnect: $disconnect');
      ref.read(resultStatusProvider.notifier).state = false;
      state = AsyncValue.error(e, st);
    } finally {
      if(showPrintingResultMessage) {
        String msg = ref.read(printingMessageProvider);
        if (context.mounted) {
          await showSuccessCenterToast(context, 'OK: $msg');
        } else {
          if (context.mounted) {
            await showErrorCenterToast(
                context, 'Error: $msg', durationSeconds: 0);
          }
        }
      }
      /*if(disconnect){
        debugPrint('[NIIMBOT] disconnect: handleDisconnectSilence()');
        await ctrl.handleDisconnectSilence();
      }*/
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
StateProvider<int>((ref) => 10);

final niimbotPacketIntervalSavedProvider =
StateProvider<int?>((ref) => null);

void initPacketIntervalForAddressContainer({
  required ProviderContainer container,
  required String bluetoothAddress,
  required GetStorage box,
}) {
  final saved = NiimbotPacketIntervalStorage.load(box, bluetoothAddress);
  container.read(niimbotPacketIntervalSavedProvider.notifier).state = saved;
  container.read(niimbotPacketIntervalEditProvider.notifier).state = saved ?? 0;
}

void initMtuForAddressContainer({
  required ProviderContainer container,
  required String bluetoothAddress,
  required GetStorage box,
}) {
  final saved = NiimbotMtuStorage.load(box, bluetoothAddress) ?? 0;
  container.read(niimbotMtuSavedProvider.notifier).state = saved;
  container.read(niimbotMtuEditProvider.notifier).state = saved;

  debugPrint('[NIIMBOT][INFO][MTU INI] mtu saved=$saved');

  final ctrl = container.read(niimbotControllerProvider.notifier);
  ctrl.setMtu(saved);
}

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


class NiimbotMtuStorage {
  static String _key(String addr) => 'niimbot_mtu_${addr.trim()}';

  static int? load(GetStorage box, String addr) {
    final v = box.read(_key(addr));
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  static Future<void> save(GetStorage box, String addr, int mtu) async {
    await box.write(_key(addr), mtu);
  }
}

final niimbotMtuSavedProvider = StateProvider<int?>((ref) => null);
final niimbotMtuEditProvider = StateProvider<int>((ref) => 0); // 0 = no ajustar

Future<void> initMtuForAddress({
  required WidgetRef ref,
  required String bluetoothAddress,
  required GetStorage box,
}) async {
  final saved = NiimbotMtuStorage.load(box, bluetoothAddress) ?? 0;
  ref.read(niimbotMtuSavedProvider.notifier).state = saved;
  ref.read(niimbotMtuEditProvider.notifier).state = saved;
  debugPrint('[NIIMBOT][INFO][MTU INI] mtu saved=$saved');
  final ctrl = ref.read(niimbotControllerProvider.notifier);
  ctrl.setMtu(saved);
}
Future<void> initMtuForAddressRef({
  required Ref ref,
  required String bluetoothAddress,
  required GetStorage box,
}) async {
  final saved = NiimbotMtuStorage.load(box, bluetoothAddress) ?? 0;
  ref.read(niimbotMtuSavedProvider.notifier).state = saved;
  ref.read(niimbotMtuEditProvider.notifier).state = saved;
  debugPrint('[NIIMBOT][INFO][MTU INI] mtu saved=$saved');
  final ctrl = ref.read(niimbotControllerProvider.notifier);
  ctrl.setMtu(saved);
}

Future<void> saveMtuForAddress({
  required WidgetRef ref,
  required String bluetoothAddress,
  required GetStorage box,
}) async {
  final v = ref.read(niimbotMtuEditProvider);
  await NiimbotMtuStorage.save(box, bluetoothAddress, v);
  ref.read(niimbotMtuSavedProvider.notifier).state = v;
}

class BleExplorer {
  static void _log(int req, String msg, {StringBuffer? buf}) {
    final line = '[BLEX][$req] $msg';
    debugPrint(line);
    buf?.writeln(line);
  }

  static String _normUuid16(String u) => u.toLowerCase().replaceAll('-', '');

  static bool _isUuid16(String full128, String uuid16Hex) {
    final n = _normUuid16(full128);
    final base = '0000${uuid16Hex.toLowerCase()}00001000800000805f9b34fb';
    return n == base;
  }

  static Future<String> probeAdvancedGenericAttributeToString({
    required BluetoothDevice device,
    Duration notifyWindow = const Duration(seconds: 4),
    Duration discoverTimeout = const Duration(seconds: 6),
    bool disableNotifyAtEnd = true,
  }) async {
    final buf = StringBuffer();
    await probeAdvancedGenericAttribute(
      device: device,
      notifyWindow: notifyWindow,
      discoverTimeout: discoverTimeout,
      buf: buf,
      disableNotifyAtEnd: disableNotifyAtEnd,
    );
    return buf.toString();
  }

  /// ✅ SOLO escucha Service Changed (GATT 0x1801 / Char 0x2A05)
  static Future<void> probeAdvancedGenericAttribute({
    required BluetoothDevice device,
    Duration notifyWindow = const Duration(seconds: 4),
    Duration discoverTimeout = const Duration(seconds: 6),
    StringBuffer? buf,
    bool disableNotifyAtEnd = true,
  }) async {
    final req = DateTime.now().microsecondsSinceEpoch;
    _log(req, 'ADV_PROBE START device="${device.platformName}" id="${device.remoteId.str}"', buf: buf);

    StreamSubscription<List<int>>? sub;
    BluetoothCharacteristic? targetChar;

    try {
      final services = await device.discoverServices().timeout(discoverTimeout);
      _log(req, 'services=${services.length}', buf: buf);

      // buscar Generic Attribute (0x1801)
      final gattSvc = services.firstWhere(
            (s) => _isUuid16(s.uuid.str, '1801'),
        orElse: () => throw Exception('Generic Attribute service (0x1801) not found'),
      );

      // buscar Service Changed (0x2A05)
      targetChar = gattSvc.characteristics.firstWhere(
            (c) => _isUuid16(c.uuid.str, '2a05'),
        orElse: () => throw Exception('Service Changed char (0x2A05) not found'),
      );

      final props = targetChar.properties;
      _log(req, 'Found 0x1801/0x2A05 props notify=${props.notify} indicate=${props.indicate}', buf: buf);

      if (!(props.notify || props.indicate)) {
        throw Exception('0x2A05 has no notify/indicate');
      }

      await targetChar.setNotifyValue(true);
      _log(req, '0x2A05 notify enabled', buf: buf);

      sub = targetChar.lastValueStream.listen((v) {
        if (v.isEmpty) return;
        _log(req, '0x2A05 NOTIFY len=${v.length} raw=$v', buf: buf);
      }, onError: (e) {
        _log(req, '0x2A05 stream error $e', buf: buf);
      });

      _log(req, 'Waiting notifyWindow=${notifyWindow.inMilliseconds}ms...', buf: buf);
      await Future.delayed(notifyWindow);

      _log(req, 'ADV_PROBE DONE', buf: buf);
    } finally {
      try { await sub?.cancel(); } catch (_) {}
      if (disableNotifyAtEnd && targetChar != null) {
        try { await targetChar.setNotifyValue(false); } catch (_) {}
      }
    }
  }
}
