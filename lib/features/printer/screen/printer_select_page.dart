// ===============================
// printer_select_page.dart
// ===============================
import 'dart:async';
import 'dart:convert';

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
import '../printer_scan_notifier.dart';

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

  // New fields
  final _wifiLang = TextEditingController(text: PrinterState.PRINTER_TYPE_TPL);
  final _btLang = TextEditingController(text: PrinterState.PRINTER_TYPE_TPL);
  final _btType = TextEditingController(text: PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE);

  final box = GetStorage();
  StreamSubscription<PrinterDevice>? _btScanSub;
  final List<PrinterDevice> _btScanDevices = <PrinterDevice>[];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);

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

    _wifiLang.dispose();
    _btLang.dispose();
    _btType.dispose();

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



  final PosUniversalPrinter _pos = PosUniversalPrinter.instance;

  Future<bool> _testBluetoothTsplConnection(String mac) async {
    const String tsplTest =
        'SIZE 40 mm,25 mm\r\n'
        'GAP 2 mm,0 mm\r\n'
        'CLS\r\n'
        'TEXT 20,20,"2",0,1,1,"TEST"\r\n'
        'PRINT 1,1\r\n';

    const int maxAttempts = 3;
    const Duration backoffBase = Duration(milliseconds: 250);

    bool isValidMac(String s) {
      final t = s.trim().toUpperCase();
      final macRegex = RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$');
      return macRegex.hasMatch(t);
    }

    final macTrim = mac.trim();
    if (macTrim.isEmpty || !isValidMac(macTrim)) {
      debugPrint('POS BT test: invalid MAC: "$mac"');
      return false;
    }

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        // Create device (adjust fields if your plugin differs)
        final device = PrinterDevice(
          id: macTrim,
          name: 'BT Printer $macTrim',
          address: macTrim,
          type: PrinterType.bluetooth,
        );

        await _pos.registerDevice(PosPrinterRole.sticker, device);

        final connected = _pos.isRoleConnected(PosPrinterRole.sticker);
        if (!connected) {
          debugPrint('POS BT test: not connected (attempt $attempt/$maxAttempts)');
          await Future.delayed(backoffBase + Duration(milliseconds: attempt * 150));
          continue;
        }

        final bytes = latin1.encode(tsplTest);
        _pos.printRaw(PosPrinterRole.sticker, bytes);

        await Future.delayed(const Duration(milliseconds: 200));
        debugPrint('POS BT test: OK (attempt $attempt/$maxAttempts)');
        return true;
      } catch (e) {
        debugPrint('POS BT test: exception (attempt $attempt/$maxAttempts): $e');
        await Future.delayed(backoffBase + Duration(milliseconds: attempt * 200));
      }
    }

    return false;
  }





  /*Future<bool> _testBluetoothTsplConnection(String mac) async {
    const String tsplTest = 'CLS\n';

    try {
      final already = await PrintBluetoothThermal.connectionStatus;
      if (already) {
        await _disconnectSafe();
      }

      final connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if (!connected) return false;

      await Future.delayed(const Duration(milliseconds: 150));
      final ok = await PrintBluetoothThermal.writeBytes(utf8.encode(tsplTest).toList());

      await Future.delayed(const Duration(milliseconds: 120));
      await _disconnectSafe();

      return ok;
    } catch (_) {
      await _disconnectSafe();
      return false;
    }
  }*/

  Future<void> testConnection(PrinterConnConfig p) async {
    try {
      if (p.type == PrinterConnType.wifi) {
        // ... igual que ya lo tenés
      } else {
        final mac = (p.btAddress ?? '').trim();
        if (mac.isEmpty) {
          showErrorMessage(context, ref, '❌ BT address vacío');
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

  void _saveBtFromValues({
    required String name,
    required String mac,
  }) {
    final lang = _btLang.text.trim().toUpperCase();
    final btType = _btType.text.trim().toUpperCase();

    // Defaults seguros si estás en SCAN y inputs están bloqueados
    final safeLang = (lang == 'TSPL' || lang == 'ZPL') ? lang : 'TSPL';
    final safeType = (btType == PrinterState.PRINTER_TYPE_BLUETOOTH_BLE ||
        btType == PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE)
        ? btType
        : PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE;

    final p = PrinterConnConfig(
      id: 'bt_$mac',
      type: PrinterConnType.bluetooth,
      name: name.isEmpty ? 'BT Printer' : name,
      btAddress: mac,
      lang: safeLang,
      typeText: safeType,
    );

    _addOrUpdatePrinter(p);
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

  // BT picker (paired devices) -> fill form
  Future<void> _openBluetoothPickerDialog() async {
    if (!mounted) return;

    final ok = await ensureBluetoothPermissions();
    if (!ok) {
      showErrorMessage(context, ref, 'Permisos requeridos');
      return;
    }

    // Clean previous scan if any
    await _btScanSub?.cancel();
    _btScanSub = null;
    _btScanDevices.clear();

    bool scanning = true;

    // Start scan
    try {
      _btScanSub = _pos.scanBluetooth().listen((device) {
        // Deduplicate by address
        final addr = (device.address)?.trim() ??'';
        if (addr.isEmpty) return;

        final exists = _btScanDevices.any((d) => (d.address?.trim()??'') == addr);
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
            // Small timer to refresh UI while scanning
            // (no heavy stuff; just redraw)
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
                  final addr = device.address?.trim() ??'';
                  if (addr.isEmpty) return;

                  final exists = _btScanDevices.any((d) => (d.address?.trim() ?? '')== addr);
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
              // Stop scan to avoid radio conflicts on some devices
              await stopScan();

              try {
                await _pos.registerDevice(PosPrinterRole.sticker, d);

                final connected = _pos.isRoleConnected(PosPrinterRole.sticker);
                if (!connected) {
                  if (!ctx.mounted) return;
                  await _showMsg('Bluetooth', '❌ No se pudo conectar a ${d.address}');
                  return;
                }

                // Fill form (even if inputs disabled, we can set text)
                if (mounted) {
                  _btName.text = (d.name.trim().isEmpty) ? 'BT Printer' : d.name.trim();
                  _btAddress.text = d.address?.trim() ??'';

                  // Defaults seguros (si estabas en SCAN y no podías editar)
                  final lang = _btLang.text.trim().toUpperCase();
                  if (lang != 'TSPL' && lang != 'ZPL') _btLang.text = 'TSPL';

                  final btType = _btType.text.trim().toUpperCase();
                  if (btType != PrinterState.PRINTER_TYPE_BLUETOOTH_BLE &&
                      btType != PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE) {
                    _btType.text = PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE;
                  }
                }

                // Save immediately (recommended, because SCAN disables manual inputs)
                final p = PrinterConnConfig(
                  id: 'bt_${d.address?.trim() ?? ''}',
                  type: PrinterConnType.bluetooth,
                  name: _btName.text.trim().isEmpty ? 'BT Printer' : _btName.text.trim(),
                  btAddress: d.address?.trim() ?? '',
                  lang: _btLang.text.trim().toUpperCase(),
                  typeText: _btType.text.trim().toUpperCase(),
                );
                _addOrUpdatePrinter(p);

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
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: _btScanDevices.isEmpty
                    ? Text(scanning
                    ? 'Buscando dispositivos...'
                    : 'No se encontraron dispositivos.')
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

    // Safety: stop scan when dialog closed
    try {
      await _btScanSub?.cancel();
    } catch (_) {}
    _btScanSub = null;
  }


  @override
  Widget build(BuildContext context) {
    final list = ref.watch(printerListProvider);
    final selectedId = ref.watch(selectedPrinterIdProvider);
    final inputMode = ref.watch(printerInputModeProvider);
    final bool enableInputs = inputMode == PrinterInputMode.manual;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Select Printer'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Bluetooth'),
            Tab(text: 'WiFi'),
          ],
        ),
      ),
      body: SafeArea(
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
                    ? 'WiFi: ${p.ip}:${p.port}  lang:${p.lang ?? "-"}'
                    : 'BT: ${p.btAddress}  lang:${p.lang ?? "-"}  type:${p.typeText ?? "-"}';
        
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Radio<String>(
                          value: p.id,
                          groupValue: selectedId,
                          onChanged: (v) {
                            ref.read(selectedPrinterIdProvider.notifier).state = v;
                            _savePrintersToStorage();
                          },
                        ),
        
                        const SizedBox(width: 8),
        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
        
                        const SizedBox(width: 8),
        
                        SizedBox(
                          width: 90,
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _actionIcon(Icons.link, () => testConnection(p)),
                              _actionIcon(Icons.edit, () => _fillFormForEdit(p)),
                              _actionIcon(Icons.delete, () => _removePrinter(p.id),
                                  color: Colors.red),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
        
        
              }),
        
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
        
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
                      label: Text('SCAN'),
                      icon: Icon(Icons.qr_code_scanner, size: 16),
                    ),
                    ButtonSegment(
                      value: PrinterInputMode.manual,
                      label: Text('MANUAL'),
                      icon: Icon(Icons.edit, size: 16),
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
              style: TextStyle(fontSize: themeFontSizeNormal),
            ),
            const SizedBox(height: 8),
        
            SizedBox(
              height: 360,
              child: TabBarView(
                controller: _tab,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBluetoothForm(enableInputs),
                  _buildWifiForm(enableInputs),
                ],
              ),
            ),
          ],
        ),
      ),
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
      readOnly: !enabled, // permite copiar
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: !enabled,
        fillColor: !enabled ? Colors.grey.withOpacity(0.08) : null,
      ),
    );
  }
  Widget _actionIcon(IconData icon, VoidCallback onTap,
      {Color? color}) {
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
                label: 'Language (TSPL/ZPL)',
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
                  final name = _wifiName.text.trim();
                  final ip = _wifiIp.text.trim();
                  final port = int.tryParse(_wifiPort.text.trim()) ?? 9100;
                  final lang = _wifiLang.text.trim().toUpperCase();

                  if (name.isEmpty || ip.isEmpty) return;
                  if (lang != 'TSPL' && lang != 'ZPL') return;

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
                onPressed: _openBluetoothPickerDialog, // esto sí puede quedar habilitado en SCAN
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
                label: 'Language (TSPL/ZPL)',
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
                  if (lang != 'TSPL' && lang != 'ZPL') return;

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

}
