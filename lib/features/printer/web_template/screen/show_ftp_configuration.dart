import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';

import '../../../products/common/messages_dialog.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../models/ftp_account_config.dart';

/// Show FTP configuration dialog (view + edit + save)
Future<void> showFtpAccountConfiguration(WidgetRef ref, BuildContext context) async {
  final current = loadFtpAccountConfig();
  final urlCtrl = TextEditingController(text: current.url);
  final userCtrl = TextEditingController(text: current.user);
  final passCtrl = TextEditingController(text: current.pass);
  final portCtrl = TextEditingController(text: current.port.toString());

  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Configurar FTP'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: urlCtrl,
            decoration: const InputDecoration(
              labelText: 'URL / Host',
              hintText: 'ftp://example.com',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: portCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Puerto',
              hintText: '21',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: userCtrl,
            decoration: const InputDecoration(
              labelText: 'Usuario',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: passCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(Messages.CANCEL),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('SAVE'),
        ),
      ],
    ),
  );

  if (ok != true) return;

  final url = urlCtrl.text.trim();
  final user = userCtrl.text.trim();
  final pass = passCtrl.text.trim();
  final portStr = portCtrl.text.trim();

  // English comment: "Validate fields"
  if (url.isEmpty || user.isEmpty || pass.isEmpty || portStr.isEmpty) {
    showWarningMessage(context, ref, Messages.ERROR_EMPTY_FIELDS);
    return;
  }

  // English comment: "URL must contain ftp"
  if (!url.toLowerCase().contains('ftp')) {
    showWarningMessage(context, ref, Messages.ERROR_FTP_URL);
    return;
  }

  // English comment: "Port must be numeric"
  final port = int.tryParse(portStr);
  if (port == null) {
    showWarningMessage(context, ref, Messages.ERROR_PORT_NUMBER);
    return;
  }

  await _saveFtpAccountConfig(
    FtpAccountConfig(url: url, user: user, pass: pass, port: port),
  );

  showSuccessMessage(context, ref, Messages.SAVED);
}
/// Load FTP config from local storage
FtpAccountConfig loadFtpAccountConfig() {
  final box = GetStorage();
  final url = (box.read<String>(kFtpUrlKey) ?? Memory.printerFileFtpServer).trim();
  final user = (box.read<String>(kFtpUserKey) ?? Memory.printerFileFtpServerUserName).trim();
  final pass = (box.read<String>(kFtpPassKey) ?? Memory.printerFileFtpServerPassword).trim();
  final port = box.read<int>(kFtpPortKey) ?? Memory.printerFileFtpServerPort;
  Memory.printerFileFtpServer = url ;
  Memory.printerFileFtpServerUserName = user ;
  Memory.printerFileFtpServerPassword = pass ;
  Memory.printerFileFtpServerPort = port ;
  return FtpAccountConfig(url: url, user: user, pass: pass, port: port);
}

/// Save FTP config to local storage
Future<void> _saveFtpAccountConfig(FtpAccountConfig cfg) async {
  final box = GetStorage();

  await box.write(kFtpUserKey, cfg.user);
  await box.write(kFtpUrlKey, cfg.url);
  await box.write(kFtpPassKey, cfg.pass);
  await box.write(kFtpPortKey, cfg.port);
  Memory.printerFileFtpServerUserName = cfg.user;
  Memory.printerFileFtpServerPassword = cfg.pass;
  Memory.printerFileFtpServerPort = cfg.port;
  Memory.printerFileFtpServer = cfg.url;
}
