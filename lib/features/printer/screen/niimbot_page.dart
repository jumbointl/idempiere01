import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:niim_blue_flutter/niim_blue_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../products/common/input_dialog.dart';
import '../../products/domain/models/label_profile.dart';

import '../../products/domain/idempiere/idempiere_locator.dart';
import '../../products/domain/idempiere/idempiere_product.dart';

import '../../products/presentation/providers/common_provider.dart';
import '../models/printer_select_models.dart';

import 'label_config_page.dart';
import 'label_profiles_storage_helper.dart';
import 'niimbot_page_helper.dart';
import 'niimbot_silence_page_provider.dart';
import 'printer_select_page.dart';

// ------------------------------
// Provider
// ------------------------------

final niimbotControllerProvider =
StateNotifierProvider<NiimbotController, NiimbotState>(
      (ref) => NiimbotController(),
);
final resultStatusProvider = StateProvider.autoDispose<bool?>((ref) {
  return null; // valor inicial
});

// ------------------------------
// State
// ------------------------------
class PendingJob {
  final PrintPage page;
  final String successMessage;
  const PendingJob({required this.page, required this.successMessage});
}

class NiimbotState {
  final NiimbotBluetoothClient? client;
  final String status;
  final List<BluetoothDevice> devices;
  final bool showDeviceList;
  final Uint8List? previewImage;
  final bool showPreview;
  final PendingJob? pendingJob;
  final int marginXOffSet; // 0..10
  final bool isPrinting;
  final bool autoDisconnectAfterPrint;
  final LabelProfile profile;

  const NiimbotState({
    required this.client,
    required this.status,
    required this.devices,
    required this.showDeviceList,
    required this.previewImage,
    required this.showPreview,
    required this.pendingJob,
    required this.marginXOffSet,
    required this.isPrinting,
    required this.autoDisconnectAfterPrint,
    required this.profile,

  });

  factory NiimbotState.initial() => NiimbotState(
    client: null,
    status: 'Disconnected',
    devices: const <BluetoothDevice>[],
    showDeviceList: false,
    previewImage: null,
    showPreview: false,
    pendingJob: null,
    marginXOffSet: 4,
    isPrinting: false,
    autoDisconnectAfterPrint: true,

    profile: const LabelProfile(
      id: 'default',
      name: 'Default',
      copies: 1,
      widthMm: 50,
      heightMm: 30,
      marginXmm: 2,
      marginYmm: 2,
      barcodeHeightMm: 12,
      charactersToPrint: 0,
      maxCharsPerLine: 22,
      barcodeHeight: 96,
      barcodeWidth: 3,
      barcodeNarrow: 2,
      fontId: 2,
      gapMm: 2,
    ),
  );

  NiimbotState copyWith({
    NiimbotBluetoothClient? client,
    String? status,
    List<BluetoothDevice>? devices,
    bool? showDeviceList,
    Uint8List? previewImage,
    bool? showPreview,
    PendingJob? pendingJob,
    bool clearPreviewImage = false,
    bool clearPendingJob = false,
    int? marginXOffSet,
    bool? isPrinting,
    bool? autoDisconnectAfterPrint,
    LabelProfile? profile,
  }) {
    return NiimbotState(
      client: client ?? this.client,
      status: status ?? this.status,
      devices: devices ?? this.devices,
      showDeviceList: showDeviceList ?? this.showDeviceList,
      previewImage: clearPreviewImage ? null : (previewImage ?? this.previewImage),
      showPreview: showPreview ?? this.showPreview,
      pendingJob: clearPendingJob ? null : (pendingJob ?? this.pendingJob),
      marginXOffSet: marginXOffSet ?? this.marginXOffSet,
      isPrinting: isPrinting ?? this.isPrinting,
      autoDisconnectAfterPrint:
      autoDisconnectAfterPrint ?? this.autoDisconnectAfterPrint,
      profile: profile ?? this.profile,
    );
  }
}
final niimbotPrintControllerProvider = StateNotifierProvider.autoDispose<
    NiimbotPrintController, AsyncValue<ResponseAsyncValue?>>((ref) {
  return NiimbotPrintController(ref);
});

class NiimbotPrintController
    extends StateNotifier<AsyncValue<ResponseAsyncValue?>> {
  final Ref ref;
  NiimbotPrintController(this.ref) : super(const AsyncValue.data(null));

  Future<void> print({LabelProfile? profile,
    required bool autoDisconnectAfterPrint,required BuildContext context}) async {
    state = const AsyncValue.loading();
    ref.read(resultStatusProvider.notifier).state = null ;
    final ctrl = ref.read(niimbotControllerProvider.notifier);
    final client = ctrl.state.client!;
    bool success = false;
    try {


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
      client.packetIntervalMs = ctrl.getPacketIntervalMs(copies: profile?.copies ?? 1);
      debugPrint('executePrintSilence packetIntervalMs ${client.packetIntervalMs}');

      int poll = ctrl.getStatusPollIntervalMs();
      int timeout = ctrl.getStatusTimeoutMs(copies: profile?.copies ??1);
      String msg ='packet interval(ms) = ${client.packetIntervalMs},'
          ' poll(ms) = $poll, timeout(ms) = $timeout , mtu = ${ctrl.savedMtu}';

      if(!context.mounted) return;
      final res = await ctrl.executePrintSilence(ref, profile: profile
          ,overrideCopies: true,context: context); // ✅ Ref estable
      if (res.success == true) {
        ref.read(resultStatusProvider.notifier).state = true;
      } else {
        ref.read(resultStatusProvider.notifier).state = false;
      }
      //res.message = '${res.message} , $msg';
      ctrl.state = ctrl.state.copyWith(status: msg, isPrinting: false);
      state = AsyncValue.data(res);
      success = true;
      autoDisconnectAfterPrint = false ;
    } catch (e, st) {
      autoDisconnectAfterPrint = true;
      ref.read(resultStatusProvider.notifier).state = false;
      state = AsyncValue.error(e, st);
    } finally {
      if(showPrintingResultMessage) {
        String msg = ref.read(printingMessageProvider);
        if (showPrintingResultMessage) {
          if (success) {
            if (context.mounted) {
              await showSuccessCenterToast(context, 'OK: $msg');
            }
          } else {
            if (context.mounted) {
              await showErrorCenterToast(context, 'Error: $msg');
            }
          }
        }
      }
      /*if (autoDisconnectAfterPrint) {
        await ctrl.handleDisconnectSilence();
      }*/

    }
  }
}
// ------------------------------
// Controller
// ------------------------------

// ------------------------------------------------------------
// BLE mutex (Fix4): serialize BLE operations to avoid races
// ------------------------------------------------------------
class _BleMutex {
  Future<void> _tail = Future.value();

  Future<T> synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();

    // Ensure chain continues even if previous step failed.
    _tail = _tail.catchError((_) {}).then((_) async {
      try {
        final res = await action();
        completer.complete(res);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });

    return completer.future;
  }
}

class NiimbotController extends StateNotifier<NiimbotState> {
  NiimbotController() : super(NiimbotState.initial());


  final _BleMutex _bleMutex = _BleMutex();
  int savedMtu = 240;

  Future<T> _ble<T>(Future<T> Function() action) {
    return _bleMutex.synchronized(action);
  }

  // ------------------------------------------------------------
  // Profile helpers
  // ------------------------------------------------------------
  static const int _pixelsPerMm = 8;

  int _pxFromMm(num mm) => (mm * _pixelsPerMm).round();

  int _pxMarginXFromMm(num mm) {
    final mmN = mm.toInt();
    final off = state.marginXOffSet; // ✅ from state
    final v = mmN - off > 0 ? mmN - off : 0;
    if (v == 0) return 0;
    return (v * _pixelsPerMm).round();
  }

  void setAutoDisconnectAfterPrint(bool v) {
    if (state.autoDisconnectAfterPrint == v) return;
    state = state.copyWith(autoDisconnectAfterPrint: v);
  }
  Future<void> queuePendingJobForDataSilence({
    required dynamic data,
    required LabelProfile profile,
  }) async {
    // decidir layout por tipo
    if (data is IdempiereProduct) {
      // Elegí complete o simple como default. Acá uso "complete".

      final page = await _buildPageForProduct(
        product: data,
        profile: profile,
        isComplete: profile.heightMm>=30,
      );

      state = state.copyWith(
        pendingJob: PendingJob(
          page: page,
          successMessage: 'Product label printed',
        ),
      );
      return;
    }

    if (data is IdempiereLocator) {
      // Elegí barcode o QR como default. Acá uso barcode.
      final page = await _buildPageForLocatorQr(
        locator: data,
        profile: profile,
      );

      state = state.copyWith(
        pendingJob: PendingJob(
          page: page,
          successMessage: 'Locator label printed',
        ),
      );
      return;
    }

    if (data is PrinterConnConfig) {
      // Elegí barcode o QR como default. Acá uso barcode.
      final page = await _buildPageForPrinterConfigQr(
        profile: profile, cfg: data,
      );

      state = state.copyWith(
        pendingJob: PendingJob(
          page: page,
          successMessage: 'Locator label printed',
        ),
      );
      return;
    }

    // Si no es soportado:
    throw Exception('Unsupported dataToPrint type: ${data.runtimeType}');
  }
  PrinterConnConfig? buildPrinterConnConfigFromClient() {
    final client = state.client;
    if (client == null || !client.isConnected()) {
      _log('buildPrinterConnConfigFromClient: not connected');
      return null;
    }

    final device = client.getDevice();
    if (device == null) {
      _log('buildPrinterConnConfigFromClient: device null');
      return null;
    }
    _log('buildPrinterConnConfigFromClient: device=${device.toString()}');

    final name = device.platformName.isEmpty ? 'NIIMBOT' : device.platformName;
    final btAddress = device.remoteId.str;

    final newPrinter = PrinterConnConfig(
      btAddress: btAddress,
      id: 'bt_$btAddress',
      type: PrinterConnType.bluetooth,
      name: name,
      lang: 'NIIMBOT',
      typeText: 'BLE',
    );

    _log('buildPrinterConnConfigFromClient: name="$name" addr="$btAddress"');
    return newPrinter;
  }

  void setMarginXOffSet(int v) {
    final clamped = v.clamp(0, 10);
    state = state.copyWith(marginXOffSet: clamped);
  }

  void incMarginXOffSet() {
    setMarginXOffSet(state.marginXOffSet + 1);
  }

  Future<String> runBleProbeAdvanced(BluetoothDevice device) async {
    try {
      return await _ble(() async {
        if (state.isPrinting) {
          return 'Device is currently printing. Advanced probe skipped.';
        }

        // ✅ solo 0x1801/0x2A05
        final log = await BleExplorer.probeAdvancedGenericAttributeToString(
          device: device,
          notifyWindow: const Duration(seconds: 6),
          discoverTimeout: const Duration(seconds: 6),
          disableNotifyAtEnd: true,
        );

        return log;
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () => 'Advanced probe timeout (global 15s)',
      );
    } catch (e, st) {
      debugPrint('[NIIMBOT][ADV_PROBE] ERROR: $e');
      debugPrint('$st');
      return 'ERROR running advanced probe:\n$e';
    }
  }
  Future<void> handleDisconnectSilence({int? waitForExit}) async {
    return _ble(() async {
      final client = state.client;
      if (client == null) return;
      if (!client.isConnected()) return;
      if(waitForExit==null){
        final copies = state.profile.copies;
        final base = 500; // ms
        final extra = (client.packetIntervalMs * 25) + (copies * 250); // tuneable
        waitForExit = base + extra;
      }
      if(waitForExit!= null && waitForExit!>0){
        await Future.delayed(Duration(milliseconds: waitForExit!));
      }


      try {
        client.stopHeartbeat();
        await client.abstraction.printEnd();
        await client.disconnect();

        debugPrint('Disconnected status 1, ${state.status}');
        String msg ='Disconnected';
        if(state.status.toLowerCase().contains('mtu') || state.status.toLowerCase().contains('error')
            || state.status.toLowerCase().contains('success')){
          msg ='Disconnected , ${state.status}';
        }

        state = state.copyWith(
          status: msg,
          client: null,
          clearPreviewImage: true,
          clearPendingJob: true,
          showPreview: false,
          showDeviceList: false,
        );
      } catch (_) {
        // silence
      }

    });
  }

  Future<ResponseAsyncValue> executePrintSilence(
      Ref ref, {
        LabelProfile? profile, required bool overrideCopies,
        required BuildContext context,
      }) async {


    state = state.copyWith(showPreview: false);

    final copiesTemp = ref.read(copiesTempProvider);
    bool success= false;
    String msg ='';

    if (!isConnected()) {
      debugPrint('executePrintSilence Not connected');
      state = state.copyWith(clearPendingJob: true);
      return ResponseAsyncValue(
        isInitiated: true,
        success: false,
        message: 'Not connected',
      );
    }

    final job = state.pendingJob;
    if (job == null) {
      debugPrint('executePrintSilence Job = null');
      return ResponseAsyncValue(
        isInitiated: true,
        success: false,
        message: 'Job not found',
      );
    }

    final p0 = profile ?? defaultProfile();
    debugPrint('executePrintSilence profile=${p0.copies}');


    final p = LabelProfile(
      id: p0.id,
      name: p0.name,
      copies: (overrideCopies) ? copiesTemp : p0.copies,
      widthMm: p0.widthMm,
      heightMm: p0.heightMm,
      marginXmm: p0.marginXmm,
      marginYmm: p0.marginYmm,
      barcodeHeightMm: p0.barcodeHeightMm,
      charactersToPrint: p0.charactersToPrint,
      maxCharsPerLine: p0.maxCharsPerLine,
      barcodeHeight: p0.barcodeHeight,
      barcodeWidth: p0.barcodeWidth,
      barcodeNarrow: p0.barcodeNarrow,
      fontId: p0.fontId,
      gapMm: p0.gapMm,
    );

    state = state.copyWith(isPrinting: true,profile: p);

    try {
      debugPrint('_executePrintTask started');
      await _executePrintTask(page: job.page);
      state = state.copyWith(clearPendingJob: true);
      success = true;
      return ResponseAsyncValue(
        isInitiated: true,
        success: true,
        message: 'Print done',
        data: 'Print done',
      );
    } catch (e) {
      debugPrint('Print failed: $e');
      state = state.copyWith(clearPendingJob: true, isPrinting: false);
      return ResponseAsyncValue(
        isInitiated: true,
        success: false,
        message: 'Print failed: $e',
      );
    } finally {
      debugPrint('Print done finally');
      if(showPrintingResultMessage) {
        if (success) {
          String msg = ref.read(printingMessageProvider);
          if (context.mounted) {
            await showSuccessCenterToast(
                context, 'OK: $msg', durationSeconds: 5);
          }
        } else {
          if (context.mounted) {
            await showErrorCenterToast(
                context, 'Error: $msg', durationSeconds: 0);
          }
        }
      }

    }
  }

  LabelProfile defaultProfile() {
    return const LabelProfile(
      id: 'default',
      name: 'Default',
      copies: 1,
      widthMm: 50,
      heightMm: 30,
      marginXmm: 2,
      marginYmm: 2,
      barcodeHeightMm: 12,
      charactersToPrint: 0,
      maxCharsPerLine: 22,
      barcodeHeight: 96,
      barcodeWidth: 3,
      barcodeNarrow: 2,
      fontId: 2,
      gapMm: 2,
    );
  }

  PrintOptions _optionsFromProfile(LabelProfile profile, {required int totalPages}) {
    return PrintOptions(
      totalPages: totalPages,
      density: 2,
      labelType: LabelType.withGaps,
      statusPollIntervalMs: 150,
      statusTimeoutMs: 20000,
    );
  }

  // ------------------------------------------------------------
  // Bluetooth logic
  // ------------------------------------------------------------
  String _normId(String s) => s.toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');

  Future<bool> _requestPermissions() async {
    if (Platform.isIOS) return true;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 31) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      return statuses.values.every((s) => s.isGranted);
    } else {
      final statuses = await [
        Permission.bluetooth,
        Permission.location,
      ].request();
      return statuses.values.every((s) => s.isGranted);
    }
  }
  Future<void> reconnect({required BuildContext context, required String address, required NiimbotState state
    }) async {
    state = state.copyWith(status: 'Re-connecting, 1- disconnecting... ');
    await handleDisconnect(context);
    if(address.isNotEmpty) {
      state = state.copyWith(status: 'Re-connecting, 2- connecting... ');
      await Future.delayed(Duration(milliseconds: 1000));
      if(!context.mounted) return;
      await connectToAddressSilence(
          context, address: address);
    }
  }
  Future<void> connectToDevice(
      BuildContext context,
      BluetoothDevice device, {
        Duration connectTimeout = const Duration(seconds: 12),
      }) {
    return _ble(() => _connectToDeviceInternal(
      context,
      device,
      connectTimeout: connectTimeout,
    ));
  }

  Future<void> _connectToDeviceInternal(
      BuildContext context,
      BluetoothDevice device, {
        Duration connectTimeout = const Duration(seconds: 12),
      }) async {
    final req = DateTime.now().microsecondsSinceEpoch;
    _log('[$req] Connect: begin name="${device.platformName}" id="${device.remoteId.str}"');

    state = state.copyWith(
      showDeviceList: false,
      status: 'Connecting...',
      isPrinting: true,
    );

    try { await FlutterBluePlus.stopScan(); } catch (_) {}

    const int maxAttempts = 3;

    Future<void> hardDisconnect(NiimbotBluetoothClient c) async {
      try { await c.disconnect(); } catch (_) {}
      try { await device.disconnect(); } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 250));
    }

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      NiimbotBluetoothClient? client;

      try {
        _log('[$req] Connect: attempt $attempt/$maxAttempts');

        client = NiimbotBluetoothClient();
        client.setDevice(device);

        await Future.delayed(const Duration(milliseconds: 300));
        await client.connect().timeout(connectTimeout);
        await Future.delayed(const Duration(milliseconds: 600));

        // ✅ leer info + metadata
        final info = client.getPrinterInfo();
        final metaData = client.getModelMetadata();

        final modelId = info.modelId;
        final batteryCharge = info.charge;

        _log('[$req] Connect: printerInfo modelId=$modelId charge=$batteryCharge');
        _log('[$req] Connect: metaData=${metaData?.model ?? "null"}');

        // ✅ si handshake incompleto: desconectar y reintentar
        final bool handshakeIncomplete = (modelId == null || metaData == null);

        if (handshakeIncomplete) {
          final msg = 'Handshake incompleto (modelId=$modelId meta=${metaData?.model}). Reintentando...';
          state = state.copyWith(status: msg);

          await hardDisconnect(client);

          if (attempt < maxAttempts) {
            await Future.delayed(Duration(milliseconds: 500 + attempt * 350));
            continue;
          } else {
            // último intento falló -> desconectar y abortar
            final finalMsg = 'Connection failed: $msg';
            state = state.copyWith(status: finalMsg, client: null, isPrinting: false);
            throw StateError(finalMsg);
          }
        }

        // ✅ a partir de acá: conexión válida
        state = state.copyWith(
          client: client,
          status: 'Connected to $modelId / ${metaData.model}',
          isPrinting: false,
        );


        // ✅ MTU (NO return si savedMtu <= 0)
        final int? mtuNow = client.getDevice()?.mtuNow;
        if (savedMtu > 0 && mtuNow != null && savedMtu != mtuNow) {
          try {
            final negotiated = await device.requestMtu(savedMtu);
            debugPrint('[NIIMBOT] requestMtu($savedMtu) => negotiated=$negotiated');
          } catch (e) {
            debugPrint('[NIIMBOT] requestMtu($savedMtu) failed: $e');
          }
        } else {
          debugPrint('[NIIMBOT] MTU: skip (savedMtu=$savedMtu mtuNow=$mtuNow)');
        }

        client.startHeartbeat();

        _log('[$req] Connect: DONE isConnected=${client.isConnected()}');
        return;
      } catch (e, st) {
        _log('[$req] Connect: ERROR attempt $attempt => $e');
        debugPrint('$st');

        // ✅ asegurar desconexión si algo quedó a medias
        if (client != null) {
          await hardDisconnect(client);
        } else {
          try { await device.disconnect(); } catch (_) {}
        }

        if (attempt < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 500 + attempt * 350));
          continue;
        }

        final msg = '${state.status}, Connection failed: $e';
        state = state.copyWith(status: msg, client: null, isPrinting: false);
        rethrow;
      }
    }

    state = state.copyWith(isPrinting: false);
  }

  Future<void> handleConnectScan(BuildContext context) async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      if (!context.mounted) return;
      _showAlert(context, 'Error', 'Bluetooth permissions are required');
      return;
    }

    try {
      state = state.copyWith(status: 'Scanning for devices...');

      final devices = await _scanNiimbotDevices(timeout: const Duration(seconds: 3));

      if (devices.isEmpty) {
        if (!context.mounted) return;
        _showAlert(
          context,
          'No Devices Found',
          'No compatible printers found. Make sure your printer is turned on and in pairing mode.',
        );
        state = state.copyWith(status: 'No devices found');
        return;
      }

      state = state.copyWith(
        devices: devices,
        showDeviceList: true,
        status: 'Select a device',
      );
    } catch (e) {
      if (e.toString().contains('Bluetooth is not powered on')) {
        if (!context.mounted) return;
        _showAlert(
          context,
          'Bluetooth Required',
          'Please enable Bluetooth in your device settings and try connecting again.',
        );
      } else {
        if (!context.mounted) return;
        _showAlert(context, 'Error', e.toString());
      }
      state = state.copyWith(status: 'Scan failed');
    }
  }

  void _log(String msg) {
    debugPrint('[NIIMBOT] $msg');
  }

  Future<List<BluetoothDevice>> _scanNiimbotDevices({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    _log('Scan: starting timeout=${timeout.inSeconds}s');

    final foundDevices = await NiimbotBluetoothClient.listDevices(timeout: timeout);
    _log('Scan: listDevices found=${foundDevices.length}');
    for (final d in foundDevices) {
      _log(
          'Scan: found name="${d.platformName}" id="${d.remoteId.str}" norm="${_normId(d.remoteId.str)}"');
    }

    final connectedDevices = FlutterBluePlus.connectedDevices;
    _log('Scan: FlutterBluePlus.connectedDevices=${connectedDevices.length}');
    for (final d in connectedDevices) {
      _log(
          'Scan: connected name="${d.platformName}" id="${d.remoteId.str}" norm="${_normId(d.remoteId.str)}"');
    }

    final allDevices = [...foundDevices, ...connectedDevices];

    final unique = <BluetoothDevice>[];
    final seen = <String>{};
    for (final d in allDevices) {
      final id = d.remoteId.str;
      if (seen.add(id)) unique.add(d);
    }

    _log('Scan: unique=${unique.length}');
    return unique;
  }

  BluetoothDevice? _findDeviceByAddressSmart(
      List<BluetoothDevice> devices,
      String inputAddress,
      ) {
    final target = _normId(inputAddress);
    _log('SmartMatch: input="$inputAddress" targetNorm="$target"');

    if (target.isEmpty) return null;

    // 1) exact
    for (final d in devices) {
      final dn = _normId(d.remoteId.str);
      if (dn == target) {
        _log('SmartMatch: EXACT hit dn="$dn" name="${d.platformName}"');
        return d;
      }
    }

    // 2) suffix last 8 hex
    if (target.length >= 8) {
      final suffix = target.substring(target.length - 8);
      _log('SmartMatch: trying suffix="$suffix"');

      final candidates = <BluetoothDevice>[];
      for (final d in devices) {
        final dn = _normId(d.remoteId.str);
        if (dn.endsWith(suffix)) {
          candidates.add(d);
          _log('SmartMatch: suffix candidate dn="$dn" name="${d.platformName}"');
        }
      }

      if (candidates.length == 1) {
        _log('SmartMatch: suffix UNIQUE => use it');
        return candidates.first;
      }

      if (candidates.isNotEmpty) {
        final byName = candidates
            .where((d) =>
        d.platformName.toUpperCase().contains('NIIM') ||
            d.platformName.toUpperCase().startsWith('B1-'))
            .toList();

        if (byName.length == 1) {
          _log('SmartMatch: suffix multi, name UNIQUE => use it');
          return byName.first;
        }

        _log('SmartMatch: suffix multi candidates=${candidates.length} => ambiguous');
      }
    }

    return null;
  }

  Future<bool> connectToAddressSilence(
      BuildContext context, {
        required String address,
        Duration scanTimeout = const Duration(seconds: 3),
        Duration connectTimeout = const Duration(seconds: 12),
      }) {
    return _ble(() async {
      final req = DateTime.now().microsecondsSinceEpoch;
      final hasPermission = await _requestPermissions();
      if (!hasPermission) return false;
      state = state.copyWith(status: 'Scanning for devices...', isPrinting: true);


      final devices = await _scanNiimbotDevices(timeout: scanTimeout);
      if(devices.isEmpty) {
        state = state.copyWith(status: 'No devices found');
        return false;
      }

      final match = _findDeviceByAddressSmart(devices, address);
      if (match == null) {
        state = state.copyWith(status: 'Device not found', isPrinting: false);
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 500));
      // ✅ IMPORTANTE: NO llames al connectToDevice() (que usa _ble)
      state = state.copyWith(status: 'Connecting...$match');
      await _connectToDeviceInternal(context, match, connectTimeout: connectTimeout);

      final ok = isConnected();

      state = state.copyWith(status: ok ? 'Connected: $match' : 'Connection failed', isPrinting: false);
      return ok;
    });
  }

  Future<void> handleDisconnect(BuildContext context) async {
    return _ble(() async {
      final client = state.client;
      if (client == null) return;
      if (!client.isConnected()) return;

      try {
        client.stopHeartbeat();
        try {
          await client.abstraction.printEnd();
        } catch (e){
          debugPrint('Failed to disconnect client.abstraction.printEnd(): $e');
        }

        await client.disconnect();
        String msg ='Disconnected';
        if(state.status.toLowerCase().contains('mtu') || state.status.toLowerCase().contains('error')
            || state.status.toLowerCase().contains('success')){
          msg ='Disconnected , ${state.status}';
        }
        state = state.copyWith(
          status: msg,
          client: null,
          clearPreviewImage: true,
          clearPendingJob: true,
          showPreview: false,
          showDeviceList: false,
          isPrinting: false,
        );
      } catch (e) {
        debugPrint('Failed to disconnect: $e');
        if (!context.mounted) return;
        state = state.copyWith(status: 'Failed to disconnect: $e',isPrinting: false);
        //_showAlert(context, 'Error', 'Failed to disconnect: $e');
      }

    });
  }

  bool isConnected() => state.client != null && state.client!.isConnected();

  // ------------------------------------------------------------
  // Preview + Print pipeline
  // ------------------------------------------------------------
  Future<void> showPreviewAndQueueJob(
      BuildContext context, {
        required PrintPage page,
        required String successMessage,
      }) async {
    try {
      final imageData = await page.toPreviewImage();

      state = state.copyWith(
        previewImage: imageData,
        pendingJob: PendingJob(page: page, successMessage: successMessage),
        showPreview: true,
      );
    } catch (e) {
      if (!context.mounted) return;
      _showAlert(context, 'Error', 'Failed to generate preview: $e');
    }
  }



  Future<void> _executePrintTask({
    required PrintPage page,
  }) async {
    return _ble(() async {
      final client = state.client;
      if (client == null || !client.isConnected()) {
        debugPrint('executePrintTask: Not connected');

        throw Exception('Not connected');
      }
      final profile = state.profile;
      final copies = profile.copies < 1 ? 1 : profile.copies;

      try {
      state = state.copyWith(status: 'Starting print...',isPrinting: true);

      client.stopHeartbeat();
      int poll = getStatusPollIntervalMs();
      int timeout = getStatusTimeoutMs(copies:copies);


      // ✅ ';
      final task = client.createPrintTask(
        PrintOptions(
          totalPages: copies,
          density: 3,
          labelType: client.info.labelType,
          statusPollIntervalMs: poll,
          statusTimeoutMs: timeout,

        ),
      );
      //final task = await _createTaskWithWarmup(client, options);
      if (task == null) {
        throw Exception('Failed to create print task - printer model not detected');
      }


        debugPrint('PRINT: before printInit');
        await task.printInit().timeout(const Duration(seconds: 45));
        debugPrint('PRINT: after printInit');

        await Future.delayed(const Duration(milliseconds: 250));

        final encoded = page.toEncodedImage();

        for (int i = 1; i <= copies; i++) {
          state = state.copyWith(status: 'Printing $i/$copies');
          debugPrint('PRINT: before printPage page=$i/$copies');

          // ✅ CLAVE: page index = i (no siempre 1)
          await task.printPage(encoded, 1).timeout(const Duration(seconds: 45));

          debugPrint('PRINT: after printPage page=$i/$copies');
          await Future.delayed(const Duration(milliseconds: 300));
        }

        debugPrint('PRINT: before waitForFinished');
        await task.waitForFinished().timeout(const Duration(seconds: 45));
        debugPrint('PRINT: after waitForFinished');
        state = state.copyWith(status: 'Printed $copies copies',isPrinting: false);
      } catch (e) {

        final msg = e.toString();
        if (msg.contains('Future already completed')) {
          debugPrint('NIIMBOT: ignore plugin double-complete: $msg');
        } else {
          debugPrint('NIIMBOT: ERROR: $msg');
          state = state.copyWith(status: 'NIIMBOT: ERROR: $msg',isPrinting: false);
          rethrow;
        }
      } finally {
        try { client.startHeartbeat(); } catch (e) {
          debugPrint('NIIMBOT: print task startHeartbeat() exception: $e');
        }
      }
    });
  }

  // ------------------------------------------------------------
  // Demo actions
  // ------------------------------------------------------------
  Future<void> handlePrintSimple(BuildContext context) async {
    if (!isConnected()) {
      if (!context.mounted) return;
      _showAlert(context, 'Error', 'Not connected');
      return;
    }

    final page = PrintPage(400, 240);

    page.addQR(
      'Hello Niimbot',
      const QROptions(
        x: 100,
        y: 120,
        width: 100,
        height: 60,
        align: HAlignment.center,
        vAlign: VAlignment.middle,
      ),
    );

    page.addBarcode(
      '123456789012',
      const BarcodeOptions(
        encoding: BarcodeEncoding.ean13,
        x: 300,
        y: 120,
        width: 150,
        height: 60,
        align: HAlignment.center,
        vAlign: VAlignment.middle,
      ),
    );

    await showPreviewAndQueueJob(
      context,
      page: page,
      successMessage: 'Simple demo printed',
    );
  }

  Future<void> handlePrintBoldText(BuildContext context) async {
    if (!isConnected()) {
      if (!context.mounted) return;
      _showAlert(context, 'Error', 'Not connected');
      return;
    }

    final page = PrintPage(400, 240);

    await page.addText(
      'Normal Text',
      const TextOptions(
        x: 200,
        y: 60,
        fontSize: 18,
        align: HAlignment.center,
        vAlign: VAlignment.middle,
      ),
    );

    await page.addText(
      'Bold Text',
      const TextOptions(
        x: 200,
        y: 120,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        align: HAlignment.center,
        vAlign: VAlignment.middle,
      ),
    );

    await page.addText(
      'Light Text',
      const TextOptions(
        x: 200,
        y: 180,
        fontSize: 18,
        fontWeight: FontWeight.w300,
        align: HAlignment.center,
        vAlign: VAlignment.middle,
      ),
    );

    await showPreviewAndQueueJob(
      context,
      page: page,
      successMessage: 'Styled text printed',
    );
  }

  Future<void> printPrinterInformationQr(
      BuildContext context, {
        required PrinterConnConfig printer,
        required LabelProfile? profile,
      }) async {
    if (!isConnected()) {
      if (!context.mounted) return;
      _showAlert(context, 'Error', 'Not connected');
      return;
    }

    final p = profile ?? defaultProfile();
    final page = await _buildPageForPrinterConfigQr(cfg: printer, profile: p);

    await showPreviewAndQueueJob(
      context,
      page: page,
      successMessage: 'Printer Information (QR) printed',
    );
  }

  Future<void> handleQuickPrintTest(BuildContext context,
      {LabelProfile? profile}) async {
    if (!isConnected()) {
      if (!context.mounted) return;
      _showAlert(context, 'Error', 'Not connected');
      return;
    }

    final p = profile ?? defaultProfile();
    final width = (p.widthMm * 8).toInt();
    final height = (p.heightMm * 8).toInt();

    final page = PrintPage(width, height);

    await page.addText(
      'TEST',
      const TextOptions(
        x: 200,
        y: 70,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        align: HAlignment.center,
        vAlign: VAlignment.middle,
      ),
    );

    page.addBarcode(
      '1234567890123',
      const BarcodeOptions(
        encoding: BarcodeEncoding.code128,
        x: 200,
        y: 160,
        width: 260,
        height: 70,
        align: HAlignment.center,
        vAlign: VAlignment.middle,
      ),
    );

    await showPreviewAndQueueJob(
      context,
      page: page,
      successMessage: 'Print sent',
    );
  }

  // ------------------------------------------------------------
  // Dynamic printing (Product / Locator)
  // ------------------------------------------------------------
  Future<void> printProductSimple(
      BuildContext context, {
        required IdempiereProduct product,
        required LabelProfile? profile,
      }) async {
    if (!isConnected()) {
      if (!context.mounted) return;
      _showAlert(context, 'Error', 'Not connected');
      return;
    }

    final p = profile ?? defaultProfile();
    final sku = (product.sKU ?? '').trim();
    final upc = (product.uPC ?? '').trim();

    if (upc.isEmpty && sku.isEmpty) {
      if (!context.mounted) return;
      _showAlert(context, 'Error', 'Product SKU/UPC is empty');
      return;
    }

    final page = await _buildPageForProduct(
      product: product,
      profile: p,
      isComplete: false,
    );

    await showPreviewAndQueueJob(
      context,
      page: page,
      successMessage: 'Product label (simple) printed',
    );
  }

  Future<void> printProductComplete(
      BuildContext context, {
        required IdempiereProduct product,
        required LabelProfile? profile,
      }) async {
    if (!isConnected()) {
      if (!context.mounted) return;
      _showAlert(context, 'Error', 'Not connected');
      return;
    }

    final p = profile ?? defaultProfile();
    final name = (product.name ?? '').trim();
    final sku = (product.sKU ?? '').trim();
    final upc = (product.uPC ?? '').trim();

    if (upc.isEmpty && sku.isEmpty && name.isEmpty) {
      if (!context.mounted) return;
      _showAlert(context, 'Error', 'Product data is empty');
      return;
    }

    final page = await _buildPageForProduct(
      product: product,
      profile: p,
      isComplete: true,
    );

    await showPreviewAndQueueJob(
      context,
      page: page,
      successMessage: 'Product label (complete) printed',
    );
  }

  String clip(String s, int maxChars) =>
      (maxChars <= 0 || s.length <= maxChars) ? s : s.substring(0, maxChars);

  (String, String) split2LinesSmart(String text, int maxPerLine) {
    final t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) return ('', '');
    if (maxPerLine <= 0) return (t, '');
    if (t.length <= maxPerLine) return (t, '');

    int cut;

    if (maxPerLine < t.length && t[maxPerLine] == ' ') {
      cut = maxPerLine;
    } else {
      int? backCut;
      for (int delta = 1; delta <= 5; delta++) {
        final idx = maxPerLine - delta;
        if (idx > 0 && idx < t.length && t[idx] == ' ') {
          backCut = idx;
          break;
        }
      }

      if (backCut != null) {
        cut = backCut;
      } else {
        cut = maxPerLine - 1;
        final l1 = '${t.substring(0, cut).trim()}_';
        final rest = t.substring(cut).trim();
        final l2 = clip(rest, maxPerLine).trim();
        return (l1, l2);
      }
    }

    final l1 = t.substring(0, cut).trim();
    final rest = t.substring(cut).trim();
    final l2 = clip(rest, maxPerLine).trim();
    return (l1, l2);
  }

  int clampFontId(int v) => v <= 1 ? 1 : (v >= 4 ? 4 : v);

  int fontSizeTitleById(int fontId) {
    switch (clampFontId(fontId)) {
      case 1:
        return 17;
      case 2:
        return 19;
      case 3:
        return 21;
      case 4:
      default:
        return 23;
    }
  }

  int fontSizeBodyById(int fontId) {
    switch (clampFontId(fontId)) {
      case 1:
        return 16;
      case 2:
        return 18;
      case 3:
        return 20;
      case 4:
      default:
        return 22;
    }
  }

  Future<PrintPage> _buildPageForProduct({
    required IdempiereProduct product,
    required LabelProfile profile,
    required bool isComplete,
  }) async {
    final widthPx = _pxFromMm(profile.widthMm);
    final heightPx = _pxFromMm(profile.heightMm);

    final marginX = _pxMarginXFromMm(profile.marginXmm);
    final marginY = _pxFromMm(profile.marginYmm);

    final safeName =
    (product.name ?? '').replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
    final safeSku =
    (product.sKU ?? '').replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
    final upcOriginal =
    (product.uPC ?? '').replaceAll('\n', ' ').replaceAll('\r', ' ').trim();

    // Barcode normalize + symbology
    final normalized = normalizeUpc(upcOriginal);
    final sym = pickBarcodeType(normalized);

    final BarcodeEncoding encoding = switch (sym) {
      BarcodeSymbology.ean13 => BarcodeEncoding.ean13,
      BarcodeSymbology.ean8 => BarcodeEncoding.code128,
      BarcodeSymbology.code128 => BarcodeEncoding.code128,
    };

    final barcodeData = (normalized.isNotEmpty)
        ? normalized
        : (safeSku.isNotEmpty ? safeSku : '');

    final belowText = upcOriginal.isNotEmpty ? upcOriginal : barcodeData;

    final page = PrintPage(widthPx, heightPx);
    final fontId = profile.fontId;

    final nameFontSize = fontSizeTitleById(fontId);
    final skuFontSize = fontSizeTitleById(fontId);
    final upcFontSize = fontSizeTitleById(fontId);

    final charLimit = profile.charactersToPrint;
    final nameToPrint = (charLimit <= 0 || safeName.length <= charLimit)
        ? safeName
        : safeName.substring(0, charLimit);

    final maxPerLine = (profile.maxCharsPerLine <= 0) ? 22 : profile.maxCharsPerLine;

    String nameLine1 = '';
    String nameLine2 = '';
    if (isComplete) {
      final limitedName = clip(nameToPrint, maxPerLine * 2);
      final (l1, l2) = split2LinesSmart(limitedName, maxPerLine);
      nameLine1 = l1;
      nameLine2 = l2;
    }

    final skuLine = safeSku.isEmpty ? '' : 'SKU: ${clip(safeSku, 28)}';

    final gapPx = (_pxFromMm(profile.gapMm) * 0.40).round().clamp(1, 6);
    final lineHName = (nameFontSize + 6).clamp(14, 26);
    final lineHSku = (skuFontSize + 6).clamp(12, 22);
    final lineHUpc = (upcFontSize + 6).clamp(12, 22);

    int y = marginY;

    if (isComplete && nameLine1.isNotEmpty) {
      await page.addText(
        nameLine1,
        TextOptions(
          x: marginX,
          y: y + (lineHName ~/ 2),
          fontSize: nameFontSize,
          fontWeight: FontWeight.bold,
          align: HAlignment.left,
          vAlign: VAlignment.middle,
        ),
      );
      y += lineHName + gapPx;
    }

    if (isComplete && nameLine2.isNotEmpty) {
      await page.addText(
        nameLine2,
        TextOptions(
          x: marginX,
          y: y + (lineHName ~/ 2),
          fontSize: nameFontSize,
          fontWeight: FontWeight.bold,
          align: HAlignment.left,
          vAlign: VAlignment.middle,
        ),
      );
      y += lineHName + gapPx;
    }
    debugPrint('skuLine: $skuLine y ${y + (lineHSku ~/ 2)}');
    if (skuLine.isNotEmpty) {
      await page.addText(
        skuLine,
        TextOptions(
          x: marginX,
          y: y + (lineHSku ~/ 2),
          fontSize: skuFontSize,
          fontWeight: FontWeight.bold,
          align: HAlignment.left,
          vAlign: VAlignment.middle,
        ),
      );
      y += lineHSku + gapPx;
    }



    final reservedBelow = lineHUpc + gapPx + 2;

    final maxBarcodeH =
    (heightPx - marginY - y - reservedBelow );
    final barcodeTop = y;
    int barcodeH = (profile.barcodeHeight > 0)
        ? profile.barcodeHeight
        :maxBarcodeH;
    if (barcodeH > maxBarcodeH || profile.barcodeHeight<=40) {
      barcodeH = maxBarcodeH;
    }
    final barcodeCenterY = (barcodeTop+ (barcodeH/ 2)).round();

    int maxBarcodeSize =widthPx -marginX*2;
    if (sym == BarcodeSymbology.ean13) {
      maxBarcodeSize >35*8 ? maxBarcodeSize =35*8 : maxBarcodeSize;
    }
    final barcodeWidth =
    (widthPx - marginX * 2).clamp(120, maxBarcodeSize).toInt();



    if (barcodeData.isNotEmpty) {
      page.addBarcode(
        barcodeData,
        BarcodeOptions(
          encoding: encoding,
          x: marginX,
          y: barcodeCenterY,
          width: barcodeWidth,
          height: barcodeH,
          align: HAlignment.left,
          vAlign: VAlignment.middle,
        ),
      );

      final upcTextY =
      (barcodeTop + barcodeH +  (lineHUpc ~/ 2)).round();
      debugPrint('upcTextY: $upcTextY');


      await page.addText(
        belowText,
        TextOptions(
          x: marginX,
          y: upcTextY,
          fontSize: upcFontSize,
          fontWeight: FontWeight.bold,
          align: HAlignment.left,
          vAlign: VAlignment.middle,
        ),
      );
    }

    return page;
  }

  Future<void> printLocatorBarcode(
      BuildContext context, {
        required IdempiereLocator locator,
        required LabelProfile? profile,
      }) async {
    if (!isConnected()) {
      if (!context.mounted) return;
      _showAlert(context, 'Error', 'Not connected');
      return;
    }

    final p = profile ?? defaultProfile();
    final value = (locator.value ?? '').trim();
    if (value.isEmpty) {
      if (!context.mounted) return;
      _showAlert(context, 'Error', 'Locator value is empty');
      return;
    }

    final page = await _buildPageForLocatorBarcode(locator: locator, profile: p);

    await showPreviewAndQueueJob(
      context,
      page: page,
      successMessage: 'Locator label (barcode) printed',
    );
  }

  Future<void> printLocatorQr(
      BuildContext context, {
        required IdempiereLocator locator,
        required LabelProfile? profile,
      }) async {
    if (!isConnected()) {
      if (!context.mounted) return;
      _showAlert(context, 'Error', 'Not connected');
      return;
    }

    final p = profile ?? defaultProfile();
    final value = (locator.value ?? '').trim();
    if (value.isEmpty) {
      if (!context.mounted) return;
      _showAlert(context, 'Error', 'Locator value is empty');
      return;
    }

    final page = await _buildPageForLocatorQr(locator: locator, profile: p);

    await showPreviewAndQueueJob(
      context,
      page: page,
      successMessage: 'Locator label (QR) printed',
    );
  }

  Future<PrintPage> _buildPageForLocatorBarcode({
    required IdempiereLocator locator,
    required LabelProfile profile,
  }) async {
    final widthPx = _pxFromMm(profile.widthMm);
    final heightPx = _pxFromMm(profile.heightMm);

    final marginX = _pxMarginXFromMm(profile.marginXmm);
    final marginY = _pxFromMm(profile.marginYmm);

    final value =
    (locator.value ?? '').replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
    final page = PrintPage(widthPx, heightPx);
    final centerX = (widthPx / 2).round();

    final fontId = profile.fontId;
    final titleFontSize = fontSizeTitleById(fontId);
    final bodyFontSize = fontSizeBodyById(fontId);

    final gapPx = (_pxFromMm(profile.gapMm) * 0.40).round().clamp(1, 6);
    final lineH = (titleFontSize + 6).clamp(14, 26);

    int y = marginY;

    final text = _limitChars(value, profile.maxCharsPerLine <= 0 ? 22 : profile.maxCharsPerLine);
    if (text.isNotEmpty) {
      await page.addText(
        text,
        TextOptions(
          x: centerX,
          y: y + (lineH ~/ 2),
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          align: HAlignment.center,
          vAlign: VAlignment.middle,
        ),
      );
      y += lineH + gapPx;
    }

    final barcodeH = (profile.barcodeHeight > 0)
        ? profile.barcodeHeight
        : _pxFromMm(profile.barcodeHeightMm).clamp(40, heightPx - marginY * 2);

    final reservedBelow = (bodyFontSize + 6).clamp(12, 22) + gapPx;

    final minTop = y + gapPx;
    final maxTop = (heightPx - marginY - barcodeH - reservedBelow).clamp(0, heightPx);
    final top = minTop.clamp(marginY, maxTop);
    final centerY = (top + barcodeH / 2).round();

    final barcodeWidth = (widthPx - marginX * 3).clamp(120, widthPx - marginX * 4).toInt();

    page.addBarcode(
      value,
      BarcodeOptions(
        encoding: BarcodeEncoding.code128,
        x: marginX,
        y: centerY,
        width: barcodeWidth,
        height: barcodeH,
        align: HAlignment.left,
        vAlign: VAlignment.middle,
      ),
    );

    return page;
  }

  Future<PrintPage> _buildPageForPrinterConfigQr({
    required PrinterConnConfig cfg,
    required LabelProfile profile,
  }) async {
    final widthPx = _pxFromMm(profile.widthMm);
    final heightPx = _pxFromMm(profile.heightMm);

    final marginX = _pxMarginXFromMm(profile.marginXmm);
    final marginY = _pxFromMm(profile.marginYmm);

    final name = (cfg.printerInformationName).replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
    final bt = (cfg.printerInformationAddress.isEmpty ?
    'No address' : cfg.printerInformationAddress)
        .replaceAll('\n', ' ').replaceAll('\r', ' ').trim();

    final qrValue  = cfg.getPrinterInfoQRString();

    final page = PrintPage(widthPx, heightPx);
    final centerX = (widthPx / 2).round();

    final fontId = profile.fontId;
    final titleFontSize = fontSizeTitleById(fontId) + 6;

    final gapPx = (_pxFromMm(profile.gapMm) * 0.40).round().clamp(1, 6);
    final lineH = (titleFontSize + 6).clamp(14, 26);

    int y = marginY;

    final maxChars = profile.maxCharsPerLine <= 0 ? 22 : profile.maxCharsPerLine;
    final line1 = _limitChars(name.isEmpty ? 'No name' : name, maxChars);
    final line2 = _limitChars(bt, maxChars);

    if (line1.isNotEmpty) {
      await page.addText(
        line1,
        TextOptions(
          x: centerX,
          y: y + (lineH ~/ 2),
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          align: HAlignment.center,
          vAlign: VAlignment.middle,
        ),
      );
      y += lineH + gapPx;
    }

    if (line2.isNotEmpty) {
      await page.addText(
        line2,
        TextOptions(
          x: centerX,
          y: y + (lineH ~/ 2),
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          align: HAlignment.center,
          vAlign: VAlignment.middle,
        ),
      );
      y += lineH + gapPx;
    }

    final availableH = (heightPx - marginY - y - gapPx).clamp(60, heightPx);
    final qrSize = availableH.clamp(80, 180).toInt();

    final maxQrByWidth = (widthPx - marginX * 2).clamp(80, 220).toInt();
    final finalQr = qrSize > maxQrByWidth ? maxQrByWidth : qrSize;

    final qrTop = (heightPx - marginY - finalQr).clamp(y + gapPx, heightPx);
    final qrCenterY = (qrTop + finalQr / 2).round();

    page.addQR(
      qrValue,
      QROptions(
        x: centerX,
        y: qrCenterY,
        width: finalQr,
        height: finalQr,
        align: HAlignment.center,
        vAlign: VAlignment.middle,
      ),
    );

    return page;
  }

  Future<PrintPage> _buildPageForLocatorQr({
    required IdempiereLocator locator,
    required LabelProfile profile,
  }) async {
    final widthPx = _pxFromMm(profile.widthMm);
    final heightPx = _pxFromMm(profile.heightMm);

    final marginX = _pxMarginXFromMm(profile.marginXmm);
    final marginY = _pxFromMm(profile.marginYmm);

    final value =
    (locator.value ?? '').replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
    final page = PrintPage(widthPx, heightPx);
    final centerX = (widthPx / 2).round();

    final fontId = profile.fontId;
    final titleFontSize = fontSizeTitleById(fontId) + 6;

    final gapPx = (_pxFromMm(profile.gapMm) * 0.40).round().clamp(1, 6);
    final lineH = (titleFontSize + 6).clamp(14, 26);

    int y = marginY;

    final text = _limitChars(value, profile.maxCharsPerLine <= 0 ? 22 : profile.maxCharsPerLine);
    if (text.isNotEmpty) {
      await page.addText(
        text,
        TextOptions(
          x: centerX,
          y: y + (lineH ~/ 2),
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          align: HAlignment.center,
          vAlign: VAlignment.middle,
        ),
      );
      y += lineH + gapPx;
    }

    final availableH = (heightPx - marginY - y - gapPx).clamp(60, heightPx);
    final qrSize = availableH.clamp(80, 180).toInt();

    final maxQrByWidth = (widthPx - marginX * 2).clamp(80, 220).toInt();
    final finalQr = qrSize > maxQrByWidth ? maxQrByWidth : qrSize;

    final qrTop = (heightPx - marginY - finalQr).clamp(y + gapPx, heightPx);
    final qrCenterY = (qrTop + finalQr / 2).round();

    page.addQR(
      value,
      QROptions(
        x: centerX,
        y: qrCenterY,
        width: finalQr,
        height: finalQr,
        align: HAlignment.center,
        vAlign: VAlignment.middle,
      ),
    );

    return page;
  }

  String _limitChars(String s, int maxChars) {
    if (maxChars <= 0) return s;
    if (s.length <= maxChars) return s;
    return s.substring(0, maxChars);
  }

  // ------------------------------------------------------------
  // UI helpers
  // ------------------------------------------------------------
  void hideDeviceList() {
    state = state.copyWith(showDeviceList: false);
  }

  void hidePreview() {
    state = state.copyWith(showPreview: false);
  }

  void _showAlert(BuildContext context, String title, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }



  void setMtu(int saved) {
     savedMtu = saved ;
  }

  int getStatusPollIntervalMs() {
    final p = state.client!.packetIntervalMs < 0 ? 0 : state.client!.packetIntervalMs;
    int poll = (p == 0) ? 120 : (p * 12).clamp(120, 1200).toInt();
    return poll;

  }
  int getPacketIntervalMs({required int copies}) {
    if(copies<=1) {
      return state.client!.packetIntervalMs;
    }
    int newValue = (copies -1)* 3+state.client!.packetIntervalMs;
    return newValue.clamp(20, maxPacketIntervalMs);
  }

  int getStatusTimeoutMs({required int copies}) {
    final p = state.client!.packetIntervalMs < 0 ? 0 : state.client!.packetIntervalMs;
    int timeout = (8000 + copies * 2500).clamp(8000, 60000);
    timeout += (p * 250).clamp(0, 15000).toInt();
    return timeout;
  }

  void setProfile(LabelProfile profile) {
    state = state.copyWith(profile: profile);

  }



}

// ------------------------------
// Page (UI)
// ------------------------------
// ----------------------------------------------------------------------
// AsyncValue / Print pipeline moved to NiimbotPage
// ----------------------------------------------------------------------
final fireNiimbotPrintProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Guardamos el perfil a usar en la impresión (lo setea el PreviewModal)
final printProfileForNiimbotProvider = StateProvider.autoDispose<LabelProfile?>((ref) => null);



// ----------------------------------------------------------------------
// Page (UI)
// ----------------------------------------------------------------------
class NiimbotPage extends ConsumerStatefulWidget {
  final dynamic dataToPrint;
  final LabelProfile? profile;
  final bool? autoDisconnectAfterPrint;
  final String? bluetoothAddress;

  const NiimbotPage({
    super.key,
    this.dataToPrint,
    this.profile,
    this.autoDisconnectAfterPrint,
    this.bluetoothAddress,
  });

  @override
  ConsumerState<NiimbotPage> createState() => _NiimbotPageState();
}

class _NiimbotPageState extends ConsumerState<NiimbotPage> {
  bool autoConnectDone = false;
  bool _copiesInitDone = false;


  // ✅ Local active profile (picked from LabelConfigPage)
  LabelProfile? _activeProfile;
  bool _labelInitDone = false;
  late final NiimbotController _ctrl;
  void dispose(){
    debugPrint('[NIIMBOT] dispose');
    _ctrl.handleDisconnectSilence(waitForExit: 0);
    super.dispose();


  }
  @override
  void initState() {
    super.initState();

    _activeProfile = widget.profile;


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _ctrl = ref.read(niimbotControllerProvider.notifier);
      _ctrl.setAutoDisconnectAfterPrint(widget.autoDisconnectAfterPrint ?? false);
      await _loadSavedLabelIfNeeded();
      _ensureCopiesInit();
      if (!mounted || widget.bluetoothAddress == null || widget.bluetoothAddress!.isEmpty) return;
      await autoConnectIfNeeded(context, ref,
          autoConnectDone: autoConnectDone,
          bluetoothAddress: widget.bluetoothAddress!,
      );

    });
  }

  Future<void> _loadSavedLabelIfNeeded() async {
    if (_labelInitDone) return;
    _labelInitDone = true;

    // Si te pasaron profile explícito, no tocar storage
    if (widget.profile != null) {
      setState(() => _activeProfile = widget.profile);
      return;
    }

    try {
      final box = GetStorage();

      final helper = LabelProfilesStorageHelper(
        box: box,
        ref: ref,
        default40x25: defaultLabel40x25,
        default60x40: defaultLabel60x40,
        default50x30: defaultLabel50x30,
      );

      final selected = helper.loadAndHydrateProviders();

      setState(() => _activeProfile = selected);

      // sync copiesTemp
      final c = selected.copies < 1 ? 1 : selected.copies;
      ref.read(copiesTempProvider.notifier).state = c;
    } catch (e) {
      debugPrint('[NIIMBOT] loadSavedLabelIfNeeded failed: $e');
    }
  }

  Future<void> _printSelectedPrinterInfo() async {
    final ctrl = ref.read(niimbotControllerProvider.notifier);
    final selectedPrinter = ref.read(selectedPrinterConfigProvider);

    if (selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No printer selected')),
      );
      return;
    }

    if (!ctrl.isConnected()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to Niimbot')),
      );
      return;
    }

    await ctrl.printPrinterInformationQr(
      context,
      printer: selectedPrinter,
      profile: widget.profile,
    );
  }

  void _ensureCopiesInit() {
    if (_copiesInitDone) return;
    _copiesInitDone = true;

    final current = ref.read(copiesTempProvider);
    if (current > 0) return;

    final initial = (_activeProfile?.copies ?? widget.profile?.copies ?? 1);
    ref.read(copiesTempProvider.notifier).state = initial < 1 ? 1 : initial;
  }



  // ✅ Open LabelConfigPage and get selected profile back
  Future<void> _openLabelConfig() async {
    final LabelProfile? picked = await Navigator.push<LabelProfile?>(
      context,
      MaterialPageRoute(builder: (_) => const LabelConfigPage()),
    );

    if (picked == null) return;

    setState(() => _activeProfile = picked);

    // Update copies temp with profile copies (nice UX)
    final c = picked.copies < 1 ? 1 : picked.copies;
    ref.read(copiesTempProvider.notifier).state = c;

    final box = GetStorage();
    LabelProfilesStorageHelper(
      box: box,
      ref: ref,
      default40x25: defaultLabel40x25,
      default60x40: defaultLabel60x40,
      default50x30: defaultLabel50x30,
    ).saveFromProviders();
  }

  // ✅ Open PrinterSelectPage and get selected printer back
  Future<void> _openPrinterSelectAndPrintQr() async {
    final ctrl = ref.read(niimbotControllerProvider.notifier);

    final PrinterConnConfig? picked = await Navigator.push<PrinterConnConfig?>(
      context,
      MaterialPageRoute(
        builder: (_) => PrinterSelectPage(dataToPrint: widget.dataToPrint),
      ),
    );

    if (picked == null) return;

    ref.read(selectedPrinterConfigProvider.notifier).state = picked;

    // If user picked NIIMBOT BLE, auto-connect to that address (optional but helpful)
    final isNiimbot = (picked.lang ?? '').toUpperCase() == 'NIIMBOT';
    final addr = (picked.btAddress ?? '').trim();
    if (isNiimbot && addr.isNotEmpty && !ctrl.isConnected()) {
      ref.read(isPrintingProvider.notifier).state = true;
      await ctrl.connectToAddressSilence(context, address: addr);
      ref.read(isPrintingProvider.notifier).state = false;
    }

    if (!mounted) return;

    // Print QR info (requires connection)
    if (!ctrl.isConnected()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to Niimbot printer')),
      );
      return;
    }

    await ctrl.printPrinterInformationQr(
      context,
      printer: picked,
      profile: _activeProfile ?? widget.profile,
    );
  }

  @override
  Widget build(BuildContext context) {




    final state = ref.watch(niimbotControllerProvider);

    final ctrl = ref.read(niimbotControllerProvider.notifier);
    final printAsync = ref.watch(niimbotPrintControllerProvider);
    final isPrintLoading = printAsync.isLoading;
    final isConnected = ctrl.isConnected();
    final copiesTemp = ref.watch(copiesTempProvider);
    final isPrinting = ref.watch(isPrintingProvider);
    final selectedPrinter = ref.watch(selectedPrinterConfigProvider);
    ref.listen<AsyncValue<ResponseAsyncValue?>>(niimbotPrintControllerProvider,
            (prev, next) {
          next.whenOrNull(
            data: (res) {
              if (res == null) return;
              if (!context.mounted) return;


            },
            error: (e, st) {
              if (!context.mounted) return;
              showErrorCenterToast(context, e.toString());
            },
          );
        });
    final widthConnectButton = MediaQuery.of(context).size.width * 0.4;
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: () => popScopAction(context, ref),
              icon: const Icon(Icons.arrow_back),
            ),
            title: (widget.dataToPrint == null)
                ? const Text('NIIMBOT PRINTER')
                : getDataCard(widget.dataToPrint),
            actions: [
              if((state.client!=null && state.client!.isConnected()) &&
                  (!isPrinting && !state.isPrinting && !isPrintLoading))IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings),
                onPressed: () {
                  if(state.client==null || !state.client!.isConnected()){
                    return ;
                  }

                  _openSettingsSheet(context, ref);
                }
              ),

              if ((state.client!=null && state.client!.isConnected()) &&
                  (!isPrinting && !state.isPrinting && !isPrintLoading))
                printerInfoRefresh(context, ref, state),



            ],
          ),
          body: PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              if (didPop) return;
              await popScopAction(context, ref);
            },
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                children: [
                  // --- Label summary button ---
                  _summaryButton(
                    context: context,
                    title: 'Active label profile',
                    subtitle: _profileSummary(_activeProfile ?? widget.profile),
                    icon: Icons.label,
                    onPressed: () async => _openLabelConfig(),
                  ),

                  // --- Printer summary button ---
                  if (widget.dataToPrint == null)
                    _summaryButton(
                      context: context,
                      title: 'Selected printer',
                      subtitle: _printerSummary(selectedPrinter),
                      icon: Icons.print,
                      onPressed: () async => _openPrinterSelectAndPrintQr(),
                    ),

                  const SizedBox(height: 6),
                  // --- Status + progress (ARRIBA) ---
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if((state.client!=null && state.client!.isConnected()) &&
                                  (!isPrinting && !state.isPrinting && !isPrintLoading))
                              batteryChip(ref,
                                  isConnected: state.client?.isConnected() ?? false),

                              if((state.client!=null && state.client!.isConnected()) &&
                                  (!isPrinting && !state.isPrinting && !isPrintLoading))
                                printerInfoIcon(context, ref, state),


                              if (!isPrinting && !state.isPrinting && !isPrintLoading)
                                Expanded(
                                  child: SizedBox(
                                    width: widthConnectButton,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isConnected ? Colors.green : themeColorPrimary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: const Size(0, 34),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (!isConnected) {
                                          ref.invalidate(niimbotPacketIntervalSavedProvider);
                                          ref.read(isPrintingProvider.notifier).state = true;
                                          await ctrl.handleConnectScan(context);

                                          ref.read(isPrintingProvider.notifier).state = false;

                                        } else {
                                          ref.read(resultStatusProvider.notifier).state = null;
                                          try{
                                            await ctrl.handleDisconnect(context);
                                          }catch(_){

                                          }
                                          autoConnectDone = false;
                                        }
                                      },
                                      child: Text(
                                        isConnected ? 'Disconnect' : 'Connect',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 6),
                          Row(
                            children: [
                              getBluetoothIndicatorPanel(state),
                              const SizedBox(width: 10),
                              Expanded(child: Text(state.status,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12,)),),
                            ],
                          ),
                          const SizedBox(height: 15),
                          if (isPrinting || state.isPrinting || isPrintLoading)
                            const LinearProgressIndicator(minHeight: 6),

                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 110,
                          child: Text('Copies:', style: TextStyle(fontSize: 14,fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              await getIntDialog(
                                useScreenKeyboardOnly: true,
                                ref: ref,
                                minValue: 1,
                                quantity: copiesTemp,
                                targetProvider: copiesTempProvider,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$copiesTemp',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // --- Actions ---
                  if (!state.isPrinting && !isPrintLoading)
                    ..._buildActionButtons(
                      context,
                      ctrl: ctrl,
                      isConnected: isConnected,
                      profile: _activeProfile ?? widget.profile,
                    ),
                ],
              ),
            ),
          ),
        ),

        if (state.showDeviceList) _DeviceSelectionModal(state: state),

        // ✅ Preview modal ahora usa AsyncValue desde provider (sin executePrint directo)
        if (state.showPreview)
          _PreviewModal(
            state: state,
            profile: _activeProfile ?? widget.profile,
          ),
      ],
    );
  }


  Widget _summaryButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.purple),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
  void _openSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent, // para borde redondeado lindo
      builder: (_) {
        return Consumer(
          builder: (context, ref, __) {
            final state = ref.watch(niimbotControllerProvider);
            final ctrl = ref.read(niimbotControllerProvider.notifier);

            final printAsync = ref.watch(niimbotPrintControllerProvider);
            final isPrintLoading = printAsync.isLoading;
            final isPrinting = ref.watch(isPrintingProvider);

            final savedInterval = ref.watch(niimbotPacketIntervalSavedProvider) ?? 0;
            final editInterval = ref.watch(niimbotPacketIntervalEditProvider);
            final savedMtu = ref.watch(niimbotMtuSavedProvider) ?? 0;
            final editMtu = ref.watch(niimbotMtuEditProvider);

            final hasAddr = state.client?.getDevice()?.remoteId.str.isNotEmpty == true;
            final disabled = !hasAddr || isPrinting || state.isPrinting || isPrintLoading;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.62,
              minChildSize: 0.35,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Settings',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // --- Card settings (tu mismo contenido) ---
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // marginXOffSet
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'marginXOffSet: ${state.marginXOffSet}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: const Size(0, 30),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                                      ),
                                      onPressed: disabled ? null : () => ctrl.incMarginXOffSet(),
                                      child: const Text('+1', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    DropdownButton<int>(
                                      value: state.marginXOffSet,
                                      isDense: true,
                                      iconSize: 18,
                                      items: List.generate(
                                        11,
                                            (i) => DropdownMenuItem(
                                          value: i,
                                          child: Text('$i', style: const TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      onChanged: disabled
                                          ? null
                                          : (v) {
                                        if (v == null) return;
                                        ctrl.setMarginXOffSet(v);
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // packet interval
                                packetIntervalEditor(
                                  paddingHorizontal: 0,
                                  ref: ref,
                                  disabled: disabled,
                                  saved: savedInterval,
                                  edit: editInterval,
                                  onSave: () async {

                                    final addr = state.client?.getDevice()?.remoteId.str ?? '';
                                    debugPrint('Saving packet interval: $addr');
                                    if (addr.isEmpty) return;
                                    final box = GetStorage();
                                    debugPrint('Saving packet interval success: $addr');
                                    await savePacketIntervalForAddress(
                                      ref: ref,
                                      bluetoothAddress: addr,
                                      box: box,
                                    );
                                    debugPrint('Saving packet interval success: ${ref.read(niimbotPacketIntervalSavedProvider)}');
                                    if (context.mounted) {
                                      showSuccessCenterToast(context, 'Packet Interval(ms) saved');
                                    }
                                  },
                                  onDec: () {
                                    final v = ref.read(niimbotPacketIntervalEditProvider);
                                    ref.read(niimbotPacketIntervalEditProvider.notifier).state =
                                        (v - 1).clamp(minPacketIntervalMs, maxPacketIntervalMs);
                                  },
                                  onInc: () {
                                    final v = ref.read(niimbotPacketIntervalEditProvider);
                                    ref.read(niimbotPacketIntervalEditProvider.notifier).state =
                                        (v + 1).clamp(minPacketIntervalMs, maxPacketIntervalMs);
                                  },
                                ),

                                const SizedBox(height: 10),

                                // mtu
                                mtuEditor(
                                  paddingHorizontal: 0,
                                  disabled: disabled,
                                  saved: savedMtu,
                                  edit: editMtu,
                                  onChanged: (v) {
                                    if (v == null) return;
                                    ref.read(niimbotMtuEditProvider.notifier).state = v;
                                  },
                                  onSave: () async {
                                    final addr = state.client?.getDevice()?.remoteId.str ?? '';
                                    if (addr.isEmpty) return;
                                    final box = GetStorage();
                                    await saveMtuForAddress(
                                      ref: ref,
                                      bluetoothAddress: addr,
                                      box: box,
                                    );
                                    if (context.mounted) {
                                      showSuccessCenterToast(context, 'MTU saved');
                                    }
                                  },
                                ),

                                const SizedBox(height: 10),

                                //autoDisconnectPanel(ref: ref),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Acciones abajo (opcional)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  String _printerSummary(PrinterConnConfig? p) {
    if (p == null) return 'None';
    final name = (p.name ?? '').trim().isEmpty ? 'Printer' : p.name!;
    final addr = (p.printerInformationAddress).trim();
    final lang = (p.lang ?? '').trim();
    final type = (p.typeText ?? '').trim();
    return '$name (${addr.isEmpty ? 'no addr' : addr})'
        '${lang.isEmpty ? '' : '  lang:$lang'}'
        '${type.isEmpty ? '' : '  type:$type'}';
  }

  // Common button builder
  Widget btn(
      BuildContext context, {
        required String label,
        Color? colorBackground,
        Color? colorTextForeground,
        IconData? icon,
        double? iconSize,
        Color? iconColor,
        required VoidCallback? onPressed,
      }) {
    final bg = onPressed == null ? Colors.grey.shade400 : (colorBackground ?? Colors.blue.shade700);
    final fg = colorTextForeground ?? Colors.white;
    final icColor = iconColor ?? fg;

    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize ?? 20, color: icColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(
      BuildContext context, {
        required NiimbotController ctrl,
        required bool isConnected,
        required LabelProfile? profile,
      }) {
    final data = widget.dataToPrint;

    // No data -> demos
    if (data == null) {
      return [
        btn(
          context,
          label: '🖨️ Printer Information QR(Actual)',
          onPressed: isConnected
              ? () {
            final newPrinter = ctrl.buildPrinterConnConfigFromClient();
            if (newPrinter == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printer data not available')),
              );
              return;
            }
            ctrl.printPrinterInformationQr(
              context,
              printer: newPrinter,
              profile: widget.profile,
            );
          }
              : null,
        ),
        btn(
          context,
          label: '🖨️ Printer Information QR(Selected)',
          onPressed: isConnected ? _printSelectedPrinterInfo : null,
        ),
        btn(
          context,
          label: 'Bold Text Demo',
          icon: Icons.text_fields,
          onPressed: isConnected ? () => ctrl.handlePrintBoldText(context) : null,
        ),
        btn(
          context,
          label: 'Simple Demo (QR + EAN13)',
          icon: Icons.qr_code,
          onPressed: isConnected ? () => ctrl.handlePrintSimple(context) : null,
        ),
        btn(
          context,
          label: 'Quick Print Test',
          icon: Icons.speed,
          onPressed: isConnected ? () => ctrl.handleQuickPrintTest(context, profile: profile) : null,
        ),

      ];
    }

    // Product
    if (data is IdempiereProduct) {
      return [
        btn(
          context,
          label: 'Print simple (SKU text + UPC barcode)',
          onPressed: isConnected
              ? () => ctrl.printProductSimple(
            context,
            product: data,
            profile: profile,
          )
              : null,
        ),
        btn(
          context,
          label: 'Print complete (Name + SKU + UPC)',
          onPressed: isConnected
              ? () => ctrl.printProductComplete(
            context,
            product: data,
            profile: profile,
          )
              : null,
        ),
      ];
    }

    // Locator
    if (data is IdempiereLocator) {
      return [
        btn(
          context,
          label: 'Print barcode (Value)',
          onPressed: isConnected
              ? () => ctrl.printLocatorBarcode(
            context,
            locator: data,
            profile: profile,
          )
              : null,
        ),
        btn(
          context,
          label: 'Print QR (Value)',
          onPressed: isConnected
              ? () => ctrl.printLocatorQr(
            context,
            locator: data,
            profile: profile,
          )
              : null,
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Unsupported dataToPrint type: ${data.runtimeType}',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    ];
  }

  // Header card
  Widget getDataCard(dynamic dataToPrint) {
    const double fontSize = 16;
    const double fontSizeData = 13;
    const double fontSizeDataSmall = 12;

    if (dataToPrint == null) {
      return const Text(
        'TEST PANEL',
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.purple),
      );
    }

    if (dataToPrint is IdempiereProduct) {
      final name = dataToPrint.name ?? '';
      final upc = dataToPrint.uPC ?? '';
      final sku = dataToPrint.sKU ?? '';

      return Padding(
        padding: const EdgeInsets.only(top: 5, right: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: const TextStyle(
                fontSize: fontSizeData,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    upc,
                    style: const TextStyle(
                      fontSize: fontSizeDataSmall,
                      fontWeight: FontWeight.bold,
                      color: themeColorPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sku,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: fontSizeDataSmall,
                      fontWeight: FontWeight.bold,
                      color: themeColorPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (dataToPrint is IdempiereLocator) {
      return Text(
        dataToPrint.value ?? '',
        style: const TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.purple),
      );
    }

    return Text(
      'OBJETO NO SOPORTADO ${dataToPrint.runtimeType}',
      style: const TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.purple),
    );
  }

  String _profileSummary(LabelProfile? p) {
    final x = p;
    if (x == null) return 'None';
    return '${x.name}  ${x.widthMm}x${x.heightMm}mm  copies:${x.copies}  margin:${x.marginXmm}/${x.marginYmm}  font:${x.fontId}';
  }

  Future<void> popScopAction(BuildContext context, WidgetRef ref) async {
    final ctrl = ref.read(niimbotControllerProvider.notifier);
    try{
      await ctrl.handleDisconnect(context);
    }catch(_){

    }

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  Widget getStatusIcon(BuildContext context, WidgetRef ref) {
    final resultStatus = ref.watch(resultStatusProvider);
    Color resultColor = Colors.white ;
    IconData iconData = Icons.cancel ;
    if(resultStatus == null){
      resultColor = themeColorPrimary;
      iconData = Icons.radio_button_checked;
    } else if(resultStatus == true) {
      resultColor = Colors.green;
      iconData = Icons.check_circle;
    } else {
      resultColor = Colors.red;
      iconData = Icons.error;
    }
    return Icon(iconData,color: resultColor,);
  }
  Color getStatusColor(BuildContext context, WidgetRef ref) {
    final resultStatus = ref.watch(resultStatusProvider);
    Color resultColor = Colors.white ;
    if(resultStatus == null){
      resultColor = Colors.white;
    } else if(resultStatus == true) {
      resultColor = Colors.green.shade200;
    } else {
      resultColor = Colors.red.shade100;
    }
    return resultColor ;
  }
}

// ----------------------------------------------------------------------
// Device Modal
// ----------------------------------------------------------------------
class _DeviceSelectionModal extends ConsumerWidget {
  final NiimbotState state;
  const _DeviceSelectionModal({required this.state});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(niimbotControllerProvider.notifier);

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                blurRadius: 20,
                offset: Offset(0, 10),
                color: Colors.black26,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // 🔵 HEADER estilo Niimbot
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: const BoxDecoration(
                  color: themeColorPrimary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bluetooth, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Select a Device',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 📜 DEVICE LIST
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: state.devices.length,
                  itemBuilder: (_, i) {
                    final d = state.devices[i];
                    final name = d.platformName;
                    final id = d.remoteId.str;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Material(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            final container = ProviderScope.containerOf(context, listen: false);
                            ctrl.hideDeviceList();

                            unawaited(() async {
                              try {
                                await ctrl.connectToDevice(context, d)
                                    .timeout(const Duration(seconds: 12));
                                debugPrint('[NIIMBOT] connect flow OK');
                                await Future.delayed(const Duration(milliseconds: 200));
                                final st = container.read(niimbotControllerProvider);
                                final client = st.client;

                                if (client != null && client.isConnected()) {

                                  debugPrint('[NIIMBOT] client connected');
                                  final box = GetStorage();
                                  final bluetoothAddress =
                                      client.getDevice()?.remoteId.str ?? '';

                                  if (bluetoothAddress.isNotEmpty) {
                                    debugPrint('[NIIMBOT] initPacketIntervalForAddressContainer');

                                    initPacketIntervalForAddressContainer(
                                      container: container,
                                      bluetoothAddress: bluetoothAddress,
                                      box: box,
                                    );

                                    debugPrint('[NIIMBOT] initMtuForAddressContainer');


                                    initMtuForAddressContainer(
                                      container: container,
                                      bluetoothAddress: bluetoothAddress,
                                      box: box,
                                    );

                                    debugPrint('[NIIMBOT] refreshPrinterInfoFromClientContainer');


                                    await refreshPrinterInfoFromClientContainer(
                                        container, client);
                                    debugPrint('[NIIMBOT] refreshPrinterInfoFromClientContainer end');


                                  }
                                }
                              } catch (e, st) {
                                debugPrint('[NIIMBOT] connect flow ERROR: $e');
                                debugPrint('$st');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Connection failed: $e')),
                                  );
                                }
                              }
                            }());
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.print,
                                    size: 18, color: themeColorPrimary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name.isEmpty ? 'NIIMBOT' : name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        id,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    size: 18, color: Colors.black45),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // 🔴 CANCEL BUTTON estilo Niimbot
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton(
                  onPressed: ctrl.hideDeviceList,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Preview Modal (UI-only + triggers provider fire)
// ----------------------------------------------------------------------
class _PreviewModal extends ConsumerWidget {
  final NiimbotState state;
  final LabelProfile? profile;

  const _PreviewModal({
    required this.state,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(niimbotControllerProvider.notifier);


    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),

                if (state.previewImage != null)
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Image.memory(
                          state.previewImage!,
                          fit: BoxFit.contain,
                          height: MediaQuery.of(context).size.height * 0.4,
                        ),
                      ),
                    ),
                  ),

                const Divider(height: 1),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: ctrl.hidePreview,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:  () {
                        ref.read(niimbotPrintControllerProvider.notifier)
                            .print(profile: profile
                            ,autoDisconnectAfterPrint: state.autoDisconnectAfterPrint,
                        context: context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34C759),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text('Print', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

