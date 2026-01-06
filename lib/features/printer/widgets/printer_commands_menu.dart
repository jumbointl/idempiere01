import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';


enum _PrinterCommandAction {
  configFtpAccount,
  createZplTemplate,
  useZplTemplate,
  configurePos,
  configureSocketTimeout,
  diagnoseRaw9100,
}

class PrinterCommandsMenu extends ConsumerWidget {
  final Future<void> Function() onConfigFtpAccount;
  final Future<void> Function() onLoadZplTemplate;
  final Future<void> Function() onUseZplTemplate;
  final Future<void> Function() onConfigurePos;
  final Future<void> Function() onConfigureSocketTimeout;
  final Future<void> Function() onDiagnoseRaw9100;


  const PrinterCommandsMenu({
    super.key,
    required this.onConfigFtpAccount,
    required this.onLoadZplTemplate,
    required this.onUseZplTemplate,
    required this.onConfigurePos,
    required this.onConfigureSocketTimeout,
    required this.onDiagnoseRaw9100,
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
            case _PrinterCommandAction.configurePos:
            await onConfigurePos();
            break;
          case _PrinterCommandAction.configureSocketTimeout: // 👈 NUEVO
            await onConfigureSocketTimeout();
            break;
          case _PrinterCommandAction.diagnoseRaw9100:
            await onDiagnoseRaw9100();
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
        PopupMenuItem(
          value: _PrinterCommandAction.configurePos,
          child: const ListTile(
            leading: Icon(Symbols.point_of_sale_rounded),
            title: Text('Configurar POS'),
          ),
        ),
        PopupMenuItem(
          value: _PrinterCommandAction.configureSocketTimeout,
          child: const ListTile(
            leading: Icon(Icons.timer_outlined),
            title: Text('Socket timeout (RAW 9100)'),
          ),
        ),
        PopupMenuItem(
          value: _PrinterCommandAction.diagnoseRaw9100,
          child: const ListTile(
            leading: Icon(Icons.wifi_tethering_outlined),
            title: Text('Diagnóstico Socket'),
          ),
        ),
      ],
    );
  }
}
