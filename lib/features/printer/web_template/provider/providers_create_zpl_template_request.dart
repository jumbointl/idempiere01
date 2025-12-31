import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path_provider/path_provider.dart';

import '../../../products/domain/models/zpl_printing_template.dart';
import '../../../shared/data/memory.dart';
import '../../zpl/new/models/zpl_template.dart';
import '../models/create_zpl_template_request.dart';

// ----------------------------
// Request model
// ----------------------------

// ----------------------------
// Trigger provider (set this when user presses Create)
// ----------------------------
final createZplTemplateRequestProvider =
StateProvider.autoDispose<CreateZplTemplateRequest?>((ref) => null);

// ----------------------------
// Async upload provider
// ----------------------------
final uploadZplTemplateToFtpProvider = FutureProvider.autoDispose<bool?>((ref) async {
  final req = ref.watch(createZplTemplateRequestProvider);
  if (req == null) return null;

  // English comment: "Build ZplTemplate entity"
  final now = DateTime.now();
  final id = now.millisecondsSinceEpoch.toString();

  final zpl = ZplTemplate(
    id: id,
    templateFileName: buildTemplateFileName(req.content, req.isForPrinter),
    zplTemplateDf: req.isForPrinter ? req.content : '',
    zplReferenceTxt: req.isForPrinter ? '' : req.content,
    mode: req.mode,
    rowPerpage: req.rowsPerPage, // ✅ from UI
    isDefault: req.isDefault,     // ✅ from UI
    createdAt: now,
  );



  final jsonText = jsonEncode(zpl.toJson());

  // English comment: "Upload JSON to FTP into mode directory"
  return _uploadJsonToFtp(
    remoteDir: Memory.FTP_SERVER_ZPL_TEMPLATES_DIR,
    remoteFileName: '${zpl.templateFileName}.json',
    jsonText: jsonText,
    overwrite: req.overwrite,
  );
});

Future<bool> ftpFileExists({
  required String remoteDir,
  required String remoteFileName,
}) async {
  final userName = Memory.printerFileFtpServerUserName;
  final password = Memory.printerFileFtpServerPassword;
  final host = Memory.printerFileFtpServer;
  final port = Memory.printerFileFtpServerPort ?? 21;

  final ftp = FTPConnect(
    host,
    user: userName,
    pass: password,
    port: port,
    timeout: 20,
  );

  try {
    final connected = await ftp.connect();
    if (!connected) return false;

    await ftp.changeDirectory(remoteDir);

    // English comment: "List directory and check file names"
    final items = await ftp.listDirectoryContent();
    return items.any((e) => (e.name ?? '').toString() == remoteFileName);
  } catch (_) {
    return false;
  } finally {
    try {
      await ftp.disconnect();
    } catch (_) {}
  }
}

// ----------------------------
// Helpers
// ----------------------------
String buildTemplateFileName(
    String zplContent,
    bool isForPrinter,
    ) {
  // English comment: "Extract logical template name from ZPL"
  final baseName = extractTemplateNameFromZpl(zplContent);

  if (baseName == null || baseName.isEmpty) {
    throw Exception('No se pudo extraer el nombre del template desde el ZPL (^DF / ^XF).');
  }

  // English comment: "Use suffix to classify files on server"
  final suffix = isForPrinter
      ? ZplPrintingTemplate.filterOfFileToPrinter
      : ZplPrintingTemplate.filterOfFileToFillData;

  return '$baseName$suffix';
}

/// Extracts template name from ZPL content.
/// Supports:
///   ^DFE:MOV_CAT1.ZPL^FS
///   ^XFE:MOV_CAT1^FS
/// Returns null if not found.
String? extractTemplateNameFromZpl(String zpl) {
  // English comment: "Match ^DF or ^XF commands with optional .ZPL extension"
  final regex = RegExp(
    r'\^(DF|XF)[A-Z]?:\s*([A-Za-z0-9_\-]+)(?:\.ZPL)?\s*\^FS',
    caseSensitive: false,
    multiLine: true,
  );

  final match = regex.firstMatch(zpl);
  if (match == null) return null;

  return match.group(2); // MOV_CAT1
}

Future<bool> _uploadJsonToFtp({
  required String remoteDir,
  required String remoteFileName,
  required String jsonText,
  required bool overwrite,
}) async {
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

  try {
    final connected = await ftp.connect();
    if (!connected) return false;

    try {
      await ftp.changeDirectory(remoteDir);
    } catch (_) {
      await ftp.makeDirectory(remoteDir);
      await ftp.changeDirectory(remoteDir);
    }

    // English comment: "If overwrite is allowed, delete remote file first"
    if (overwrite) {
      try {
        await ftp.deleteFile(remoteFileName);
      } catch (_) {
        // ignore if not found
      }
    }

    final tmpDir = await getTemporaryDirectory();
    final local = File('${tmpDir.path}/$remoteFileName');
    await local.writeAsString(jsonText, flush: true);

    final ok = await ftp.uploadFile(local);

    try {
      await local.delete();
    } catch (_) {}

    return ok;
  } finally {
    try {
      await ftp.disconnect();
    } catch (_) {}
  }
}

Future<void> deleteTemplateJsonFromFtp({
  required String remoteDir,
  required String fileName,
}) async {
  final ftp = FTPConnect(
    Memory.printerFileFtpServer,
    user: Memory.printerFileFtpServerUserName,
    pass: Memory.printerFileFtpServerPassword,
    port: Memory.printerFileFtpServerPort ?? 21,
    timeout: 20,
  );

  try {
    final connected = await ftp.connect();
    if (!connected) throw Exception('No se pudo conectar al FTP');

    await ftp.changeDirectory(remoteDir);

    // English comment: "Try delete; ignore if not found"
    try {
      await ftp.deleteFile(fileName);
    } catch (_) {
      // ignore
    }
  } finally {
    try {
      await ftp.disconnect();
    } catch (_) {}
  }
}


