import 'dart:convert';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

Future<void> sendTsplViaBluetooth({
  required String macPrinterAddress,
  required String tspl,
}) async {
  final connected = await PrintBluetoothThermal.connect(
    macPrinterAddress: macPrinterAddress,
  );

  if (!connected) {
    throw Exception('No se pudo conectar por Bluetooth');
  }

  final bytes = utf8.encode(tspl); // TSPL = texto plano
  final ok = await PrintBluetoothThermal.writeBytes(bytes);

  if (!ok) {
    throw Exception('writeBytes devolvió false');
  }

  // Opcional: desconectar
  await PrintBluetoothThermal.disconnect;
}

Future<bool> testBluetoothTsplConnection({
  required String macPrinterAddress,
}) async {
  try {
    // 1️⃣ Connect
    final connected = await PrintBluetoothThermal.connect(
      macPrinterAddress: macPrinterAddress,
    );

    if (!connected) {
      return false;
    }

    // 2️⃣ Send minimal TSPL test command
    // English: CLS is harmless and safe
    const testCommand = 'CLS\n';

    final ok = await PrintBluetoothThermal.writeBytes(
      utf8.encode(testCommand),
    );

    // 3️⃣ Disconnect
    await PrintBluetoothThermal.disconnect;

    return ok;
  } catch (_) {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {}
    return false;
  }
}
