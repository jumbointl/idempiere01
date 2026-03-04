import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niim_blue_flutter/niim_blue_flutter.dart';

import '../models/printer_select_models.dart';
import 'niimbot_page.dart';

Future<PrinterConnConfig?> showPrinterPickerBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required NiimbotController controller,
}) async {
  return showModalBottomSheet<PrinterConnConfig?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _PrinterPickerSheet(controller: controller),
  );
}

class _PrinterPickerSheet extends ConsumerStatefulWidget {
  final NiimbotController controller;
  const _PrinterPickerSheet({required this.controller});

  @override
  ConsumerState<_PrinterPickerSheet> createState() => _PrinterPickerSheetState();
}

class _PrinterPickerSheetState extends ConsumerState<_PrinterPickerSheet> {
  int _timeoutSec = 12; // default 12
  bool _loadingSaved = false;
  bool _scanning = false;

  // Saved printers from pos_universal_printer (you adapt)
  List<PrinterConnConfig> _saved = [];

  // Nearby devices found by scan (NiimbotBluetoothClient.listDevices)
  List<BluetoothDevice> _nearby = [];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    setState(() => _loadingSaved = true);
    try {
      // TODO: Use pos_universal_printer here.
      // Replace this adapter with your real call that returns saved bluetooth printers.
      //
      // Example idea (fake):
      // final saved = await PosUniversalPrinter.instance.getSavedBluetoothPrinters();
      // _saved = saved.map((p) => PrinterConnConfig(
      //   btAddress: p.address,
      //   id: 'bt_${p.address}',
      //   type: PrinterConnType.bluetooth,
      //   name: p.name ?? 'BT Printer',
      //   lang: p.lang ?? 'NIIMBOT',
      //   typeText: p.isBle ? 'BLE' : 'BT',
      // )).toList();

      _saved = []; // keep empty if you haven't wired it yet
    } finally {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  Future<void> _scanNearby() async {
    setState(() => _scanning = true);
    try {
      final devices = await NiimbotBluetoothClient.listDevices(
        timeout: Duration(seconds: _timeoutSec),
      );

      // Deduplicate by remoteId
      final seen = <String>{};
      final unique = <BluetoothDevice>[];
      for (final d in devices) {
        final id = d.remoteId.str;
        if (seen.add(id)) unique.add(d);
      }

      if (mounted) setState(() => _nearby = unique);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _connectAndReturnBluetooth({
    required String name,
    required String btAddress,
    required String lang,
    required String typeText,
    BluetoothDevice? device,
  }) async {
    final ctrl = widget.controller;

    // If already connected: disconnect first (as requested)
    if (ctrl.isConnected()) {
      try{
        await ctrl.handleDisconnect(context);
      }catch(_){

      }

    }

    // Connect using BluetoothDevice if provided, else use silent address
    bool ok = false;
    if (device != null) {
      await ctrl.connectToDevice(context, device);
      ok = ctrl.isConnected();
    } else {
      ok = await ctrl.connectToAddressSilence(context, address: btAddress);
    }

    if (!ok) return;

    final newPrinter = PrinterConnConfig(
      btAddress: btAddress,
      id: 'bt_$btAddress',
      type: PrinterConnType.bluetooth,
      name: name.isEmpty ? 'NIIMBOT' : name,
      lang: lang.isEmpty ? 'NIIMBOT' : lang,
      typeText: typeText.isEmpty ? 'BLE' : typeText,
    );

    if (!mounted) return;
    Navigator.pop(context, newPrinter);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return SafeArea(

      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Bluetooth Printer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Timeout spinner + Scan
            Row(
              children: [
                const Text('Scan timeout:'),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: _timeoutSec,
                  items: List.generate(
                    49, // 12..60 inclusive => 49 values
                        (i) {
                      final v = 12 + i;
                      return DropdownMenuItem(
                        value: v,
                        child: Text('${v}s'),
                      );
                    },
                  ),
                  onChanged: _scanning
                      ? null
                      : (v) {
                    if (v == null) return;
                    setState(() => _timeoutSec = v);
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _scanning ? null : _scanNearby,
                  icon: _scanning
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.bluetooth_searching),
                  label: const Text('Scan'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Saved section
            Row(
              children: [
                const Expanded(
                  child: Text('Saved Bluetooth', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: _loadingSaved ? null : _loadSaved,
                  icon: _loadingSaved
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                ),
              ],
            ),

            if (_saved.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No saved printers.'),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.25),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _saved.length,
                  itemBuilder: (_, i) {
                    final p = _saved[i];
                    return ListTile(
                      leading: const Icon(Icons.print),
                      title: Text(p.name),
                      subtitle: Text(p.btAddress! ),
                      onTap: () => _connectAndReturnBluetooth(
                        name: p.name,
                        btAddress: p.btAddress!,
                        lang: p.lang!,
                        typeText: p.typeText!,
                      ),
                    );
                  },
                ),
              ),

            const Divider(height: 20),

            // Nearby section
            Row(
              children: const [
                Expanded(
                  child: Text('Nearby', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            if (_nearby.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No nearby devices scanned yet.'),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _nearby.length,
                  itemBuilder: (_, i) {
                    final d = _nearby[i];
                    final name = d.platformName.isEmpty ? 'NIIMBOT' : d.platformName;
                    final btAddress = d.remoteId.str;

                    return ListTile(
                      leading: const Icon(Icons.bluetooth),
                      title: Text(name),
                      subtitle: Text(btAddress),
                      trailing: ctrl.isConnected() ? const Icon(Icons.link) : null,
                      onTap: () => _connectAndReturnBluetooth(
                        name: name,
                        btAddress: btAddress,
                        lang: 'NIIMBOT',
                        typeText: 'BLE',
                        device: d,
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
