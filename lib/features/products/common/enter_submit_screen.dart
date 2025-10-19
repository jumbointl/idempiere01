import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/providers/common_provider.dart';
import 'input_data_processor.dart';

/*// Un StateProvider para almacenar el texto del TextField
final textProvider = StateProvider<String>((ref) => '');

// Un StateProvider para el resultado de la acción
final resultProvider = StateProvider<String>((ref) => 'Esperando...');*/

class EnterSubmitScreen extends ConsumerWidget {
  final InputDataProcessor processor;
  const EnterSubmitScreen({
    required this.processor,
    super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(resultProvider);

    // Usa un TextEditingController para interactuar con el TextField
    final controller = TextEditingController(text: ref.watch(textProvider));
    ref.listen(textProvider, (_, next) {
      if (next != controller.text) {
        controller.text = next;
      }
    });

    void handleSubmitted(String value) {
      processor.handleInputString(context, ref, value);
      // Usa ref.read para leer el valor del provider
      print('-------------------------------------scanned $value');
      ref.read(resultProvider.notifier).state = 'Texto enviado: "$value"';
      // Opcional: limpiar el campo después de enviar
      ref.read(textProvider.notifier).state = '';
    }
    return TextField(
        controller: controller,
        onSubmitted: handleSubmitted,);
        /*
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextField(
            controller: controller,
            onSubmitted: handleSubmitted,
            *//*decoration: const InputDecoration(
              labelText: 'Escribe algo',
              border: OutlineInputBorder(),
            ),*//*
          ),
          *//*const PreferredSize(
            preferredSize: Size.fromHeight(20),
            child: SizedBox(height: 20),
          ),*//*
          Text(result, style: const TextStyle(fontSize: 18)),
        ]);*/
    /*return Scaffold(
      appBar: AppBar(
        title: const Text('Manejar Enter en TextField'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: controller,
              onSubmitted: handleSubmitted,
              decoration: const InputDecoration(
                labelText: 'Escribe algo y presiona Enter',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(result, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );*/
  }
}
