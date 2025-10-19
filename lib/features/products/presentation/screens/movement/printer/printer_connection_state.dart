
import 'printer_type.dart';

class PrinterConnectionState {
  final String ip;
  final String name;
  final int port;
  final PrinterType printType; // Nuevo atributo

  const PrinterConnectionState({
    this.ip = '',
    this.name = '',
    this.port = 9100,
    this.printType = PrinterType.A4, // Valor por defecto
  });

  PrinterConnectionState copyWith({
    String? ip,
    String? name,
    int? port,
    PrinterType? printType,
  }) {
    return PrinterConnectionState(
      ip: ip ?? this.ip,
      name: name ?? this.name,
      port: port ?? this.port,
      printType: printType ?? this.printType,
    );
  }
}
