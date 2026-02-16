import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

Future<int> _androidSdkInt() async =>
    (await DeviceInfoPlugin().androidInfo).version.sdkInt;

Future<bool> ensureBluetoothPermissions() async {
  if (!Platform.isAndroid) return true;

  final sdk = await _androidSdkInt();

  if (sdk >= 31) {
    // Android 12+
    final connect = await Permission.bluetoothConnect.request();
    final scan = await Permission.bluetoothScan.request(); // para listar paired en muchas libs

    final ok = connect.isGranted && scan.isGranted;

    if (!ok && (connect.isPermanentlyDenied || scan.isPermanentlyDenied)) {
      await openAppSettings();
    }
    return ok;
  }

  // Android 11 o menor:
  // Para listar/scan en muchos casos piden location.
  // Si SOLO conectas a paired y tu lib no escanea, podrías return true.
  final loc = await Permission.locationWhenInUse.request();
  if (!loc.isGranted && loc.isPermanentlyDenied) await openAppSettings();
  return loc.isGranted;
}
Future<bool> requestMediaPermissionsForOcr() async {
  if (!Platform.isAndroid) {
    final p = await Permission.photos.request();
    if (!p.isGranted && p.isPermanentlyDenied) await openAppSettings();
    return p.isGranted;
  }

  final sdk = await _androidSdkInt();

  if (sdk >= 33) {
    // Android 13+: READ_MEDIA_IMAGES
    final p = await Permission.photos.request();
    if (!p.isGranted && p.isPermanentlyDenied) await openAppSettings();
    return p.isGranted;
  } else {
    // Android 12L o menor: READ_EXTERNAL_STORAGE
    final p = await Permission.storage.request();
    if (!p.isGranted && p.isPermanentlyDenied) await openAppSettings();
    return p.isGranted;
  }
}
