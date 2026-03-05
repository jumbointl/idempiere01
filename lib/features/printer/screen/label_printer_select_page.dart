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

import '../../products/common/input_dialog.dart';
import '../../shared/data/memory.dart';
import '../models/printer_select_models.dart';
import '../printer_scan_notifier.dart';
import 'niimbot_silence_page.dart';
import 'printer_select_page.dart';


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
  int get actionScanType => Memory.ACTION_NO_SCAN_ACTION;

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


  Future<void> goNiimbotPageBottomSheet(
      BuildContext context,
      WidgetRef ref, {
        required Object dataToPrint,
        LabelProfile? profile,
        required String bluetoothAddress,
        required Future<void> Function() popScopeAction,
      }) async {
    final bool? shouldExit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      enableDrag: false, // opcional: más “modal”
      builder: (ctx) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.95,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: NiimbotPrintSilencePage(
                dataToPrint: dataToPrint,
                profile: profile,
                bluetoothAddress: bluetoothAddress,
              ),
            ),
          ),
        );
      },
    );

    if (shouldExit == true) {
      await popScopeAction();
    }
  }
  String checkLabelSize(WidgetRef ref, LabelProfile profile, {required bool printSimpleData});


}

class _LabelPrinterSelectPageState extends ConsumerState<LabelPrinterSelectPage>
    with SingleTickerProviderStateMixin {
  final box = GetStorage();

  late final int oldAction;
  late final TabController _tab;


  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadLabelProfiles();
      _loadPrintersForHome();

      oldAction = ref.read(actionScanProvider);
      ref.read(actionScanProvider.notifier).state = widget.actionScanType;
      ref.read(printerInputModeProvider.notifier).state = PrinterInputMode.scan;
      await Future.delayed(const Duration(milliseconds: 200));
      final selectedPrinter = _selectedPrinter() ;
      if(selectedPrinter!=null && selectedPrinter.btAddress!=null
          && selectedPrinter.lang == PrinterState.PRINTER_TYPE_NIIMBOT){
        if(context.mounted) {
          widget.goNiimbotPageBottomSheet(
            context,
            ref,
            dataToPrint: widget.dataToPrint,
            bluetoothAddress: selectedPrinter.btAddress!,
            profile: selectedProfileOrDefault50(),
            popScopeAction: () async =>popScopeAction(context, ref),
          );
        }
      }

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
    if (list.where((e) => e.id == 'default_30x20').isEmpty) {
      list.add(defaultLabel30x20());
    }

    if (list.where((e) => e.id == 'default_40x25').isEmpty) {
      list.add(defaultLabel40x25());
    }
    if (list.where((e) => e.id == 'default_40x15').isEmpty) {
      list.add(defaultLabel40x15());
    }
    if (list.where((e) => e.id == 'default_60x40').isEmpty) {
      list.add(defaultLabel60x40());
    }
    if (list.where((e) => e.id == 'default_50x30').isEmpty) {
      list.add(defaultLabel50x30());
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
  LabelProfile selectedProfileOrDefault50() {
    final list = ref.read(labelProfilesProvider);
    final id = ref.read(selectedLabelProfileIdProvider);

    final p = list
        .where((e) => e.id == id)
        .cast<LabelProfile?>()
        .firstWhere((e) => e != null, orElse: () => null);

    return p ?? defaultLabel50x30();
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

  Future<void> showMsg(String title, String msg) async {
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
    required int copies,
  }) async {
    final printer = _selectedPrinter();
    if (printer == null) {
      await showMsg('Printer', 'Select a printer first.');
      return;
    }


    final err = widget.validateDataToPrint();
    if (err != null) {
      await showMsg('Data', err);
      return;
    }
    final p0 = profile ;
    final p = LabelProfile(
      id: p0.id,
      name: p0.name,
      copies: copies, // ✅
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
    ref.read(isPrintingProvider.notifier).state = true;
    String errorMessage = widget.checkLabelSize(ref,p,printSimpleData:printSimpleData);
    if(errorMessage.isNotEmpty) {
      await showMsg('Profile', widget.checkLabelSize(ref,p,printSimpleData: printSimpleData));
      return ;
    }



    final tspl = widget.buildTsplForData(
      profile: p,
      printSimpleData: printSimpleData,
    );

    try {
      if (printer.type == PrinterConnType.wifi) {
        await sendTsplViaWifi(
          ip: printer.ip!,
          port: printer.port ?? 9100,
          tspl: tspl,
        );

        await showMsg('Print', '✅ Printed via WiFi');
      } else {
        await sendTsplViaBluetooth(
          btAddress: printer.btAddress!,
          tspl: tspl,
        );
        await showMsg('Print', '✅ Printed via Bluetooth');
      }
    } catch (e) {
      await showMsg('Print', '❌ Error: $e');
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
      await showMsg('Printer', 'Select a printer first.');
      return;
    }

    const upc = '1234567890123';
    final line = _buildAdjustmentLine(profile.maxCharsPerLine);
    ref.read(isPrintingProvider.notifier).state = true;
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
        await showMsg('Print', '✅ Adjustment label printed via WiFi');
      } else {
        await sendTsplViaBluetooth(
          btAddress: printer.btAddress!,
          tspl: tspl,
        );
        await showMsg('Print', '✅ Adjustment label printed via Bluetooth');
      }
    } catch (e) {
      await showMsg('Print', '❌ Error: $e');
    } finally {
      ref
          .read(isPrintingProvider.notifier)
          .state = false;
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

    final int x = 20;
    final int yText = 20;
    final int yBar = 60;
    final int h = profile.barcodeHeight > 0 ? profile.barcodeHeight : 80;
    final int narrow = profile.barcodeNarrow > 0 ? profile.barcodeNarrow : 2;
    final int wide = profile.barcodeWidth > 0 ? profile.barcodeWidth : 3;

    final res = [
      'SIZE ${profile.widthMm} mm,${profile.heightMm} mm',
      'GAP ${profile.gapMm} mm,0 mm',
      'DIRECTION 1',
      'CLS',
      'TEXT $x,$yText,"${profile.fontId}",0,1,1,"$topText"',
      'BARCODE $x,$yBar,"128",$h,0,0,$narrow,$wide,"$barcodeData"',
      'PRINT ${profile.copies},1',
      '',
    ].join('\n');
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
              int copies = ref.read(copiesTempProvider);
              if(copies<1) copies =1;


              await printLabel(
                profile: selectedProfileOrDefault40(),
                printSimpleData: true,
                copies: copies,
              );
            },
            child: const Text('1) Imprimir simple'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              int copies = ref.read(copiesTempProvider);
              if(copies<1) copies =1;
              await printLabel(
                profile: selectedProfileOrDefault60(),
                printSimpleData: false,
                copies: copies,
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
    debugPrint('QR inputDat: $qrData');
    if (qrData.isEmpty) return;
    if (actionScan != widget.actionScanType) return;
    bool isNiimbot = false;
    bool isValidLang(String s) {

      final t = s.trim().toUpperCase();
      debugPrint('lang: $t');
      return t == PrinterState.PRINTER_TYPE_TSPL || t == 'TPL'
      || t== PrinterState.PRINTER_TYPE_NIIMBOT || t == 'NIIMBOT';
    }

    String normalizeLang(String s) {
      final t = s.trim().toUpperCase();
      return t == 'TPL' ? PrinterState.PRINTER_TYPE_TSPL : t;
    }
    bool normalizeBluetoothType(String s) {
      final btType = s.trim().toUpperCase();
      if (btType != PrinterState.PRINTER_TYPE_BLUETOOTH_BLE &&
          btType != PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE) {
        return false;
      }
      return true;
    }
    late final PrinterConnConfig scanedPrinter;
    if (qrData.toUpperCase().startsWith('BLUETOOTH*')) {
      //BLUETOOTH*NAME*BLUETOOTH_ADDRESS*LANGUAGE*BLUETOOTH_TYPE
      final parts = qrData.split('*');
      if (parts.length < 5) {
        await showMsg('QR', 'Invalid Bluetooth QR format.\n$qrData');
        return;
      }
      final name = parts[1].trim();
      if (name.isEmpty) {
        await showMsg('QR', 'Invalid Bluetooth QR format. name\n$qrData');
        return;
      }
      final btAddress = parts[2].trim();
      if (btAddress.isEmpty) {
        await showMsg('QR', 'Invalid Bluetooth QR format. address\n$qrData');
        return;
      }
      final lang = parts[3].trim().toUpperCase();
      if (!isValidLang(lang)) {
        await showMsg('Printer', 'Tipo impresora invalido para configuración de impresora $lang\n$qrData');
        return;
      }
      if(lang==PrinterState.PRINTER_TYPE_NIIMBOT){
        isNiimbot = true;
      }
      final bluetoothType = parts[4].trim();
      if (bluetoothType.isEmpty || !normalizeBluetoothType(bluetoothType)) {
        await showMsg('QR', 'Invalid Bluetooth QR format.\n$qrData');
        return;
      }
      scanedPrinter = PrinterConnConfig(
        btAddress: btAddress,
        id: 'bt_$btAddress',
        type: PrinterConnType.bluetooth,
        name: name,
        lang: lang,
        typeText: bluetoothType,
      );


    } else {
      final parts = qrData.split(':');
      if (parts.length < 3) {
        await showMsg('QR', 'Invalid WiFi QR format.\n$qrData');
        return;
      }

      final ip = parts[0].trim();
      final port = int.tryParse(parts[1].trim()) ?? 0;
      final langRaw = parts[2].trim().toUpperCase();

      if (ip.isEmpty || port <= 0) {
        await showMsg('QR', 'Invalid IP or port.\n$qrData');
        return;
      }

      if (!isValidLang(langRaw)) {
        await showMsg('Printer', 'Tipo impresora invalido para configuración de impresora.\n$qrData');
        return;
      }

      final lang = normalizeLang(langRaw);
      final name = (parts.length > 3 && parts[3].trim().isNotEmpty)
          ? parts[3].trim()
          : 'WiFi Printer $ip';

      scanedPrinter = PrinterConnConfig(
        id: 'wifi_${ip}_$port',
        type: PrinterConnType.wifi,
        name: name,
        ip: ip,
        port: port,
        lang: lang,
        typeText: lang,
      );
    }


    final list = [...ref.read(printerListProvider)];
    final idx = list.indexWhere((p) => p.id == scanedPrinter.id);
    if (idx >= 0) {
      list[idx] = scanedPrinter;
    } else {
      list.add(scanedPrinter);
    }
    ref.read(printerListProvider.notifier).state = list;
    ref.read(selectedPrinterIdProvider.notifier).state = scanedPrinter.id;
    _savePrintersToStorageFromHere();

    _tab.index = 0;
    if(isNiimbot){
      widget.goNiimbotPageBottomSheet(context,
          ref,
          dataToPrint: widget.dataToPrint,
          profile: selectedProfileOrDefault50(),
          bluetoothAddress: scanedPrinter.btAddress!,
          popScopeAction: () async =>popScopeAction(context, ref));
    } else {
      await _showPrintOptionsDialog();
    }

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
            PrinterSelectPage(dataToPrint: widget.dataToPrint,popOnSelect: false,),
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
    final isNiimbot = selectedPrinter != null &&
        (selectedPrinter.lang ?? '').toUpperCase() == 'NIIMBOT';
    final copiesTemp = ref.watch(copiesTempProvider);
    final isPrinting = ref.read(isPrintingProvider);
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
          const SizedBox(height: 10),
          if (isNiimbot) ...[
            buildNiimbotConnectCard(ref, selectedPrinter),
          ] else ...[
            // copiesTemp row
            Row(
              children: [
                const SizedBox(width: 120, child: Text('Copies (temp):')),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      await getIntDialog(
                        useScreenKeyboardOnly: true,
                        ref: ref,
                        minValue: 1,
                        quantity: copiesTemp, // valor actual
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
                        style: const TextStyle(fontSize: 14, color: Colors.purple, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if(!isPrinting)widget.buildPrintingPanel(
              context: context,
              ref: ref,
              selectedPrinter: selectedPrinter,
              profile40: profile40,
              profile60: profile60,
              onPrint: ({required LabelProfile profile, required bool printSimpleData}) {
                return printLabel(profile: profile, printSimpleData: printSimpleData, copies: copiesTemp);
              },
            ),
            const SizedBox(height: 10),
            if(!isPrinting)ElevatedButton(
              onPressed: selectedPrinter == null
                  ? null
                  : () async => printAdjustmentSticker(profile: selectedProfileOrDefault40()),
              child: const Text('Print adjustment label'),
            ),
          ],



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
  Widget buildNiimbotConnectCard(WidgetRef ref, PrinterConnConfig selectedPrinter) {
    LabelProfile getSelectedProfile() {
      final profiles = ref.read(labelProfilesProvider);
      final selectedId = ref.read(selectedLabelProfileIdProvider);
      if (selectedId == null) return defaultLabel40x25();
      return profiles.firstWhere(
            (p) => p.id == selectedId,
        orElse: () => defaultLabel40x25(),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NIIMBOT BLUETOOTH PRINTER', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                debugPrint('selectedPrinter: ${selectedPrinter.toJson()}');
                widget.goNiimbotPageBottomSheet(
                  context,
                  ref,
                  dataToPrint: widget.dataToPrint,
                  profile: getSelectedProfile(),
                  bluetoothAddress: selectedPrinter.btAddress ?? '',
                  popScopeAction: () async =>popScopeAction(context, ref),
                );
              },
              icon: const Icon(Icons.print),
              label: const Text('Ir a la pagina de impresion'),
            ),
          ],
        ),
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
