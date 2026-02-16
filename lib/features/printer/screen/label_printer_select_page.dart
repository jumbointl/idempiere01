import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../products/domain/idempiere/idempiere_product.dart';
import '../../products/presentation/providers/product_provider_common.dart';
import '../../shared/data/memory.dart';
import '../models/printer_select_models.dart';
import 'printer_select_page.dart';

final labelProfilesProvider = StateProvider<List<LabelProfile>>((ref) => []);
final selectedLabelProfileIdProvider = StateProvider<String?>((ref) => null);

class LabelPrinterSelectPage extends PrinterSelectPage {

  const LabelPrinterSelectPage({super.key, required super.dataToPrint});

  @override
  ConsumerState<PrinterSelectPage> createState() =>
      _LabelPrinterSelectPageState();
}

class _LabelPrinterSelectPageState extends ConsumerState<PrinterSelectPage> {
  final box = GetStorage();
  final int actionScanType = Memory.ACTION_FIND_PRINTER_BY_QR_WIFI;
  late final int oldAction;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLabelProfiles();
      oldAction = ref.read(actionScanProvider);
      ref.read(actionScanProvider.notifier).state = actionScanType;
    });
  }


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

  LabelProfile _getSelectedProfileOrDefault40() {
    final list = ref.read(labelProfilesProvider);
    final id = ref.read(selectedLabelProfileIdProvider);

    final p = list
        .where((e) => e.id == id)
        .cast<LabelProfile?>()
        .firstWhere((e) => e != null, orElse: () => null);

    debugPrint('selected profile: ${p?.toJson() ?? 'null'}');
    return p ?? defaultLabel40x25();
  }
  LabelProfile _getSelectedProfileOrDefault60() {
    final list = ref.read(labelProfilesProvider);
    final id = ref.read(selectedLabelProfileIdProvider);

    final p = list
        .where((e) => e.id == id)
        .cast<LabelProfile?>()
        .firstWhere((e) => e != null, orElse: () => null);
    debugPrint('selected profile: ${p?.toJson() ?? 'null'}');
    return p ?? defaultLabel60x40();
  }

  Future<void> _editOrCreateProfile({LabelProfile? initial}) async {
    final profile = await showLabelConfigBottomSheet(context: context, initial: initial);
    if (profile == null) return;
    debugPrint('profile: ${profile.toJson()}');

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

  PrinterConnConfig? _selectedPrinter() {
    final list = ref.read(printerListProvider);
    final selectedId = ref.read(selectedPrinterIdProvider);
    if (selectedId == null) return null;
    return list
        .where((e) => e.id == selectedId)
        .cast<PrinterConnConfig?>()
        .firstWhere((e) => e != null, orElse: () => null);
  }

  Future<void> _disconnectSafe() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {}
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
    late final tspl ;
    if(profile.widthMm<=50){
      tspl = buildTsplProductLabelSmall(
        upc: upc,
        sku: sku,
        profile: profile,
      );
    } else {
      tspl = buildTsplProductLabel(
        upc: upc,
        sku: sku,
        name: name,
        profile: profile,
      );
    }


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

  Future<void> sendTsplViaWifi({
    required String ip,
    required int port,
    required String tspl,
  }) async {
    final socket =
    await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
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

    // Avoid stuck connections
    final already = await PrintBluetoothThermal.connectionStatus;
    if (already) {
      await _disconnectSafe();
      await Future.delayed(const Duration(milliseconds: 120));
    }

    final connected = await PrintBluetoothThermal.connect(
      macPrinterAddress: mac,
    );
    if (!connected) {
      throw Exception('No se pudo conectar por Bluetooth: $mac');
    }

    // Small delay helps some printers
    await Future.delayed(const Duration(milliseconds: 150));
    final bytes = utf8.encode(tspl).toList();
    final ok = await PrintBluetoothThermal.writeBytes(
      bytes, // List<int>
    );

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

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(labelProfilesProvider);
    final selectedProfileId = ref.watch(selectedLabelProfileIdProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Label Printer Select'),
      ),
      body: PopScope(
        canPop: true, // ✅ deja que el sistema haga pop si hay stack
        onPopInvokedWithResult: (didPop, result) {
          // English: If the route already popped, do nothing.
          if (didPop) return;

          popScopeAction(context, ref);
        },
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
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

              SizedBox(
                height: 220,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: profiles.length,
                  itemBuilder: (_, i) {
                    final p = profiles[i];
                    return Card(
                      child: ListTile(
                        leading: Radio<String>(
                          value: p.id,
                          groupValue: selectedProfileId,
                          onChanged: (v) {
                            ref.read(selectedLabelProfileIdProvider.notifier).state =
                                v;
                            _saveLabelProfiles();
                          },
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                          '${p.widthMm}x${p.heightMm}mm  copies:${p.copies}  margin:${p.marginXmm}/${p.marginYmm}  barcodeH:${p.barcodeHeightMm}mm  chars:${p.charactersToPrint} maxCharPerLine:${p.maxCharsPerLine}',
                        ),
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
                          ref.read(selectedLabelProfileIdProvider.notifier).state =
                              p.id;
                          _saveLabelProfiles();
                        },
                      ),
                    );
                  },
                ),
              ),

              const Divider(),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final base = _getSelectedProfileOrDefault40();
                          /*final p = base.copyWith(
                            widthMm: 40,
                            heightMm: 25,
                            marginXmm: 2,
                            marginYmm: 2,
                            maxCharsPerLine: 22,
                            barcodeHeight: 96,
                            barcodeWidth: 3,
                            barcodeNarrow: 2,
                            barcodeHeightMm: 12,
                            fontId: 1,
                          );*/
                          await _printLabel(profile: base);
                        },
                        child: const Text('Print 40x25'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final base = _getSelectedProfileOrDefault60();
                          /*final p = base.copyWith(
                            widthMm: 60,
                            heightMm: 40,
                            marginXmm: 2,
                            marginYmm: 2,

                          );*/
                          await _printLabel(profile: base);
                        },
                        child: const Text('Print 60x40'),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              Expanded(
                child: PrinterSelectPage(dataToPrint: widget.dataToPrint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void popScopeAction(BuildContext context, WidgetRef ref) {
    ref.read(actionScanProvider.notifier).state = oldAction;
    Navigator.pop(context);

  }
}

extension _LabelProfileCopy on LabelProfile {
  LabelProfile copyWith({
    String? id,
    String? name,
    int? copies,
    double? widthMm,
    double? heightMm,
    double? marginXmm,
    double? marginYmm,
    int? barcodeHeightMm,
    int? charactersToPrint,
    int? maxCharsPerLine,
    int? barcodeHeight,
    int? barcodeWidth,
    int? barcodeNarrow,
    int? fontId,
    int? gapMm,
  }) {
    return LabelProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      copies: copies ?? this.copies,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      marginXmm: marginXmm ?? this.marginXmm,
      marginYmm: marginYmm ?? this.marginYmm,
      barcodeHeightMm: barcodeHeightMm ?? this.barcodeHeightMm,
      charactersToPrint: charactersToPrint ?? this.charactersToPrint,
      maxCharsPerLine: maxCharsPerLine ?? this.maxCharsPerLine,
      barcodeHeight: barcodeHeight ?? this.barcodeHeight,
      barcodeWidth: barcodeWidth ?? this.barcodeWidth,
      barcodeNarrow: barcodeNarrow ?? this.barcodeNarrow,
      fontId: fontId ?? this.fontId,
      gapMm: gapMm ?? this.gapMm,

    );
  }
}

Future<LabelProfile?> showLabelConfigBottomSheet({
  required BuildContext context,
  LabelProfile? initial,
}) async {
  return showModalBottomSheet<LabelProfile>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final nameC = TextEditingController(text: initial?.name ?? 'New Label');
      final copiesC = TextEditingController(text: '${initial?.copies ?? 1}');
      final wC = TextEditingController(text: '${initial?.widthMm ?? 40}');
      final hC = TextEditingController(text: '${initial?.heightMm ?? 25}');
      final mxC = TextEditingController(text: '${initial?.marginXmm ?? 2}');
      final myC = TextEditingController(text: '${initial?.marginYmm ?? 2}');
      final bhC = TextEditingController(text: '${initial?.barcodeHeightMm ?? 12}');
      final chC = TextEditingController(text: '${initial?.charactersToPrint ?? 0}');
      final maxCh = TextEditingController(text: '${initial?.maxCharsPerLine ?? 0}');
      final barcodeW = TextEditingController(text: '${initial?.barcodeWidth ?? 0}');
      final barcodeN = TextEditingController(text: '${initial?.barcodeNarrow ?? 0}');
      final barcodeH = TextEditingController(text: '${initial?.barcodeHeight ?? 0}');
      final fontIdC = TextEditingController(text: '${initial?.fontId ?? 0}');
      final gapC = TextEditingController(text: '${initial?.gapMm ?? 0}');

      // Dispose when the sheet is popped
      void disposeAll() {
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
      }

      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          // English: If the route already popped, do nothing.
          if (didPop) disposeAll();
        },
        child: Padding(
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
                    const Text('Label Config',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name')),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _field(copiesC, 'Copies'),
                        _field(gapC, 'Gap (mm)'),
                        _field(wC, 'Width (mm)'),
                        _field(hC, 'Height (mm)'),
                        _field(mxC, 'Margin X (mm)'),
                        _field(myC, 'Margin Y (mm)'),
                        _field(bhC, 'Barcode height (mm)'),
                        _field(barcodeH, 'Barcode Height (dot)'),
                        _field(barcodeW, 'Barcode wide'),
                        _field(barcodeN, 'Barcode narrow'),
                        _field(chC, 'charactersToPrint'),
                        _field(maxCh, 'maxCharacterPerLine'),
                        _field(fontIdC, 'Font Id'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            disposeAll();
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
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
                              fontId: int.tryParse(fontIdC.text.trim()) ?? 1,
                              gapMm: int.tryParse(gapC.text.trim()) ?? 2,
                            );

                            disposeAll();
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
        ),
      );
    },
  );
}

Widget _field(TextEditingController controller, String label) {
  return SizedBox(
    width: 160,
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    ),
  );
}




