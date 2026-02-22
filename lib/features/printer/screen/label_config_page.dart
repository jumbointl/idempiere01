// ===============================
// label_config_page.dart
// ===============================
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';

import 'package:monalisa_app_001/features/products/domain/models/label_profile.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common_provider.dart';
import '../models/printer_select_models.dart';

// If you already have a confirm dialog helper, keep using it.
// Otherwise, this file includes a small confirm dialog.
class LabelConfigPage extends ConsumerStatefulWidget {
  /// If true, pops returning the currently selected LabelProfile.
  final bool popWithSelectedProfile;

  const LabelConfigPage({
    super.key,
    this.popWithSelectedProfile = true,
  });

  @override
  ConsumerState<LabelConfigPage> createState() => _LabelConfigPageState();
}

class _LabelConfigPageState extends ConsumerState<LabelConfigPage> {
  final _box = GetStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLabelProfiles();
    });
  }

  LabelProfile _defaultProfile() {
    return const LabelProfile(
      id: 'default',
      name: 'Default',
      copies: 1,
      widthMm: 50,
      heightMm: 30,
      marginXmm: 2,
      marginYmm: 2,
      barcodeHeightMm: 12,
      charactersToPrint: 0,
      maxCharsPerLine: 22,
      barcodeHeight: 96,
      barcodeWidth: 3,
      barcodeNarrow: 2,
      fontId: 2,
      gapMm: 2,
    );
  }

  void _loadLabelProfiles() {
    try {
      final raw = _box.read(PrinterSelectStorageKeys.labelProfilesList);
      final selectedId = _box.read(PrinterSelectStorageKeys.selectedLabelProfileId);

      List<LabelProfile> parsed = <LabelProfile>[];
      if (raw is String && raw.trim().isNotEmpty) {
        final arr = jsonDecode(raw);
        if (arr is List) {
          parsed = arr
              .whereType<Map>()
              .map((m) => LabelProfile.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        }
      }

      if (parsed.isEmpty) {
        parsed = [_defaultProfile()];
      }

      ref.read(labelProfilesProvider.notifier).state = parsed;

      final exists = parsed.any((p) => p.id == selectedId);
      ref.read(selectedLabelProfileIdProvider.notifier).state =
      (selectedId is String && exists) ? selectedId : parsed.first.id;

      _saveLabelProfiles();
    } catch (_) {
      final fallback = [_defaultProfile()];
      ref.read(labelProfilesProvider.notifier).state = fallback;
      ref.read(selectedLabelProfileIdProvider.notifier).state = fallback.first.id;
      _saveLabelProfiles();
    }
  }

  void _saveLabelProfiles() {
    final profiles = ref.read(labelProfilesProvider);
    final selectedId = ref.read(selectedLabelProfileIdProvider);

    _box.write(
      PrinterSelectStorageKeys.labelProfilesList,
      jsonEncode(profiles.map((e) => e.toJson()).toList()),
    );
    _box.write(PrinterSelectStorageKeys.selectedLabelProfileId, selectedId);
  }

  LabelProfile? _getSelectedProfile() {
    final profiles = ref.read(labelProfilesProvider);
    final selectedId = ref.read(selectedLabelProfileIdProvider);

    for (final p in profiles) {
      if (p.id == selectedId) return p;
    }
    return profiles.isNotEmpty ? profiles.first : null;
  }

  Future<void> _editOrCreateProfile({LabelProfile? initial}) async {
    final result = await showLabelConfigBottomSheet(
      context: context,
      initial: initial,
    );

    if (!mounted) return;
    if (result == null) return;

    final profiles = [...ref.read(labelProfilesProvider)];
    final idx = profiles.indexWhere((p) => p.id == result.id);

    if (idx >= 0) {
      profiles[idx] = result;
    } else {
      profiles.add(result);
    }

    ref.read(labelProfilesProvider.notifier).state = profiles;

    // If there is no selection yet, select the new/edited one
    ref.read(selectedLabelProfileIdProvider.notifier).state = result.id;

    _saveLabelProfiles();
    setState(() {});
  }

  Future<void> _deleteProfile(LabelProfile p) async {
    final profiles = ref.read(labelProfilesProvider);
    if (profiles.length <= 1) {
      // Keep at least one profile
      await _showInfo('Cannot delete', 'You must keep at least one profile.');
      return;
    }

    final ok = await _confirmDialog(
      title: 'Delete profile?',
      message: 'Delete "${p.name}"?',
      okText: 'Delete',
      cancelText: 'Cancel',
    );
    if (!ok) return;
    if (!mounted) return;

    final updated = [...ref.read(labelProfilesProvider)]..removeWhere((x) => x.id == p.id);
    ref.read(labelProfilesProvider.notifier).state = updated;

    final selectedId = ref.read(selectedLabelProfileIdProvider);
    if (selectedId == p.id) {
      ref.read(selectedLabelProfileIdProvider.notifier).state = updated.first.id;
    }

    _saveLabelProfiles();
    setState(() {});
  }

  Future<void> _showInfo(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    String okText = 'OK',
    String cancelText = 'Cancel',
  }) async {
    if (!mounted) return false;
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelText)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(okText)),
        ],
      ),
    );
    return res ?? false;
  }

  void _pop() {
    if (!widget.popWithSelectedProfile) {
      Navigator.pop(context);
      return;
    }
    final selected = _getSelectedProfile();
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(labelProfilesProvider);
    final selectedProfileId = ref.watch(selectedLabelProfileIdProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Label Config'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _pop,
          ),
          actions: [
            IconButton(
              onPressed: () => _editOrCreateProfile(),
              icon: const Icon(Icons.add),
              tooltip: 'Add profile',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
        ),
      ),
    );
  }
}

// ------------------------------
// Bottom sheet: LabelProfile editor
// (adapt this to match your existing fields/validation)
// ------------------------------
Future<LabelProfile?> showLabelConfigBottomSheet({
  required BuildContext context,
  LabelProfile? initial,
}) async {
  return showModalBottomSheet<LabelProfile?>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _LabelProfileEditorSheet(initial: initial),
  );
}

class _LabelProfileEditorSheet extends StatefulWidget {
  final LabelProfile? initial;
  const _LabelProfileEditorSheet({this.initial});

  @override
  State<_LabelProfileEditorSheet> createState() => _LabelProfileEditorSheetState();
}

class _LabelProfileEditorSheetState extends State<_LabelProfileEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _copies;
  late final TextEditingController _widthMm;
  late final TextEditingController _heightMm;
  late final TextEditingController _marginXmm;
  late final TextEditingController _marginYmm;
  late final TextEditingController _barcodeHeightMm;
  late final TextEditingController _charactersToPrint;
  late final TextEditingController _maxCharsPerLine;
  late final TextEditingController _barcodeHeight;
  late final TextEditingController _barcodeWidth;
  late final TextEditingController _barcodeNarrow;
  late final TextEditingController _fontId;
  late final TextEditingController _gapMm;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;

    _name = TextEditingController(text: p?.name ?? 'New profile');
    _copies = TextEditingController(text: '${p?.copies ?? 1}');
    _widthMm = TextEditingController(text: '${p?.widthMm ?? 50}');
    _heightMm = TextEditingController(text: '${p?.heightMm ?? 30}');
    _marginXmm = TextEditingController(text: '${p?.marginXmm ?? 2}');
    _marginYmm = TextEditingController(text: '${p?.marginYmm ?? 2}');
    _barcodeHeightMm = TextEditingController(text: '${p?.barcodeHeightMm ?? 12}');
    _charactersToPrint = TextEditingController(text: '${p?.charactersToPrint ?? 0}');
    _maxCharsPerLine = TextEditingController(text: '${p?.maxCharsPerLine ?? 22}');
    _barcodeHeight = TextEditingController(text: '${p?.barcodeHeight ?? 96}');
    _barcodeWidth = TextEditingController(text: '${p?.barcodeWidth ?? 3}');
    _barcodeNarrow = TextEditingController(text: '${p?.barcodeNarrow ?? 2}');
    _fontId = TextEditingController(text: '${p?.fontId ?? 2}');
    _gapMm = TextEditingController(text: '${p?.gapMm ?? 2}');
  }

  @override
  void dispose() {
    _name.dispose();
    _copies.dispose();
    _widthMm.dispose();
    _heightMm.dispose();
    _marginXmm.dispose();
    _marginYmm.dispose();
    _barcodeHeightMm.dispose();
    _charactersToPrint.dispose();
    _maxCharsPerLine.dispose();
    _barcodeHeight.dispose();
    _barcodeWidth.dispose();
    _barcodeNarrow.dispose();
    _fontId.dispose();
    _gapMm.dispose();
    super.dispose();
  }

  int _toInt(String s, {required int fallback}) => int.tryParse(s.trim()) ?? fallback;
  double _toDouble(String s, {required double fallback}) => double.tryParse(s.trim()) ?? fallback;

  void _save() {
    final name = _name.text.trim().isEmpty ? 'Profile' : _name.text.trim();

    final copies = _toInt(_copies.text, fallback: 1);
    final widthMm = _toDouble(_widthMm.text, fallback: 50);
    final heightMm = _toDouble(_heightMm.text, fallback: 30);

    final marginXmm = _toDouble(_marginXmm.text, fallback: 2);
    final marginYmm = _toDouble(_marginYmm.text, fallback: 2);

    final barcodeHeightMm = _toInt(_barcodeHeightMm.text, fallback: 12);
    final charactersToPrint = _toInt(_charactersToPrint.text, fallback: 0);
    final maxCharsPerLine = _toInt(_maxCharsPerLine.text, fallback: 22);

    final barcodeHeight = _toInt(_barcodeHeight.text, fallback: 96);
    final barcodeWidth = _toInt(_barcodeWidth.text, fallback: 3);
    final barcodeNarrow = _toInt(_barcodeNarrow.text, fallback: 2);
    final fontId = _toInt(_fontId.text, fallback: 2);

    final gapMm = _toInt(_gapMm.text, fallback: 2);

    final id = widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();

    final profile = LabelProfile(
      id: id,
      name: name,
      copies: copies < 1 ? 1 : copies,
      widthMm: widthMm <= 0 ? 50 : widthMm,
      heightMm: heightMm <= 0 ? 30 : heightMm,
      marginXmm: marginXmm < 0 ? 0 : marginXmm,
      marginYmm: marginYmm < 0 ? 0 : marginYmm,
      barcodeHeightMm: barcodeHeightMm <= 0 ? 12 : barcodeHeightMm,
      charactersToPrint: charactersToPrint < 0 ? 0 : charactersToPrint,
      maxCharsPerLine: maxCharsPerLine <= 0 ? 22 : maxCharsPerLine,
      barcodeHeight: barcodeHeight <= 0 ? 96 : barcodeHeight,
      barcodeWidth: barcodeWidth <= 0 ? 3 : barcodeWidth,
      barcodeNarrow: barcodeNarrow <= 0 ? 2 : barcodeNarrow,
      fontId: fontId <= 0 ? 2 : fontId,
      gapMm: gapMm < 0 ? 0 : gapMm,
    );

    Navigator.pop(context, profile);
  }

  Widget _field(String label, TextEditingController c, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        keyboardType: keyboardType ?? TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Edit label profile',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              _field('Name', _name),
              _field('Copies', _copies, keyboardType: TextInputType.number),
              Row(
                children: [
                  Expanded(child: _field('Width (mm)', _widthMm, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _field('Height (mm)', _heightMm, keyboardType: TextInputType.number)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field('Margin X (mm)', _marginXmm, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _field('Margin Y (mm)', _marginYmm, keyboardType: TextInputType.number)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field('Barcode height (mm)', _barcodeHeightMm, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _field('Gap (mm)', _gapMm, keyboardType: TextInputType.number)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field('Chars to print (0=full)', _charactersToPrint, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _field('Max chars per line', _maxCharsPerLine, keyboardType: TextInputType.number)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field('BarcodeHeight (px)', _barcodeHeight, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _field('BarcodeWidth', _barcodeWidth, keyboardType: TextInputType.number)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field('BarcodeNarrow', _barcodeNarrow, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _field('FontId', _fontId, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
