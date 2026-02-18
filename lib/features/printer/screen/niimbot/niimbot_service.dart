import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:niim_blue_flutter/niim_blue_flutter.dart';

/// Servicio reusable para Niimbot (niim_blue_flutter).
///
/// - Conecta sin UI (silencioso)
/// - Mantiene heartbeat
/// - Imprime etiquetas simples con Texto + Barcode o Texto + QR
///
/// Nota: para B1 suele ser 203dpi ≈ 8 dots/mm.
class NiimbotService {
  NiimbotService();

  static const int defaultDotsPerMm = 8;

  static int mmToDots(double mm, {int dotsPerMm = defaultDotsPerMm}) {
    return (mm * dotsPerMm).round().clamp(1, 1000000);
  }

  /// Crea un [BluetoothDevice] únicamente con address.
  /// Esto permite conectar sin escanear ni mostrar dialogs.
  static BluetoothDevice buildDeviceFromAddress(String address,
      {String? platformName}) {
    final a = address.trim();
    return BluetoothDevice(
      remoteId: DeviceIdentifier(a),
    );
  }

  /// Conecta sin UI y devuelve el client listo.
  Future<NiimbotBluetoothClient> connectToBluetoothDeviceSilence({
    required BluetoothDevice device,
  }) async {
    final client = NiimbotBluetoothClient();
    client.setDevice(device);
    final result = await client.connect();
    debugPrint('Niimbot connected: ${result.deviceName}');
    client.startHeartbeat();
    return client;
  }

  Future<void> disconnectSafe(NiimbotBluetoothClient? client) async {
    if (client == null) return;
    try {
      client.stopHeartbeat();
      await client.abstraction.printEnd();
    } catch (_) {}
    try {
      await client.disconnect();
    } catch (_) {}
  }

  /// Ejecuta un print task (1 página). Maneja heartbeat.
  Future<void> executePrintTask({
    required NiimbotBluetoothClient client,
    required PrintPage page,
    PrintOptions options = const PrintOptions(
      totalPages: 1,
      density: 3,
      labelType: LabelType.withGaps,
      statusPollIntervalMs: 100,
      statusTimeoutMs: 8000,
    ),
  }) async {
    client.stopHeartbeat();
    client.packetIntervalMs = 0;

    final task = client.createPrintTask(options);
    if (task == null) {
      client.startHeartbeat();
      throw Exception('Failed to create print task (printer model not detected)');
    }

    try {
      await task.printInit();
      await task.printPage(page.toEncodedImage(), 1);
      await task.waitForFinished();
    } finally {
      client.startHeartbeat();
    }
  }

  /// Texto (arriba) + Barcode (abajo), centrado.
  Future<void> printTextBarcodeWithNiimbot({
    required NiimbotBluetoothClient client,
    required double widthMm,
    required double heightMm,
    required String text,
    required String barcode,
    int dotsPerMm = defaultDotsPerMm,
    BarcodeEncoding encoding = BarcodeEncoding.code128,
    int density = 3,
    LabelType labelType = LabelType.withGaps,
  }) async {
    final w = mmToDots(widthMm, dotsPerMm: dotsPerMm);
    final h = mmToDots(heightMm, dotsPerMm: dotsPerMm);

    final page = PrintPage(w, h);

    // Texto cerca del top
    await page.addText(
      text,
      TextOptions(
        x: w ~/ 2,
        y: (h * 0.22).round(),
        fontSize: (h * 0.16).clamp(14, 36).round(),
        fontWeight: FontWeight.bold,
        align: HAlignment.center,
        vAlign: VAlignment.middle,
      ),
    );

    // Barcode abajo
    page.addBarcode(
      barcode,
      BarcodeOptions(
        encoding: encoding,
        x: w ~/ 2,
        y: (h * 0.68).round(),
        width: (w * 0.82).round(),
        height: (h * 0.30).round(),
        align: HAlignment.center,
        vAlign: VAlignment.middle,
      ),
    );

    await executePrintTask(
      client: client,
      page: page,
      options: PrintOptions(
        totalPages: 1,
        density: density,
        labelType: labelType,
        statusPollIntervalMs: 100,
        statusTimeoutMs: 8000,
      ),
    );
  }

  /// Texto (arriba) + QR (abajo), centrado.
  Future<void> printTextQRWithNiimbot({
    required NiimbotBluetoothClient client,
    required double widthMm,
    required double heightMm,
    required String text,
    required String qrData,
    int dotsPerMm = defaultDotsPerMm,
    int density = 3,
    LabelType labelType = LabelType.withGaps,
  }) async {
    final w = mmToDots(widthMm, dotsPerMm: dotsPerMm);
    final h = mmToDots(heightMm, dotsPerMm: dotsPerMm);

    final page = PrintPage(w, h);

    await page.addText(
      text,
      TextOptions(
        x: w ~/ 2,
        y: (h * 0.20).round(),
        fontSize: (h * 0.15).clamp(14, 34).round(),
        fontWeight: FontWeight.bold,
        align: HAlignment.center,
        vAlign: VAlignment.middle,
      ),
    );

    final qrSize = (h * 0.55).round().clamp(60, w);
    page.addQR(
      qrData,
      QROptions(
        x: w ~/ 2,
        y: (h * 0.67).round(),
        width: qrSize,
        height: qrSize,
        align: HAlignment.center,
        vAlign: VAlignment.middle,
      ),
    );

    await executePrintTask(
      client: client,
      page: page,
      options: PrintOptions(
        totalPages: 1,
        density: density,
        labelType: labelType,
        statusPollIntervalMs: 100,
        statusTimeoutMs: 8000,
      ),
    );
  }
}
