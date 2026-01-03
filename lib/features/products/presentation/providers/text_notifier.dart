import 'package:flutter_riverpod/legacy.dart';


// 4. Crea el StateNotifierProvider
final textProvider = StateNotifierProvider<TextNotifier, String>(
      (ref) => TextNotifier(),
);

// 1. Define tu StateNotifier
class TextNotifier extends StateNotifier<String> {
  TextNotifier() : super('');

  // 2. Método para actualizar el estado del texto
  void updateText(String newText) {
    state = newText;
  }

  // 3. Método que procesa el texto (se llama al presionar Enter)
  void processText(String textToProcess) {
    state = '';
  }
}

