import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/providers/scan_provider.dart';
import 'input_data_processor.dart';

class PhysicalKeyboardScreen extends ConsumerStatefulWidget {
  final InputDataProcessor processor;
  const PhysicalKeyboardScreen({
    required this.processor,
    super.key});

  @override
  ConsumerState<PhysicalKeyboardScreen> createState() => _PhysicalKeyboardScreenState();
}

class _PhysicalKeyboardScreenState extends ConsumerState<PhysicalKeyboardScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Solicita el foco automáticamente al iniciar el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Nuevo método para manejar eventos de teclado con la API moderna
  void _handleKeyEvent(KeyEvent event) {
    // Escucha el evento de presión de tecla
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      final textController = ref.read(scanTextControllerProvider);

      // Maneja la tecla de retroceso
      if (key == LogicalKeyboardKey.backspace) {
        final currentText = textController.text;
        if (currentText.isNotEmpty) {
          textController.text = currentText.substring(0, currentText.length - 1);
          textController.selection = TextSelection.fromPosition(
            TextPosition(offset: textController.text.length),
          );
        }
      }
      // Maneja caracteres imprimibles
      else if (event.character != null && event.character!.isNotEmpty) {
        textController.text += event.character!;
        textController.selection = TextSelection.fromPosition(
          TextPosition(offset: textController.text.length),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textController = ref.watch(scanTextControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teclado Físico en Flutter'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: KeyboardListener( // Usamos KeyboardListener en lugar de RawKeyboardListener
            focusNode: _focusNode,
            onKeyEvent: (event) => _handleKeyEvent(event), // Pasamos el evento al método
            child: TextField(
              controller: textController,
              readOnly: true, // Evita el teclado en pantalla
              showCursor: true, // Muestra el cursor para indicar entrada
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Escribe aquí (con teclado físico)',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
