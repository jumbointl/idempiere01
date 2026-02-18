// ===============================
// label_printer_select_page.dart
// ===============================
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pos_universal_printer/pos_universal_printer.dart';

import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action_fixed_short.dart';
import 'package:monalisa_app_001/features/products/domain/models/label_profile.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';

import '../models/printer_select_models.dart';
import '../printer_scan_notifier.dart';
import '../tspl/tspl_printer_helper.dart';
import 'printer_select_page.dart';



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
  Future<bool> printDataToNiimbot({
    required BuildContext context,
    required PrinterConnConfig printer,
    required LabelProfile profile,
    required dynamic data,
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
    final pos = PosUniversalPrinter.instance;

    if (!pos.isRoleConnected(PosPrinterRole.sticker)) {
      throw Exception('Bluetooth printer not connected');
    }

    final bytes = latin1.encode(tspl);

    try {
      pos.printRaw(PosPrinterRole.sticker, bytes);

      // Tiempo para que el buffer salga por Bluetooth
      await Future.delayed(const Duration(milliseconds: 700));
    } finally {
      try {
        await pos.unregisterDevice(PosPrinterRole.sticker);
      } catch (_) {}
    }
  }


  Future<void> _disconnectStickerRoleSafe(PosUniversalPrinter pos) async {
    try {
      final dynamic dyn = pos;

      // Intento 1
      try {
        debugPrint('Disconnecting sticker role disconnect');
        await dyn.disconnect(PosPrinterRole.sticker);
        return;
      } catch (_) {
        debugPrint('Disconnecting sticker role disconnect failed');
      }

      // Intento 2 (algunas versiones usan unregisterDevice)
      try {
        debugPrint('Disconnecting sticker role unregisterDevice');
        await dyn.unregisterDevice(PosPrinterRole.sticker);
        return;
      } catch (_) {
        debugPrint('Disconnecting sticker role unregisterDevice failed');
      }

      // Intento 3 (otros nombres posibles)
      try {
        debugPrint('Disconnecting sticker role disconnectRole');
        await dyn.disconnectRole(PosPrinterRole.sticker);
        return;
      } catch (_) {
        debugPrint('Disconnecting sticker role disconnectRole failed');
      }

      // Si no existe ninguno, no hacemos nada (mejor no romper el flujo)
    } catch (_) {
      debugPrint('Disconnecting sticker role failed');
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
    ref.read(isPrintingProvider.notifier).state = true;
    if(printer.typeText== PrinterState.PRINTER_TYPE_NIIMBOT) {
      final res = await widget.printDataToNiimbot(context: context, printer: printer,
          profile: profile, data: widget.dataToPrint);
      ref.read(isPrintingProvider.notifier).state = false;
      if(res){
        await _showMsg('Print', '✅ Printed via Niimbot');
      } else {
        await _showMsg('Print', '❌ Error: $res');
      }
      return ;
    }



    final tspl = widget.buildTsplForData(
      profile: profile,
      printSimpleData: printSimpleData,
    );
    final bool connected = await testConnectionPrinterSilence(context, printer);
    if(!connected) {
      ref.read(isPrintingProvider.notifier).state = false;
      await _showMsg('Printer', 'Printer not connected');

      return;
    }

    try {
      if (printer.type == PrinterConnType.wifi) {
        await sendTsplViaWifi(
          ip: printer.ip!,
          port: printer.port ?? 9100,
          tspl: tspl,
        );
        ref.read(isPrintingProvider.notifier).state = false;
        await _showMsg('Print', '✅ Printed via WiFi');
      } else {
        await sendTsplViaBluetooth(
          btAddress: printer.btAddress!,
          tspl: tspl,
        );
        ref.read(isPrintingProvider.notifier).state = false;
        await _showMsg('Print', '✅ Printed via Bluetooth');
      }
    } catch (e) {
      ref.read(isPrintingProvider.notifier).state = false;
      await _showMsg('Print', '❌ Error: $e');
    } finally {
      ref
          .read(isPrintingProvider.notifier)
          .state = false;
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
    ref.read(isPrintingProvider.notifier).state = true;
    try {
      final connected = await testConnectionPrinterSilence(context, printer);
      if(!connected) {
        ref.read(isPrintingProvider.notifier).state = false;
        await _showMsg('Printer', 'Printer not connected');
        return;
      }
      if (printer.type == PrinterConnType.wifi) {
        await sendTsplViaWifi(
          ip: printer.ip!,
          port: printer.port ?? 9100,
          tspl: tspl,
        );
        ref.read(isPrintingProvider.notifier).state = false;
        await _showMsg('Print', '✅ Adjustment label printed via WiFi');
      } else {
        await sendTsplViaBluetooth(
          btAddress: printer.btAddress!,
          tspl: tspl,
        );
        ref.read(isPrintingProvider.notifier).state = false;
        await _showMsg('Print', '✅ Adjustment label printed via Bluetooth');
      }
    } catch (e) {
      await _showMsg('Print', '❌ Error: $e');
    } finally {
      ref
          .read(isPrintingProvider.notifier)
          .state = false;
    }
  }

  String _buildGenericAdjustmentTspl({
    required LabelProfile profile,
    required String topText,
    required String barcodeData,
  }) {
    const int dotsPerMm = 8;

    final int labelW = (profile.widthMm * dotsPerMm).round();
    final int labelH = (profile.heightMm * dotsPerMm).round();

    final int marginX = (profile.marginXmm * dotsPerMm).round();
    final int marginY = (profile.marginYmm * dotsPerMm).round();

    final int yText = marginY + 10;
    final int yBar = yText + 40;

    final int h = profile.barcodeHeight > 0 ? profile.barcodeHeight : 80;
    final int narrow = profile.barcodeNarrow > 0 ? profile.barcodeNarrow : 2;
    final int wide = profile.barcodeWidth > 0 ? profile.barcodeWidth : 3;

    final int estBarcodeWidth =
    estimateBarcodeWidthDots(barcodeData.length, narrow);

    int xBarcode = ((labelW - estBarcodeWidth) / 2).round();

    xBarcode = xBarcode.clamp(marginX, labelW - marginX - estBarcodeWidth);

    final res = [
      'SIZE ${profile.widthMm} mm,${profile.heightMm} mm',
      'GAP ${profile.gapMm} mm,0 mm',
      'DIRECTION 1',
      'CLS',
      'TEXT $marginX,$yText,"${profile.fontId}",0,1,1,"$topText"',
      'BARCODE $xBarcode,$yBar,"128",$h,1,0,$narrow,$wide,"$barcodeData"',
      'PRINT ${profile.copies},1',
      '',
    ].join('\n');

    debugPrint(res);
    return res;
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
    final isPrinting = ref.watch(isPrintingProvider) ;

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
        child: isPrinting ? LinearProgressIndicator() : TabBarView(
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
    final printerConnected = ref.watch(printerConnectedProvider);


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
              trailing: IconButton(onPressed: null, icon: Icon(Icons.tune)),
              onTap: () => _tab.index = 1,
            ),
          ),

          Card(
            child: ListTile(
              trailing: IconButton(onPressed: (){
                 testConnectionSelectPrinterPage(selectedPrinter: selectedPrinter);
              }, icon:Icon(Icons.link),color: printerConnected? Colors.green : Colors.grey,),
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
                }),
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

  void testConnectionSelectPrinterPage({PrinterConnConfig? selectedPrinter}) async {
    if (selectedPrinter == null) {
      await _showMsg('Printer', 'No hay impresora seleccionada.');
      return;
    }

    // Reusa el helper del otro archivo
    bool res = await testConnectionPrinter(context, selectedPrinter);
    ref.read(printerConnectedProvider.notifier).state = res;


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
  const _LabelConfigSheet({this.initial});

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
