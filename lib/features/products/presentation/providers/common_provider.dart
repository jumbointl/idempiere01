import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/movement/printer/mo_printer.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
      (ref) => throw UnimplementedError(),
);
// El Notifier que gestiona el estado del String
class SharedStringNotifier extends StateNotifier<String?> {
  final SharedPreferences sharedPreferences;
  static const String key = 'username';

  SharedStringNotifier(this.sharedPreferences) : super(sharedPreferences.getString(key));

  // Método para guardar el String
  Future<void> saveString(String value) async {
    await sharedPreferences.setString(key, value);
    state = value; // Actualiza el estado para notificar a los oyentes
  }

  // Método para eliminar el String
  Future<void> deleteString() async {
    await sharedPreferences.remove(key);
    state = null; // Actualiza el estado para notificar a los oyentes
  }
}

// El StateNotifierProvider que expone el Notifier y el estado
final usernameProvider = StateNotifierProvider<SharedStringNotifier, String?>(
      (ref) {
    final sharedPrefs = ref.watch(sharedPreferencesProvider);
    return SharedStringNotifier(sharedPrefs);
  },
);

final inputStringProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

// Un StateProvider para almacenar el texto del TextField
final textProvider = StateProvider<String>((ref) => '');

// Un StateProvider para el resultado de la acción
final resultProvider = StateProvider<String>((ref) => 'Esperando...');

final scannerFocusNodeProvider = Provider<FocusNode>((ref) {
  final focusNode = FocusNode();
  // Limpia el FocusNode cuando el proveedor ya no se use
  ref.onDispose(focusNode.dispose);
  return focusNode;
});
final textControllerProvider = StateProvider<TextEditingController>((ref) {
  return TextEditingController();
});

final lastPrinterProvider = StateProvider<MOPrinter?>((ref) {
  return null;
});

final directPrintWithLastPrinterProvider = StateProvider<bool>((ref) {
  return false;
});

final isPrintingProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final initializingProvider = StateProvider<bool>((ref) => false);
/// null = ALL, true = IN, false = OUT
final inOutProvider = StateProvider<bool?>((ref) => null);