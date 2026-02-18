// ===============================
// niimbot_printer_helper.dart
// ===============================
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:niimbot_label_printer/niimbot_label_printer.dart';

/// Para Niimbot, el plugin NO usa rawRgba como el ejemplo oficial.
/// Usa bytes de `ui.Image.toByteData()` (formato default).
class NiimbotBitmap {
  /// OJO: en este helper, `rgba` puede ser RGBA *o* bytes default según el método.
  /// Preferí usar `renderWidgetToNiimbotBytes()` para imprimir.
  final Uint8List rgba;
  final int widthPx;
  final int heightPx;

  const NiimbotBitmap({
    required this.rgba,
    required this.widthPx,
    required this.heightPx,
  });
}

class NiimbotPrinterHelper {
  /// NIIMBOT B1 suele ser 203 dpi (≈8 dots/mm)
  static const int defaultDpi = 203;

  final NiimbotLabelPrinter _niimbot;

  NiimbotPrinterHelper({NiimbotLabelPrinter? niimbot})
      : _niimbot = niimbot ?? NiimbotLabelPrinter();

  int mmToPx(double mm, {int dpi = defaultDpi}) {
    // px = mm * dpi / 25.4
    return (mm * dpi / 25.4).round().clamp(1, 1000000);
  }

  // ---------------------------------------------------------------------------
  // RENDER (OFFSCREEN) HELPERS
  // ---------------------------------------------------------------------------

  /// Renderiza un widget fuera de pantalla y devuelve bytes RGBA (rawRgba).
  /// Útil para otros pipelines, pero **NO recomendado** para Niimbot print.
  Future<NiimbotBitmap> renderWidgetToRgba({
    required BuildContext context,
    required Widget child,
    required int widthPx,
    required int heightPx,
    double pixelRatio = 1.0,
    int maxFramesToWait = 120,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final repaintKey = GlobalKey();

    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) throw Exception('No Overlay found');

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) {
        return IgnorePointer(
          ignoring: true,
          child: Material(
            type: MaterialType.transparency,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(
                children: [
                  Positioned(
                    left: -10000,
                    top: -10000,
                    child: RepaintBoundary(
                      key: repaintKey,
                      child: SizedBox(
                        width: widthPx.toDouble(),
                        height: heightPx.toDouble(),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);

    try {
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final ro = repaintKey.currentContext?.findRenderObject();
      if (ro is! RenderRepaintBoundary) {
        throw Exception('RenderObject is not RenderRepaintBoundary');
      }

      int frames = 0;
      final sw = Stopwatch()..start();
      while ((ro.debugNeedsPaint || ro.debugNeedsLayout) &&
          frames < maxFramesToWait &&
          sw.elapsed < timeout) {
        await WidgetsBinding.instance.endOfFrame;
        frames++;
      }

      if (ro.debugNeedsPaint || ro.debugNeedsLayout) {
        throw TimeoutException(
          'Boundary still needs paint/layout after ${sw.elapsedMilliseconds}ms (frames=$frames)',
        );
      }

      final ui.Image image = await ro.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();

      if (byteData == null) throw Exception('toByteData(rawRgba) returned null');

      final rgba = byteData.buffer.asUint8List();
      return NiimbotBitmap(rgba: rgba, widthPx: image.width, heightPx: image.height);
    } finally {
      entry.remove();
    }
  }


  /// ✅ Para Niimbot: renderiza widget y devuelve bytes como `image.toByteData()`
  /// (igual que el ejemplo del plugin).
  Future<Uint8List> renderWidgetToNiimbotBytes({
    required BuildContext context,
    required Widget child,
    required int widthPx,
    required int heightPx,
    double pixelRatio = 1.0,
    int maxFramesToWait = 120, // ~2s a 60fps
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final repaintKey = GlobalKey();

    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) {
      throw Exception('No Overlay found');
    }

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) {
        return IgnorePointer(
          ignoring: true,
          child: Material(
            type: MaterialType.transparency,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(
                children: [
                  // ✅ Positioned ahora sí está dentro de Stack
                  Positioned(
                    left: -10000,
                    top: -10000,
                    child: RepaintBoundary(
                      key: repaintKey,
                      child: SizedBox(
                        width: widthPx.toDouble(),
                        height: heightPx.toDouble(),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);

    try {
      // Esperar a que construya y pinte
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final ro = repaintKey.currentContext?.findRenderObject();
      if (ro is! RenderRepaintBoundary) {
        throw Exception('RenderObject is not RenderRepaintBoundary');
      }

      // Esperar hasta que no necesite layout/paint
      int frames = 0;
      final sw = Stopwatch()..start();
      while ((ro.debugNeedsPaint || ro.debugNeedsLayout) &&
          frames < maxFramesToWait &&
          sw.elapsed < timeout) {
        await WidgetsBinding.instance.endOfFrame;
        frames++;
      }

      if (ro.debugNeedsPaint || ro.debugNeedsLayout) {
        throw TimeoutException(
          'Boundary still needs paint/layout after ${sw.elapsedMilliseconds}ms (frames=$frames)',
        );
      }

      final ui.Image image = await ro.toImage(pixelRatio: pixelRatio).timeout(
        timeout,
        onTimeout: () => throw TimeoutException('toImage() timed out after $timeout'),
      );

      // ✅ CLAVE Niimbot: byteData default (igual que el ejemplo del plugin)
      final byteData = await image.toByteData();
      image.dispose();

      if (byteData == null) {
        throw Exception('toByteData() returned null');
      }

      return byteData.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }


  // ---------------------------------------------------------------------------
  // NIIMBOT CONNECT / DISCONNECT
  // ---------------------------------------------------------------------------

  Future<bool> ensurePermissionsAndBtOn() async {
    final granted = await _niimbot.requestPermissionGrant();
    if (!granted) return false;
    return await _niimbot.bluetoothIsEnabled();
  }

  Future<BluetoothDevice?> findPairedByMac(String mac) async {
    final list = await _niimbot.getPairedDevices(); // List<BluetoothDevice>
    final target = mac.trim().toUpperCase();

    for (final d in list) {
      if (d.address.trim().toUpperCase() == target) return d;
    }
    return null;
  }

  Future<bool> connectByMac(String mac) async {
    final ok = await ensurePermissionsAndBtOn();
    if (!ok) return false;

    final device = await findPairedByMac(mac);
    if (device == null) return false;

    return await _niimbot.connect(device);
  }

  Future<void> disconnectSafe() async {
    try {
      await _niimbot.disconnect();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // TEST CONNECTION
  // ---------------------------------------------------------------------------

  /// Test visible: conecta → imprime "TEST" → (opcional) desconecta.
  /// Para Niimbot usamos bytes tipo `image.toByteData()` (como el ejemplo).
  Future<bool> testConnectionNiimbot({
    required BuildContext context,
    required String mac,
    int dpi = defaultDpi,
    int density = 3,
    int labelType = 1,
    bool disconnectAfter = false,
  }) async {

    debugPrint('testConnectionNiimbot: start');
    final connected = await connectByMac(mac);
    debugPrint('testConnectionNiimbot: start $connected');
    if (!connected) return false;

    try {
      final wPx = mmToPx(40, dpi: dpi);
      final hPx = mmToPx(25, dpi: dpi);
      debugPrint('testConnectionNiimbot: wPx=$wPx, hPx=$hPx');


      final bytes = await renderWidgetToNiimbotBytes(
        context: context,
        widthPx: wPx,
        heightPx: hPx,
        child: Container(
          color: Colors.white,
          alignment: Alignment.center,
          child: const Text(
            'TEST',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      );
      debugPrint('testConnectionNiimbot: await _niimbot.send');
      final ok = await _niimbot.send(
        PrintData(
          data: bytes,
          width: wPx,
          height: hPx,
          rotate: false,
          invertColor: false,
          density: density,
          labelType: labelType,
        ),
      );
      debugPrint('testConnectionNiimbot: await _niimbot.send end');
      return ok;
    } finally {
      await Future.delayed(const Duration(milliseconds: 250));
      /*if (disconnectAfter) {
        await disconnectSafe();
      }*/
    }
  }

  // ---------------------------------------------------------------------------
  // PRINT FROM WIDGET
  // ---------------------------------------------------------------------------

  /// Imprime un widget armado por vos, respetando width/height en mm.
  /// ✅ Para Niimbot: usa bytes via `renderWidgetToNiimbotBytes()`.
  Future<bool> printLabelFromWidget({
    required BuildContext context,
    required String mac,
    required double widthMm,
    required double heightMm,
    required Widget widget,
    int dpi = defaultDpi,
    int density = 4,
    int labelType = 1,
    bool rotate = false,
    bool invert = false,
    bool disconnectAfter = true,
  }) async {
    final connected = await connectByMac(mac);
    if (!connected) return false;

    try {
      final wPx = mmToPx(widthMm, dpi: dpi);
      final hPx = mmToPx(heightMm, dpi: dpi);

      if (!context.mounted) return false;

      final bytes = await renderWidgetToNiimbotBytes(
        context: context,
        widthPx: wPx,
        heightPx: hPx,
        child: widget,
      );

      final ok = await _niimbot.send(
        PrintData(
          data: bytes,
          width: wPx,
          height: hPx,
          rotate: rotate,
          invertColor: invert,
          density: density,
          labelType: labelType,
        ),
      );

      return ok;
    } finally {
      await Future.delayed(const Duration(milliseconds: 250));
      if (disconnectAfter) {
        await disconnectSafe();
      }
    }
  }
}
