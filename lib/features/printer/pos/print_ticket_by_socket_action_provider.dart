



import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/printer/pos/sock_time_out_provider.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';

import 'PosTicket.dart';

final fireSendCommandBySocketProvider = StateProvider<int>((ref) {
  return 0;
});

final posTickerProvider = StateProvider<PosTicket?>((ref) {
  return null;
});

final sendCommandBySocketProvider =
FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  final int count = ref.watch(fireSendCommandBySocketProvider);
  if (count == 0) return ResponseAsyncValue();

  final PosTicket? ticket = ref.read(posTickerProvider);
  if (ticket == null) return ResponseAsyncValue();

  final int timeoutSec = ref.read(sockTimeOutInSecoundsProvider);
  final timeout = Duration(seconds: timeoutSec);

  final err = await rawSend9100(
    host: ticket.ip,
    port: ticket.port, // 9100
    bytes: ticket.ticket,
    timeout: timeout,
  );

  ref.invalidate(posTickerProvider);
  await Future.delayed(const Duration(milliseconds: 100));

  if (err == null) {
    return ResponseAsyncValue(
      isInitiated: true,
      success: true,
      data: true,
      message: 'RAW OK (${timeoutSec}s)',
    );
  }

  return ResponseAsyncValue(
    isInitiated: true,
    success: false,
    message: '$err | timeout=${timeoutSec}s',
  );
});

String _prettySocketPrintError(Object e) {
  if (e is SocketException) {
    final os = e.osError;
    final osMsg = os == null ? '' : ' (${os.errorCode} ${os.message})';
    return 'SocketException: ${e.message}$osMsg';
  }
  if (e is TimeoutException) {
    return 'Timeout: ${e.message ?? ''}';
  }
  return '${e.runtimeType}: $e';
}



class SocketProbeResult {
  final bool ok;
  final String message;
  final Duration? latency;

  SocketProbeResult({required this.ok, required this.message, this.latency});
}

Future<SocketProbeResult> probeTcp({
  required String host,
  required int port,
  Duration timeout = const Duration(seconds: 3),
}) async {
  final sw = Stopwatch()..start();
  try {
    final socket = await Socket.connect(host, port, timeout: timeout);
    socket.destroy(); // cierra ya mismo
    sw.stop();
    return SocketProbeResult(
      ok: true,
      message: 'TCP OK $host:$port (${sw.elapsedMilliseconds}ms)',
      latency: sw.elapsed,
    );
  } on SocketException catch (e) {
    sw.stop();
    final os = e.osError;
    final osMsg = os == null ? '' : ' | osError: ${os.errorCode} ${os.message}';
    return SocketProbeResult(
      ok: false,
      message: 'TCP FAIL $host:$port | ${e.message}$osMsg',
      latency: sw.elapsed,
    );
  } catch (e) {
    sw.stop();
    return SocketProbeResult(
      ok: false,
      message: 'TCP FAIL $host:$port | ${e.runtimeType}: $e',
      latency: sw.elapsed,
    );
  }
}
Future<SocketProbeResult> probeWithRetries({
  required String host,
  required int port,
  int retries = 2,
  Duration timeout = const Duration(seconds: 3),
  Duration retryDelay = const Duration(milliseconds: 250),
}) async {
  SocketProbeResult last = SocketProbeResult(ok: false, message: 'No attempts');
  for (int i = 0; i <= retries; i++) {
    last = await probeTcp(host: host, port: port, timeout: timeout);
    if (last.ok) return last;
    if (i < retries) {
      await Future.delayed(retryDelay);
    }
  }
  return last;
}


bool _isBenignAfterSend(SocketException e) {
  final msg = (e.message).toLowerCase();
  final osMsg = (e.osError?.message ?? '').toLowerCase();
  // Casos típicos cuando la impresora corta la conexión
  return msg.contains('connection reset') ||
      msg.contains('broken pipe') ||
      osMsg.contains('connection reset') ||
      osMsg.contains('broken pipe') ||
      // A veces aparece como "Software caused connection abort"
      osMsg.contains('connection abort');
}

Future<String?> rawSend9100({
  required String host,
  required int port,
  required List<int> bytes,
  required Duration timeout,
}) async {
  Socket? s;

  bool connected = false;
  bool sent = false;
  bool flushed = false;

  try {
    s = await Socket.connect(host, port, timeout: timeout);
    connected = true;

    s.add(bytes);
    sent = true;

    // flush puede fallar si la impresora corta, pero ya puede haber impreso
    await s.flush();
    flushed = true;

    // IMPORTANT: close() a veces lanza error si el peer cortó.
    // No dejemos que eso convierta éxito en error.
    try {
      await s.close();
    } catch (_) {
      // ignorar
    }

    return null; // OK
  } on SocketException catch (e) {
    final os = e.osError;
    final osMsg = os == null ? '' : ' | osError=${os.errorCode} ${os.message}';

    // ✅ Si ya mandaste datos (sent o flushed) y el error es benigno -> OK
    if ((sent || flushed) && _isBenignAfterSend(e)) {
      return null; // tratar como éxito
    }

    // Caso normal: error real antes de enviar o error no benigno
    return 'RAW FAIL $host:$port | ${e.message}$osMsg'
        ' | stage=${_stage(connected, sent, flushed)}';
  } on TimeoutException catch (e) {
    // Si timeout ocurre después de mandar, también puede haber impreso igual.
    // Acá prefiero ser conservador: lo dejo como error, pero con stage.
    return 'RAW TIMEOUT $host:$port | ${e.message ?? ''}'
        ' | stage=${_stage(connected, sent, flushed)}';
  } catch (e) {
    return 'RAW ERROR $host:$port | ${e.runtimeType}: $e'
        ' | stage=${_stage(connected, sent, flushed)}';
  } finally {
    try {
      s?.destroy();
    } catch (_) {}
  }
}

String _stage(bool connected, bool sent, bool flushed) {
  if (!connected) return 'connecting';
  if (!sent) return 'connected';
  if (!flushed) return 'sent';
  return 'flushed';
}


List<int> buildMiniTestTicketBytes({
  required String ip,
  required int port,
  required int timeoutSec,
}) {
  final now = DateTime.now();
  final ts = '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')} '
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}';

  // ESC/POS (muy estándar)
  // - ESC @ : initialize
  // - ESC a n : align (0 left, 1 center, 2 right)
  // - GS ! n : double size etc (opcional)
  // - LF: \n
  // - GS V m : cut (algunas usan m=0/1/66/67; probamos 66)
  final bytes = <int>[];

  void addAscii(String s) => bytes.addAll(ascii.encode(s));
  void lf([int n = 1]) => bytes.addAll(List<int>.filled(n, 0x0A));

  bytes.addAll([0x1B, 0x40]); // ESC @ init
  bytes.addAll([0x1B, 0x61, 0x01]); // ESC a 1 (center)

  addAscii('*** TEST RAW 9100 ***');
  lf();
  bytes.addAll([0x1B, 0x61, 0x00]); // left
  addAscii('IP: $ip');
  lf();
  addAscii('PORT: $port');
  lf();
  addAscii('TIMEOUT: ${timeoutSec}s');
  lf();
  addAscii('DATE: $ts');
  lf();
  lf();

  addAscii('Si ves esto, RAW TCP OK.');
  lf();
  lf(2);

  // Feed y corte (si la impresora soporta)
  // GS V 66 0 : partial cut (muy común)
  bytes.addAll([0x1D, 0x56, 0x42, 0x00]);

  return bytes;
}
