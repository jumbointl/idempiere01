import 'package:flutter/material.dart';

enum _PrinterCommandAction {
  configureZplProfile,
  printZplDirect,
  labelToPrint,
  copyZpl,
  copyTspl,
  saveTxt,
  createZplTemplate,
  useZplTemplate,
}

class PrinterCommandsMenu extends StatelessWidget {
  final Future<void> Function() onConfigureZpl;
  final Future<void> Function() onPrintZplDirect;

  final Future<void> Function() onChooseLabelType; // <-- NUEVO

  final VoidCallback onCopyZpl;
  final VoidCallback onCopyTspl;
  final Future<void> Function() onCreateZplTemplate;
  final Future<void> Function() onUseZplTemplate;
  final Future<void> Function() onSaveTxt;

  const PrinterCommandsMenu({
    super.key,
    required this.onConfigureZpl,
    required this.onPrintZplDirect,
    required this.onChooseLabelType, // <-- NUEVO
    required this.onCopyZpl,
    required this.onCopyTspl,
    required this.onSaveTxt,
    required this.onCreateZplTemplate,
    required this.onUseZplTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PrinterCommandAction>(
      tooltip: 'Comandos impresora',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) async {
        switch (action) {
          case _PrinterCommandAction.configureZplProfile:
            await onConfigureZpl();
            break;
          case _PrinterCommandAction.printZplDirect:
            await onPrintZplDirect();
            break;

          case _PrinterCommandAction.labelToPrint: // <-- NUEVO
            await onChooseLabelType();
            break;

          case _PrinterCommandAction.copyZpl:
            onCopyZpl();
            break;
          case _PrinterCommandAction.copyTspl:
            onCopyTspl();
            break;
          case _PrinterCommandAction.saveTxt:
            await onSaveTxt();
            break;
          case _PrinterCommandAction.createZplTemplate:
            await onCreateZplTemplate();
            break;
          case _PrinterCommandAction.useZplTemplate:
            await onUseZplTemplate();
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _PrinterCommandAction.configureZplProfile,
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Configurar ZPL (perfiles)'),
          ),
        ),
        PopupMenuItem(
          value: _PrinterCommandAction.printZplDirect,
          child: ListTile(
            leading: Icon(Icons.print),
            title: Text('Imprimir ZPL directo'),
          ),
        ),

        // ===== NUEVO ITEM =====
        PopupMenuItem(
          value: _PrinterCommandAction.labelToPrint,
          child: ListTile(
            leading: Icon(Icons.label),
            title: Text('Label a imprimir'),
          ),
        ),

        PopupMenuDivider(),
        PopupMenuItem(
          value: _PrinterCommandAction.copyZpl,
          child: ListTile(
            leading: Icon(Icons.copy),
            title: Text('Copiar ZPL'),
          ),
        ),
        PopupMenuItem(
          value: _PrinterCommandAction.copyTspl,
          child: ListTile(
            leading: Icon(Icons.copy),
            title: Text('Copiar TSPL'),
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _PrinterCommandAction.saveTxt,
          child: ListTile(
            leading: Icon(Icons.save_alt),
            title: Text('Guardar / Compartir TXT'),
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _PrinterCommandAction.createZplTemplate,
          child: ListTile(
            leading: Icon(Icons.note_add),
            title: Text('Crear template ZPL'),
          ),
        ),
        PopupMenuItem(
          value: _PrinterCommandAction.useZplTemplate,
          child: ListTile(
            leading: Icon(Icons.playlist_play),
            title: Text('Usar template ZPL'),
          ),
        ),

      ],
    );
  }
}

