import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../products/common/bluetooth_permission.dart';
import '../models/printer_select_models.dart';

final printerListProvider = StateProvider<List<PrinterConnConfig>>((ref) => []);
final selectedPrinterIdProvider = StateProvider<String?>((ref) => null);

class PrinterSelectPage extends ConsumerStatefulWidget {
  final dynamic dataToPrint;
  const PrinterSelectPage({super.key, required this.dataToPrint});

  @override
  ConsumerState<PrinterSelectPage> createState() => _PrinterSelectPageState();
}

class _PrinterSelectPageState extends ConsumerState<PrinterSelectPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final _wifiName = TextEditingController();
  final _wifiIp = TextEditingController();
  final _wifiPort = TextEditingController(text: '9100');

  final _btName = TextEditingController();
  final _btAddress = TextEditingController();

  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);

    // Riverpod: avoid modifying providers inside initState lifecycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrinters();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _wifiName.dispose();
    _wifiIp.dispose();
    _wifiPort.dispose();
    _btName.dispose();
    _btAddress.dispose();
    super.dispose();
  }

  void _loadPrinters() {
    final raw = box.read(PrinterSelectStorageKeys.printersList);
    final selectedId = box.read(PrinterSelectStorageKeys.selectedPrinterId);

    if (raw is String && raw.trim().isNotEmpty) {
      final list = (jsonDecode(raw) as List)
          .map((e) => PrinterConnConfig.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      ref.read(printerListProvider.notifier).state = list;
    }

    if (selectedId is String && selectedId.trim().isNotEmpty) {
      ref.read(selectedPrinterIdProvider.notifier).state = selectedId;
    }
  }

  void _savePrintersToStorage() {
    final list = ref.read(printerListProvider);
    box.write(
      PrinterSelectStorageKeys.printersList,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    final selected = ref.read(selectedPrinterIdProvider);
    box.write(PrinterSelectStorageKeys.selectedPrinterId, selected);
  }

  void _addPrinter(PrinterConnConfig p) {
    final list = [...ref.read(printerListProvider)];
    final idx = list.indexWhere((x) => x.id == p.id);
    if (idx >= 0) {
      list[idx] = p;
    } else {
      list.add(p);
    }
    ref.read(printerListProvider.notifier).state = list;
    ref.read(selectedPrinterIdProvider.notifier).state = p.id;
    _savePrintersToStorage();
  }

  void _removePrinter(String id) {
    final list = [...ref.read(printerListProvider)];
    list.removeWhere((x) => x.id == id);
    ref.read(printerListProvider.notifier).state = list;

    final selected = ref.read(selectedPrinterIdProvider);
    if (selected == id) {
      ref.read(selectedPrinterIdProvider.notifier).state =
      list.isNotEmpty ? list.last.id : null;
    }
    _savePrintersToStorage();
  }

  Future<void> _disconnectSafe() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {}
  }

  Future<bool> _testBluetoothTsplConnection(String mac) async {
    const String tsplTest = 'CLS\n';

    try {
      final already = await PrintBluetoothThermal.connectionStatus;
      if (already) {
        await _disconnectSafe();
      }

      final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: mac,
      );

      if (!connected) return false;

      await Future.delayed(const Duration(milliseconds: 150));
      final List<int> bytes = utf8.encode(tsplTest).toList();
      final ok = await PrintBluetoothThermal.writeBytes(
          bytes,
      );

      await Future.delayed(const Duration(milliseconds: 120));
      await _disconnectSafe();

      return ok;
    } catch (_) {
      await _disconnectSafe();
      return false;
    }
  }

  Future<void> testConnection(PrinterConnConfig p) async {
    try {
      if (p.type == PrinterConnType.wifi) {
        final ip = p.ip ?? '';
        final port = p.port ?? 9100;

        final socket = await Socket.connect(
          ip,
          port,
          timeout: const Duration(seconds: 4),
        );
        socket.destroy();

        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Connection'),
            content: Text('✅ WiFi OK: $ip:$port'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              )
            ],
          ),
        );
      } else {
        final mac = (p.btAddress ?? '').trim();
        if (mac.isEmpty) {
          if (!mounted) return;
          await _showMsg('Connection', '❌ BT address vacío');
          return;
        }

        final ok = await _testBluetoothTsplConnection(mac);
        if (!mounted) return;
        await _showMsg(
          'Connection',
          ok ? '✅ Bluetooth OK: $mac' : '❌ Bluetooth ERROR: $mac',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await _showMsg('Connection', '❌ Error: $e');
    }
  }

  Future<void> _showMsg(String title, String msg) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  // =========================================================
  // ✅ NEW: BT picker dialog (paired devices) + connect + fill form
  // =========================================================
  Future<void> _openBluetoothPickerDialog() async {
    if (!mounted) return;

    final ok = await ensureBluetoothPermissions();
    if (!ok) {
      showErrorMessage(context, ref, 'Permisos requeridos');
      return;
    }

    List<BluetoothInfo> devices = [];
    try {
      debugPrint('start PrintBluetoothThermal.pairedBluetooth');
      devices = await PrintBluetoothThermal.pairedBluetooths;
      debugPrint('listResult ${devices.length}');
    } catch (e) {
      if (!mounted) return;
      await _showMsg('Bluetooth', '❌ Error obteniendo lista: $e');
      return;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Bluetooth devices (paired)'),
          content: SizedBox(
            width: double.maxFinite,
            child: devices.isEmpty
                ? const Text('No paired devices found.')
                : ListView.separated(
              shrinkWrap: true,
              itemCount: devices.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final d = devices[i];
                final name = d.name.trim().isEmpty ? 'Unknown' : d.name.trim();
                final mac = d.macAdress.trim();

                return ListTile(
                  title: Text(name),
                  subtitle: Text(mac),
                  leading: const Icon(Icons.print),
                  onTap: () async {
                    // Intentar conectar
                    try {
                      final already = await PrintBluetoothThermal.connectionStatus;
                      if (already) {
                        await _disconnectSafe();
                        await Future.delayed(const Duration(milliseconds: 120));
                      }

                      final connected = await PrintBluetoothThermal.connect(
                        macPrinterAddress: mac,
                      );

                      if (!connected) {
                        await _showInlineError(ctx, 'No se pudo conectar a $mac');
                        return;
                      }

                      // Fill fields
                      if (mounted) {
                        _btName.text = name.isEmpty ? 'BT Printer' : name;
                        _btAddress.text = mac;
                      }

                      // Disconnect after check (optional)
                      await Future.delayed(const Duration(milliseconds: 120));
                      await _disconnectSafe();

                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      await _disconnectSafe();
                      await _showInlineError(ctx, 'Error: $e');
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _showInlineError(BuildContext ctx, String msg) async {
    if (!ctx.mounted) return;
    await showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Bluetooth'),
        content: Text('❌ $msg'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(printerListProvider);
    final selectedId = ref.watch(selectedPrinterIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Printer'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Bluetooth'),
            Tab(text: 'WiFi'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text(
                  'Saved printers',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (list.isEmpty)
                  const Text('No printers saved yet.')
                else
                  ...list.map((p) {
                    final subtitle = (p.type == PrinterConnType.wifi)
                        ? 'WiFi: ${p.ip}:${p.port}'
                        : 'BT: ${p.btAddress}';
                    return Card(
                      child: ListTile(
                        title: Text(p.name),
                        subtitle: Text(subtitle),
                        leading: Radio<String>(
                          value: p.id,
                          groupValue: selectedId,
                          onChanged: (v) {
                            ref.read(selectedPrinterIdProvider.notifier).state =
                                v;
                            _savePrintersToStorage();
                          },
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.link),
                              onPressed: () => testConnection(p),
                            ),
                            IconButton(
                              icon:
                              const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removePrinter(p.id),
                            ),
                          ],
                        ),
                        onTap: () {
                          ref.read(selectedPrinterIdProvider.notifier).state =
                              p.id;
                          _savePrintersToStorage();
                        },
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Add / Update printer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 360,
                  child: TabBarView(
                    controller: _tab,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildBluetoothForm(),
                      _buildWifiForm(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiForm() {
    return Column(
      children: [
        TextField(
          controller: _wifiName,
          decoration: const InputDecoration(labelText: 'Printer name'),
        ),
        TextField(
          controller: _wifiIp,
          decoration: const InputDecoration(labelText: 'IP'),
        ),
        TextField(
          controller: _wifiPort,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Port (9100)'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final name = _wifiName.text.trim();
                  final ip = _wifiIp.text.trim();
                  final port = int.tryParse(_wifiPort.text.trim()) ?? 9100;

                  if (name.isEmpty || ip.isEmpty) return;

                  final p = PrinterConnConfig(
                    id: 'wifi_${ip}_$port',
                    type: PrinterConnType.wifi,
                    name: name,
                    ip: ip,
                    port: port,
                  );
                  _addPrinter(p);
                },
                child: const Text('Save WiFi'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBluetoothForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openBluetoothPickerDialog,
                icon: const Icon(Icons.search),
                label: const Text('Buscar BT (paired)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _btName,
          decoration: const InputDecoration(labelText: 'Printer name'),
        ),
        TextField(
          controller: _btAddress,
          decoration: const InputDecoration(labelText: 'BT address (MAC)'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final name = _btName.text.trim();
                  final addr = _btAddress.text.trim();
                  if (name.isEmpty || addr.isEmpty) return;

                  final p = PrinterConnConfig(
                    id: 'bt_$addr',
                    type: PrinterConnType.bluetooth,
                    name: name,
                    btAddress: addr,
                  );
                  _addPrinter(p);
                },
                child: const Text('Save Bluetooth'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
