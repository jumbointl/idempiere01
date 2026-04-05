import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action_fixed_short.dart';
import 'package:riverpod_printer/riverpod_printer.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';

import '../../products/common/input_dialog.dart';
import '../../shared/data/memory.dart';
import '../models/printer_select_models.dart';
import '../printer_scan_notifier.dart';
import 'niimbot_silence_page.dart';
import 'printer_select_page.dart';

abstract class LabelPrinterSelectPageOld extends ConsumerStatefulWidget {
  final dynamic dataToPrint;

  const LabelPrinterSelectPageOld({
    super.key,
    required this.dataToPrint,
  });

  int get actionScanType => Memory.ACTION_NO_SCAN_ACTION;

  String get pageTitle => 'Label Printer Select';

  String? validateDataToPrint();

  Future<PrintResult> executePrintJob({
    required BuildContext context,
    required WidgetRef ref,
    required LabelProfile profile,
    required bool printSimpleData,
    required PrinterConnConfig selectedPrinter,
    required int copies,
  });

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

  String checkLabelSize(
      WidgetRef ref,
      LabelProfile profile, {
        required bool printSimpleData,
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
      enableDrag: false,
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

  @override
  ConsumerState<LabelPrinterSelectPageOld> createState() =>
      _LabelPrinterSelectPageStateOld();
}

class _LabelPrinterSelectPageStateOld extends ConsumerState<LabelPrinterSelectPageOld>
    with SingleTickerProviderStateMixin {
  final GetStorage box = GetStorage();

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

      final PrinterConnConfig? selectedPrinter = _selectedPrinter();
      if (selectedPrinter != null &&
          selectedPrinter.btAddress != null &&
          selectedPrinter.lang == PrinterState.PRINTER_TYPE_NIIMBOT) {
        if (!mounted) return;
        await widget.goNiimbotPageBottomSheet(
          context,
          ref,
          dataToPrint: widget.dataToPrint,
          bluetoothAddress: selectedPrinter.btAddress!,
          profile: selectedProfileOrDefault50(),
          popScopeAction: () async => popScopeAction(context, ref),
        );
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _loadLabelProfiles() {
    final dynamic raw = box.read(PrinterSelectStorageKeys.labelProfilesList);
    final dynamic selectedId =
    box.read(PrinterSelectStorageKeys.selectedLabelProfileId);

    List<LabelProfile> list = <LabelProfile>[];
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
    final List<LabelProfile> list = ref.read(labelProfilesProvider);
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
    final List<LabelProfile> list = ref.read(labelProfilesProvider);
    final String? id = ref.read(selectedLabelProfileIdProvider);

    final LabelProfile? p = list
        .where((e) => e.id == id)
        .cast<LabelProfile?>()
        .firstWhere((e) => e != null, orElse: () => null);

    return p ?? defaultLabel40x25();
  }

  LabelProfile selectedProfileOrDefault50() {
    final List<LabelProfile> list = ref.read(labelProfilesProvider);
    final String? id = ref.read(selectedLabelProfileIdProvider);

    final LabelProfile? p = list
        .where((e) => e.id == id)
        .cast<LabelProfile?>()
        .firstWhere((e) => e != null, orElse: () => null);

    return p ?? defaultLabel50x30();
  }

  LabelProfile selectedProfileOrDefault60() {
    final List<LabelProfile> list = ref.read(labelProfilesProvider);
    final String? id = ref.read(selectedLabelProfileIdProvider);

    final LabelProfile? p = list
        .where((e) => e.id == id)
        .cast<LabelProfile?>()
        .firstWhere((e) => e != null, orElse: () => null);

    return p ?? defaultLabel60x40();
  }

  Future<void> _editOrCreateProfile({LabelProfile? initial}) async {
    final PrinterInputMode inputModeOld = ref.read(printerInputModeProvider);

    if (inputModeOld == PrinterInputMode.scan) {
      ref.read(printerInputModeProvider.notifier).state =
          PrinterInputMode.manual;
    }

    final LabelProfile? profile = await showLabelConfigBottomSheet(
      context: context,
      initial: initial,
    );

    if (inputModeOld != ref.read(printerInputModeProvider)) {
      ref.read(printerInputModeProvider.notifier).state = inputModeOld;
    }

    if (profile == null) return;

    final List<LabelProfile> list = <LabelProfile>[
      ...ref.read(labelProfilesProvider),
    ];
    final int idx = list.indexWhere((e) => e.id == profile.id);

    if (idx >= 0) {
      list[idx] = profile;
    } else {
      list.add(profile);
    }

    ref.read(labelProfilesProvider.notifier).state = list;
    ref.read(selectedLabelProfileIdProvider.notifier).state = profile.id;
    _saveLabelProfiles();
  }

  void _deleteProfile(LabelProfile profile) {
    if (profile.id.startsWith('default_')) return;

    final List<LabelProfile> list = <LabelProfile>[
      ...ref.read(labelProfilesProvider),
    ];
    list.removeWhere((e) => e.id == profile.id);
    ref.read(labelProfilesProvider.notifier).state = list;

    final String? selected = ref.read(selectedLabelProfileIdProvider);
    if (selected == profile.id) {
      ref.read(selectedLabelProfileIdProvider.notifier).state =
      list.isNotEmpty ? list.first.id : null;
    }

    _saveLabelProfiles();
  }

  void _loadPrintersForHome() {
    final dynamic raw = box.read(PrinterSelectStorageKeys.printersList);
    final dynamic selectedId =
    box.read(PrinterSelectStorageKeys.selectedPrinterId);

    if (raw is String && raw.trim().isNotEmpty) {
      final List<PrinterConnConfig> list = (jsonDecode(raw) as List)
          .map((e) => PrinterConnConfig.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      ref.read(printerListProvider.notifier).state = list;
    }

    if (selectedId is String && selectedId.trim().isNotEmpty) {
      ref.read(selectedPrinterIdProvider.notifier).state = selectedId;
    }
  }

  void _savePrintersToStorageFromHere() {
    final List<PrinterConnConfig> list = ref.read(printerListProvider);
    box.write(
      PrinterSelectStorageKeys.printersList,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );

    final String? selected = ref.read(selectedPrinterIdProvider);
    box.write(PrinterSelectStorageKeys.selectedPrinterId, selected);
  }

  PrinterConnConfig? _selectedPrinter() {
    final List<PrinterConnConfig> list = ref.read(printerListProvider);
    final String? selectedId = ref.read(selectedPrinterIdProvider);
    if (selectedId == null) return null;

    return list
        .where((e) => e.id == selectedId)
        .cast<PrinterConnConfig?>()
        .firstWhere((e) => e != null, orElse: () => null);
  }

  Future<void> showMsg(String title, String msg) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> printLabel({
    required LabelProfile profile,
    required bool printSimpleData,
    required int copies,
  }) async {
    final PrinterConnConfig? printer = _selectedPrinter();
    if (printer == null) {
      await showMsg('Printer', 'Select a printer first.');
      return;
    }

    final String? err = widget.validateDataToPrint();
    if (err != null) {
      await showMsg('Data', err);
      return;
    }

    final LabelProfile p0 = profile;
    final LabelProfile p = LabelProfile(
      id: p0.id,
      name: p0.name,
      copies: copies,
      widthMm: p0.widthMm,
      heightMm: p0.heightMm,
      marginLeftMm: p0.marginLeftMm,
      marginTopMm: p0.marginTopMm,
      barcodeHeightMm: p0.barcodeHeightMm,
      charactersToPrint: p0.charactersToPrint,
      maxCharsPerLine: p0.maxCharsPerLine,
      barcodeHeight: p0.barcodeHeight,
      barcodeWide: p0.barcodeWide,
      barcodeNarrow: p0.barcodeNarrow,
      fontId: p0.fontId,
      gapMm: p0.gapMm,
    );

    ref.read(isPrintingProvider.notifier).state = true;

    final String errorMessage = widget.checkLabelSize(
      ref,
      p,
      printSimpleData: printSimpleData,
    );

    if (errorMessage.isNotEmpty) {
      ref.read(isPrintingProvider.notifier).state = false;
      await showMsg('Profile', errorMessage);
      return;
    }

    try {
      final PrintResult result = await widget.executePrintJob(
        context: context,
        ref: ref,
        profile: p,
        printSimpleData: printSimpleData,
        selectedPrinter: printer,
        copies: copies,
      );

      await showMsg(
        'Print',
        result.success ? '✅ Printed successfully' : '❌ ${result.message}',
      );
    } catch (e) {
      await showMsg('Print', '❌ Error: $e');
    } finally {
      ref.read(isPrintingProvider.notifier).state = false;
    }
  }

  void handleInputString({
    required int actionScan,
    required String inputData,
    required WidgetRef ref,
  }) async {
    final String qrData = inputData.trim();
    if (qrData.isEmpty) return;
    if (actionScan != widget.actionScanType) return;

    bool isNiimbot = false;

    bool isValidLang(String s) {
      final String t = s.trim().toUpperCase();
      return t == PrinterState.PRINTER_TYPE_TSPL ||
          t == 'TPL' ||
          t == PrinterState.PRINTER_TYPE_NIIMBOT ||
          t == 'NIIMBOT';
    }

    String normalizeLang(String s) {
      final String t = s.trim().toUpperCase();
      return t == 'TPL' ? PrinterState.PRINTER_TYPE_TSPL : t;
    }

    bool normalizeBluetoothType(String s) {
      final String btType = s.trim().toUpperCase();
      return btType == PrinterState.PRINTER_TYPE_BLUETOOTH_BLE ||
          btType == PrinterState.PRINTER_TYPE_BLUETOOTH_NO_BLE;
    }

    late final PrinterConnConfig scannedPrinter;

    if (qrData.toUpperCase().startsWith('BLUETOOTH*')) {
      final List<String> parts = qrData.split('*');
      if (parts.length < 5) {
        await showMsg('QR', 'Invalid Bluetooth QR format.\n$qrData');
        return;
      }

      final String name = parts[1].trim();
      if (name.isEmpty) {
        await showMsg('QR', 'Invalid Bluetooth QR format. name\n$qrData');
        return;
      }

      final String btAddress = parts[2].trim();
      if (btAddress.isEmpty) {
        await showMsg('QR', 'Invalid Bluetooth QR format. address\n$qrData');
        return;
      }

      final String lang = parts[3].trim().toUpperCase();
      if (!isValidLang(lang)) {
        await showMsg(
          'Printer',
          'Tipo impresora invalido para configuración de impresora $lang\n$qrData',
        );
        return;
      }

      if (lang == PrinterState.PRINTER_TYPE_NIIMBOT) {
        isNiimbot = true;
      }

      final String bluetoothType = parts[4].trim();
      if (bluetoothType.isEmpty || !normalizeBluetoothType(bluetoothType)) {
        await showMsg('QR', 'Invalid Bluetooth QR format.\n$qrData');
        return;
      }

      scannedPrinter = PrinterConnConfig(
        btAddress: btAddress,
        id: 'bt_$btAddress',
        type: PrinterConnType.bluetooth,
        name: name,
        lang: lang,
        typeText: bluetoothType,
      );
    } else {
      final List<String> parts = qrData.split(':');
      if (parts.length < 3) {
        await showMsg('QR', 'Invalid WiFi QR format.\n$qrData');
        return;
      }

      final String ip = parts[0].trim();
      final int port = int.tryParse(parts[1].trim()) ?? 0;
      final String langRaw = parts[2].trim().toUpperCase();

      if (ip.isEmpty || port <= 0) {
        await showMsg('QR', 'Invalid IP or port.\n$qrData');
        return;
      }

      if (!isValidLang(langRaw)) {
        await showMsg(
          'Printer',
          'Tipo impresora invalido para configuración de impresora.\n$qrData',
        );
        return;
      }

      final String lang = normalizeLang(langRaw);
      final String name =
      (parts.length > 3 && parts[3].trim().isNotEmpty)
          ? parts[3].trim()
          : 'WiFi Printer $ip';

      scannedPrinter = PrinterConnConfig(
        id: 'wifi_${ip}_$port',
        type: PrinterConnType.wifi,
        name: name,
        ip: ip,
        port: port,
        lang: lang,
        typeText: lang,
      );
    }

    final List<PrinterConnConfig> list = <PrinterConnConfig>[
      ...ref.read(printerListProvider),
    ];
    final int idx = list.indexWhere((p) => p.id == scannedPrinter.id);

    if (idx >= 0) {
      list[idx] = scannedPrinter;
    } else {
      list.add(scannedPrinter);
    }

    ref.read(printerListProvider.notifier).state = list;
    ref.read(selectedPrinterIdProvider.notifier).state = scannedPrinter.id;
    _savePrintersToStorageFromHere();

    _tab.index = 0;

    if (isNiimbot) {
      await widget.goNiimbotPageBottomSheet(
        context,
        ref,
        dataToPrint: widget.dataToPrint,
        profile: selectedProfileOrDefault50(),
        bluetoothAddress: scannedPrinter.btAddress!,
        popScopeAction: () async => popScopeAction(context, ref),
      );
    } else {
      await _showPrintOptionsDialog();
    }
  }

  Future<void> _showPrintOptionsDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Print'),
        content: const Text('Choose what to print.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              int copies = ref.read(copiesTempProvider);
              if (copies < 1) copies = 1;

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
              if (copies < 1) copies = 1;

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

  void popScopeAction(BuildContext context, WidgetRef ref) {
    ref.read(actionScanProvider.notifier).state = oldAction;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }


  @override
  Widget build(BuildContext context) {
    final List<LabelProfile> profiles = ref.watch(labelProfilesProvider);
    final String? selectedProfileId = ref.watch(selectedLabelProfileIdProvider);

    final List<PrinterConnConfig> printers = ref.watch(printerListProvider);
    final String? selectedPrinterId = ref.watch(selectedPrinterIdProvider);

    final LabelProfile selectedProfile = profiles.firstWhere(
          (p) => p.id == selectedProfileId,
      orElse: () => defaultLabel40x25(),
    );

    final PrinterConnConfig? selectedPrinter = printers
        .cast<PrinterConnConfig?>()
        .firstWhere((p) => p?.id == selectedPrinterId, orElse: () => null);

    final PrinterInputMode inputMode = ref.watch(printerInputModeProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          widget.pageTitle,
          style: const TextStyle(fontSize: themeFontSizeLarge),
        ),
        actions: <Widget>[
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
          tabs: const <Tab>[
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
          children: <Widget>[
            _buildHomeTab(
              selectedProfile: selectedProfile,
              selectedPrinter: selectedPrinter,
            ),
            _buildProfilesTab(),
            PrinterSelectPage(
              dataToPrint: widget.dataToPrint,
              popOnSelect: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab({
    required LabelProfile selectedProfile,
    required PrinterConnConfig? selectedPrinter,
  }) {
    final List<PrinterConnConfig> printers = ref.watch(printerListProvider);
    final String? selectedPrinterId = ref.watch(selectedPrinterIdProvider);
    final LabelProfile profile40 = selectedProfileOrDefault40();
    final LabelProfile profile60 = selectedProfileOrDefault60();

    final bool isNiimbot =
        selectedPrinter != null &&
            (selectedPrinter.lang ?? '').toUpperCase() == 'NIIMBOT';

    final int copiesTemp = ref.watch(copiesTempProvider);
    final bool isPrinting = ref.read(isPrintingProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
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
          if (isNiimbot) ...<Widget>[
            buildNiimbotConnectCard(ref, selectedPrinter),
          ] else ...<Widget>[
            Row(
              children: <Widget>[
                const SizedBox(
                  width: 120,
                  child: Text('Copies (temp):'),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
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
            const SizedBox(height: 10),
            if (!isPrinting)
              widget.buildPrintingPanel(
                context: context,
                ref: ref,
                selectedPrinter: selectedPrinter,
                profile40: profile40,
                profile60: profile60,
                onPrint: ({
                  required LabelProfile profile,
                  required bool printSimpleData,
                }) {
                  return printLabel(
                    profile: profile,
                    printSimpleData: printSimpleData,
                    copies: copiesTemp,
                  );
                },
              ),
          ],
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text('Saved printers (quick select)'),
            children: <Widget>[
              if (printers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'No printers saved yet. Go to Printers tab to add one.',
                  ),
                )
              else
                ...printers.map((p) {
                  final String subtitle =
                  (p.type == PrinterConnType.wifi)
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
    final List<LabelProfile> profiles = ref.watch(labelProfilesProvider);
    final String? selectedProfileId = ref.watch(selectedLabelProfileIdProvider);

    return SafeArea(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Label profiles',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                final LabelProfile profile = profiles[i];

                return Card(
                  child: ListTile(
                    leading: Radio<String>(
                      value: profile.id,
                      groupValue: selectedProfileId,
                      onChanged: (v) {
                        ref.read(selectedLabelProfileIdProvider.notifier).state =
                            v;
                        _saveLabelProfiles();
                      },
                    ),
                    title: Text(profile.name),
                    subtitle: Text(
                      '${profile.widthMm}x${profile.heightMm}mm  copies:${profile.copies}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editOrCreateProfile(initial: profile),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProfile(profile),
                        ),
                      ],
                    ),
                    onTap: () {
                      ref.read(selectedLabelProfileIdProvider.notifier).state =
                          profile.id;
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

  Widget buildNiimbotConnectCard(
      WidgetRef ref,
      PrinterConnConfig selectedPrinter,
      ) {
    LabelProfile getSelectedProfile() {
      final List<LabelProfile> profiles = ref.read(labelProfilesProvider);
      final String? selectedId = ref.read(selectedLabelProfileIdProvider);

      if (selectedId == null) {
        return defaultLabel40x25();
      }

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
          children: <Widget>[
            const Text(
              'NIIMBOT BLUETOOTH PRINTER',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                widget.goNiimbotPageBottomSheet(
                  context,
                  ref,
                  dataToPrint: widget.dataToPrint,
                  profile: getSelectedProfile(),
                  bluetoothAddress: selectedPrinter.btAddress ?? '',
                  popScopeAction: () async => popScopeAction(context, ref),
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
    final LabelProfile? initial = widget.initial;

    nameC = TextEditingController(text: initial?.name ?? 'New Label');
    copiesC = TextEditingController(text: '${initial?.copies ?? 1}');
    wC = TextEditingController(text: '${initial?.widthMm ?? 40}');
    hC = TextEditingController(text: '${initial?.heightMm ?? 25}');
    mxC = TextEditingController(text: '${initial?.marginLeftMm ?? 2}');
    myC = TextEditingController(text: '${initial?.marginTopMm ?? 2}');
    bhC = TextEditingController(text: '${initial?.barcodeHeightMm ?? 12}');
    chC = TextEditingController(text: '${initial?.charactersToPrint ?? 0}');
    maxCh = TextEditingController(text: '${initial?.maxCharsPerLine ?? 0}');
    barcodeW = TextEditingController(text: '${initial?.barcodeWide ?? 0}');
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
    final BuildContext sheetContext = context;

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
              children: <Widget>[
                const Text(
                  'Label Config',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                  children: <Widget>[
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
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final LabelProfile? initial = widget.initial;
                        final String id =
                            initial?.id ??
                                'custom_${DateTime.now().millisecondsSinceEpoch}';

                        final LabelProfile profile = LabelProfile(
                          id: id,
                          name: nameC.text.trim().isEmpty
                              ? 'Label'
                              : nameC.text.trim(),
                          copies: int.tryParse(copiesC.text.trim()) ?? 1,
                          widthMm: double.tryParse(wC.text.trim()) ?? 40,
                          heightMm: double.tryParse(hC.text.trim()) ?? 25,
                          marginLeftMm: double.tryParse(mxC.text.trim()) ?? 2,
                          marginTopMm: double.tryParse(myC.text.trim()) ?? 2,
                          barcodeHeightMm:
                          int.tryParse(bhC.text.trim()) ?? 12,
                          charactersToPrint:
                          int.tryParse(chC.text.trim()) ?? 0,
                          maxCharsPerLine:
                          int.tryParse(maxCh.text.trim()) ?? 0,
                          barcodeHeight:
                          int.tryParse(barcodeH.text.trim()) ?? 80,
                          barcodeWide:
                          int.tryParse(barcodeW.text.trim()) ?? 3,
                          barcodeNarrow:
                          int.tryParse(barcodeN.text.trim()) ?? 2,
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