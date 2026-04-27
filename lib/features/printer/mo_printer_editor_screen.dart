import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisapy_features/printer/helpers/printer_utils.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common_provider.dart';
// Ajustá el import donde tengas savedPrintersProvider:

import 'package:monalisapy_features/printer/models/mo_printer.dart'; // si ahí está el provider
// o el archivo donde realmente vive: savedPrintersProvider

class MoPrinterEditorScreen extends ConsumerStatefulWidget {
  final MOPrinter? initial;
  final FocusNode focusNode;

  const MoPrinterEditorScreen({
    super.key,
    required this.focusNode,
    this.initial,
  });

  @override
  ConsumerState<MoPrinterEditorScreen> createState() => _MoPrinterEditorScreenState();
}

class _MoPrinterEditorScreenState extends ConsumerState<MoPrinterEditorScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ipCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _typeCtrl;
  late final TextEditingController _serverIpCtrl;
  late final TextEditingController _serverPortCtrl;

  bool _noDelete = false;

  @override
  void initState() {
    super.initState();

    final init = widget.initial;
    _nameCtrl = TextEditingController(text: init?.name ?? '');
    _ipCtrl = TextEditingController(text: init?.ip ?? '');
    _portCtrl = TextEditingController(text: init?.port ?? '');
    _typeCtrl = TextEditingController(text: init?.type ?? '');
    _serverIpCtrl = TextEditingController(text: init?.serverIp ?? '');
    _serverPortCtrl = TextEditingController(text: init?.serverPort ?? '');
    _noDelete = init?.noDelete ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enableScannerKeyboardProvider.notifier).state = false;
      widget.focusNode.unfocus();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _typeCtrl.dispose();
    _serverIpCtrl.dispose();
    _serverPortCtrl.dispose();
    super.dispose();
  }

  void _restoreScannerKeyboard() {
    ref.read(enableScannerKeyboardProvider.notifier).state = true;
    widget.focusNode.requestFocus();
  }

  MOPrinter _buildPrinterFromFields() {
    return MOPrinter(
      name: _nameCtrl.text.trim(),
      ip: _ipCtrl.text.trim(),
      port: _portCtrl.text.trim(),
      type: _typeCtrl.text.trim(),
      serverIp: _serverIpCtrl.text.trim(),
      serverPort: _serverPortCtrl.text.trim(),
      noDelete: _noDelete,
    );
  }

  bool _isValid(MOPrinter p) {
    if ((p.ip ?? '').trim().isEmpty) return false;
    if ((p.port ?? '').trim().isEmpty) return false;
    if ((p.type ?? '').trim().isEmpty) return false;
    return true;
  }

  void _send() {
    final p = _buildPrinterFromFields();
    if (!_isValid(p)) {
      // No uso dialogs tuyos aquí para mantenerlo plug&play
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IP/Port/Type son obligatorios')),
      );
      return;
    }
    _restoreScannerKeyboard();
    if (context.mounted) context.pop(p);
  }

  void _cancel() {
    _restoreScannerKeyboard();
    if (context.mounted) context.pop(null);
  }

  void _applySavedPrinter(MOPrinter p) {
    setState(() {
      _nameCtrl.text = p.name ?? '';
      _ipCtrl.text = p.ip ?? '';
      _portCtrl.text = p.port ?? '';
      _typeCtrl.text = p.type ?? '';
      _serverIpCtrl.text = p.serverIp ?? '';
      _serverPortCtrl.text = p.serverPort ?? '';
      _noDelete = p.noDelete ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedPrintersProvider); // List<MOPrinter>

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) _restoreScannerKeyboard();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Printer editor'),
          actions: [
            TextButton(
              onPressed: _send,
              child: const Text('SEND', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ====== Editor ======
                _field(_nameCtrl, label: 'Name'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _field(_ipCtrl, label: 'IP')),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: _field(_portCtrl, label: 'Port', keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _field(_typeCtrl, label: 'Type (ZPL/TSPL/POS/etc)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _field(_serverIpCtrl, label: 'Server IP (optional)')),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: _field(_serverPortCtrl, label: 'Server Port', keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _noDelete,
                  onChanged: (v) => setState(() => _noDelete = v),
                  title: const Text('Pinned (noDelete)'),
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 12),
                const Divider(),

                // ====== Lista guardada ======
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Saved printers',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${saved.length}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (saved.isEmpty)
                  const Text('No hay impresoras guardadas.'),

                if (saved.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: saved.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final p = saved[i];
                      final title = (p.name != null && p.name!.trim().isNotEmpty)
                          ? p.name!
                          : '${p.ip ?? ''}:${p.port ?? ''}';

                      return Card(
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            (p.noDelete ?? false) ? Icons.star : Icons.print,
                            color: (p.noDelete ?? false) ? Colors.green : Colors.black54,
                          ),
                          title: Text(title, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${p.ip ?? ''}:${p.port ?? ''}  [${p.type ?? ''}]',
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _applySavedPrinter(p),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColorPrimary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _send,
                    child: const Text('Send'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl, {
        required String label,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}