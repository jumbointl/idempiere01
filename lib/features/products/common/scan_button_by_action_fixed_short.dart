import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/input_dialog.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../shared/data/memory.dart';
import '../presentation/providers/common_provider.dart';
import '../../shared/data/messages.dart';
import '../presentation/providers/product_provider_common.dart';

class ScanButtonByActionFixedShort extends ConsumerStatefulWidget {
  final int actionTypeInt;
  final Color? color;

  /// Callback que se dispara cuando el lector termina (Enter)
  /// o cuando se escanea con la cámara y hay datos.
  final void Function({required WidgetRef ref
  , required String inputData,required int actionScan}) onOk;

  ScanButtonByActionFixedShort({
    super.key,
    required this.actionTypeInt,
    required this.onOk,
    this.color,
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
      if (mounted) {
        setState(() {});
      }
    });
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) async {
    // Solo manejamos cuando el scanner "termina" (Enter)
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (scannedData.isNotEmpty && context.mounted) {
        widget.onOk(ref: ref, inputData: scannedData,actionScan: widget.actionTypeInt);
      }
      scannedData = "";
      return;
    }

    // Acumular caracteres enviados por el scanner
    if (event.character != null && event.character!.isNotEmpty) {
      scannedData += event.character!;
    }
  }

  @override
  Widget build(BuildContext context) {
    isDialogShowed = ref.watch(isDialogShowedProvider);
    isScanning = ref.watch(isScanningProvider);

    // Mantener foco en el botón para que el lector de código
    // (como teclado) siga enviando eventos aquí.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        // Bloquear entrada si está escaneando o hay diálogo abierto
        if (isScanning || isDialogShowed) return;
        _handleKeyEvent(event);
      },
      child: TextButton(
        onPressed: () async {
          // marcar que está escaneando (si querés que el estado sea global)
          ref.read(isScanningProvider.notifier).state = true;

          String? result = await SimpleBarcodeScanner.scanBarcode(
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

          result = result?.trim();
          if (result != null && result.isNotEmpty) {
            print('result scan: $result');
            widget.onOk(ref: ref,  inputData: result,actionScan: widget.actionTypeInt);

          } else {
            showErrorMessage(context, ref, Messages.ERROR_SCANNING);
          }

          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) {
            ref.read(isScanningProvider.notifier).state = false;
          }
        },
        style: TextButton.styleFrom(
          backgroundColor: _focusNode.hasFocus
              ? (widget.color ?? themeColorPrimary)
              : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          minimumSize: const Size(60, 32),          // 🔹 más compacto
          tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 🔹 reduce zona táctil extra
          visualDensity: VisualDensity.compact,     // 🔹 menos espacio vertical
        ),
        child: const Text(
          'SCAN',
          style: TextStyle(
            color: Colors.white,
            fontSize: themeFontSizeSmall, // 🔹 fuente más chica
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


}
