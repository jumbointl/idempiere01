// ===============================
// niimbot_test_page.dart (Riverpod)
// ===============================
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:niim_blue_flutter/niim_blue_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

// ------------------------------
// State
// ------------------------------
class PendingJob {
  final PrintPage page;
  final String successMessage;
  const PendingJob({required this.page, required this.successMessage});
}

@immutable
class NiimbotTestState {
  final NiimbotBluetoothClient? client;
  final String status;
  final List<BluetoothDevice> devices;
  final bool showDeviceList;
  final Uint8List? previewImage;
  final bool showPreview;
  final PendingJob? pendingJob;

  const NiimbotTestState({
    required this.client,
    required this.status,
    required this.devices,
    required this.showDeviceList,
    required this.previewImage,
    required this.showPreview,
    required this.pendingJob,
  });

  factory NiimbotTestState.initial() => const NiimbotTestState(
    client: null,
    status: 'Disconnected',
    devices: <BluetoothDevice>[],
    showDeviceList: false,
    previewImage: null,
    showPreview: false,
    pendingJob: null,
  );

  NiimbotTestState copyWith({
    NiimbotBluetoothClient? client,
    String? status,
    List<BluetoothDevice>? devices,
    bool? showDeviceList,
    Uint8List? previewImage,
    bool? showPreview,
    PendingJob? pendingJob,
    bool clearPreviewImage = false,
    bool clearPendingJob = false,
  }) {
    return NiimbotTestState(
      client: client ?? this.client,
      status: status ?? this.status,
      devices: devices ?? this.devices,
      showDeviceList: showDeviceList ?? this.showDeviceList,
      previewImage: clearPreviewImage ? null : (previewImage ?? this.previewImage),
      showPreview: showPreview ?? this.showPreview,
      pendingJob: clearPendingJob ? null : (pendingJob ?? this.pendingJob),
    );
  }
}

// ------------------------------
// Controller
// ------------------------------
class NiimbotTestController extends StateNotifier<NiimbotTestState> {
  NiimbotTestController() : super(NiimbotTestState.initial());

  // Normaliza ids/MAC para comparar: quita ':' y cualquier cosa no-hex, uppercase.
  String _normId(String s) => s.toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');

  Future<List<BluetoothDevice>> _scanNiimbotDevices({Duration timeout = const Duration(seconds: 3)}) async {
    final foundDevices = await NiimbotBluetoothClient.listDevices(timeout: timeout);
    final connectedDevices = FlutterBluePlus.connectedDevices;

    final allDevices = [...foundDevices, ...connectedDevices];
    final unique = <BluetoothDevice>[];
    final seen = <String>{};
    for (final d in allDevices) {
      final id = d.remoteId.str;
      if (seen.add(id)) unique.add(d);
    }
    return unique;
  }

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

  Future<void> handleConnectScan(BuildContext context) async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      _showAlert(context, 'Error', 'Bluetooth permissions are required');
      return;
    }

    try {
      state = state.copyWith(status: 'Scanning for devices...');

      final devices = await _scanNiimbotDevices(timeout: const Duration(seconds: 3));

      if (devices.isEmpty) {
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
        _showAlert(
          context,
          'Bluetooth Required',
          'Please enable Bluetooth in your device settings and try connecting again.',
        );
      } else {
        _showAlert(context, 'Error', e.toString());
      }
      state = state.copyWith(status: 'Scan failed');
    }
  }

  /// Conecta a una impresora Niimbot usando el address guardado (remoteId.str / MAC),
  /// haciendo scan como en handleConnectScan, pero SIN mostrar modal/lista.
  /// Devuelve true si conecta.
  Future<bool> connectToAddressSilence(
    BuildContext context, {
    required String address,
    Duration scanTimeout = const Duration(seconds: 3),
  }) async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) return false;

    final target = _normId(address);
    if (target.isEmpty) return false;

    try {
      state = state.copyWith(status: 'Scanning Niimbot...');
      final devices = await _scanNiimbotDevices(timeout: scanTimeout);
      if (devices.isEmpty) {
        state = state.copyWith(status: 'No devices found');
        return false;
      }

      BluetoothDevice? match;
      for (final d in devices) {
        if (_normId(d.remoteId.str) == target) {
          match = d;
          break;
        }
      }

      if (match == null) {
        // No match exacto: guardamos lista para que el usuario elija si hace falta.
        state = state.copyWith(devices: devices, showDeviceList: true, status: 'Select a device');
        return false;
      }

      await connectToDevice(context, match);
      return isConnected();
    } catch (_) {
      state = state.copyWith(status: 'Connection failed', client: null);
      return false;
    }
  }

  Future<void> connectToDevice(BuildContext context, BluetoothDevice device) async {
    state = state.copyWith(showDeviceList: false, status: 'Connecting...');
    try {
      final client = NiimbotBluetoothClient();
      client.setDevice(device);

      final result = await client.connect();

      state = state.copyWith(
        client: client,
        status: 'Connected to ${result.deviceName}',
      );

      client.startHeartbeat();
    } catch (e) {
      if (e.toString().contains('Bluetooth is not powered on')) {
        _showAlert(
          context,
          'Bluetooth Required',
          'Please enable Bluetooth in your device settings and try connecting again.',
        );
      } else {
        _showAlert(context, 'Error', e.toString());
      }
      state = state.copyWith(status: 'Connection failed', client: null);
    }
  }

  Future<void> handleDisconnect(BuildContext context) async {
    final client = state.client;
    if (client == null) return;

    try {
      client.stopHeartbeat();
      await client.abstraction.printEnd();
      await client.disconnect();

      state = state.copyWith(
        status: 'Disconnected',
        client: null,
        clearPreviewImage: true,
        clearPendingJob: true,
        showPreview: false,
        showDeviceList: false,
      );
    } catch (e) {
      _showAlert(context, 'Error', 'Failed to disconnect: $e');
    }
  }

  bool isConnected() => state.client != null && state.client!.isConnected();

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
      _showAlert(context, 'Error', 'Failed to generate preview: $e');
    }
  }

  Future<void> executePrint(BuildContext context) async {
    state = state.copyWith(showPreview: false);

    if (!isConnected()) {
      _showAlert(context, 'Error', 'Not connected');
      state = state.copyWith(clearPendingJob: true);
      return;
    }

    final job = state.pendingJob;
    if (job == null) return;

    await _executePrintTask(context, job.page, job.successMessage);
    state = state.copyWith(clearPendingJob: true);
  }

  Future<void> _executePrintTask(
      BuildContext context,
      PrintPage page,
      String successMessage,
      ) async {
    final client = state.client;
    if (client == null || !client.isConnected()) {
      throw Exception('Not connected');
    }

    try {
      client.stopHeartbeat();
      client.packetIntervalMs = 0;

      final task = client.createPrintTask(
        const PrintOptions(
          totalPages: 1,
          density: 3,
          labelType: LabelType.withGaps,
          statusPollIntervalMs: 100,
          statusTimeoutMs: 8000,
        ),
      );

      if (task == null) {
        throw Exception('Failed to create print task - printer model not detected');
      }

      await task.printInit();
      await task.printPage(page.toEncodedImage(), 1);
      await task.waitForFinished();

      client.startHeartbeat();
      _showAlert(context, 'Success', successMessage);
    } catch (e) {
      try {
        client.startHeartbeat();
      } catch (_) {}
      _showAlert(context, 'Error', 'Failed to print: $e');
    }
  }

  // -------- demo actions (igual a tu ejemplo) --------

  Future<void> handlePrintSimple(BuildContext context) async {
    if (!isConnected()) {
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
        height: 100,
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

  // Tu “Quick Print Test” original era raro (PrintPage(8,1) + lineas 0,0)
  // Te dejo una prueba útil:
  Future<void> handleQuickPrintTest(BuildContext context) async {
    if (!isConnected()) {
      _showAlert(context, 'Error', 'Not connected');
      return;
    }

    final page = PrintPage(400, 240);

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

  @override
  void dispose() {
    final client = state.client;

    if (client != null) {
      // dispose() no puede ser async: disparo y me olvido.
      unawaited(() async {
        try {
          // opcional pero recomendado por tu ejemplo
          try {
            await client.abstraction.printEnd();
          } catch (_) {}

          client.stopHeartbeat();

          await client.disconnect();
        } catch (_) {
        }
      }());
    }

    super.dispose();
  }
}

// ------------------------------
// Provider
// ------------------------------
final niimbotTestControllerProvider =
StateNotifierProvider<NiimbotTestController, NiimbotTestState>(
      (ref) => NiimbotTestController(),
);

// ------------------------------
// Page (UI)
// ------------------------------
class NiimbotTestPage extends ConsumerWidget {
  const NiimbotTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(niimbotTestControllerProvider);
    final ctrl = ref.read(niimbotTestControllerProvider.notifier);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5FCFF),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'NiimBlueLibRN (Riverpod)',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Status: ${state.status}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),

                    _btn(
                      context,
                      label: '🔌 Connect to Printer',
                      color: Colors.blue.shade700,
                      onPressed: () => ctrl.handleConnectScan(context),
                    ),
                    _btn(
                      context,
                      label: '⏏️ Disconnect',
                      color: Colors.blue.shade700,
                      onPressed: state.client == null ? null : () => ctrl.handleDisconnect(context),
                    ),
                    _btn(
                      context,
                      label: '🖨️ Quick Print Test (TEST + CODE128)',
                      color: Colors.blue.shade700,
                      onPressed: ctrl.isConnected() ? () => ctrl.handleQuickPrintTest(context) : null,
                    ),
                    _btn(
                      context,
                      label: '🅰️ Bold Text Demo',
                      color: Colors.blue.shade700,
                      onPressed: ctrl.isConnected() ? () => ctrl.handlePrintBoldText(context) : null,
                    ),
                    _btn(
                      context,
                      label: '🎨 Simple Demo (QR + EAN13)',
                      color: const Color(0xFF34C759),
                      onPressed: ctrl.isConnected() ? () => ctrl.handlePrintSimple(context) : null,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (state.showDeviceList) _DeviceSelectionModal(state: state),
        if (state.showPreview) _PreviewModal(state: state),
      ],
    );
  }

  Widget _btn(
      BuildContext context, {
        required String label,
        required Color color,
        required VoidCallback? onPressed,
      }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

// ------------------------------
// Device Modal
// ------------------------------
class _DeviceSelectionModal extends ConsumerWidget {
  final NiimbotTestState state;
  const _DeviceSelectionModal({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(niimbotTestControllerProvider.notifier);

    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Select a Device',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.devices.length,
                    itemBuilder: (_, i) {
                      final d = state.devices[i];
                      final name = d.platformName;
                      final id = d.remoteId.str;

                      return ListTile(
                        title: Text(name.isEmpty ? 'NIIMBOT' : name),
                        subtitle: Text(id),
                        onTap: () => ctrl.connectToDevice(context, d),
                      );
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              TextButton(
                onPressed: ctrl.hideDeviceList,
                child: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------
// Preview Modal
// ------------------------------
class _PreviewModal extends ConsumerWidget {
  final NiimbotTestState state;
  const _PreviewModal({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(niimbotTestControllerProvider.notifier);

    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const Divider(height: 1),
                if (state.previewImage != null)
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(20),
                    child: Image.memory(
                      state.previewImage!,
                      fit: BoxFit.contain,
                      height: MediaQuery.of(context).size.height * 0.4,
                    ),
                  ),
                const Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: ctrl.hidePreview,
                      child: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 16)),
                    ),
                    ElevatedButton(
                      onPressed: () => ctrl.executePrint(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34C759),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text('Print', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
