
/*import 'dart:typed_data';
import 'package:flutter_net_printer/flutter_net_printer.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:printing/printing.dart';
import 'printer_connection_state.dart';
import 'printer_type.dart';

class PrinterNotifier extends StateNotifier<PrinterConnectionState> {
  PrinterNotifier() : super(const PrinterConnectionState());

  // ... (métodos para setIp, setPort, setPrintType)

  Future<void> handlePrint({required Uint8List bytes, required PrintType printType}) async {
    print('Manejando impresión para tipo: $printType');

    if (printType == PrintType.A4) {
      // Usar el paquete `printing` para abrir el diálogo de impresión nativo
      await Printing.sharePdf(bytes: bytes, filename: 'documento.pdf');
    } else {
      // Usar `flutter_net_printer` para impresión directa (POS, LABEL)
      final printer = FlutterNetPrinter();
      try {
        final connectedDevice = await printer.connectToPrinter(
          state.ip,
          state.port,
          timeout: const Duration(seconds: 5),
        );
        if (connectedDevice != null) {
          await printer.printBytes(data:bytes);
          print('Impresión directa enviada.');
        } else {
          print('Error de conexión con la impresora.');
        }
      } catch (e) {
        print('Error en la impresión directa: $e');
      }
    }
  }
}

final printerProvider = StateNotifierProvider<PrinterNotifier, PrinterConnectionState>((ref) {
  return PrinterNotifier();
});*/

import 'dart:typed_data';
// Importa el paquete principal
import 'package:flutter_net_printer/flutter_net_printer.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'printer_connection_state.dart';
import 'printer_type.dart';

class PrinterNotifier extends StateNotifier<PrinterConnectionState> {
  PrinterNotifier() : super(const PrinterConnectionState(ip: '192.168.0.100', port: 9100));

  void setIp(String ip) {
    state = state.copyWith(ip: ip);
  }
  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setPort(String port) {
    final parsedPort = int.tryParse(port) ?? 9100;
    state = state.copyWith(port: parsedPort);
  }

  void setPrintType(PrinterType type) {
    state = state.copyWith(printType: type);
  }
  void setServerIp(String serverIp) {
    state = state.copyWith(serverIp: serverIp);
  }
  void setServerPort(String serverPort) {
    state = state.copyWith(serverPort: serverPort);
  }


  Future<void> printDirectly({required Uint8List bytes}) async {
    final int port;
    final String ip;

    if(state.printType == PrinterType.LASER || state.printType == PrinterType.A4){
      print('Intentando imprimir en ${state.serverIp}:${state.serverPort} con tipo ${state.printType}');
      port = int.tryParse(state.serverPort?? '') ?? 9100;
      ip = state.serverIp ?? '192.168.0.100';
    } else {
      print('Intentando imprimir en ${state.ip}:${state.port} con tipo ${state.printType}');
      port = state.port ?? 9100;
      ip = state.ip ?? '';
    }
    // Usa la clase FlutterNetPrinter directamente.
    final printer = FlutterNetPrinter();

    try {
      // Usa el método connectToPrinter para establecer la conexión.
      final connectedDevice = await printer.connectToPrinter(
          ip,
          port,
          timeout: const Duration(seconds: 5)
      );

      if (connectedDevice != null) {
        print('Conexión exitosa a la impresora.');
        // Usa el método printBytes para enviar los datos.
        await printer.printBytes(data: bytes);
        print('Datos de impresión enviados.');

        // El paquete no tiene un método de "desconexión" explícito,
        // ya que maneja la conexión por cada comando de impresión.
      } else {
        print('Error al conectar a la impresora.');
      }
    } catch (e) {
      print('Error al imprimir directamente: $e');
    }
  }
}

final printerProvider = StateNotifierProvider<PrinterNotifier, PrinterConnectionState>((ref) {
  return PrinterNotifier();
});
