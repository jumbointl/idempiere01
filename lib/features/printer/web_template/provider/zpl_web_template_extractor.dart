import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../../products/common/utils/common_string_utils.dart';
import '../../../products/domain/models/zpl_printing_template.dart';
import '../../../products/domain/models/zpl_printing_template_movement.dart';
import '../../../shared/data/memory.dart';
import '../../zpl/new/models/zpl_template.dart';
import '../../zpl/new/models/zpl_template_store.dart';
import '../screen/show_ftp_configuration.dart';

final modeOfPrintToSearchAtFtpProvider =
StateProvider.autoDispose<ZplTemplateMode?>((ref) => null);

final resultOfPrintToSearchAtFtpProvider =
StateProvider<ZplPrintingTemplate?>((ref) => null);

final findZplPrintingTemplateProvider =
FutureProvider.autoDispose<ZplPrintingTemplate?>((ref) async {
  final mode = ref.watch(modeOfPrintToSearchAtFtpProvider);
  if (mode == null) {
    ZplPrintingTemplate template = ZplPrintingTemplate(
      directory: Memory.FTP_SERVER_ZPL_TEMPLATES_DIR,
      templateFilesToPrinter: [],
      filesCanUseToFillData: [],
    );
    ZplTemplateStore store = ZplTemplateStore(GetStorage());
    List<ZplTemplate> all = store.loadAll();
    for(int i = 0; i < all.length; i++) {
      ZplTemplate t = all[i];
      if(t.templateFileName.contains(ZplPrintingTemplate.filterOfFileToPrinter)){
        template.templateFilesToPrinter.add(t);
      } else if (t.templateFileName.contains(ZplPrintingTemplate.filterOfFileToFillData)) {
        template.filesCanUseToFillData.add(t);
      }
  }
    return template;
  }
  loadFtpAccountConfig();
  final userName = Memory.printerFileFtpServerUserName;
  final password = Memory.printerFileFtpServerPassword;
  final host = Memory.printerFileFtpServer;
  final port = Memory.printerFileFtpServerPort ?? 21;

  final remoteDir = Memory.FTP_SERVER_ZPL_TEMPLATES_DIR;

  final ftp = FTPConnect(
    host,
    user: userName,
    pass: password,
    port: port,
    timeout: 20,
  );

  final List<ZplTemplate> printerTemplates = [];
  final List<ZplTemplate> fillDataTemplates = [];

  try {
    final connected = await ftp.connect();
    if (!connected) return null;

    // Change to mode directory (e.g. /movement)
    await ftp.changeDirectory(remoteDir);

    // List files
    final files = await ftp.listDirectoryContent();

    // Temp directory to download files
    final tmpDir = await getTemporaryDirectory();

    for (final f in files) {
      final fileName = (f.name ?? '').toString().trim();
      if (fileName.isEmpty) continue;

      // Only JSON files are relevant here
      if (!fileName.toLowerCase().endsWith('.json')) continue;

      // Download file to temp
      final localFile = File('${tmpDir.path}/$fileName');
      if (await localFile.exists()) {
        try {
          await localFile.delete();
        } catch (_) {}
      }

      final ok = await ftp.downloadFile(fileName, localFile);
      if (!ok) continue;

      // Read and parse
      final raw = await localFile.readAsString();
      final cleaned = sanitizeJsonText(raw);

      Map<String, dynamic> map;
      try {
        map = jsonDecode(cleaned) as Map<String, dynamic>;
      } catch (e) {
        // If JSON is broken, skip this file
        // English comment: "Skip invalid JSON file"
        continue;
      }

      final template = ZplTemplate.fromJson(map);

      // Classify by file name
      if (fileName.contains(ZplPrintingTemplate.filterOfFileToPrinter)) {
        printerTemplates.add(template);
      } else if (fileName.contains(ZplPrintingTemplate.filterOfFileToFillData)) {
        fillDataTemplates.add(template);
      }
    }

    // Build result based on mode
    ZplPrintingTemplate result;
    switch (mode) {
      case ZplTemplateMode.movement:
      case ZplTemplateMode.shipping:
        result = ZplPrintingTemplateMovement(
          directory: remoteDir,
          templateFilesToPrinter: printerTemplates,
          filesCanUseToFillData: fillDataTemplates,
        );
        break;


    }

    // Store in provider for other screens if needed
    ref.read(resultOfPrintToSearchAtFtpProvider.notifier).state = result;

    return result;
  } finally {
    try {
      await ftp.disconnect();
    } catch (_) {}
  }
});

