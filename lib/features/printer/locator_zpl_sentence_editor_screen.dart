import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common_provider.dart';

class LocatorZplSentenceEditorScreen extends ConsumerStatefulWidget {
  final String sentence;
  final FocusNode focusNode;

  const LocatorZplSentenceEditorScreen({
    super.key,
    required this.sentence,
    required this.focusNode,
  });

  @override
  ConsumerState<LocatorZplSentenceEditorScreen> createState() =>
      _LocatorZplSentenceEditorScreenState();
}

class _LocatorZplSentenceEditorScreenState
    extends ConsumerState<LocatorZplSentenceEditorScreen> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.sentence);

    // Si querés: al entrar, desactivar scanner y evitar key events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enableScannerKeyboardProvider.notifier).state = false;
      widget.focusNode.unfocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _restoreScannerKeyboard() {
    ref.read(enableScannerKeyboardProvider.notifier).state = true;
    widget.focusNode.requestFocus();
  }

  void _send() {
    final txt = _ctrl.text.trim();
    _restoreScannerKeyboard();
    if (context.mounted) context.pop(txt);
  }

  void _cancel() {
    _restoreScannerKeyboard();
    if (context.mounted) context.pop(null);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        // Si el user vuelve atrás por sistema, restauramos igual
        if (didPop) {
          _restoreScannerKeyboard();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Send template to printer'),
          actions: [
            TextButton(
              onPressed: _send,
              child: const Text(
                'SEND',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              maxLines: 14,
              decoration: const InputDecoration(
                labelText: 'Create sentence to send',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
            ),
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
}
