import 'package:flutter_riverpod/legacy.dart';

// 1. Define tu StateNotifier
class TextNotifier extends StateNotifier<String> {
  TextNotifier() : super('');

  // 2. Método para actualizar el estado del texto
  void updateText(String newText) {
    state = newText;
  }

  // 3. Método que procesa el texto (se llama al presionar Enter)
  void processText(String textToProcess) {
    print('Texto enviado a la función: $textToProcess');
    // Aquí puedes añadir tu lógica, como:
    // - Enviar a una API
    // - Guardar en una base de datos
    // - Llamar a otro método del Notifier

    // Opcional: Limpiar el campo de texto después de procesar
    state = '';
  }
}

// 4. Crea el StateNotifierProvider
final textProvider = StateNotifierProvider<TextNotifier, String>(
      (ref) => TextNotifier(),
);
