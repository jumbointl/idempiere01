import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'text_notifier.dart'; // Asegúrate de importar tu notifier

class InputScreen extends ConsumerWidget {
  const InputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escucha el estado del texto para mantenerlo sincronizado
    final textState = ref.watch(textProvider);
    // Obtiene una referencia al notifier para poder llamar a sus métodos
    final textNotifier = ref.read(textProvider.notifier);

    // Puedes usar un TextEditingController para controlar el texto del TextField
    final controller = TextEditingController(text: textState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input con Riverpod'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Escribe algo',
                border: OutlineInputBorder(),
              ),
              // 'onChanged' se llama con cada carácter que se teclea
              onChanged: (text) {
                textNotifier.updateText(text);
              },
              // 'onSubmitted' se llama cuando se presiona la tecla Enter
              onSubmitted: (text) {
                textNotifier.processText(text);
                // Opcional: Limpiar el campo de texto después de enviar
                controller.clear();
              },
              // Configura la acción del teclado virtual para mostrar un botón de "Enviar" o "Listo"
              textInputAction: TextInputAction.send,
            ),
            const SizedBox(height: 20),
            // Muestra el texto actual del estado de Riverpod
            Text('Texto actual en el estado: ${textState.isEmpty ? 'Ninguno' : textState}'),
          ],
        ),
      ),
    );
  }
}
