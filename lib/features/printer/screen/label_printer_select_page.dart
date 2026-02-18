// ===============================
// label_printer_select_page.dart
// ===============================
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action_fixed_short.dart';
import 'package:monalisa_app_001/features/products/domain/models/label_profile.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';

import '../models/printer_select_models.dart';
import '../printer_scan_notifier.dart';
import 'niimbot_test_page.dart';
import 'printer_select_page.dart';
import 'niimbot/niimbot_service.dart';


// NIIMBOT (niim_blue_flutter)



// -----------------------------------------------------------------------------
// Base class: LabelPrinterSelectPage (parent)
// - 3 tabs: Home / Profiles / Printers
// - Loads/saves label profiles
// - Loads/saves printers (shared with PrinterSelectPage via printerListProvider)
// - Handles QR scan to add WiFi printer
// - Provides generic printing pipeline (TSPL) and a hook to build TSPL per child
// -----------------------------------------------------------------------------
abstract class LabelPrinterSelectPage extends ConsumerStatefulWidget {
  final dynamic dataToPrint;
  const LabelPrinterSelectPage({super.key, required this.dataToPrint});

  /// Override to define which scan action this page uses.
  int get actionScanType;

  /// Optional: customize title in AppBar.
  String get pageTitle => 'Label Printer Select';

  /// Override: build TSPL for the current `dataToPrint`.
  /// `printSimpleData` can be ignored by implementations that don't need it.
  String buildTsplForData({
    required LabelProfile profile,
    required bool printSimpleData,
  });

  /// Override: validates the `dataToPrint` and returns a user-friendly error if invalid.
  /// Return null if OK.
  String? validateDataToPrint();

  @override
  ConsumerState<LabelPrinterSelectPage> createState() =>
      _LabelPrinterSelectPageState();
  Widget buildPrintingPanel({
    required BuildContext context,
    required WidgetRef ref,
    required PrinterConnConfig? selectedPrinter,
    required LabelProfile profile40,
    required LabelProfile profile60,
    required Future<void> Function({
    required LabelProfile profile,
    required bool printSimpleData,
    }) onPrint,
  });

}

class _LabelPrinterSelectPageState extends ConsumerState<LabelPrinterSelectPage>
    with SingleTickerProviderStateMixin {
  final box = GetStorage();

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
      ref.read(actionScanProvider.notifier).state = widget.actionScanType;
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

  LabelProfile selectedProfileOrDefault40() {
    final list = ref.read(labelProfilesProvider);
    final id = ref.read(selectedLabelProfileIdProvider);

    final p = list
        .where((e) => e.id == id)
        .cast<LabelProfile?>()
        .firstWhere((e) => e != null, orElse: () => null);

    return p ?? defaultLabel40x25();
  }

  LabelProfile selectedProfileOrDefault60() {
    final list = ref.read(labelProfilesProvider);
    final id = ref.read(selectedLabelProfileIdProvider);

    final p = list
        .where((e) => e.id == id)
        .cast<LabelProfile?>()
        .firstWhere((e) => e != null, orElse: () => null);

    return p ?? defaultLabel60x40();
  }

  Future<void> _editOrCreateProfile({LabelProfile? initial}) async {
    final inputModeOld = ref.read(printerInputModeProvider);
    if (inputModeOld == PrinterInputMode.scan) {
      ref.read(printerInputModeProvider.notifier).state = PrinterInputMode.manual;
    }

    final profile = await showLabelConfigBottomSheet(
      context: context,
      initial: initial,
    );

    if (inputModeOld != ref.read(printerInputModeProvider)) {
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
  // Printers: load/save (shared providers from printer_select_page.dart)
  // ------------------------------------------------------------
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
    final socket = await Socket.connect(ip, port,
        timeout: const Duration(seconds: 5));
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

    final connected =
    await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (!connected) {
      throw Exception('No se pudo conectar por Bluetooth: $mac');
    }

    await Future.delayed(const Duration(milliseconds: 150));
    final ok =
    await PrintBluetoothThermal.writeBytes(tspl.codeUnits.toList());

    await Future.delayed(const Duration(milliseconds: 120));
    await _disconnectSafe();

    if (!ok) throw Exception('Bluetooth writeBytes returned false');
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

  // ------------------------------------------------------------
  // Printing pipeline (extendible)
  // ------------------------------------------------------------
  Future<void> printLabel({
    required LabelProfile profile,
    required bool printSimpleData,
  }) async {
    final printer = _selectedPrinter();
    if (printer == null) {
      await _showMsg('Printer', 'Select a printer first.');
      return;
    }

    final err = widget.validateDataToPrint();
    if (err != null) {
      await _showMsg('Data', err);
      return;
    }

    final tspl = widget.buildTsplForData(
      profile: profile,
      printSimpleData: printSimpleData,
    );

    try {
      if (printer.type == PrinterConnType.wifi) {
        await sendTsplViaWifi(
          ip: printer.ip!,
          port: printer.port ?? 9100,
          tspl: tspl,
        );
        await _showMsg('Print', '✅ Printed via WiFi');
      } else {
        await sendTsplViaBluetooth(
          btAddress: printer.btAddress!,
          tspl: tspl,
        );
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

  Future<void> printAdjustmentSticker({required LabelProfile profile}) async {
    final printer = _selectedPrinter();
    if (printer == null) {
      await _showMsg('Printer', 'Select a printer first.');
      return;
    }

    const upc = '1234567890123';
    final line = _buildAdjustmentLine(profile.maxCharsPerLine);

    // Default: use the "simple" layout idea. Child can still override by
    // returning something else in buildTsplForData, but adjustment is generic.
    final tspl = _buildGenericAdjustmentTspl(
      profile: profile,
      topText: line,
      barcodeData: upc,
    );

    try {
      if (printer.type == PrinterConnType.wifi) {
        await sendTsplViaWifi(
          ip: printer.ip!,
          port: printer.port ?? 9100,
          tspl: tspl,
        );
        await _showMsg('Print', '✅ Adjustment label printed via WiFi');
      } else {
        await sendTsplViaBluetooth(
          btAddress: printer.btAddress!,
          tspl: tspl,
        );
        await _showMsg('Print', '✅ Adjustment label printed via Bluetooth');
      }
    } catch (e) {
      await _showMsg('Print', '❌ Error: $e');
    }
  }

  // Simple generic adjustment TSPL (kept inside base)
  String _buildGenericAdjustmentTspl({
    required LabelProfile profile,
    required String topText,
    required String barcodeData,
  }) {
    // Minimal and safe TSPL. Use Code128 human=0 to avoid text under barcode.
    // You can tune dots/mm based on your printer; here we assume existing
    // buildTspl helpers elsewhere are tuned, but adjustment just needs "something".
    //
    // TIP: If you already have tuned builders, you can remove this and reuse them.
    final int labelW = (profile.widthMm * 8).round();
    final int labelH = (profile.heightMm * 8).round();
    final int gap = (profile.gapMm * 8).round();

    final int x = 20;
    final int yText = 20;
    final int yBar = 60;
    final int h = profile.barcodeHeight > 0 ? profile.barcodeHeight : 80;
    final int narrow = profile.barcodeNarrow > 0 ? profile.barcodeNarrow : 2;
    final int wide = profile.barcodeWidth > 0 ? profile.barcodeWidth : 3;

    return [
      'SIZE $labelW,$labelH',
      'GAP $gap,0',
      'DIRECTION 1',
      'CLS',
      'TEXT $x,$yText,"${profile.fontId}",0,1,1,"$topText"',
      'BARCODE $x,$yBar,"128",$h,0,0,$narrow,$wide,"$barcodeData"',
      'PRINT ${profile.copies},1',
      '',
    ].join('\n');
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
              await printLabel(
                profile: selectedProfileOrDefault40(),
                printSimpleData: true,
              );
            },
            child: const Text('1) Imprimir simple'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await printLabel(
                profile: selectedProfileOrDefault60(),
                printSimpleData: false,
              );
            },
            child: const Text('2) Imprimir completo'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // QR handler: WiFi only (Bluetooth QR disabled)
  // WiFi: ip:port:type:name:serverIp:serverPort  (you use first 3..4 parts)
  // ------------------------------------------------------------
  void handleInputString({
    required int actionScan,
    required String inputData,
    required WidgetRef ref,
  }) async {
    final qrData = inputData.trim();
    if (qrData.isEmpty) return;
    if (actionScan != widget.actionScanType) return;

    bool isValidLang(String s) {
      final t = s.trim().toUpperCase();
      return t == PrinterState.PRINTER_TYPE_TSPL || t == 'TPL';
    }

    String normalizeLang(String s) {
      final t = s.trim().toUpperCase();
      return t == 'TPL' ? PrinterState.PRINTER_TYPE_TSPL : t;
    }

    if (qrData.toUpperCase().startsWith('BLUETOOTH*')) {
      await _showMsg('QR', 'not for Bluetooth printers.');
      return;
    }

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

    _tab.index = 0;
    await _showPrintOptionsDialog();
  }

  // ------------------------------------------------------------
  // Back
  // ------------------------------------------------------------
  void popScopeAction(BuildContext context, WidgetRef ref) {
    ref.read(actionScanProvider.notifier).state = oldAction;
    Navigator.pop(context);
  }

  // ------------------------------------------------------------
  // UI
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
        title: Text(
          widget.pageTitle,
          style: const TextStyle(fontSize: themeFontSizeLarge),
        ),
        actions: [
          if (inputMode == PrinterInputMode.scan)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ScanButtonByActionFixedShort(
                onOk: handleInputString,
                actionTypeInt: widget.actionScanType,
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
            _buildHomeTab(
              selectedProfile: selectedProfile,
              selectedPrinter: selectedPrinter,
            ),
            _buildProfilesTab(),
            PrinterSelectPage(dataToPrint: widget.dataToPrint),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab({
    required LabelProfile selectedProfile,
    required PrinterConnConfig? selectedPrinter,
  }) {
    final printers = ref.watch(printerListProvider);
    final selectedPrinterId = ref.watch(selectedPrinterIdProvider);
    final profile40 = selectedProfileOrDefault40();
    final profile60 = selectedProfileOrDefault60();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            'Selected configuration',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              title: Text('Profile: ${selectedProfile.name}'),
              subtitle: Text(
                '${selectedProfile.widthMm}x${selectedProfile.heightMm}mm  copies:${selectedProfile.copies}',
              ),
              trailing: const Icon(Icons.tune),
              onTap: () => _tab.index = 1,
            ),
          ),

          // ------------------------------
          // NIIMBOT connect panel (niim_blue_flutter)
          // ------------------------------
          if (selectedPrinter != null && (selectedPrinter.lang ?? '').toUpperCase() == 'NIIMBOT')
            buildNiimbotConnectCard(ref,selectedPrinter),

          Card(
            child: ListTile(
              title: Text(
                selectedPrinter == null
                    ? 'Printer: (none selected)'
                    : 'Printer: ${selectedPrinter.name}',
              ),
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
          widget.buildPrintingPanel(
            context: context,
            ref: ref,
            selectedPrinter: selectedPrinter,
            profile40: profile40,
            profile60: profile60,
            onPrint: ({required LabelProfile profile, required bool printSimpleData}) {
              return printLabel(profile: profile, printSimpleData: printSimpleData);
            },
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: selectedPrinter == null
                ? null
                : () async => printAdjustmentSticker(profile: selectedProfileOrDefault40()),
            child: const Text('Print adjustment label'),
          ),

          // Quick select printers
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
                      _savePrintersToStorageFromHere();
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

  Widget buildNiimbotConnectCard(WidgetRef ref,PrinterConnConfig selectedPrinter) {
    final niimState = ref.watch(niimbotTestControllerProvider);
    final niimCtrl = ref.read(niimbotTestControllerProvider.notifier);
    final addr = (selectedPrinter.btAddress ?? '').trim();

    Future<void> connectAuto() async {
      if (addr.isEmpty) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('NIIMBOT'),
            content: Text('❌ Falta BT address (MAC / remoteId) en la impresora seleccionada.'),
          ),
        );
        return;
      }

      final ok = await niimCtrl.connectToAddressSilence(context, address: addr);
      if (ok) return;

      // Si no encontró match exacto, hacemos scan UI y dejamos elegir.
      if (!mounted) return;
      await niimCtrl.handleConnectScan(context);
      if (!mounted) return;
      await _showNiimbotDevicePicker(ref);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NIIMBOT', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Status: ${niimState.status}', style: const TextStyle(fontSize: 12)),
            if (addr.isNotEmpty) Text('Address: $addr', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: connectAuto,
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('Conectar (scan+auto)'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await niimCtrl.handleConnectScan(context);
                    if (!mounted) return;
                    await _showNiimbotDevicePicker(ref);
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('Elegir dispositivo'),
                ),
                OutlinedButton.icon(
                  onPressed: niimCtrl.isConnected() ? () => niimCtrl.handleDisconnect(context) : null,
                  icon: const Icon(Icons.link_off),
                  label: const Text('Desconectar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNiimbotDevicePicker(WidgetRef ref) async {
    final niimState = ref.read(niimbotTestControllerProvider);
    final niimCtrl = ref.read(niimbotTestControllerProvider.notifier);
    final devices = niimState.devices;
    if (devices.isEmpty) return;

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: devices.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = devices[i];
              final name = d.platformName.isEmpty ? 'NIIMBOT' : d.platformName;
              final id = d.remoteId.str;
              return ListTile(
                leading: const Icon(Icons.print),
                title: Text(name),
                subtitle: Text(id),
                onTap: () async {
                  Navigator.pop(ctx);
                  await niimCtrl.connectToDevice(context, d);
                },
              );
            },
          ),
        );
      },
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
                        final id = initial?.id ??
                            'custom_${DateTime.now().millisecondsSinceEpoch}';

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
