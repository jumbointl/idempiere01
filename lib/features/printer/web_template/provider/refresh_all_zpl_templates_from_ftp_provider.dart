import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path_provider/path_provider.dart';

import '../../../products/common/utils/common_string_utils.dart';
import '../../../shared/data/memory.dart';
import '../../zpl/new/models/zpl_template.dart';
import '../screen/show_ftp_configuration.dart';

final refreshAllZplTemplatesFromFtpProvider =
StateProvider.autoDispose<int>((ref) => 0);

final findAllZplTemplatesFromFtpProvider =
FutureProvider.autoDispose<List<ZplTemplate>>((ref) async {
  // Re-run when refreshed
  final  count = ref.watch(refreshAllZplTemplatesFromFtpProvider);
  if(count==0) return [];
  loadFtpAccountConfig();
  final userName = Memory.printerFileFtpServerUserName;
  final password = Memory.printerFileFtpServerPassword;
  final host = Memory.printerFileFtpServer;
  final port = Memory.printerFileFtpServerPort ?? 21;

  final ftp = FTPConnect(
    host,
    user: userName,
    pass: password,
    port: port,
    timeout: 25,
  );

  final List<ZplTemplate> out = [];
  final tmpDir = await getTemporaryDirectory();

  // English comment: "Only scan directories whose name matches enum values"

  final dirName = Memory.FTP_SERVER_ZPL_TEMPLATES_DIR;

  try {
    final connected = await ftp.connect();
    if (!connected) return out;
      // English comment: "Enter mode directory if it exists"
      try {
        await ftp.changeDirectory(dirName);
      } catch (_) {
        // Directory doesn't exist yet -> skip
        return [];
      }

      // English comment: "List JSON files in this mode directory"
      final items = await ftp.listDirectoryContent();
      final jsonFiles = items
          .where((e) => e.type == FTPEntryType.file)
          .map((e) => (e.name ?? '').toString())
          .where((name) =>
      name.toLowerCase().endsWith('.json')) // ✅ SOLO fill_data
          .toList();
      for (final fileName in jsonFiles) {
        final localFile = File('${tmpDir.path}/${dirName}__$fileName');
        final ok = await ftp.downloadFile(fileName, localFile);
        if (!ok) continue;

        try {
          final raw = await localFile.readAsString();
          final cleaned = sanitizeJsonText(raw);

          final map = jsonDecode(cleaned) as Map<String, dynamic>;
          final t = ZplTemplate.fromJson(map);

          // English comment: "If JSON mode is wrong/missing, you can enforce by directory"
          // out.add(t.copyWith(mode: ZplTemplateMode.values.firstWhere((m)=>m.name==dirName)));
          out.add(t);
        } catch (_) {
          // skip invalid file
        } finally {
          try {
            await localFile.delete();
          } catch (_) {}
        }
      }

      // English comment: "Go back to root"
      try {
        await ftp.changeDirectory('..');
      } catch (_) {}

    // English comment: "Sort by mode then newest first"
    out.sort((a, b) {
      final m = a.mode.name.compareTo(b.mode.name);
      if (m != 0) return m;
      return b.createdAt.compareTo(a.createdAt);
    });

    return out;
  } finally {
    try {
      await ftp.disconnect();
    } catch (_) {}
  }
});


