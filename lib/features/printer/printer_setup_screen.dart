import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/printer/pos/pos_adjustment_selector_sheet.dart';
import 'package:monalisa_app_001/features/printer/pos/pos_adjustment_values.dart';
import 'package:monalisa_app_001/features/printer/pos/print_ticket_by_socket_action_provider.dart';
import 'package:monalisa_app_001/features/printer/pos/show_printer_raw_9100_diagnostic_dialog.dart';
import 'package:monalisa_app_001/features/printer/pos/show_socket_timeout_selector_dialog.dart';
import 'package:monalisa_app_001/features/printer/printer_utils.dart';
import 'package:monalisa_app_001/features/printer/web_template/screen/show_ftp_configuration.dart';
import 'package:monalisa_app_001/features/printer/web_template/screen/show_search_zpl_template_sheet.dart';
import 'package:monalisa_app_001/features/printer/widgets/printer_commands_menu.dart';
import 'package:monalisa_app_001/features/printer/zpl/new/models/locator_zpl_template.dart';
import 'package:monalisa_app_001/features/printer/zpl/new/models/locator_zpl_template_provider.dart';
import 'package:monalisa_app_001/features/printer/zpl/new/models/zpl_template.dart';
import 'package:monalisa_app_001/features/printer/zpl/new/models/zpl_template_store.dart';
import 'package:monalisa_app_001/features/printer/zpl/new/provider/always_use_last_template_provider.dart';
import 'package:monalisa_app_001/features/printer/zpl/new/provider/template_zpl_utils.dart';
import 'package:monalisa_app_001/features/printer/zpl/new/screen/template_zpl_on_use_sheet.dart';
import 'package:monalisa_app_001/features/products/common/widget/app_initializer_overlay.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../products/common/messages_dialog.dart';
import '../products/common/widget_utils.dart';
import '../products/domain/idempiere/movement_and_lines.dart';
import '../products/presentation/providers/common_provider.dart';
import '../products/presentation/providers/product_provider_common.dart';
import '../shared/data/memory.dart';
import '../shared/data/messages.dart';
import 'cups_printer.dart';
import 'models/mo_printer.dart';
import 'movement_pdf_generator.dart';
import 'printer_scan_notifier.dart';

class PrinterSetupScreen extends ConsumerStatefulWidget {
  final dynamic dataToPrint;
  final int oldAction;

  final bool noDeleteFlag = false; // state
  final FocusNode focusNode = FocusNode();
  final int actionTypeInt = Memory.ACTION_FIND_PRINTER_BY_QR;
  String scannedData = '';

  String get cupsPrinterName {
    return 'BR_HL_10003';
  }

  PrinterSetupScreen({
    super.key,
    this.dataToPrint,
    required this.oldAction,
  });

  @override
  PrinterSetupScreenState createState() => PrinterSetupScreenState();

  void popScopeAction(BuildContext context, WidgetRef ref) {
    try{
      ref
          .read(actionScanProvider.notifier)
          .state = oldAction ;
    } catch (e) {
      debugPrint('popScopeAction: $e');
    }


    Navigator.of(context).pop();
  }

  Future<void> actionAfterWidgetBuild(BuildContext context,
      WidgetRef ref) async {
    bool b1 = ref.read(enableScannerKeyboardProvider);
    bool b2 = ref.read(isDialogShowedProvider);
    if (b1 && !b2) {
      FocusScope.of(context).requestFocus(focusNode);
    }
  }

  Future<void> actionAfterWidgetBuildInitState(BuildContext context,
      WidgetRef ref) async {

    final storedValue = loadAlwaysUseLastTemplate();
    ref
        .read(alwaysUseLastTemplateProvider.notifier)
        .state = storedValue;
  }

  Widget printerSetupScreenBody(BuildContext context, WidgetRef ref,
      {dynamic dataToPrint}) {
    // El FocusNode debe ser solicitado explícitamente después de que el widget se construya.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      actionAfterWidgetBuild(context, ref);
    });

    return KeyboardListener(
      focusNode: focusNode, // Usar un FocusNode separado para el listener
      onKeyEvent: (event) => _handleKeyEvent(ref, focusNode, event),
      child: Scaffold(

        appBar: AppBar(
          centerTitle: false,
          automaticallyImplyLeading: true,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async =>
              {
                popScopeAction(context, ref),

              }
            //
          ),
          title: Text(Messages.SELECT_A_PRINTER,
            style: TextStyle(fontSize: themeFontSizeNormal),),
          actions: [
            TextButton.icon(
              onPressed: () => _startCameraScan(context, ref),
              icon: const Icon(Icons.camera, color: Colors.purple, size: 18),
              label: const Text(
                'SCAN',
                style: TextStyle(color: Colors.purple, fontSize: 12),
              ),

              style: TextButton.styleFrom(
                // o menor tamanho possível
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: const Size(0, 30),
                // altura mínima reduzida
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
                side: const BorderSide(color: Colors.purple),
              ),
            ),

            const SizedBox(width: 4),
            // 👇 MENÚ DE COMANDOS ZPL / TSPL
            PrinterCommandsMenu(
              onConfigFtpAccount: () async {
                await showFtpAccountConfiguration(ref, context);
              },
              onLoadZplTemplate: () async {
                final results = await showSearchZplTemplateSheet(
                  context: context, ref: ref,
                  mode: ZplTemplateMode.movement,);
                if (results != null && results.isNotEmpty) {
                  if (context.mounted) {
                    String message = '${results.length} ${Messages
                        .ZPL_TEMPLATE_LOADED}';
                    showSuccessMessage(context, ref, message);
                  }
                }
              },
              onUseZplTemplate: () async {
                onUseZplTemplate(context, ref);
              },
              onConfigurePos: () async {
                String p = ref
                    .read(printerScanNotifierProvider)
                    .portController
                    .text;
                int port = int.tryParse(p) ?? 9100;

                debugPrint('printReceiptWithQrWithBematech');
                ref
                    .read(isDialogShowedProvider.notifier)
                    .state = true;
                ref
                    .read(enableScannerKeyboardProvider.notifier)
                    .state = false;
                final actual = ref.read(actionScanProvider);
                ref
                    .read(actionScanProvider.notifier)
                    .state = Memory.ACTION_NO_SCAN_ACTION;


                final PosAdjustmentValues? adj = await showPosAdjustmentSelectorSheet(
                  context: ref.context,
                  ref: ref,
                  ip: ref
                      .read(printerScanNotifierProvider)
                      .ipController
                      .text,
                  port: port,
                  alwaysOpen: true,
                );

                ref
                    .read(enableScannerKeyboardProvider.notifier)
                    .state = true;
                ref
                    .read(actionScanProvider.notifier)
                    .state = actual;
                ref
                    .read(isDialogShowedProvider.notifier)
                    .state = false;
                if (adj == null) return;
              },
              onConfigureSocketTimeout: () async {
                ref
                    .read(isDialogShowedProvider.notifier)
                    .state = true;
                ref
                    .read(enableScannerKeyboardProvider.notifier)
                    .state = false;

                await showSocketTimeoutSelectorDialog(
                  context: context,
                  ref: ref,
                );

                ref
                    .read(enableScannerKeyboardProvider.notifier)
                    .state = true;
                ref
                    .read(isDialogShowedProvider.notifier)
                    .state = false;
              },
              onDiagnoseRaw9100: () async {
                // Reusar tu patrón para bloquear scanner mientras hay dialog
                ref
                    .read(isDialogShowedProvider.notifier)
                    .state = true;
                ref
                    .read(enableScannerKeyboardProvider.notifier)
                    .state = false;

                // Conseguir IP/port actuales (adaptalo a tu modelo/provider real)
                final ip = ref
                    .read(printerScanNotifierProvider)
                    .ipController
                    .text;
                String portString = ref
                    .read(printerScanNotifierProvider)
                    .portController
                    .text;

                final port = int.tryParse(portString) ??
                    9100; // o selectedPrinter.port

                await showPrinterRaw9100DiagnosticDialog(
                  context: context,
                  ref: ref,
                  ip: ip,
                  port: port,
                );

                ref
                    .read(enableScannerKeyboardProvider.notifier)
                    .state = true;
                ref
                    .read(isDialogShowedProvider.notifier)
                    .state = false;
              },


            ),
            SizedBox(width: 8,),
          ],

        ),
        body: _buildSetupTab(ref, context),

      ),
    );
  }

  KeyEventResult _handleKeyEvent(WidgetRef ref, FocusNode node,
      KeyEvent event) {
    final enabled = ref.watch(enableScannerKeyboardProvider);
    if (!enabled) {
      return KeyEventResult.ignored;
    }

    // Escuchar solo el evento KeyDown para evitar duplicados
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        // Cuando se presiona Enter, procesamos los datos acumulados
        if (scannedData.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 100), () {
            ref.read(printerScanNotifierProvider.notifier).updateFromScan(
                scannedData, ref);
            // Limpiar los datos escaneados para el próximo escaneo
            scannedData = '';
          });
        }
        // Devolver handled para evitar que el evento se propague
        return KeyEventResult.handled;
      } else
      if (event.logicalKey.keyLabel.isNotEmpty && event.character != null) {
        // Acumular los caracteres de las teclas presionadas
        scannedData += event.character!;
        return KeyEventResult.handled;
      }
    }
    // Devolver ignored para permitir que el evento continúe propagándose
    return KeyEventResult.ignored;
  }


  // Iniciar escaneo con cámara
  Future<void> _startCameraScan(BuildContext context, WidgetRef ref) async {
    if (await Permission.camera
        .request()
        .isGranted) {
      if (ref.context.mounted) {
        String? result = await SimpleBarcodeScanner.scanBarcode(
          ref.context,
          barcodeAppBar: BarcodeAppBar(
            appBarTitle: Messages.SCANNING,
            centerTitle: false,
            enableBackButton: true,
            backButtonIcon: Icon(Icons.arrow_back_ios),
          ),
          isShowFlashIcon: true,
          delayMillis: 300,
          cameraFace: CameraFace.back,
        );
        if (result != null) {
          Future.delayed(const Duration(milliseconds: 100), () {});
          ref.read(printerScanNotifierProvider.notifier).updateFromScan(
              result, ref);
        } else {
          if (ref.context.mounted) {
            showWarningMessage(
              ref.context, ref, Messages.ERROR_SCAN);
          }
        }
      }
    } else {
      if (ref.context.mounted) {
        showWarningMessage(ref.context, ref, Messages.ERROR_CAMERA_PERMISSION);
      }
    }
  }

  Future<void> onUseZplTemplate(BuildContext context,
      WidgetRef ref,) async {
    try {
      final store = ZplTemplateStore(GetStorage());

      final selected = await showUseZplTemplateSheet(
        context: context,
        ref: ref,
        store: store,
      );

      if (selected == null) return;
    } catch (e) {
      if (context.mounted) {
        showWarningMessage(
          context, ref, 'Error usando template: $e');
      }
    }
  }

  Widget getCopiesPanel(BuildContext context, WidgetRef ref, int copies) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Text(
                  'Copies',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: copies <= 1
                      ? null
                      : () =>
                      ref
                          .read(locatorZplCopiesProvider.notifier)
                          .setCopies(copies - 1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$copies',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref
                          .read(locatorZplCopiesProvider.notifier)
                          .setCopies(copies + 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildSetupTab(WidgetRef ref, BuildContext context) {
    final async = ref.watch(sendCommandBySocketProvider);
    final printerState = ref.watch(printerScanNotifierProvider);
    final savedPrinters = ref.watch(savedPrintersProvider);
    final isPrinting = ref.watch(isPrintingProvider);
    return AppInitializerOverlay(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;
          }
          popScopeAction(context, ref);
        },

        child: isPrinting ? LinearProgressIndicator() : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 5,
                children: [

                  Text(Messages.TOUCH_ON_TEXTFIELD_UNTIL_KEYBOARD_IS_OPEN,
                      style: TextStyle(fontSize: 10)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        flex: 2,
                        child: CompactEditableField(
                          label: Messages.IP,
                          controller: printerState.ipController,
                          keyboardType: TextInputType.text,
                          onTapAction: (ref) {
                            ref
                                .read(enableScannerKeyboardProvider.notifier)
                                .state = false;
                            focusNode.unfocus();
                          },
                          onEditingCompleteAction: (ref) {
                            FocusScope.of(context).unfocus();
                            ref
                                .read(enableScannerKeyboardProvider.notifier)
                                .state = true;
                            focusNode.requestFocus();
                          },
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: CompactEditableField(
                            label: Messages.PORT,
                            controller: printerState.portController,
                            keyboardType: TextInputType.number,
                            onTapAction: (ref) {
                              ref
                                  .read(enableScannerKeyboardProvider.notifier)
                                  .state = false;
                              focusNode.unfocus();
                            },
                            onEditingCompleteAction: (ref) {
                              FocusScope.of(context).unfocus();
                              ref
                                  .read(enableScannerKeyboardProvider.notifier)
                                  .state = true;
                              focusNode.requestFocus();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        flex: 2,
                        child: CompactEditableField(
                          label: Messages.NAME,
                          controller: printerState.nameController,
                          keyboardType: TextInputType.text,
                          onTapAction: (ref) {
                            ref
                                .read(enableScannerKeyboardProvider.notifier)
                                .state = false;
                            focusNode.unfocus();
                          },
                          onEditingCompleteAction: (ref) {
                            FocusScope.of(context).unfocus();
                            ref
                                .read(enableScannerKeyboardProvider.notifier)
                                .state = true;
                            focusNode.requestFocus();
                          },
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: CompactEditableField(
                            label: Messages.TYPE,
                            controller: printerState.typeController,
                            keyboardType: TextInputType.text,
                            onTapAction: (ref) {
                              ref
                                  .read(enableScannerKeyboardProvider.notifier)
                                  .state = false;
                              focusNode.unfocus();
                            },
                            onEditingCompleteAction: (ref) {
                              FocusScope.of(context).unfocus();
                              ref
                                  .read(enableScannerKeyboardProvider.notifier)
                                  .state = true;
                              focusNode.requestFocus();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        flex: 2,
                        child: CompactEditableField(
                          label: Messages.SERVER,
                          controller: printerState.serverIpController,
                          keyboardType: TextInputType.number,
                          onTapAction: (ref) {
                            ref
                                .read(enableScannerKeyboardProvider.notifier)
                                .state = false;
                            focusNode.unfocus();
                          },
                          onEditingCompleteAction: (ref) {
                            FocusScope.of(context).unfocus();
                            ref
                                .read(enableScannerKeyboardProvider.notifier)
                                .state = true;
                            focusNode.requestFocus();
                          },
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: CompactEditableField(
                            label: Messages.SERVER_PORT,
                            controller: printerState.serverPortController,
                            keyboardType: TextInputType.number,
                            onTapAction: (ref) {
                              ref
                                  .read(enableScannerKeyboardProvider.notifier)
                                  .state = false;
                              focusNode.unfocus();
                            },
                            onEditingCompleteAction: (ref) {
                              FocusScope.of(context).unfocus();
                              ref
                                  .read(enableScannerKeyboardProvider.notifier)
                                  .state = true;
                              focusNode.requestFocus();
                            },
                          ),
                        ),

                      ),
                    ],
                  ),
                  getDataPanel(context, ref, dataToPrint),

                  async.when(
                    data: (data) {
                      if (!data.isInitiated) {
                        return ListTile(
                            title: Text(Messages.WAIT_FOR_PRINT));
                      }

                      if (data.data == true) {
                        return ListTile(
                            leading: Icon(
                                Icons.check_circle, color: Colors.green),
                            trailing: Icon(
                                Icons.check_circle, color: Colors.green),
                            title: Text(Messages.PRINTED_SUCCESSFULLY));
                      } else {
                        return ListTile(
                            leading: Icon(Icons.error, color: Colors.red),
                            trailing: Icon(Icons.error, color: Colors.red),
                            title: Text(
                                '${Messages.PRINT_FAILED} : ${data.message ??
                                    'null'}'));
                      }
                    },
                    error: (error, stackTrace) {
                      return Text('${Messages.ERROR} $stackTrace ',
                        overflow: TextOverflow.ellipsis,);
                    },
                    loading: () {
                      return LinearProgressIndicator(minHeight: 36,);
                    },
                  ),

                  getPrintPanel(ref, context),

                  Row(
                    children: [
                      Expanded(
                        child: compactElevatedButton(
                          label: Messages.SELECT_A_PRINTER,
                          backgroundColor: themeColorPrimary,
                          onPressed: () async {
                            await openPrintDialog(ref, context);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      compactElevatedButton(
                        label: 'SAVE',
                        backgroundColor: themeColorPrimary,
                        onPressed: () async {
                          String ip = printerState.ipController.text.trim();
                          String port = printerState.portController.text.trim();
                          String type = printerState.typeController.text.trim();
                          String name = printerState.nameController.text.trim();
                          String serverIp = printerState.serverIpController.text
                              .trim();
                          String serverPort = printerState.serverPortController
                              .text.trim();

                          if (ip.isEmpty || port.isEmpty || type.isEmpty) {
                            showWarningMessage(
                                context, ref, Messages.ERROR_SAVE_PRINTER);
                            return;
                          }

                          final printer = MOPrinter()
                            ..name = name
                            ..ip = ip
                            ..port = port
                            ..type = type
                            ..serverIp = serverIp
                            ..noDelete = true
                            ..serverPort = serverPort;

                          await savePrinterToStorage(ref, printer);
                        },
                      ),
                    ],
                  ),

                  if (savedPrinters.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('Impresoras guardadas', style: TextStyle(
                          fontSize: themeFontSizeLarge,
                          fontWeight: FontWeight.bold,),),
                        Icon(Icons.star, color: Colors.green),
                        Text('= No borrar', style: TextStyle(
                          fontSize: themeFontSizeLarge,
                          fontWeight: FontWeight.bold,),),
                      ],
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: savedPrinters.length,
                      itemBuilder: (context, index) {
                        final p = savedPrinters[index];
                        final title = p.name?.isNotEmpty == true
                            ? p.name!
                            : '${p.ip ?? ''}:${p.port ?? ''}';

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12.0),
                          ),

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ==== CENTRO (TÍTULO + SUBTÍTULO) ====
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 13),
                                    Text(
                                      title,
                                      style: const TextStyle(fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${p.ip ?? ''}:${p.port ?? ''}  [${p
                                          .type ?? ''}]',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // ==== DERECHA (COPY + PRINT) ====
                              SizedBox(
                                width: 150,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [

                                    // ⭐ NO DELETE STAR
                                    IconButton(
                                      icon: Icon((p.noDelete ?? false)
                                          ? Icons.star
                                          : Icons.star_border),
                                      color: (p.noDelete ?? false) ? Colors
                                          .green : Colors.grey,
                                      iconSize: 24,
                                      // o el tamaño que desees
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      tooltip: 'Fijar impresora',
                                      onPressed: () async {
                                        p.noDelete = !(p.noDelete ?? false);
                                        await savePrinterToStorage(ref, p);
                                      },
                                    ),

                                    // 🗑 DELETE
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      color: Colors.red,
                                      iconSize: 24,
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      tooltip: Messages.DELETE,
                                      onPressed: () async {
                                        if (p.noDelete == true) {
                                          showWarningMessage(context, ref,
                                              Messages.NOT_DELETE_PRINTER);
                                          return;
                                        }
                                        await _deletePrinterFromStorage(ref, p);
                                      },
                                    ),
                                    // 📋 COPY
                                    IconButton(
                                      icon: Icon(Icons.content_copy),
                                      color: Colors.black,
                                      iconSize: 24,
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      tooltip: Messages.COPY_LAST_DATA,
                                      onPressed: () {
                                        _applyPrinterToFields(ref, p);
                                      },
                                    ),

                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<MOPrinter> loadSavedPrinters() {
    final box = GetStorage();
    final raw = box.read(kSavedPrintersKey);

    if (raw is List) {
      return raw.map<MOPrinter>((item) {
        if (item is Map) {
          final p = MOPrinter();
          p.name = item['name'] as String?;
          p.ip = item['ip'] as String?;
          p.port = item['port'] as String?;
          p.type = item['type'] as String?;
          p.serverIp = item['serverIp'] as String?;
          p.serverPort = item['serverPort'] as String?;
          p.noDelete = item['noDelete'] as bool? ?? false; // 👈 AQUI
          return p;
        }
        if (item is String) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          final p = MOPrinter();
          p.name = map['name'] as String?;
          p.ip = map['ip'] as String?;
          p.port = map['port'] as String?;
          p.type = map['type'] as String?;
          p.serverIp = map['serverIp'] as String?;
          p.serverPort = map['serverPort'] as String?;
          p.noDelete = map['noDelete'] as bool? ?? false; // 👈 AQUI
          return p;
        }
        return MOPrinter();
      }).toList();
    }

    return <MOPrinter>[];
  }


  Future<void> copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiado al clipboard')),
    );
  }

  Future<File> saveTxtToDownloadsOrAppDir({
    required String filename,
    required String content,
  }) async {
    // En Android/iOS lo más estable es guardar en app documents
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, encoding: utf8);
    return file;
  }


  Future<void> printFromCurrentSetup(WidgetRef ref, BuildContext context,
      dynamic dataToPrint) async {
    final printerState = ref.read(printerScanNotifierProvider);
    String ip = printerState.ipController.text.trim();
    String port = printerState.portController.text.trim();
    String type = printerState.typeController.text.trim();
    String name = printerState.nameController.text.trim();
    String serverIp = printerState.serverIpController.text.trim();
    String serverPort = printerState.serverPortController.text.trim();

    if (ip.isEmpty || port.isEmpty || type.isEmpty) {
      showWarningMessage(context, ref, Messages.ERROR_SAVE_PRINTER);
      return;
    }

    final printer = MOPrinter()
      ..name = name
      ..ip = ip
      ..port = port
      ..type = type
      ..serverIp = serverIp
      ..noDelete = noDeleteFlag
      ..serverPort = serverPort;

    await savePrinterToStorage(ref, printer);

    String qrData = '$ip:$port:$type';
    if (name.isNotEmpty) qrData = '$qrData:$name';
    if (serverIp.isNotEmpty) qrData = '$qrData:$serverIp';
    if (serverPort.isNotEmpty) qrData = '$qrData:$serverPort';

    ref.read(printerScanNotifierProvider.notifier).updateFromScan(
        qrData, ref, dataToPrint: dataToPrint);
  }

  bool isDfOk(ZplTemplate t) =>
      t.zplTemplateDf
          .trim()
          .isNotEmpty;

  Future<void> savePrinterToStorage(WidgetRef ref, MOPrinter printer) async {
    final box = GetStorage();
    final list = loadSavedPrinters();

    // 🔑 unicidad por ip+port
    final index = list.indexWhere(
          (p) =>
      (p.ip ?? '') == (printer.ip ?? '') &&
          (p.port ?? '') == (printer.port ?? ''),
    );

    if (index >= 0) {
      final existing = list[index];
      // si el nuevo no trae noborrar, conserva el valor anterior
      printer.noDelete ??= existing.noDelete ?? false;
      list.removeAt(index);
    }

    // 👉 más usada = la que se usó/guardó más recientemente
    list.insert(0, printer);

    // 🎯 aplicar límite de 10 sin tocar las protegidas (noborrar == true)
    final pinned = list.where((p) => p.noDelete == true).toList();
    final normals = list.where((p) => p.noDelete != true).toList();

    // máximo 10 impresoras totales, pero nunca borramos las pinned
    const int maxTotal = 10;
    final int maxNormales = (maxTotal - pinned.length).clamp(0, 1000);

    final trimmedNormals = normals.take(maxNormales).toList();

    final finalList = <MOPrinter>[];
    // puedes decidir si quieres pinned primero o dejar orden por uso.
    // Aquí: primero pinned, luego las más usadas normales
    finalList.addAll(pinned);
    finalList.addAll(trimmedNormals);

    final jsonList = finalList.map((p) => p.toJson()).toList();

    await box.write(kSavedPrintersKey, jsonList);
    ref
        .read(savedPrintersProvider.notifier)
        .state = List<MOPrinter>.from(finalList);
  }


  Future<void> _deletePrinterFromStorage(WidgetRef ref,
      MOPrinter printer) async {
    final box = GetStorage();
    final list = loadSavedPrinters();

    list.removeWhere(
          (p) =>
      (p.ip ?? '') == (printer.ip ?? '') &&
          (p.port ?? '') == (printer.port ?? ''),
    );

    final jsonList = list.map((p) => p.toJson()).toList();

    await box.write(kSavedPrintersKey, jsonList);
    ref
        .read(savedPrintersProvider.notifier)
        .state = List<MOPrinter>.from(list);
  }

  void _applyPrinterToFields(WidgetRef ref, MOPrinter printer) {
    final printerState = ref.read(printerScanNotifierProvider);

    printerState.nameController.text = printer.name ?? '';
    printerState.ipController.text = printer.ip ?? '';
    printerState.portController.text = printer.port ?? '';
    printerState.typeController.text = printer.type ?? '';
    printerState.serverIpController.text = printer.serverIp ?? '';
    printerState.serverPortController.text = printer.serverPort ?? '';
  }

  Future<void> printPdf(WidgetRef ref, BuildContext context,
      {required bool direct}) async {
    if (dataToPrint == null) return;
    if (dataToPrint is! MovementAndLines) {
      MovementAndLines movementAndLines = dataToPrint as MovementAndLines;
      final image = await imageLogo;
      final pdfBytes = await generateMovementDocument(movementAndLines, image);
      direct ? ref.read(printerScanNotifierProvider.notifier).printDirectly(
          bytes: pdfBytes, ref: ref)
          : await Printing.sharePdf(bytes: pdfBytes, filename: 'documento.pdf');
    }
    if (context.mounted) {
      String message = Messages.NOT_IMPLEMENTED_YET;
      showWarningCenterToast(context, message);
    }
  }


  Future<void> openPrintDialog(WidgetRef ref, BuildContext context) async {
    if (dataToPrint == null) return;
    if (dataToPrint is MovementAndLines) {
      MovementAndLines movementAndLines = dataToPrint as MovementAndLines;
      final image = await imageLogo;
      final pdfBytes = await generateMovementDocument(movementAndLines, image);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          // No necesitas llamar a generateDocument aquí, ya tienes los bytes
          return pdfBytes;
        },
      );
    }
    if (context.mounted) {
      String message = Messages.NOT_IMPLEMENTED_YET;
      showWarningCenterToast(context, message);
    }
  }

  Widget getDataPanel(BuildContext context, WidgetRef ref, dataToPrint) {
    late IconData iconData = Symbols.upload_file;
    String title = 'Printer setup';
    String subtitle = 'Sent ZPL template to printer';
    if (dataToPrint is MovementAndLines) {
      iconData = Symbols.receipt_long;
      title = 'Movement Doc No ${dataToPrint.documentNo ?? ''}';
      subtitle = 'Date: ${dataToPrint.movementDate ?? ''}';
    }
    if (dataToPrint is List<IdempiereLocator>) {
      iconData = Symbols.fork_left;



      if(dataToPrint.length==1){
        title = 'Locator to print : ${dataToPrint[0].value ?? dataToPrint[0].identifier ?? ''}';
        subtitle = 'Warehouse: ${dataToPrint[0].mWarehouseID?.identifier ?? ''}';
      } else {
        title = 'Total Locator to print : ${dataToPrint.length}';
        subtitle = 'Warehouse: ${dataToPrint[0].mWarehouseID?.identifier ?? ''} may others';
      }

    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(iconData,
              color: themeColorPrimary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget getPrintPanel(WidgetRef ref, BuildContext context) {
    final selected = ref.watch(selectedLocatorZplTemplateProvider);
    return Column(
      children: [
        SizedBox(height: 6,),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => openLocatorTemplateSheet(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    selected == null ? Icons.add_circle_outline : Icons.edit,
                    color: themeColorPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Locator ZPL Template',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selected == null
                              ? 'Ninguno seleccionado (tocar para agregar/seleccionar)'
                              : '${selected.name}  •  ${selected.size}  •  ${selected.templateFilename}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black54),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 6,),
        SizedBox(
          width: double.infinity,
          child: compactElevatedButton(
            label: Messages.CREATE_ZPL_TEMPLATE,
            backgroundColor: Colors.cyan.shade800,
            onPressed: () async {


              final state = ref.read(printerScanNotifierProvider);
              String ip = state.ipController.text;
              int port = int.parse(state.portController.text);
              if (ip.isEmpty) {
                if (context.mounted) {
                  showWarningMessage(
                      context, ref, 'IP address is empty');
                }
                return;
              }
              if (port <= 0) {
                if (context.mounted) {
                  showWarningMessage(
                      context, ref, 'Port is empty');
                }
                return;
              }
              String zpl = '';
              final newZpl = await context.push<String>(
                AppRouter.PAGE_LOCATOR_SENTENCE_EDITOR,
                extra: {
                  'sentence': zpl,
                  'focusNode': focusNode,
                },
              );
              if (newZpl == null || newZpl.isEmpty) {
                if (context.mounted) {
                  showWarningMessage(context, ref, 'No template created');
                }
                return;
              }


              bool res = await sendZplBySocket(
                  ip: ip, port: port, zpl: newZpl);
              if (res) {
                if (context.mounted) {
                  showSuccessMessage(context, ref,
                      'ZPL sent successfully $newZpl');
                }
              } else {
                if (context.mounted) {
                  showErrorMessage(
                      context, ref, 'Error sending ZPL');
                }
              }
            },
          ),
        ),
        SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: compactElevatedButton(
            label: Messages.PRINTER_LABEL,
            backgroundColor: Colors.green,
            onPressed: () async {
              final state = ref.read(printerScanNotifierProvider);
              final printerIp = state.ipController.text ;
              final printerPortText = state.portController.text ;
              final printerTypeString = state.typeController.text;

              if (printerIp.isEmpty) {
                if (context.mounted) {
                  showWarningMessage(
                      context, ref, 'IP address is empty');
                }
                return;
              }
              int? printerPort = int.tryParse(printerPortText);
              if (printerPort == null || printerPort <= 0) {
                if (context.mounted) {
                  showWarningMessage(
                      context, ref, 'Port is empty');
                }
                return;
              }
              if (printerTypeString.isEmpty) {
                if (context.mounted) {
                  showWarningMessage(
                      context, ref, 'Type is empty');
                } else {
                  if(printerTypeString != PrinterState.PRINTER_TYPE_LASER
                      && printerTypeString != PrinterState.PRINTER_TYPE_ZPL){
                    showWarningMessage(
                        context, ref, 'Type error $printerTypeString');
                  }
                }
                return;
              }
              MOPrinter? p = await getMOPrinter(context: context,
                  ref: ref, focusNode: focusNode);
              if(p==null){
                return;
              }

              String zpl = p.zplLabelPrintSentenceAutoSelect ;
              if(zpl.isEmpty){
                if (context.mounted) {
                  showWarningMessage(context, ref, 'No template found zpl empty');
                }
                return;
              }


              debugPrint(zpl);
              bool res = await sendZplBySocket(
                  ip: printerIp, port: printerPort, zpl: zpl);
              if (res) {
                if (context.mounted) {
                  showSuccessMessage(context, ref,
                      'ZPL sent successfully $zpl');
                }
              } else {
                if (context.mounted) {
                  showErrorMessage(
                      context, ref, 'Error sending ZPL');
                }
              }
            },
          ),
        ),
      ],
    );
  }
  Future<void> openLocatorTemplateSheet(
      BuildContext context,
      WidgetRef ref,
      ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => LocatorTemplateSheet(focusNode: focusNode,),
    );
  }
}

class PrinterSetupScreenState extends ConsumerState<PrinterSetupScreen>
    with SingleTickerProviderStateMixin {
  final int actionTypeInt = Memory.ACTION_FIND_PRINTER_BY_QR;
  String scannedData='';

  String get cupsPrinterName {
    return 'BR_HL_10003';
  }


  @override
  void dispose() {
    widget.focusNode.dispose();
    super.dispose();
  }

  // Manejador del evento de teclado





  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {

      widget.actionAfterWidgetBuildInitState(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.printerSetupScreenBody(context, ref);

  }

  void savePrinter(WidgetRef ref) {

    final printerState = ref.read(printerScanNotifierProvider);
    if(printerState.ipController.text.isEmpty
        || printerState.portController.text.isEmpty || printerState.typeController.text.isEmpty){
      showWarningMessage(ref.context, ref, Messages.ERROR_SAVE_PRINTER);
      return;
    }
    MOPrinter printer = MOPrinter();
    printer.name = printerState.nameController.text;
    printer.ip = printerState.ipController.text;
    printer.port = printerState.portController.text;
    printer.type = printerState.typeController.text;
    printer.serverIp = printerState.serverIpController.text;
    printer.serverPort = printerState.serverPortController.text;

    ref.read(lastPrinterProvider.notifier).state = printer;
    ref.read(directPrintWithLastPrinterProvider.notifier).update((state) => !state);


  }

  Future<void> askForPrint(WidgetRef ref, MOPrinter printer) async {
    if(printer.name==null){
      return ;
    }
    String title = Messages.PRINT_TO_LAST_PRINTER;
    String message = printer.name!;
    bool directPrint = true;
    directPrint = await showConfirmDialog(
      context,
      title: title,
      message: message,
      okText: Messages.OK,
      cancelText: Messages.CANCEL,
      okColor: themeColorSuccessful,
      cancelColor: themeColorError,
      icon: Icons.help_outline_rounded,
      iconColor: themeColorWarning,
    );

    if (!directPrint) {
      ref.read(directPrintWithLastPrinterProvider.notifier).state = false;
      return;
    }

    final printerState = ref.read(printerScanNotifierProvider);
    final String ip = printerState.ipController.text.trim();
    final String port = printerState.portController.text.trim();
    final String type = printerState.typeController.text.trim();
    final String name = printerState.nameController.text.trim();

    if (ip.isEmpty || port.isEmpty || type.isEmpty || name.isEmpty) {
      showWarningMessage(context, ref, Messages.ERROR_SAVE_PRINTER);
      return;
    }

    final String qrData = '$ip:$port:$type:$name:END';
    ref.read(printerScanNotifierProvider.notifier).updateFromScan(qrData, ref);

  }



  void popScopeAction(BuildContext context, WidgetRef ref) async {
    widget.popScopeAction(context, ref);
  }

}

/// BottomSheet UI
class LocatorTemplateSheet extends ConsumerWidget {
  final FocusNode focusNode;

  const LocatorTemplateSheet({super.key, required this. focusNode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(locatorZplTemplatesProvider);
    final list = st.list;
    final selectedId = st.selectedId;

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Locator ZPL Templates',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        ref.read(enableScannerKeyboardProvider.notifier).state = false;
                        focusNode.unfocus();
                        final created = await _showEditDialog(context, null,focusNode);
                        ref.read(enableScannerKeyboardProvider.notifier).state = true;
                        focusNode.requestFocus();
                        if (created != null) {
                          ref.read(locatorZplTemplatesProvider.notifier).upsert(created);
                        }
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                        backgroundColor: themeColorPrimary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),

                Flexible(
                  child: list.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('No hay templates aún. Tocá “Add”.'),
                  )
                      : ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final t = list[i];
                      final isSel = (t.id == selectedId);

                      return ListTile(
                        dense: true,
                        leading: Icon(
                          isSel ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSel ? Colors.green : Colors.grey,
                        ),
                        title: Text(
                          t.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${t.size} • ${t.templateFilename}${t.isDefault ? " • default" : ""}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          ref.read(locatorZplTemplatesProvider.notifier).select(t.id);
                          Navigator.pop(context);
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () async {
                                ref.read(enableScannerKeyboardProvider.notifier).state = false;
                                focusNode.unfocus();
                                final edited = await _showEditDialog(context, t, focusNode);
                                ref.read(enableScannerKeyboardProvider.notifier).state = true;
                                focusNode.requestFocus();
                                if (edited != null) {
                                  ref
                                      .read(locatorZplTemplatesProvider.notifier)
                                      .upsert(edited);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () async {
                                ref
                                    .read(locatorZplTemplatesProvider.notifier)
                                    .deleteById(t.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<LocatorZplTemplate?> _showEditDialog(
      BuildContext context,
      LocatorZplTemplate? current,
      FocusNode focusNode,
      ) async {
    final id = current?.id ?? DateTime.now().microsecondsSinceEpoch.toString();

    final nameCtrl = TextEditingController(text: current?.name ?? '');
    final fileCtrl = TextEditingController(text: current?.templateFilename ?? '');
    final sizeCtrl = TextEditingController(text: current?.size ?? '100x40mm');
    final sentCtrl = TextEditingController(text: current?.sentenceToSendToPrinter ?? '');
    final intervalCtrl = TextEditingController(text: current?.printingIntervalMs.toString() ?? '');

    bool isDefault = current?.isDefault ?? false;

    return showDialog<LocatorZplTemplate>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(current == null ? 'Add template' : 'Edit template'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: fileCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Template filename (E:WHLabel2.ZPL / WHLabel2)',
                      ),
                    ),
                    TextField(
                      controller: sizeCtrl,
                      decoration: const InputDecoration(labelText: 'Size (ej: 100x40mm)'),
                    ),
                    TextField(
                      controller: sentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Sentence to send (opcional)',
                        hintText: 'Si lo dejás vacío, usamos ^XF + ^FN1...',
                      ),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: intervalCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Intervalo de impresión en ms',
                        hintText: '',
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: isDefault,
                      onChanged: (v) => setLocal(() => isDefault = v ?? false),
                      title: const Text('Default'),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColorPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final tpl = LocatorZplTemplate(
                      id: id,
                      name: nameCtrl.text.trim().isEmpty
                          ? 'Template $id'
                          : nameCtrl.text.trim(),
                      templateFilename: fileCtrl.text.trim(),
                      isDefault: isDefault,
                      size: sizeCtrl.text.trim(),
                      sentenceToSendToPrinter: sentCtrl.text.trim(),
                      printingIntervalMs: int.tryParse(intervalCtrl.text.trim()) ?? 1,
                    );
                    Navigator.pop(ctx, tpl);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}


// Helper para abrir la pantalla y esperar un MOPrinter?
Future<MOPrinter?> getMOPrinter({
  required BuildContext context,
  required WidgetRef ref,
  required FocusNode focusNode,
  MOPrinter? initial,
}) async {
  final res = await context.push<MOPrinter>(
    AppRouter.PAGE_MO_PRINTER_EDITOR,
    extra: {
      'focusNode': focusNode,
      'initial': initial,
    },
  );
  return res; // puede ser null si canceló
}