import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


enum _PrinterCommandAction {
  configFtpAccount,
  createZplTemplate,
  useZplTemplate,
}

class PrinterCommandsMenu extends ConsumerWidget {
  final Future<void> Function() onConfigFtpAccount;
  final Future<void> Function() onLoadZplTemplate;
  final Future<void> Function() onUseZplTemplate;

  const PrinterCommandsMenu({
    super.key,
    required this.onConfigFtpAccount,
    required this.onLoadZplTemplate,
    required this.onUseZplTemplate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return PopupMenuButton<_PrinterCommandAction>(
      tooltip: 'Comandos impresora',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) async {
        switch (action) {
          case _PrinterCommandAction.configFtpAccount:
            await onConfigFtpAccount();
            break;
          case _PrinterCommandAction.createZplTemplate:
            await onLoadZplTemplate();
            break;
          case _PrinterCommandAction.useZplTemplate:
            await onUseZplTemplate();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _PrinterCommandAction.configFtpAccount,
          child: ListTile(
            leading: Icon(Icons.cloud_outlined),
            title: Text('Configurar cuenta FTP'),
          ),
        ),
        const PopupMenuItem(
          value: _PrinterCommandAction.createZplTemplate,
          child: ListTile(
            leading: Icon(Icons.note_add),
            title: Text('Bajar template ZPL'),
          ),
        ),
        const PopupMenuItem(
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
