import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../shared/data/messages.dart';
import '../../presentation/providers/product_provider_common.dart';

class ScanButtonFixedShort extends ConsumerStatefulWidget {
  final Color? color;

  /// English: Button label (default: "SCAN")
  final String label;

  /// English: Optional custom action (OCR dialog / custom scan flow).
  final Future<String?> Function(BuildContext context, WidgetRef ref)? customAction;

  /// English: actionScan is always 0
  final void Function({
  required WidgetRef ref,
  required String inputData,
  required int actionScan,
  }) onOk;

  const ScanButtonFixedShort({
    super.key,
    required this.onOk,
    this.color,
    this.label = 'SCAN',
    this.customAction,
  });

  @override
  ConsumerState<ScanButtonFixedShort> createState() =>
      _ScanButtonFixedShortState();
}

class _ScanButtonFixedShortState
    extends ConsumerState<ScanButtonFixedShort> {

  static const int _fixedActionScan = 0;

  late bool isScanning;

  Future<void> _runPressedAction() async {
    ref.read(isScanningProvider.notifier).state = true;

    try {
      String? result;

      if (widget.customAction != null) {
        // English: Custom OCR or scan flow
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
        widget.onOk(
          ref: ref,
          inputData: result,
          actionScan: _fixedActionScan,
        );
      }

    } catch (_) {
      if(context.mounted) showErrorMessage(context, ref, Messages.ERROR_SCANNING);

    } finally {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        ref.read(isScanningProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    isScanning = ref.watch(isScanningProvider);

    return TextButton(
      onPressed: isScanning ? null : _runPressedAction,
      style: TextButton.styleFrom(
        backgroundColor: widget.color ?? themeColorPrimary,
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
    );
  }
}
