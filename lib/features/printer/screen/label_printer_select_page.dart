// ===============================
// label_printer_select_page.dart
// ===============================
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action_fixed_short.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../products/domain/idempiere/idempiere_product.dart';
import '../../products/domain/models/label_profile.dart';
import '../../products/presentation/providers/common_provider.dart';
import '../../products/presentation/providers/product_provider_common.dart';
import '../../shared/data/memory.dart';
import '../models/printer_select_models.dart';
import '../printer_scan_notifier.dart';
import 'printer_select_page.dart';

// Profiles providers live here



class LabelPrinterSelectPage extends PrinterSelectPage {
  const LabelPrinterSelectPage({super.key, required super.dataToPrint});

  @override
  ConsumerState<PrinterSelectPage> createState() => _LabelPrinterSelectPageState();
}

class _LabelPrinterSelectPageState extends ConsumerState<PrinterSelectPage>
    with SingleTickerProviderStateMixin {
  final box = GetStorage();

  final int actionScanType = Memory.ACTION_FIND_PRINTER_BY_QR_WIFI_BLUETOOTH;
  late final int oldAction;

  late final TabController _tab; // Home / Profiles / Printers

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLabelProfiles();
      _loadPrintersForHome();
      oldAction = ref.read(actionScanProvider);
      ref.read(actionScanProvider.notifier).state = actionScanType;
      ref.read(printerInputModeProvider.notifier).state = PrinterInputMode.scan;
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // Profiles: load/save
  // ------------------------------------------------------------
  void _loadLabelProfiles() {
    final raw = box.read(PrinterSelectStorageKeys.labelProfilesList);
    final selectedId = box.read(PrinterSelectStorageKeys.selectedLabelProfileId);

    List<LabelProfile> list = [];
    if (raw is String && raw.trim().isNotEmpty) {
      list = (jsonDecode(raw) as List)
          .map((e) => LabelProfile.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (list.where((e) => e.id == 'default_40x25').isEmpty) {
      list.add(defaultLabel40x25());
    }
    if (list.where((e) => e.id == 'default_60x40').isEmpty) {
      list.add(defaultLabel60x40());
    }

    ref.read(labelProfilesProvider.notifier).state = list;

    if (selectedId is String && selectedId.trim().isNotEmpty) {
      ref.read(selectedLabelProfileIdProvider.notifier).state = selectedId;
    } else {
      ref.read(selectedLabelProfileIdProvider.notifier).state = list.first.id;
    }

    _saveLabelProfiles();
  }

  void _saveLabelProfiles() {
    final list = ref.read(labelProfilesProvider);
    box.write(
      PrinterSelectStorageKeys.labelProfilesList,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    box.write(
      PrinterSelectStorageKeys.selectedLabelProfileId,
      ref.read(selectedLabelProfileIdProvider),
    );
  }

  LabelProfile _selectedProfileOrDefault40() {
    final list = ref.read(labelProfilesProvider);
    final id = ref.read(selectedLabelProfileIdProvider);

    final p = list
        .where((e) => e.id == id)
        .cast<LabelProfile?>()
        .firstWhere((e) => e != null, orElse: () => null);

    return p ?? defaultLabel40x25();
  }

  LabelProfile _selectedProfileOrDefault60() {
    final list = ref.read(labelProfilesProvider);
    final id = ref.read(selectedLabelProfileIdProvider);

    final p = list
        .where((e) => e.id == id)
        .cast<LabelProfile?>()
        .firstWhere((e) => e != null, orElse: () => null);

    return p ?? defaultLabel60x40();
  }

  Future<void> _editOrCreateProfile({LabelProfile? initial}) async {
    var inputModeOld = ref.read(printerInputModeProvider);
    if (inputModeOld == PrinterInputMode.scan) {
      ref.read(printerInputModeProvider.notifier).state = PrinterInputMode.manual;
    }
    final profile = await showLabelConfigBottomSheet(context: context, initial: initial);
    if(inputModeOld!=ref.read(printerInputModeProvider)){
      ref.read(printerInputModeProvider.notifier).state = inputModeOld;
    }
    if (profile == null) return;

    final list = [...ref.read(labelProfilesProvider)];
    final idx = list.indexWhere((e) => e.id == profile.id);

    if (idx >= 0) {
      list[idx] = profile;
    } else {
      list.add(profile);
    }

    ref.read(labelProfilesProvider.notifier).state = list;
    ref.read(selectedLabelProfileIdProvider.notifier).state = profile.id;
    _saveLabelProfiles();
  }

  void _deleteProfile(LabelProfile p) {
    if (p.id.startsWith('default_')) return;

    final list = [...ref.read(labelProfilesProvider)];
    list.removeWhere((e) => e.id == p.id);
    ref.read(labelProfilesProvider.notifier).state = list;

    final selected = ref.read(selectedLabelProfileIdProvider);
    if (selected == p.id) {
      ref.read(selectedLabelProfileIdProvider.notifier).state =
      list.isNotEmpty ? list.first.id : null;
    }
    _saveLabelProfiles();
  }

  // ------------------------------------------------------------
  // Printers: save (so QR scan persists)
  // ------------------------------------------------------------
  void _savePrintersToStorageFromHere() {
    final list = ref.read(printerListProvider);
    box.write(
      PrinterSelectStorageKeys.printersList,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    final selected = ref.read(selectedPrinterIdProvider);
    box.write(PrinterSelectStorageKeys.selectedPrinterId, selected);
  }

  PrinterConnConfig? _selectedPrinter() {
    final list = ref.read(printerListProvider);
    final selectedId = ref.read(selectedPrinterIdProvider);
    if (selectedId == null) return null;
    return list
        .where((e) => e.id == selectedId)
        .cast<PrinterConnConfig?>()
        .firstWhere((e) => e != null, orElse: () => null);
  }

  // ------------------------------------------------------------
  // Printing helpers (WiFi/BT)
  // ------------------------------------------------------------
  Future<void> _disconnectSafe() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {}
  }

  Future<void> sendTsplViaWifi({
    required String ip,
    required int port,
    required String tspl,
  }) async {
    final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
    socket.add(Uint8List.fromList(tspl.codeUnits));
    await socket.flush();
    await socket.close();
  }

  Future<void> sendTsplViaBluetooth({
    required String btAddress,
    required String tspl,
  }) async {
    final mac = btAddress.trim();
    if (mac.isEmpty) throw Exception('BT address vacío');

    final already = await PrintBluetoothThermal.connectionStatus;
    if (already) {
      await _disconnectSafe();
      await Future.delayed(const Duration(milliseconds: 120));
    }

    final connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (!connected) {
      throw Exception('No se pudo conectar por Bluetooth: $mac');
    }

    await Future.delayed(const Duration(milliseconds: 150));
    final ok = await PrintBluetoothThermal.writeBytes(utf8.encode(tspl).toList());

    await Future.delayed(const Duration(milliseconds: 120));
    await _disconnectSafe();

    if (!ok) {
      throw Exception('Bluetooth writeBytes returned false');
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
          ),
        ],
      ),
    );
  }

  Future<void> _printLabel({required LabelProfile profile}) async {
    final printer = _selectedPrinter();
    if (printer == null) {
      await _showMsg('Printer', 'Select a printer first.');
      return;
    }

    final data = widget.dataToPrint;
    if (data is! IdempiereProduct) {
      await _showMsg('Data', 'dataToPrint must be IdempiereProduct.');
      return;
    }

    final upc = normalizeUpc(data.uPC ?? '');
    final sku = (data.sKU ?? 'sku').trim();
    final name = (data.name ?? 'name').trim();

    if (upc.isEmpty) {
      await _showMsg('UPC', 'Product has empty UPC.');
      return;
    }

    late final String tspl;
    if (profile.widthMm <= 50) {
      tspl = buildTsplProductLabelSmall(upc: upc, sku: sku, profile: profile);
    } else {
      tspl = buildTsplProductLabel(upc: upc, sku: sku, name: name, profile: profile);
    }

    try {
      if (printer.type == PrinterConnType.wifi) {
        await sendTsplViaWifi(ip: printer.ip!, port: printer.port ?? 9100, tspl: tspl);
        await _showMsg('Print', '✅ Printed via WiFi');
      } else {
        await sendTsplViaBluetooth(btAddress: printer.btAddress!, tspl: tspl);
        await _showMsg('Print', '✅ Printed via Bluetooth');
      }
    } catch (e) {
      await _showMsg('Print', '❌ Error: $e');
    }
  }

  String _buildAdjustmentLine(int maxCharsPerLine) {
    const base = '123456789|';
    if (maxCharsPerLine <= 0) return base;

    final sb = StringBuffer();
    while (sb.length < maxCharsPerLine) {
      sb.write(base);
      sb.write('123456789|');
    }
    final s = sb.toString();
    return s.length > maxCharsPerLine ? s.substring(0, maxCharsPerLine) : s;
  }

  Future<void> imprimirEtiquetaDeAjuste({required LabelProfile profile}) async {
    final printer = _selectedPrinter();
    if (printer == null) {
      await _showMsg('Printer', 'Select a printer first.');
      return;
    }

    const upc = '1234567890123';
    final line = _buildAdjustmentLine(profile.maxCharsPerLine);

    final String tspl;
    if (profile.widthMm <= 50) {
      tspl = buildTsplProductLabelSmall(upc: upc, sku: line, profile: profile);
    } else {
      tspl = buildTsplProductLabel(upc: upc, sku: line, name: line, profile: profile);
    }

    try {
      if (printer.type == PrinterConnType.wifi) {
        await sendTsplViaWifi(ip: printer.ip!, port: printer.port ?? 9100, tspl: tspl);
        await _showMsg('Print', '✅ Adjustment label printed via WiFi');
      } else {
        await sendTsplViaBluetooth(btAddress: printer.btAddress!, tspl: tspl);
        await _showMsg('Print', '✅ Adjustment label printed via Bluetooth');
      }
    } catch (e) {
      await _showMsg('Print', '❌ Error: $e');
    }
  }

  Future<void> _showPrintOptionsDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Print'),
        content: const Text('Choose what to print.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _printLabel(profile: _selectedProfileOrDefault40());
            },
            child: const Text('1) Imprimir etiqueta 40x25'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _printLabel(profile: _selectedProfileOrDefault60());
            },
            child: const Text('2) Imprimir etiqueta 60x40'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await imprimirEtiquetaDeAjuste(profile: _selectedProfileOrDefault40());
            },
            child: const Text('3) Imprimir etiqueta tique de ajuste'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // QR handler
  // BLUETOOTH*name*mac*TSPL*PRINTER_TYPE_BLUETOOTH_BLE
  // WiFi: ip:port:type:name:serverIp:serverPort
  // ------------------------------------------------------------
  void handleInputString({
    required int actionScan,
    required String inputData,
    required WidgetRef ref,
  }) async {
    final qrData = inputData.trim();
    if (qrData.isEmpty) return;
    if (actionScan != actionScanType) return;

    bool isValidLang(String s) {
      final t = s.trim().toUpperCase();
      return t == PrinterState.PRINTER_TYPE_TSPL || t == 'TPL';
    }

    String normalizeLang(String s) {
      final t = s.trim().toUpperCase();
      return t == 'TPL' ? PrinterState.PRINTER_TYPE_TSPL : t;
    }

    bool isValidBtType(String s) {
      final t = s.trim().toUpperCase();
      return t == PrinterState.PRINTER_TYPE_BLUETOOTH_BLE ||
          t == PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE;
    }

    // Bluetooth printer from scan disable

    if (qrData.toUpperCase().startsWith('BLUETOOTH*')) {
      await _showMsg('QR', 'not for Bluetooth printers.');
      return ;
      /*
      final parts = qrData.split('*');
      if (parts.length < 5) {
        await _showMsg('QR', 'Invalid Bluetooth QR format.');
        return;
      }

      final name = parts[1].trim();
      final mac = parts[2].trim();
      final langRaw = parts[3].trim().toUpperCase();
      final btTypeRaw = parts[4].trim().toUpperCase();

      if (!isValidLang(langRaw)) {
        await _showMsg('Printer', 'Tipo impresora invalido para configuración de impresora');
        return;
      }
      if (!isValidBtType(btTypeRaw)) {
        await _showMsg('Printer', 'Tipo Bluetooth inválido');
        return;
      }

      final lang = normalizeLang(langRaw);

      final newPrinter = PrinterConnConfig(
        id: 'bt_$mac',
        type: PrinterConnType.bluetooth,
        name: name.isEmpty ? 'Bluetooth Printer' : name,
        btAddress: mac,
        lang: lang,
        typeText: btTypeRaw,
      );

      final list = [...ref.read(printerListProvider)];
      final idx = list.indexWhere((p) => p.id == newPrinter.id);
      if (idx >= 0) {
        list[idx] = newPrinter;
      } else {
        list.add(newPrinter);
      }
      ref.read(printerListProvider.notifier).state = list;
      ref.read(selectedPrinterIdProvider.notifier).state = newPrinter.id;
      _savePrintersToStorageFromHere();

      await _showMsg('Printer', 'Impresora Bluetooth guardada: ${newPrinter.name}');
      _tab.index = 0;
      await _showPrintOptionsDialog();
      return;
       */
    }

    // WiFi
    final parts = qrData.split(':');
    if (parts.length < 3) {
      await _showMsg('QR', 'Invalid WiFi QR format.');
      return;
    }

    final ip = parts[0].trim();
    final port = int.tryParse(parts[1].trim()) ?? 0;
    final langRaw = parts[2].trim().toUpperCase();

    if (ip.isEmpty || port <= 0) {
      await _showMsg('QR', 'Invalid IP or port.');
      return;
    }

    if (!isValidLang(langRaw)) {
      await _showMsg('Printer', 'Tipo impresora invalido para configuración de impresora');
      return;
    }

    final lang = normalizeLang(langRaw);
    final name = (parts.length > 3 && parts[3].trim().isNotEmpty)
        ? parts[3].trim()
        : 'WiFi Printer $ip';

    final newPrinter = PrinterConnConfig(
      id: 'wifi_${ip}_$port',
      type: PrinterConnType.wifi,
      name: name,
      ip: ip,
      port: port,
      lang: lang,
      typeText: lang,
    );

    final list = [...ref.read(printerListProvider)];
    final idx = list.indexWhere((p) => p.id == newPrinter.id);
    if (idx >= 0) {
      list[idx] = newPrinter;
    } else {
      list.add(newPrinter);
    }
    ref.read(printerListProvider.notifier).state = list;
    ref.read(selectedPrinterIdProvider.notifier).state = newPrinter.id;
    _savePrintersToStorageFromHere();

    //await _showMsg('Printer', 'Impresora WiFi guardada: ${newPrinter.name}');
    _tab.index = 0;
    await _showPrintOptionsDialog();
  }

  // ------------------------------------------------------------
  // Back
  // ------------------------------------------------------------
  void popScopeAction(BuildContext context, WidgetRef ref) {
    debugPrint('popScopeAction $oldAction');
    debugPrint('popScopeAction ${Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND}');
    ref.read(actionScanProvider.notifier).state = oldAction;
    Navigator.pop(context);
  }

  // ------------------------------------------------------------
  // UI: 3 tabs
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(labelProfilesProvider);
    final selectedProfileId = ref.watch(selectedLabelProfileIdProvider);

    final printers = ref.watch(printerListProvider);
    final selectedPrinterId = ref.watch(selectedPrinterIdProvider);

    final selectedProfile = profiles.firstWhere(
          (p) => p.id == selectedProfileId,
      orElse: () => defaultLabel40x25(),
    );

    final selectedPrinter = printers.cast<PrinterConnConfig?>().firstWhere(
          (p) => p?.id == selectedPrinterId,
      orElse: () => null,
    );
    final inputMode = ref.watch(printerInputModeProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Column(
          children: [
            const Text('Label Printer Select',style: TextStyle(fontSize: themeFontSizeLarge),),
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
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: MaterialStateProperty.all(
                  const TextStyle(fontSize: 12),
                ),
              ),
            )

          ],
        ),
        actions: [


          if (inputMode == PrinterInputMode.scan)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ScanButtonByActionFixedShort(
              onOk: handleInputString,
              actionTypeInt: actionScanType,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Home'),
            Tab(text: 'Profiles'),
            Tab(text: 'Printers'),
          ],
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          popScopeAction(context, ref);
        },
        child: TabBarView(
          controller: _tab,
          children: [
            _buildHomeTab(selectedProfile: selectedProfile, selectedPrinter: selectedPrinter),
            _buildProfilesTab(),
            // Reuse PrinterSelectPage (add/edit/delete already there)
            PrinterSelectPage(dataToPrint: widget.dataToPrint),
          ],
        ),
      ),
    );
  }
  void _loadPrintersForHome() {
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


  Widget _buildHomeTab({
    required LabelProfile selectedProfile,
    required PrinterConnConfig? selectedPrinter,
  }) {
    final printers = ref.watch(printerListProvider);
    final selectedPrinterId = ref.watch(selectedPrinterIdProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('Selected configuration', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              title: Text('Profile: ${selectedProfile.name}'),
              subtitle: Text('${selectedProfile.widthMm}x${selectedProfile.heightMm}mm  copies:${selectedProfile.copies}'),
              trailing: const Icon(Icons.tune),
              onTap: () => _tab.index = 1,
            ),
          ),

          Card(
            child: ListTile(
              title: Text(selectedPrinter == null ? 'Printer: (none selected)' : 'Printer: ${selectedPrinter.name}'),
              subtitle: Text(
                selectedPrinter == null
                    ? 'Go to Printers tab to add/select one.'
                    : (selectedPrinter.type == PrinterConnType.wifi)
                    ? 'WiFi: ${selectedPrinter.ip}:${selectedPrinter.port}  lang:${selectedPrinter.lang ?? "-"}'
                    : 'BT: ${selectedPrinter.btAddress}  lang:${selectedPrinter.lang ?? "-"}  type:${selectedPrinter.typeText ?? "-"}',
              ),
              trailing: const Icon(Icons.print),
              onTap: () => _tab.index = 2,
            ),
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: selectedPrinter == null ? null : () async => _showPrintOptionsDialog(),
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedPrinter == null
                      ? null
                      : () async => _printLabel(profile: _selectedProfileOrDefault40()),
                  child: const Text('Print 40x25'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedPrinter == null
                      ? null
                      : () async => _printLabel(profile: _selectedProfileOrDefault60()),
                  child: const Text('Print 60x40'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: selectedPrinter == null
                ? null
                : () async => imprimirEtiquetaDeAjuste(profile: _selectedProfileOrDefault40()),
            child: const Text('Print adjustment label'),
          ),
          // ✅ Selector rápido
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text('Saved printers (quick select)'),
            children: [
              if (printers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No printers saved yet. Go to Printers tab to add one.'),
                )
              else
                ...printers.map((p) {
                  final subtitle = (p.type == PrinterConnType.wifi)
                      ? 'WiFi: ${p.ip}:${p.port}  lang:${p.lang ?? "-"}'
                      : 'BT: ${p.btAddress}  lang:${p.lang ?? "-"}  type:${p.typeText ?? "-"}';

                  return RadioListTile<String>(
                    value: p.id,
                    groupValue: selectedPrinterId,
                    title: Text(p.name),
                    subtitle: Text(subtitle),
                    onChanged: (v) {
                      if (v == null) return;
                      ref.read(selectedPrinterIdProvider.notifier).state = v;
                      _savePrintersToStorageFromHere(); // 👈 persiste selección
                    },
                  );
                }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfilesTab() {
    final profiles = ref.watch(labelProfilesProvider);
    final selectedProfileId = ref.watch(selectedLabelProfileIdProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Label profiles', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => _editOrCreateProfile(),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: profiles.length,
              itemBuilder: (_, i) {
                final p = profiles[i];
                return Card(
                  child: ListTile(
                    leading: Radio<String>(
                      value: p.id,
                      groupValue: selectedProfileId,
                      onChanged: (v) {
                        ref.read(selectedLabelProfileIdProvider.notifier).state = v;
                        _saveLabelProfiles();
                      },
                    ),
                    title: Text(p.name),
                    subtitle: Text('${p.widthMm}x${p.heightMm}mm  copies:${p.copies}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editOrCreateProfile(initial: p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProfile(p),
                        ),
                      ],
                    ),
                    onTap: () {
                      ref.read(selectedLabelProfileIdProvider.notifier).state = p.id;
                      _saveLabelProfiles();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Bottom sheet for LabelProfile config
// -----------------------------------------------------------------------------
Future<LabelProfile?> showLabelConfigBottomSheet({
  required BuildContext context,
  LabelProfile? initial,
}) {
  return showModalBottomSheet<LabelProfile>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _LabelConfigSheet(initial: initial),
  );
}

class _LabelConfigSheet extends StatefulWidget {
  final LabelProfile? initial;
  const _LabelConfigSheet({super.key, this.initial});

  @override
  State<_LabelConfigSheet> createState() => _LabelConfigSheetState();
}

class _LabelConfigSheetState extends State<_LabelConfigSheet> {
  late final TextEditingController nameC;
  late final TextEditingController copiesC;
  late final TextEditingController wC;
  late final TextEditingController hC;
  late final TextEditingController mxC;
  late final TextEditingController myC;
  late final TextEditingController bhC;
  late final TextEditingController chC;
  late final TextEditingController maxCh;
  late final TextEditingController barcodeW;
  late final TextEditingController barcodeN;
  late final TextEditingController barcodeH;
  late final TextEditingController fontIdC;
  late final TextEditingController gapC;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;

    nameC = TextEditingController(text: initial?.name ?? 'New Label');
    copiesC = TextEditingController(text: '${initial?.copies ?? 1}');
    wC = TextEditingController(text: '${initial?.widthMm ?? 40}');
    hC = TextEditingController(text: '${initial?.heightMm ?? 25}');
    mxC = TextEditingController(text: '${initial?.marginXmm ?? 2}');
    myC = TextEditingController(text: '${initial?.marginYmm ?? 2}');
    bhC = TextEditingController(text: '${initial?.barcodeHeightMm ?? 12}');
    chC = TextEditingController(text: '${initial?.charactersToPrint ?? 0}');
    maxCh = TextEditingController(text: '${initial?.maxCharsPerLine ?? 0}');
    barcodeW = TextEditingController(text: '${initial?.barcodeWidth ?? 0}');
    barcodeN = TextEditingController(text: '${initial?.barcodeNarrow ?? 0}');
    barcodeH = TextEditingController(text: '${initial?.barcodeHeight ?? 0}');
    fontIdC = TextEditingController(text: '${initial?.fontId ?? 0}');
    gapC = TextEditingController(text: '${initial?.gapMm ?? 0}');
  }

  @override
  void dispose() {
    nameC.dispose();
    copiesC.dispose();
    wC.dispose();
    hC.dispose();
    mxC.dispose();
    myC.dispose();
    bhC.dispose();
    chC.dispose();
    maxCh.dispose();
    barcodeW.dispose();
    barcodeN.dispose();
    barcodeH.dispose();
    fontIdC.dispose();
    gapC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheetContext = context;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Label Config',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _numField(copiesC, 'Copies'),
                    _numField(gapC, 'Gap (mm)'),
                    _numField(wC, 'Width (mm)'),
                    _numField(hC, 'Height (mm)'),
                    _numField(mxC, 'Margin X (mm)'),
                    _numField(myC, 'Margin Y (mm)'),
                    _numField(barcodeH, 'Barcode Height (dot)'),
                    _numField(barcodeW, 'Barcode wide'),
                    _numField(barcodeN, 'Barcode narrow'),
                    _numField(chC, 'charactersToPrint'),
                    _numField(maxCh, 'maxCharacterPerLine'),
                    _numField(fontIdC, 'Font Id'),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final initial = widget.initial;
                        final id = initial?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}';

                        final profile = LabelProfile(
                          id: id,
                          name: nameC.text.trim().isEmpty ? 'Label' : nameC.text.trim(),
                          copies: int.tryParse(copiesC.text.trim()) ?? 1,
                          widthMm: double.tryParse(wC.text.trim()) ?? 40,
                          heightMm: double.tryParse(hC.text.trim()) ?? 25,
                          marginXmm: double.tryParse(mxC.text.trim()) ?? 2,
                          marginYmm: double.tryParse(myC.text.trim()) ?? 2,
                          barcodeHeightMm: int.tryParse(bhC.text.trim()) ?? 12,
                          charactersToPrint: int.tryParse(chC.text.trim()) ?? 0,
                          maxCharsPerLine: int.tryParse(maxCh.text.trim()) ?? 0,
                          barcodeHeight: int.tryParse(barcodeH.text.trim()) ?? 80,
                          barcodeWidth: int.tryParse(barcodeW.text.trim()) ?? 3,
                          barcodeNarrow: int.tryParse(barcodeN.text.trim()) ?? 2,
                          fontId: int.tryParse(fontIdC.text.trim()) ?? 2,
                          gapMm: int.tryParse(gapC.text.trim()) ?? 2,
                        );

                        Navigator.pop(sheetContext, profile);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return SizedBox(
      width: 160,
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}



