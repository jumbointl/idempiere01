import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/providers/common_provider.dart';


class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  // Mantén una referencia al último FocusNode que tenía el foco
  FocusNode? _lastFocusedNode;

  @override
  void initState() {
    super.initState();
    // Pide el foco automáticamente al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scannerFocusNodeProvider).requestFocus();
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      final textController = ref.read(textControllerProvider);

      if (key == LogicalKeyboardKey.enter) {
        // Maneja el evento de escaneo
        print('Escaneado: ${textController.text}');
        textController.clear();
      } else if (key == LogicalKeyboardKey.backspace) {
        // Lógica para borrar, si es necesario
        final currentText = textController.text;
        if (currentText.isNotEmpty) {
          textController.text = currentText.substring(0, currentText.length - 1);
        }
      } else if (event.character != null && event.character!.isNotEmpty) {
        // Agrega el carácter al controlador
        textController.text += event.character!;
      }
    }
  }

  void _showInputDialog() {
    // 1. Guarda el nodo de foco antes de abrir el diálogo
    _lastFocusedNode = ref.read(scannerFocusNodeProvider);
    _lastFocusedNode?.unfocus();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Entrada manual'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Escribe aquí...'),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
        );
      },
    ).then((_) {
      // 2. Al cerrar el diálogo, restaura el foco al KeyboardListener
      if (_lastFocusedNode != null) {
        _lastFocusedNode!.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textController = ref.watch(textControllerProvider);
    final scannerFocusNode = ref.watch(scannerFocusNodeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Escáner de Código de Barras')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // El KeyboardListener se encarga de las pulsaciones del escáner
              KeyboardListener(
                focusNode: scannerFocusNode,
                onKeyEvent: _handleKeyEvent,
                child: TextField(
                  controller: textController,
                  readOnly: true, // Deshabilita el teclado virtual en este campo
                  showCursor: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Resultado del escaneo',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showInputDialog,
                child: const Text('Abrir Diálogo de Entrada Manual'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
