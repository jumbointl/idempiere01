// ===============================
// printer_select_page.dart
// ===============================
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:pos_universal_printer/pos_universal_printer.dart';

import '../../products/common/bluetooth_permission.dart';
import '../../products/presentation/providers/common_provider.dart';
import '../../products/presentation/providers/product_provider_common.dart';
import '../../shared/data/memory.dart';
import '../models/printer_select_models.dart';
import '../niimbot/niimbot_printer_helper.dart';
import '../printer_scan_notifier.dart';

final printerListProvider = StateProvider<List<PrinterConnConfig>>((ref) => []);
final selectedPrinterIdProvider = StateProvider<String?>((ref) => null);
final printerConnectedProvider = StateProvider<bool>((ref) => false);
enum ScanAction { scan, stop }
class PrinterSelectPage extends ConsumerStatefulWidget {
  final dynamic dataToPrint;
  /// Optional: if you want to auto-close returning printer after selection
  final bool popOnSelect;

  const PrinterSelectPage({
    super.key,
    required this.dataToPrint,
    this.popOnSelect = true,
  });

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

  // New fields
  final _wifiLang = TextEditingController(text: PrinterState.PRINTER_TYPE_TSPL);
  final _btLang = TextEditingController(text: PrinterState.PRINTER_TYPE_TSPL);
  final _btType = TextEditingController(text: PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE);

  final box = GetStorage();

  // pos_universal_printer
  final PosUniversalPrinter _pos = PosUniversalPrinter.instance;

  // --- SCAN TAB STATE ---
  StreamSubscription<PrinterDevice>? _btScanSub;
  final List<PrinterDevice> _btScanDevices = <PrinterDevice>[];
  bool _isScanning = false;
  Timer? _scanTimer;

  int _scanTimeoutSec = 12; // default 12, max 60

  // Optional: remember last used lang/type in scan tab
  String _scanLang = 'TSPL'; // TSPL/ZPL/NIIMBOT
  String _scanBtType = PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE; // BLE/NO_BLE

  @override
  void initState() {
    super.initState();
    // 3 tabs now: Bluetooth, WiFi, Scan
    _tab = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrinters();
      if(widget.popOnSelect){
        ref.read(printerInputModeProvider.notifier).state = PrinterInputMode.manual;
      }
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

    _wifiLang.dispose();
    _btLang.dispose();
    _btType.dispose();

    _stopScanSilence();

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

  void _addOrUpdatePrinter(PrinterConnConfig p) {
    debugPrint('addOrUpdatePrinter: $p');
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

  void _fillFormForEdit(PrinterConnConfig p) {
    if (p.type == PrinterConnType.wifi) {
      _tab.index = 1;
      _wifiName.text = p.name;
      _wifiIp.text = p.ip ?? '';
      _wifiPort.text = '${p.port ?? 9100}';
      _wifiLang.text = (p.lang ?? PrinterState.PRINTER_TYPE_TPL).toUpperCase();
    } else {
      _tab.index = 0;
      _btName.text = p.name;
      _btAddress.text = p.btAddress ?? '';
      _btLang.text = (p.lang ?? PrinterState.PRINTER_TYPE_TPL).toUpperCase();
      _btType.text =
          (p.typeText ?? PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE).toUpperCase();
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

  // ------------------------------------------------------------
  // Selection + return (disconnect and return printer)
  // ------------------------------------------------------------
  Future<void> _selectAndReturnPrinter(PrinterConnConfig p) async {
    ref.read(selectedPrinterIdProvider.notifier).state = p.id;
    _savePrintersToStorage();

    if (!mounted) return;
    if (widget.popOnSelect) {
      Navigator.pop(context, p);
    }
  }

  Future<void> _testSelectReturn(PrinterConnConfig p) async {
    // Test connection (it already disconnects internally for pos_universal_printer).
    final ok = await testConnectionPrinter(context, p);
    ref.read(printerConnectedProvider.notifier).state = ok;

    if (!ok) return;

    // Select + return printer (and ensure no lingering connection)
    try {
      await _pos.unregisterDevice(PosPrinterRole.sticker);
    } catch (_) {}

    await _selectAndReturnPrinter(p);
  }

  // ------------------------------------------------------------
  // SCAN TAB: start/stop scan, adjustable timeout (12..60)
  // ------------------------------------------------------------
  Future<bool> _ensureBtPermissions() async {
    final ok = await ensureBluetoothPermissions();
    if (!ok) {
      if (!mounted) return false;
      showErrorMessage(context, ref, 'Permisos requeridos');
      return false;
    }
    return true;
  }

  Future<void> _stopScanSilence() async {
    _scanTimer?.cancel();
    _scanTimer = null;

    try {
      await _btScanSub?.cancel();
    } catch (_) {}
    _btScanSub = null;

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    } else {
      _isScanning = false;
    }
  }

  Future<void> _startScan() async {
    final ok = await _ensureBtPermissions();
    if (!ok) return;

    await _stopScanSilence();

    if (!mounted) return;
    setState(() {
      _btScanDevices.clear();
      _isScanning = true;
    });

    // Auto-stop after timeout
    _scanTimer = Timer(Duration(seconds: _scanTimeoutSec), () async {
      await _stopScanSilence();
    });

    try {
      _btScanSub = _pos.scanBluetooth().listen((device) {
        final addr = (device.address)?.trim() ?? '';
        if (addr.isEmpty) return;

        final exists = _btScanDevices.any((d) => (d.address?.trim() ?? '') == addr);
        if (!exists) {
          if (mounted) {
            setState(() => _btScanDevices.add(device));
          } else {
            _btScanDevices.add(device);
          }
        }
      }, onDone: () async {
        await _stopScanSilence();
      }, onError: (_) async {
        await _stopScanSilence();
      });
    } catch (e) {
      await _stopScanSilence();
      await _showMsg('Bluetooth', '❌ Error al iniciar scan: $e');
    }
  }
  Future<void> _selectFromScanAndReturn(PrinterDevice d) async {
    final name = (d.name.trim().isEmpty) ? 'BT Printer' : d.name.trim();
    final mac = d.address?.trim() ?? '';

    if (mac.isEmpty) {
      await _showMsg('Bluetooth', '❌ Dirección inválida');
      return;
    }

    // Solo construir objeto, SIN conectar
    final cfg = PrinterConnConfig(
      btAddress: mac,
      id: 'bt_$mac',
      type: PrinterConnType.bluetooth,
      name: name,
      lang: _scanLang.toUpperCase(),   // si lo estás usando
      typeText: _scanBtType.toUpperCase(),
    );

    // Retornar directamente
    if (!mounted) return;
    Navigator.pop(context, cfg);
  }




  // ------------------------------------------------------------
  // Old dialog picker (paired devices) - keep it for manual tab
  // ------------------------------------------------------------
  Future<void> _openBluetoothPickerDialog() async {
    if (!mounted) return;

    final ok = await _ensureBtPermissions();
    if (!ok) return;

    // Clean previous scan if any
    await _btScanSub?.cancel();
    _btScanSub = null;
    _btScanDevices.clear();

    bool scanning = true;

    // Start scan
    try {
      _btScanSub = _pos.scanBluetooth().listen((device) {
        // Deduplicate by address
        final addr = (device.address)?.trim() ?? '';
        if (addr.isEmpty) return;

        final exists = _btScanDevices.any((d) => (d.address?.trim() ?? '') == addr);
        if (!exists) {
          _btScanDevices.add(device);
        }
      }, onDone: () {
        scanning = false;
      }, onError: (_) {
        scanning = false;
      });
    } catch (e) {
      await _showMsg('Bluetooth', '❌ Error al iniciar scan: $e');
      return;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future.microtask(() {
              if (ctx.mounted) setState(() {});
            });

            Future<void> stopScan() async {
              try {
                await _btScanSub?.cancel();
              } catch (_) {}
              _btScanSub = null;
              scanning = false;
              if (ctx.mounted) setState(() {});
            }

            Future<void> rescan() async {
              await stopScan();
              _btScanDevices.clear();
              scanning = true;

              try {
                _btScanSub = _pos.scanBluetooth().listen((device) {
                  final addr = device.address?.trim() ?? '';
                  if (addr.isEmpty) return;

                  final exists = _btScanDevices.any((d) => (d.address?.trim() ?? '') == addr);
                  if (!exists) {
                    _btScanDevices.add(device);
                    if (ctx.mounted) setState(() {});
                  }
                }, onDone: () {
                  scanning = false;
                  if (ctx.mounted) setState(() {});
                }, onError: (_) {
                  scanning = false;
                  if (ctx.mounted) setState(() {});
                });
              } catch (_) {
                scanning = false;
              }

              if (ctx.mounted) setState(() {});
            }

            Future<void> connectAndFill(PrinterDevice d) async {
              await stopScan();

              try {
                await _pos.registerDevice(PosPrinterRole.sticker, d);

                final connected = _pos.isRoleConnected(PosPrinterRole.sticker);
                if (!connected) {
                  if (!ctx.mounted) return;
                  await _showMsg('Bluetooth', '❌ No se pudo conectar a ${d.address}');
                  return;
                }

                if (mounted) {
                  _btName.text = (d.name.trim().isEmpty) ? 'BT Printer' : d.name.trim();
                  _btAddress.text = d.address?.trim() ?? '';

                  final lang = _btLang.text.trim().toUpperCase();
                  if (lang != 'TSPL' && lang != 'ZPL' && lang != 'NIIMBOT') _btLang.text = 'TSPL';

                  final btType = _btType.text.trim().toUpperCase();
                  if (btType != PrinterState.PRINTER_TYPE_BLUETOOTH_BLE &&
                      btType != PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE) {
                    _btType.text = PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE;
                  }
                }

                final p = PrinterConnConfig(
                  id: 'bt_${d.address?.trim() ?? ''}',
                  type: PrinterConnType.bluetooth,
                  name: _btName.text.trim().isEmpty ? 'BT Printer' : _btName.text.trim(),
                  btAddress: d.address?.trim() ?? '',
                  lang: _btLang.text.trim().toUpperCase(),
                  typeText: _btType.text.trim().toUpperCase(),
                );
                _addOrUpdatePrinter(p);

                // Disconnect (safe)
                try {
                  await Future.delayed(const Duration(milliseconds: 150));
                  await _pos.unregisterDevice(PosPrinterRole.sticker);
                } catch (_) {}

                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (!ctx.mounted) return;
                await _showMsg('Bluetooth', '❌ Error conectando: $e');
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  const Expanded(child: Text('Bluetooth devices (scan)')),
                  if (scanning)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: _btScanDevices.isEmpty
                    ? Text(scanning ? 'Buscando dispositivos...' : 'No se encontraron dispositivos.')
                    : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _btScanDevices.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = _btScanDevices[i];
                    final name = d.name.trim().isEmpty ? 'Unknown' : d.name.trim();
                    final mac = d.address?.trim() ?? '';

                    return ListTile(
                      title: Text(name),
                      subtitle: Text(mac),
                      leading: const Icon(Icons.print),
                      onTap: () => connectAndFill(d),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await stopScan();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: scanning ? null : () => rescan(),
                  child: const Text('Rescan'),
                ),
                TextButton(
                  onPressed: scanning ? () => stopScan() : null,
                  child: const Text('Stop'),
                ),
              ],
            );
          },
        );
      },
    );

    try {
      await _btScanSub?.cancel();
    } catch (_) {}
    _btScanSub = null;
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    late final PrinterInputMode inputMode;
    inputMode = ref.watch(printerInputModeProvider);



    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Select Printer'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Bluetooth'),
            Tab(text: 'WiFi'),
            Tab(text: 'Scan'),
          ],
        ),

      ),
      bottomNavigationBar: !widget.popOnSelect ? BottomAppBar(
          height: 75,
          //child: buttonConfirm(context, ref)
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Add / Update printer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  SegmentedButton<PrinterInputMode>(
                    segments: const [
                      ButtonSegment(
                        value: PrinterInputMode.scan,
                        label: Text('SCAN',style: TextStyle(fontSize: 12),),
                        icon: Icon(Icons.qr_code_scanner, size: 12),
                      ),
                      ButtonSegment(
                        value: PrinterInputMode.manual,
                        label: Text('MANUAL',style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.edit, size: 12),
                      ),
                    ],
                    selected: {inputMode},
                    onSelectionChanged: (set) {
                      final mode = set.first;

                      ref.read(printerInputModeProvider.notifier).state = mode;

                      ref.read(actionScanProvider.notifier).state =
                      mode == PrinterInputMode.scan
                          ? Memory.ACTION_FIND_PRINTER_BY_QR_WIFI_BLUETOOTH
                          : Memory.ACTION_NO_SCAN_ACTION;
                    },
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                ],
              ),
              const Text(
                'switch scan/manual to disable/enable input',
                style: TextStyle(fontSize: themeFontSizeSmall),
              ),
            ],
          )
      ):null,
      body: SafeArea(
        child: TabBarView(
          controller: _tab,
          children: [
            _buildBluetoothTab(),
            _buildWifiTab(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _buildScanTab(),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildBluetoothTab() {
    final list = ref.watch(printerListProvider);
    final selectedId = ref.watch(selectedPrinterIdProvider);
    final inputMode = ref.watch(printerInputModeProvider);
    final bool enableInputs = inputMode == PrinterInputMode.manual;

    return ListView(
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
            if (p.type != PrinterConnType.bluetooth) {
              return const SizedBox.shrink();
            }

            final subtitle =
                'BT: ${p.btAddress}  lang:${p.lang ?? "-"}  type:${p.typeText ?? "-"}';

            return Card(
              child: ListTile(
                title: Text(p.name),
                subtitle: Text(subtitle),
                leading: Radio<String>(
                  value: p.id,
                  groupValue: selectedId,
                  onChanged: (v) async {
                    ref.read(selectedPrinterIdProvider.notifier).state = v;
                    _savePrintersToStorage();
                    await _selectAndReturnPrinter(p);
                  },
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    _actionIcon(Icons.link, () => _testSelectReturn(p)),
                    _actionIcon(Icons.edit, () => _fillFormForEdit(p)),
                    _actionIcon(Icons.delete, () => _removePrinter(p.id),
                        color: Colors.red),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),

        _buildBluetoothForm(enableInputs),
      ],
    );
  }
  Widget _buildWifiTab() {
    final list = ref.watch(printerListProvider);
    final selectedId = ref.watch(selectedPrinterIdProvider);
    final inputMode = ref.watch(printerInputModeProvider);
    final bool enableInputs = inputMode == PrinterInputMode.manual;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [

        const Text(
          'Saved WiFi printers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        if (list.isEmpty)
          const Text('No printers saved yet.')
        else
          ...list.map((p) {
            if (p.type != PrinterConnType.wifi) {
              return const SizedBox.shrink();
            }

            final subtitle =
                'WiFi: ${p.ip}:${p.port}  lang:${p.lang ?? "-"}';

            return Card(
              child: ListTile(
                title: Text(p.name),
                subtitle: Text(subtitle),
                leading: Radio<String>(
                  value: p.id,
                  groupValue: selectedId,
                  onChanged: (v) async {
                    ref.read(selectedPrinterIdProvider.notifier).state = v;
                    _savePrintersToStorage();
                    await _selectAndReturnPrinter(p);
                  },
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    _actionIcon(Icons.link, () => _testSelectReturn(p)),
                    _actionIcon(Icons.edit, () => _fillFormForEdit(p)),
                    _actionIcon(Icons.delete, () => _removePrinter(p.id),
                        color: Colors.red),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),

        _buildWifiForm(enableInputs),
      ],
    );
  }


  Widget _tf({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      readOnly: !enabled, // allow copy
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: !enabled,
        fillColor: !enabled ? Colors.grey.withOpacity(0.08) : null,
      ),
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback onTap, {Color? color}) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: Icon(icon, color: color),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildWifiForm(bool enableInputs) {
    return Column(
      children: [
        _tf(controller: _wifiName, label: 'Printer name', enabled: enableInputs),
        _tf(controller: _wifiIp, label: 'IP', enabled: enableInputs),
        Row(
          children: [
            Expanded(
              child: _tf(
                controller: _wifiPort,
                label: 'Port (9100)',
                enabled: enableInputs,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _tf(
                controller: _wifiLang,
                label: 'Language (TSPL/ZPL/NIIMBOT)',
                enabled: enableInputs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: enableInputs
                    ? () async {
                  final String name = _wifiName.text.trim();
                  final String ip = _wifiIp.text.trim();
                  final int port = int.tryParse(_wifiPort.text.trim()) ?? 9100;

                  String lang = _wifiLang.text.trim().toUpperCase();
                  if (lang == 'TPL') {
                    lang = 'TSPL';
                  }

                  if (name.isEmpty) {
                    await _showMsg('WiFi', 'Ingrese el nombre de la impresora.');
                    return;
                  }

                  if (ip.isEmpty) {
                    await _showMsg('WiFi', 'Ingrese la IP de la impresora.');
                    return;
                  }

                  if (lang != 'TSPL' && lang != 'ZPL' && lang != 'NIIMBOT' && lang != 'TPL') {
                    await _showMsg('WiFi', 'Language inválido. Use TSPL, ZPL o NIIMBOT.');
                    return;
                  }

                  final p = PrinterConnConfig(
                    id: 'wifi_${ip}_$port',
                    type: PrinterConnType.wifi,
                    name: name,
                    ip: ip,
                    port: port,
                    lang: lang,
                    typeText: lang,
                  );

                  _addOrUpdatePrinter(p);
                  await _showMsg('WiFi', '✅ Impresora guardada.');
                }
                    : null,
                child: const Text('Save WiFi'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBluetoothForm(bool enableInputs) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openBluetoothPickerDialog, // allowed in SCAN
                icon: const Icon(Icons.search),
                label: const Text('Buscar BT (paired)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _tf(controller: _btName, label: 'Printer name', enabled: enableInputs),
        _tf(controller: _btAddress, label: 'BT address (MAC)', enabled: enableInputs),
        Row(
          children: [
            Expanded(
              child: _tf(
                controller: _btLang,
                label: 'Language (TSPL/ZPL/NIIMBOT)',
                enabled: enableInputs,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _tf(
                controller: _btType,
                label: 'Bluetooth type (BLE / NO_BLE)',
                enabled: enableInputs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: enableInputs
                    ? () {
                  final name = _btName.text.trim();
                  final address = _btAddress.text.trim();
                  final lang = _btLang.text.trim().toUpperCase();
                  final btType = _btType.text.trim().toUpperCase();

                  if (name.isEmpty || address.isEmpty) return;
                  if (lang != 'TSPL' && lang != 'ZPL' && lang != 'NIIMBOT') return;

                  if (btType != PrinterState.PRINTER_TYPE_BLUETOOTH_BLE &&
                      btType != PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE) {
                    return;
                  }

                  final p = PrinterConnConfig(
                    id: 'bt_$address',
                    type: PrinterConnType.bluetooth,
                    name: name,
                    btAddress: address,
                    lang: lang,
                    typeText: btType,
                  );
                  _addOrUpdatePrinter(p);
                }
                    : null,
                child: const Text('Save Bluetooth'),
              ),
            ),
          ],
        ),
      ],
    );
  }
  final ScanAction _currentBluetoothScanAction = ScanAction.scan;
  // ------------------------------------------------------------
  // NEW: Scan Tab UI
  // ------------------------------------------------------------
  Widget _buildScanTab() {
    final timeoutItems = List.generate(49, (i) => 12 + i); // 12..60

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.radar),
            const SizedBox(width: 8),
            Expanded( child: _isScanning ? LinearProgressIndicator()
                : Text(
                'Scan Bluetooth devices (Classic)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

          ],
        ),

        // Timeout spinner
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 120, child: Text('Timeout (sec):')),
            DropdownButton<int>(
              value: _scanTimeoutSec,
              items: timeoutItems
                  .map((v) => DropdownMenuItem<int>(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _scanTimeoutSec = v.clamp(12, 60));
              },
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _isScanning ? _stopScanSilence : _startScan,
              icon: Icon(_isScanning ? Icons.stop : Icons.search),
              label: Text(_isScanning ? 'Stop' : 'Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScanning ? Colors.red : themeColorPrimary,
                foregroundColor: Colors.white,
              ),
            )

          ],
        ),
        const SizedBox(height: 10),

        // Lang + Type
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _scanLang,
                decoration: const InputDecoration(labelText: 'Language'),
                items: const [
                  DropdownMenuItem(value: 'TSPL', child: Text('TSPL')),
                  DropdownMenuItem(value: 'ZPL', child: Text('ZPL')),
                  DropdownMenuItem(value: 'NIIMBOT', child: Text('NIIMBOT')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _scanLang = v);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _scanBtType,
                decoration: const InputDecoration(labelText: 'Bluetooth type'),
                items: const [
                  DropdownMenuItem(
                    value: PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE,
                    child: Text('NO_BLE'),
                  ),
                  DropdownMenuItem(
                    value: PrinterState.PRINTER_TYPE_BLUETOOTH_BLE,
                    child: Text('BLE'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _scanBtType = v);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),
        const Divider(),

        Expanded(
          child: _btScanDevices.isEmpty
              ? Text(_isScanning ? 'Buscando dispositivos...' : 'Sin resultados.')
              : ListView.separated(
            itemCount: _btScanDevices.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = _btScanDevices[i];
              final name = d.name.trim().isEmpty ? 'Unknown' : d.name.trim();
              final mac = d.address?.trim() ?? '';

              return ListTile(
                leading: const Icon(Icons.print),
                title: Text(name),
                subtitle: Text(mac),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  // Tap -> connect, save/select, disconnect, return
                  await _selectFromScanAndReturn(d);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Test connection helpers
// ============================================================

Future<bool> testConnectionPrinter(
    BuildContext context,
    PrinterConnConfig p, {
      PosUniversalPrinter? pos,
    }) async {
  Future<void> showMsg(String title, String msg) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // NIIMBOT
  if ((p.lang ?? '').toUpperCase() == 'NIIMBOT') {
    debugPrint('testConnectionPrinter: NIIMBOT');
    final mac = (p.btAddress ?? '').trim();
    final helper = NiimbotPrinterHelper();
    final ok = await helper.testConnectionNiimbot(
      context: context,
      mac: mac,
    );
    debugPrint('testConnectionPrinter finish: NIIMBOT');
    await showMsg('Connection', ok ? '✅ Niimbot OK: $mac' : '❌ Niimbot ERROR: $mac');
    return ok;
  }

  try {
    if (p.type == PrinterConnType.wifi) {
      final ip = (p.ip ?? '').trim();
      final port = p.port ?? 9100;

      if (ip.isEmpty) {
        await showMsg('Connection', '❌ IP vacío');
        return false;
      }

      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 4),
      );
      socket.destroy();

      await showMsg('Connection', '✅ WiFi OK: $ip:$port');
      return true;
    }

    // Bluetooth (pos_universal_printer)
    final mac = (p.btAddress ?? '').trim();
    if (mac.isEmpty) {
      await showMsg('Connection', '❌ BT address vacío');
      return false;
    }

    final posInst = pos ?? PosUniversalPrinter.instance;

    // Build device
    final device = PrinterDevice(
      name: p.name.isEmpty ? 'BT Printer' : p.name,
      address: mac,
      id: p.id,
      type: PrinterType.bluetooth,
    );

    // Ensure disconnected first
    try {
      await posInst.unregisterDevice(PosPrinterRole.sticker);
    } catch (_) {}

    await posInst.registerDevice(PosPrinterRole.sticker, device);

    final connected = posInst.isRoleConnected(PosPrinterRole.sticker);
    if (!connected) {
      await showMsg('Connection', '❌ Bluetooth ERROR: $mac');
      return false;
    }

    await Future.delayed(const Duration(milliseconds: 200));
    try {
      await posInst.unregisterDevice(PosPrinterRole.sticker);
    } catch (_) {}

    await showMsg('Connection', '✅ Bluetooth OK: $mac');
    return true;
  } catch (e) {
    await showMsg('Connection', '❌ Error: $e');
    try {
      final posInst = pos ?? PosUniversalPrinter.instance;
      await posInst.unregisterDevice(PosPrinterRole.sticker);
    } catch (_) {}
    return false;
  }
}

Future<bool> testConnectionPrinterSilence(
    BuildContext context,
    PrinterConnConfig p, {
      PosUniversalPrinter? pos,
    }) async {
  try {
    if (p.type == PrinterConnType.wifi) {
      final ip = (p.ip ?? '').trim();
      final port = p.port ?? 9100;

      if (ip.isEmpty) {
        return false;
      }

      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 4),
      );
      socket.destroy();
      return true;
    }

    // Bluetooth (pos_universal_printer)
    final mac = (p.btAddress ?? '').trim();
    if (mac.isEmpty) {
      return false;
    }

    final posInst = pos ?? PosUniversalPrinter.instance;

    final device = PrinterDevice(
      name: p.name.isEmpty ? 'BT Printer' : p.name,
      address: mac,
      id: p.id,
      type: PrinterType.bluetooth,
    );

    try {
      await posInst.unregisterDevice(PosPrinterRole.sticker);
    } catch (_) {}

    await posInst.registerDevice(PosPrinterRole.sticker, device);

    final connected = posInst.isRoleConnected(PosPrinterRole.sticker);
    if (!connected) {
      return false;
    }

    // Disconnect after test
    try {
      await Future.delayed(const Duration(milliseconds: 120));
      await posInst.unregisterDevice(PosPrinterRole.sticker);
    } catch (_) {}

    return true;
  } catch (_) {
    try {
      final posInst = pos ?? PosUniversalPrinter.instance;
      await posInst.unregisterDevice(PosPrinterRole.sticker);
    } catch (_) {}
    return false;
  }
}
