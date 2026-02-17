

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../shared/data/messages.dart';
import '../presentation/providers/product_provider_common.dart';

class ScanButtonByActionFixedShort2 extends ConsumerStatefulWidget {
  final int actionTypeInt;
  final Color? color;

  /// Button label (default: "SCAN")
  final String label;

  /// Optional custom action (OCR dialog / custom scan flow).
  final Future<String?> Function(BuildContext context, WidgetRef ref)? customAction;

  /// Callback fired when we have a non-empty result.
  final void Function({
  required WidgetRef ref,
  required String inputData,
  required int actionScan,
  }) onOk;

  const ScanButtonByActionFixedShort2({
    super.key,
    required this.actionTypeInt,
    required this.onOk,
    this.color,
    this.label = 'SCAN',
    this.customAction,
  });

  @override
  ConsumerState<ScanButtonByActionFixedShort2> createState() =>
      _ScanButtonByActionFixedShort2State();
}

class _ScanButtonByActionFixedShort2State
    extends ConsumerState<ScanButtonByActionFixedShort2> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'ScanButtonFocus');
  String _buffer = '';

  bool _disposed = false;

  // If we used a tap to restore focus, consume that press so it doesn't open scanner.
  bool _consumeNextPress = false;
  DateTime? _lastFocusRequest;

  bool _isPrimaryFocus() => FocusManager.instance.primaryFocus == _focusNode;

  @override
  void initState() {
    super.initState();
    // No autofocus here; we only request focus when needed.
  }

  @override
  void dispose() {
    _disposed = true;
    _focusNode.dispose();
    super.dispose();
  }

  // Runs BEFORE TextButton.onPressed
  void _handlePointerDown(PointerDownEvent e) {
    if (!_isPrimaryFocus()) {
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
        _consumeNextPress = true;
        _lastFocusRequest = DateTime.now();
      }
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    // Block keyboard-scanner input if scanning or dialog open
    final isDialogShowed = ref.read(isDialogShowedProvider);
    final isScanning = ref.read(isScanningProvider);
    if (isScanning || isDialogShowed) return KeyEventResult.ignored;

    // Only handle key-down
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Finish on Enter
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final payload = _buffer.trim();
      _buffer = '';

      if (payload.isNotEmpty && mounted && !_disposed) {
        widget.onOk(
          ref: ref,
          inputData: payload,
          actionScan: widget.actionTypeInt,
        );
      }
      return KeyEventResult.handled;
    }

    // Accumulate characters (USB/BT scanner acts like keyboard)
    final ch = event.character;
    if (ch != null && ch.isNotEmpty) {
      _buffer += ch;
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _runPressedAction() async {
    ref.read(isScanningProvider.notifier).state = true;

    try {
      String? result;

      if (widget.customAction != null) {
        result = await widget.customAction!(context, ref);
      } else {
        result = await SimpleBarcodeScanner.scanBarcode(
          context,
          barcodeAppBar: BarcodeAppBar(
            appBarTitle: Messages.SCANNING,
            centerTitle: false,
            enableBackButton: true,
            backButtonIcon: const Icon(Icons.arrow_back_ios),
          ),
          isShowFlashIcon: true,
          delayMillis: 300,
          cameraFace: CameraFace.back,
        );
      }

      if (!mounted || _disposed) return;

      result = result?.trim();
      if (result != null && result.isNotEmpty) {
        widget.onOk(
          ref: ref,
          inputData: result,
          actionScan: widget.actionTypeInt,
        );
      }
    } catch (_) {
      if (!mounted || _disposed) return;
      showErrorMessage(context, ref, Messages.ERROR_SCANNING);
    } finally {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted || _disposed) return;

      ref.read(isScanningProvider.notifier).state = false;

      // Restore focus safely after camera/dialog closes
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    }
  }

  Future<void> _onPressed() async {
    // If this tap was only to restore focus, do nothing.
    if (_consumeNextPress) {
      _consumeNextPress = false;
      return;
    }

    // Extra guard: if focus was requested very recently, ignore.
    final now = DateTime.now();
    if (_lastFocusRequest != null &&
        now.difference(_lastFocusRequest!) < const Duration(milliseconds: 250)) {
      return;
    }

    await _runPressedAction();
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = ref.watch(isScanningProvider);

    return Listener(
      onPointerDown: _handlePointerDown, // ✅ focus-first without triggering scan
      child: Focus(
        autofocus: false,
        focusNode: _focusNode,
        onKeyEvent: _onKeyEvent,
        child: TextButton(
          onPressed: _onPressed,
          style: TextButton.styleFrom(
            backgroundColor: _focusNode.hasFocus
                ? (widget.color ?? themeColorPrimary)
                : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(60, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(
            isScanning ? '...' : widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: themeFontSizeSmall,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
