import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/printer/web_template/screen/show_ftp_configuration.dart';
import '../../../products/common/widget/app_initializer_overlay.dart';
import '../../../products/common/messages_dialog.dart';
import '../../../products/domain/models/zpl_printing_template.dart';
import '../../../products/presentation/providers/common_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../zpl/new/models/zpl_template.dart';
import '../../zpl/new/provider/template_zpl_utils.dart';
import '../models/create_zpl_template_request.dart';
import '../models/printer_config.dart';
import '../provider/provider_printer_config.dart';
import '../provider/providers_create_zpl_template_request.dart';
import '../provider/zpl_web_template_extractor.dart';

// Your socket function

class CreateZplTemplatePage extends ConsumerStatefulWidget {
  const CreateZplTemplatePage({super.key});

  @override
  ConsumerState<CreateZplTemplatePage> createState() => _CreateZplTemplatePageState();
}

class _CreateZplTemplatePageState extends ConsumerState<CreateZplTemplatePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _contentCtrl = TextEditingController();
  final TextEditingController _rowsCtrl = TextEditingController(text: '18');

  int count = 0;
  ZplTemplateMode _mode = ZplTemplateMode.movement;
  bool _isForPrinter = true;
  bool _isDefault = false;

  ZplTemplate? _selectedPrinterTemplate;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    loadFtpAccountConfig() ;
    _tabController = TabController(length: 2, vsync: this);

    // English comment: "Load templates for movement after first frame"
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contentCtrl.dispose();
    _rowsCtrl.dispose();
    super.dispose();
  }
  void _setMode(ZplTemplateMode m) {
    setState(() => _mode = m);
    // Optional: clear selection when mode changes
    setState(() => _selectedPrinterTemplate = null);
  }


  @override
  Widget build(BuildContext context) {
    final asyncTpl = ref.watch(findZplPrintingTemplateProvider);
    final uploadAsync = ref.watch(uploadZplTemplateToFtpProvider);

    // English comment: "Close page on successful upload"
    ref.listen<AsyncValue<bool?>>(uploadZplTemplateToFtpProvider, (_, next) {
      next.whenOrNull(
        data: (ok) {
          if (ok == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Template subido al FTP ✅')),
            );
          }
        },
      );
    });

    final isLoading = uploadAsync.isLoading;
    final printerColor = ref.watch(printerColorProvider);
    final printerLabel = ref.watch(printerLabelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZPL Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_outlined),
            tooltip: 'Configurar FTP',
            onPressed: () async {
              await showFtpAccountConfiguration(ref,context);
            }
          ),
          IconButton(
            icon: Icon(Icons.print,color: printerColor),
            tooltip: 'Configurar impresora',
            onPressed: () => _openPrinterDialog(context),
          ),

        ],
      ),
      body: SafeArea(
        child:  AppInitializerOverlay(
          child: Column(
            children: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(minHeight: 36),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  children: [
                    const Text(
                      'Mode:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<ZplTemplateMode>(
                      value: _mode,
                      items: ZplTemplateMode.values
                          .map(
                            (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.name, style: const TextStyle(fontSize: themeFontSizeLarge)),
                        ),
                      )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        _setMode(v);
                      },
                    ),
                    const Spacer(),
                    // (optional) manual refresh button
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: () {
                        // English comment: "Re-trigger fetch for current mode"
                        var mode = ZplTemplateMode.movement;
                        if(count.isEven){
                            mode = ZplTemplateMode.shipping;
                        } else {
                            mode = ZplTemplateMode.movement;
                        }
                        count++;

                        ref.read(modeOfPrintToSearchAtFtpProvider.notifier).state = mode;
                      },
                      icon: const Icon(Icons.download,color: Colors.purple,),
                    ),
                  ],
                ),
              ),
              // Small printer info bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.print,
                      size: 18,
                      color: printerColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        printerLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: printerColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'To printer'),
                        Tab(text: 'Create'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // ================= TAB 1: TO PRINTER =================
                          asyncTpl.when(
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (e, _) => Center(child: Text('Error: $e')),
                            data: (data) {
                              if (data == null || data.templateFilesToPrinter.isEmpty) {
                                return const Center(child: Text('No hay templates para impresora'));
                              }

                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.print),
                                        label: const Text('Send all'),
                                        onPressed: printerColor != Colors.green
                                            ? null
                                            : () => _sendAllTemplatesToPrinter(data.templateFilesToPrinter),
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: data.templateFilesToPrinter.length,
                                      itemBuilder: (_, i) {
                                        final t = data.templateFilesToPrinter[i];
                                        final selected = _selectedPrinterTemplate?.id == t.id;

                                        final name = t.templateFileName
                                            .split(ZplPrintingTemplate.filterOfFileToPrinter)
                                            .first;

                                        return ListTile(
                                          title: Text(name),
                                          subtitle: const Text('TEMPLATE ZPL'),
                                          leading: selected
                                              ? const Icon(Icons.check_circle)
                                              : const Icon(Icons.description),
                                          onTap: () => setState(() => _selectedPrinterTemplate = t),

                                          // English comment: "Actions: delete, copy, print"
                                          trailing: Wrap(
                                            spacing: 8,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.copy),
                                                tooltip: 'Copiar contenido para editar',
                                                onPressed: () => _copyTemplateToEditor(t),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline),
                                                tooltip: 'Borrar del FTP',
                                                onPressed: () => _confirmAndDeleteFromFtp(t),
                                              ),
                                              printerColor != Colors.green
                                                  ? const SizedBox(width: 40)
                                                  : IconButton(
                                                icon: Icon(Icons.print, color: printerColor),
                                                tooltip: 'Enviar a impresora',
                                                onPressed: () => _sendSelectedTemplateToPrinter(t),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          // ================= TAB 2: CREATE =================
                          _buildCreateTab(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  /// Send all templates to the configured printer (sequential)
  Future<void> _sendAllTemplatesToPrinter(List<ZplTemplate> templates) async {
    final cfg = ref.read(printerConfigProvider);

    if (cfg == null || !cfg.isConfigured) {
      showErrorMessage(context, ref, 'Configura la impresora primero 🖨️');
      return;
    }

    if (templates.isEmpty) {
      showErrorMessage(context, ref, 'No hay templates para enviar');
      return;
    }

    // English comment: "Block UI while sending all templates"
    ref.read(initializingProvider.notifier).state = true;
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      for (int i = 0; i < templates.length; i++) {
        final t = templates[i];
        final zpl = t.zplTemplateDf.trim();

        if (zpl.isEmpty) {
          final msg =
              '${Messages.ERROR_TO_SEND_TO_PRINTER}${i + 1} ${t.templateFileName}';
          showErrorMessage(context, ref, msg);
          return; // Abort on first failure
        }

        final result = await sendZplBySocket(
          ip: cfg.ip,
          port: cfg.port,
          zpl: zpl,
        );

        if (result != true) {
          final msg =
              '${Messages.ERROR_TO_SEND_TO_PRINTER}${i + 1} ${t.templateFileName}';
          if(context.mounted) showErrorMessage(context, ref, msg);
          return; // Abort on first failure
        }
      }

      final okMsg =
          '${Messages.SUCCESS_TO_SEND_TO_PRINTER}${templates.length} ${Messages.FILES}';
      if(context.mounted) {
        showSuccessMessage(context, ref, okMsg);
      }
    } catch (e) {
      final msg = '${Messages.ERROR_TO_SEND_TO_PRINTER} $e';
      if(context.mounted) showErrorMessage(context, ref, msg);
    } finally {
      ref.read(initializingProvider.notifier).state = false;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // -------------------- TAB 2 UI --------------------
  Widget _buildCreateTab(BuildContext context) {
    final isLoading = ref.watch(uploadZplTemplateToFtpProvider).isLoading;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // rows + default (switch)
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _rowsCtrl,
                enabled: !isLoading,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rows per page',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  const Text('Default'),
                  const SizedBox(width: 8),
                  Switch(
                    value: _isDefault,
                    onChanged: isLoading ? null : (v) => setState(() => _isDefault = v),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // toggle DF / reference
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Template DF'),
                selected: _isForPrinter,
                onSelected: isLoading ? null : (_) => setState(() => _isForPrinter = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Reference'),
                selected: !_isForPrinter,
                onSelected: isLoading ? null : (_) => setState(() => _isForPrinter = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _contentCtrl,
          enabled: !isLoading,
          minLines: 10,
          maxLines: 18,
          decoration: InputDecoration(
            labelText: _isForPrinter ? 'zplTemplateDf' : 'zplReferenceTxt',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
                child: Text(Messages.CANCEL),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : _onCreatePressed,
                child: const Text('CREAR'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------- AppBar dialog: IP + port --------------------
  Future<void> _openPrinterDialog(BuildContext context) async {
    final current = ref.read(printerConfigProvider);

    final ipCtrl = TextEditingController(text: current?.ip ?? '');
    final portCtrl =
    TextEditingController(text: (current?.port ?? 9100).toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Configurar impresora'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipCtrl,
              decoration: const InputDecoration(
                labelText: 'IP',
                hintText: '192.168.1.100',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Puerto',
                hintText: '9100',
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
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final ip = ipCtrl.text.trim();
      final port = int.tryParse(portCtrl.text.trim()) ?? 9100;

      ref.read(printerConfigProvider.notifier).state = PrinterConfig(
        ip: ip,
        port: port,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impresora configurada: $ip:$port')),
        );
      }
    }
  }


  // -------------------- ListTile actions --------------------
  void _copyTemplateToEditor(ZplTemplate t) {
    // English comment: "Copy ZPL into editor and switch to Create tab"
    _contentCtrl.text = t.zplTemplateDf;
    setState(() {
      _isForPrinter = true;
    });
    _tabController.animateTo(1);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contenido copiado al editor ✅')),
    );
  }

  Future<void> _sendSelectedTemplateToPrinter(ZplTemplate t) async {
    /*final ip = _printerIp.trim();
    final port = _printerPort;

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configura IP de la impresora primero 🖨️')),
      );
      return;
    }*/

    final zpl = t.zplTemplateDf.trim();
    if (zpl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El template no tiene zplTemplateDf')),
      );
      return;
    }
    final cfg = ref.read(printerConfigProvider);

    if (cfg == null || !cfg.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configura la impresora primero 🖨️')),
      );
      return;
    }
    try {
      // English comment: "Send to printer under loading dialog"
      ref.read(initializingProvider.notifier).state = true;
      await Future.delayed(const Duration(milliseconds: 100));

      final result = await sendZplBySocket(
        ip: cfg.ip,
        port: cfg.port,
        zpl: zpl,
      );

      ref.read(initializingProvider.notifier).state = false;
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;
      String msg = 'Enviado a ${cfg.ip}:${cfg.port} ✅';
      if(result != true){
        msg = 'Error enviando: ${cfg.ip}:${cfg.port}: $result';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error enviando: $e')),
      );
    }
  }


  Future<void> _confirmAndDeleteFromFtp(ZplTemplate t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('¿Borrar "${t.templateFileName}.json" del FTP?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(Messages.CANCEL),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('BORRAR'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // English comment: "Run FTP delete under a blocking loading dialog"
      if (!mounted) return;
      ref.read(initializingProvider.notifier).state = true;
      await Future.delayed(const Duration(milliseconds: 100));
      await deleteTemplateJsonFromFtp(
        remoteDir: Memory.FTP_SERVER_ZPL_TEMPLATES_DIR,
        fileName: '${t.templateFileName}.json',
      );
      ref.read(initializingProvider.notifier).state = false;
      await Future.delayed(const Duration(milliseconds: 100));


      // English comment: "Refresh the list after deletion"
      ref.invalidate(findZplPrintingTemplateProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Archivo borrado ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error borrando: $e')),
      );
    }
  }


  // -------------------- Create button --------------------
  Future<void> _onCreatePressed() async {
    final content = _contentCtrl.text.trim();
    final rows = int.tryParse(_rowsCtrl.text.trim());

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El contenido no puede estar vacío.')),
      );
      return;
    }
    if (rows == null || rows <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rows per page debe ser > 0.')),
      );
      return;
    }

    final name = extractTemplateNameFromZpl(content);
    if (name == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró ^DF o ^XF en el ZPL.')),
      );
      return;
    }
// English comment: "Validate missing tokens before continuing"
    final fakeTemplate = ZplTemplate(
      id: 'temp',
      mode: _mode,
      rowPerpage: rows,
      zplTemplateDf: '',
      templateFileName: '',
      isDefault: false,
      zplReferenceTxt: content,
      createdAt: DateTime.now(),
    );

    final missingTokens = validateMissingTokens(
      template: fakeTemplate,
      referenceTxt: content,
    );

    if (missingTokens.isNotEmpty) {
      await _showMissingTokensDialog(missingTokens);
      return; // Abort creation
    }
    // English comment: "Compute remote filename from ZPL content"
    final baseFileName = buildTemplateFileName(content, _isForPrinter); // MOV_CAT1 + suffix
    final remoteFileName = '$baseFileName.json';
    final remoteDir = Memory.FTP_SERVER_ZPL_TEMPLATES_DIR;

    bool overwrite = false;

    try {
      // English comment: "Check collision under loading"
      ref.read(initializingProvider.notifier).state = true;
      await Future.delayed(const Duration(milliseconds: 100));
      final exists = await ftpFileExists(
        remoteDir: remoteDir,
        remoteFileName: remoteFileName,
      );
      ref.read(initializingProvider.notifier).state = false;
      await Future.delayed(const Duration(milliseconds: 100));


      if (exists == true) {
        if(!context.mounted) return;
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Archivo existente'),
            content: Text(
              'Ya existe "$remoteFileName" en FTP.\n¿Quieres sobrescribirlo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(Messages.CANCEL),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('SOBRESCRIBIR'),
              ),
            ],
          ),
        );

        if (ok != true) return;
        overwrite = true;
      }
    } catch (e) {
      // English comment: "Collision check failed"
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verificando colisión: $e')),
      );
      return;
    }

    // English comment: "Trigger upload provider (the provider may delete if overwrite=true)"
    ref.read(createZplTemplateRequestProvider.notifier).state = CreateZplTemplateRequest(
      mode: _mode,
      isForPrinter: _isForPrinter,
      content: content,
      rowsPerPage: rows,
      isDefault: _isDefault,
      overwrite: overwrite,
    );
  }
  /// Show missing token errors and abort creation
  Future<void> _showMissingTokensDialog(List<String> missing) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tokens faltantes en el template'),
        content: SizedBox(
          width: double.maxFinite,
          height: 240,
          child: ListView.separated(
            itemCount: missing.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: Text(missing[i]),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


}
