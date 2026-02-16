import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../shared/data/messages.dart';
import '../presentation/providers/product_provider_common.dart';

class ScanButtonByActionFixedShort extends ConsumerStatefulWidget {
  final int actionTypeInt;
  final Color? color;

  /// English: Button label (default: "SCAN")
  final String label;

  /// English: Optional custom action (OCR dialog / custom scan flow).
  /// If provided, it will be used instead of SimpleBarcodeScanner.
  final Future<String?> Function(BuildContext context, WidgetRef ref)? customAction;

  /// Callback fired when we have a non-empty result.
  final void Function({
  required WidgetRef ref,
  required String inputData,
  required int actionScan,
  }) onOk;

  const ScanButtonByActionFixedShort({
    super.key,
    required this.actionTypeInt,
    required this.onOk,
    this.color,
    this.label = 'SCAN',
    this.customAction,
  });

  @override
  ConsumerState<ScanButtonByActionFixedShort> createState() =>
      ScanButtonByActionFixedShortState();
}

class ScanButtonByActionFixedShortState
    extends ConsumerState<ScanButtonByActionFixedShort> {
  final FocusNode _focusNode = FocusNode();
  String scannedData = "";

  late bool isScanning;
  late bool isDialogShowed;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) async {
    // English: Only handle when scanner "finishes" (Enter)
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (scannedData.isNotEmpty && context.mounted) {
        widget.onOk(
          ref: ref,
          inputData: scannedData,
          actionScan: widget.actionTypeInt,
        );
      }
      scannedData = "";
      return;
    }

    // English: Accumulate characters coming from the scanner keyboard
    if (event.character != null && event.character!.isNotEmpty) {
      scannedData += event.character!;
    }
  }

  Future<void> _runPressedAction() async {
    ref.read(isScanningProvider.notifier).state = true;

    try {
      String? result;

      if (widget.customAction != null) {
        // English: Custom action (OCR dialog, custom scan dialog, etc.)
        result = await widget.customAction!(context, ref);
      } else {
        // English: Default barcode scan (camera)
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

      result = result?.trim();
      if (result != null && result.isNotEmpty) {
        widget.onOk(ref: ref, inputData: result, actionScan: widget.actionTypeInt);
      } else {
        // English: If user canceled, do nothing (or show error if you prefer)
        // showErrorMessage(context, ref, Messages.ERROR_SCANNING);
      }
    } catch (_) {
      showErrorMessage(context, ref, Messages.ERROR_SCANNING);
    } finally {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        ref.read(isScanningProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    isDialogShowed = ref.watch(isDialogShowedProvider);
    isScanning = ref.watch(isScanningProvider);

    // English: Keep focus for keyboard-scanner events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
    });

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        // English: Block keyboard-scanner input if scanning or dialog open
        if (isScanning || isDialogShowed) return;
        _handleKeyEvent(event);
      },
      child: TextButton(
        onPressed: _runPressedAction,
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
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: themeFontSizeSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
