import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/mo_printer.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/printer_utils.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/widgets/printer_commands_menu.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/new/template_zpl_on_create_editor_sheet.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/new/template_zpl_on_use_sheet.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/new/template_zpl_store.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/template/tspl_label_printer.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/zpl_print_profile_providers.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../common/widget_utils.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../provider/products_home_provider.dart';
import '../provider/new_movement_provider.dart';
import 'cups_printer.dart';
import 'movement_pdf_generator.dart';
import 'printer_scan_notifier.dart';

class PrinterSetupScreen extends ConsumerStatefulWidget {
  final String argument;
  MovementAndLines movementAndLines;

  PrinterSetupScreen({
    super.key,
    required this.movementAndLines,
    required this.argument,
  });

  @override
  _PrinterSetupScreenState createState() => _PrinterSetupScreenState();
}

class _PrinterSetupScreenState extends ConsumerState<PrinterSetupScreen> {
  // El FocusNode es esencial para que KeyboardListener funcione.
  final bool _noDeleteFlag = false; // state
  final FocusNode _focusNode = FocusNode();
  late MovementAndLines movementAndLines;
  late var actionScan;
  final int actionTypeInt = Memory.ACTION_FIND_PRINTER_BY_QR;
  int movementId = -1;
  String scannedData='';
  late var isPrinting;

  String get cupsPrinterName {
    return 'BR_HL_10003';
  }


  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Manejador del evento de teclado
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
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
            print('Escaneado: $scannedData');
            ref.read(printerScanProvider.notifier).updateFromScan(scannedData, ref);
            // Limpiar los datos escaneados para el próximo escaneo
            scannedData = '';
          });
        }
        // Devolver handled para evitar que el evento se propague
        return KeyEventResult.handled;
      } else if (event.logicalKey.keyLabel.isNotEmpty && event.character != null) {
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
    if (await Permission.camera.request().isGranted) {
      if(ref.context.mounted){
        String? result= await SimpleBarcodeScanner.scanBarcode(
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
          Future.delayed(const Duration(milliseconds: 100), () {
          });
          print('Escaneado: $result');
          ref.read(printerScanProvider.notifier).updateFromScan(result,ref);
        } else {
          if(ref.context.mounted) showWarningMessage(ref.context, ref, Messages.ERROR_SCAN);
        }
      }

    } else {
      if(ref.context.mounted){
        showWarningMessage(ref.context, ref, Messages.ERROR_CAMERA_PERMISSION);
      }

    }
  }



  Future<void> printPdf(WidgetRef ref, {required bool direct}) async {
    MovementAndLines movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));
    final image = await imageLogo;
    final pdfBytes = await generateMovementDocument(movementAndLines, image);
    direct ?  ref.read(printerScanProvider.notifier).printDirectly(bytes: pdfBytes,ref: ref)
        : await Printing.sharePdf(bytes: pdfBytes, filename: 'documento.pdf');
  }

  Future<void> openPrintDialog(WidgetRef ref,) async{
    MovementAndLines movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));
    final image = await imageLogo;
    final pdfBytes = await generateMovementDocument(movementAndLines, image);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        // No necesitas llamar a generateDocument aquí, ya tienes los bytes
        return pdfBytes;
      },
    );
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //_focusNode.requestFocus();
      Future.delayed(Duration(milliseconds: 50), () {
        movementAndLines = ref.read(movementAndLinesProvider.notifier).state ;
        print('movementAndLines: ${movementAndLines.documentNo ?? '--null'}');
        if(!widget.movementAndLines.hasMovement){
          widget.movementAndLines = movementAndLines;

        }

      });
    });
  }

  @override
  Widget build(BuildContext context) {


    movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));

    isPrinting = ref.watch(isPrintingProvider.notifier);
    actionScan = ref.watch(actionScanProvider.notifier);
    movementId = movementAndLines.id ?? -1;
    final printerState = ref.watch(printerScanProvider);
    final savedPrinters  = ref.watch(savedPrintersProvider); // 👈
    // El FocusNode debe ser solicitado explícitamente después de que el widget se construya.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bool b1= ref.read(enableScannerKeyboardProvider);
      bool b2 = ref.read(isDialogShowedProvider);
      if(b1 && !b2){
        FocusScope.of(context).requestFocus(_focusNode);
      }

    });

    return KeyboardListener(
      focusNode: _focusNode, // Usar un FocusNode separado para el listener
      onKeyEvent: (event) => _handleKeyEvent(_focusNode, event),
      child: Scaffold(

        appBar: AppBar(
          centerTitle: false,
          automaticallyImplyLeading: true,
          leading:IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async =>
              {
                popScopeAction(context, ref),

              }
            //
          ),
          title: Text(Messages.SELECT_A_PRINTER,style: TextStyle(fontSize: themeFontSizeNormal),),
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
                minimumSize: const Size(0, 30), // altura mínima reduzida
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
              /*onCopyZpl: () {
                final movementAndLinesNow = MovementAndLines.fromJson(jsonDecode(widget.argument));

                final int rowsPerLabel = 4;
                final int rowPerProductName = 2;
                final int marginX = 20;
                final int marginY = 20;
                final box = GetStorage();
                final current =
                zplLabelTypeFromStorage(box.read<String>(kZplLabelTypeKey));
                if(current==null){
                  showWarningMessage(context, ref, Messages.ERROR_LABEL_TYPE);
                  return;
                }

                final zplAll = buildZpl100x150NoLogoAll(
                  movementAndLines: movementAndLinesNow,
                  rowsPerLabel: rowsPerLabel,
                  rowPerProductName: rowPerProductName,
                  marginX: marginX,
                  marginY: marginY,
                  labelType: current,
                );

                copyToClipboard(context, zplAll);},
              onConfigureZpl: () async {
                await showZplPrintProfilesSheet(context, ref);
              },
              onPrintZplDirect: () async {
                MovementAndLines movementAndLines = ref.read(movementAndLinesProvider);
                await printZplDirectOrConfigure(ref,movementAndLines);
              },*/
              onCopyTspl: () {
                final movementAndLinesNow = MovementAndLines.fromJson(jsonDecode(widget.argument));

                // Ejemplo configuración (o usa tu perfil guardado)
                final int rowsPerLabel = 4;
                final int rowPerProductName = 2;
                final int marginX = 20;
                final int marginY = 20;
                final box = GetStorage();
                final current =
                zplLabelTypeFromStorage(box.read<String>(kZplLabelTypeKey));
                if(current==null){
                  showWarningMessage(context, ref, Messages.ERROR_LABEL_TYPE);
                  return;
                }

                final tsplAll = buildTspl100x150TemplateNoLogoAll(
                  marginX: marginX,
                  marginY: marginY,
                );
                copyToClipboard(context, tsplAll);},
                onSaveTxt: () async {
                  final box = GetStorage();
                  final current = zplLabelTypeFromStorage(box.read<String>(kZplLabelTypeKey));

                  if (current == null) {
                  showWarningMessage(context, ref, Messages.ERROR_LABEL_TYPE);
                  return;
                  }

                  await saveAndShareCommands(context, current);
                },



              onChooseLabelType: () async {
                final box = GetStorage();
                final current =
                zplLabelTypeFromStorage(box.read<String>(kZplLabelTypeKey));
                await showZplLabelTypeSheet(ref.context, current: current);
              },
              onCreateZplTemplate: () async{
                onCreateZplTemplate(context,ref);

              },
              onUseZplTemplate: () async {
                 onUseZplTemplate(context,ref);
              },

            ),
            SizedBox(width: 8,),
          ],

        ),
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {

            if (didPop) {
              return;
            }
            popScopeAction(context, ref);
          },

          child: isPrinting.state ? LinearProgressIndicator() : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 5,
                  children: [

                    Text(Messages.TOUCH_ON_TEXTFIELD_UNTIL_KEYBOARD_IS_OPEN, style: TextStyle(fontSize: 10)),
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
                             ref.read(enableScannerKeyboardProvider.notifier).state = false;
                             _focusNode.unfocus();
                           },
                           onEditingCompleteAction: (ref) {
                             FocusScope.of(context).unfocus();
                             ref.read(enableScannerKeyboardProvider.notifier).state = true;
                             _focusNode.requestFocus();
                           },
                         ),
                        ),
                        Flexible(
                          flex: 1,
                          child:Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: CompactEditableField(
                              label: Messages.PORT,
                              controller: printerState.portController,
                              keyboardType: TextInputType.number,
                              onTapAction: (ref) {
                                ref.read(enableScannerKeyboardProvider.notifier).state = false;
                                _focusNode.unfocus();
                              },
                              onEditingCompleteAction: (ref) {
                                FocusScope.of(context).unfocus();
                                ref.read(enableScannerKeyboardProvider.notifier).state = true;
                                _focusNode.requestFocus();
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
                              ref.read(enableScannerKeyboardProvider.notifier).state = false;
                              _focusNode.unfocus();
                            },
                            onEditingCompleteAction: (ref) {
                              FocusScope.of(context).unfocus();
                              ref.read(enableScannerKeyboardProvider.notifier).state = true;
                              _focusNode.requestFocus();
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
                                ref.read(enableScannerKeyboardProvider.notifier).state = false;
                                _focusNode.unfocus();
                              },
                              onEditingCompleteAction: (ref) {
                                FocusScope.of(context).unfocus();
                                ref.read(enableScannerKeyboardProvider.notifier).state = true;
                                _focusNode.requestFocus();
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
                              ref.read(enableScannerKeyboardProvider.notifier).state = false;
                              _focusNode.unfocus();
                            },
                            onEditingCompleteAction: (ref) {
                              FocusScope.of(context).unfocus();
                              ref.read(enableScannerKeyboardProvider.notifier).state = true;
                              _focusNode.requestFocus();
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
                                ref.read(enableScannerKeyboardProvider.notifier).state = false;
                                _focusNode.unfocus();
                              },
                              onEditingCompleteAction: (ref) {
                                FocusScope.of(context).unfocus();
                                ref.read(enableScannerKeyboardProvider.notifier).state = true;
                                _focusNode.requestFocus();
                              },
                            ),
                          ),

                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: compactElevatedButton(
                            label: Messages.SHARE,
                            backgroundColor: themeColorPrimary,
                            onPressed: () async {
                              await printPdf(ref, direct: false);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: compactElevatedButton(
                            label: Messages.PRINT,
                            backgroundColor: (ref.read(lastPrinterProvider.notifier).state != null
                                ? Colors.green
                                : themeColorPrimary),
                            onPressed: () async {
                              String ip        = printerState.ipController.text.trim();
                              String port      = printerState.portController.text.trim();
                              String type      = printerState.typeController.text.trim();
                              String name      = printerState.nameController.text.trim();
                              String serverIp  = printerState.serverIpController.text.trim();
                              String serverPort= printerState.serverPortController.text.trim();

                              if (ip.isEmpty || port.isEmpty || type.isEmpty) {
                                showWarningMessage(context, ref, Messages.ERROR_SAVE_PRINTER);
                                return;
                              }

                              final printer = MOPrinter()
                                ..name       = name
                                ..ip         = ip
                                ..port       = port
                                ..type       = type
                                ..serverIp   = serverIp
                                ..noDelete   = _noDeleteFlag
                                ..serverPort = serverPort;

                              await _savePrinterToStorage(ref, printer);

                              String qrData = '$ip:$port:$type';
                              if (name.isNotEmpty)    qrData = '$qrData:$name';
                              if (serverIp.isNotEmpty)   qrData = '$qrData:$serverIp';
                              if (serverPort.isNotEmpty) qrData = '$qrData:$serverPort';

                              print('QR Data: $qrData');
                              ref.read(printerScanProvider.notifier).updateFromScan(qrData, ref);
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: compactElevatedButton(
                            label: Messages.SELECT_A_PRINTER,
                            backgroundColor: themeColorPrimary,
                            onPressed: () async {
                              await openPrintDialog(ref);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        compactElevatedButton(
                          label: 'SAVE',
                          backgroundColor: themeColorPrimary,
                          onPressed: () async {
                            String ip        = printerState.ipController.text.trim();
                            String port      = printerState.portController.text.trim();
                            String type      = printerState.typeController.text.trim();
                            String name      = printerState.nameController.text.trim();
                            String serverIp  = printerState.serverIpController.text.trim();
                            String serverPort= printerState.serverPortController.text.trim();

                            if (ip.isEmpty || port.isEmpty || type.isEmpty) {
                              showWarningMessage(context, ref, Messages.ERROR_SAVE_PRINTER);
                              return;
                            }

                            final printer = MOPrinter()
                              ..name       = name
                              ..ip         = ip
                              ..port       = port
                              ..type       = type
                              ..serverIp   = serverIp
                              ..noDelete   = true
                              ..serverPort = serverPort;

                            await _savePrinterToStorage(ref, printer);
                          },
                        ),
                      ],
                    ),

                    if (savedPrinters.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('Impresoras guardadas', style: TextStyle(
                            fontSize: themeFontSizeLarge, fontWeight: FontWeight.bold,),),
                            Icon(Icons.star, color: Colors.green),
                            Text('= No borrar', style: TextStyle(
                              fontSize: themeFontSizeLarge, fontWeight: FontWeight.bold,),),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${p.ip ?? ''}:${p.port ?? ''}  [${p.type ?? ''}]',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                                      icon: Icon((p.noDelete ?? false) ? Icons.star : Icons.star_border),
                                      color: (p.noDelete ?? false) ? Colors.green : Colors.grey,
                                      iconSize: 24, // o el tamaño que desees
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      tooltip: 'Fijar impresora',
                                      onPressed: () async {
                                        p.noDelete = !(p.noDelete ?? false);
                                        await _savePrinterToStorage(ref, p);
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
                                          showWarningMessage(context, ref, Messages.NOT_DELETE_PRINTER);
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
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                    ),],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void savePrinter(WidgetRef ref) {

    final printerState = ref.read(printerScanProvider);
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

  void askForPrint(WidgetRef ref, MOPrinter printer) {
    if(printer.name==null){
      return ;
    }
    String title = Messages.PRINT_TO_LAST_PRINTER;
    String message = printer.name!;
    bool directPrint = true;
    AwesomeDialog(
        context: ref.context,
        headerAnimationLoop: false,
        dialogType: DialogType.noHeader,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Center(
            child: Column(
              spacing: 10,
              children: [
                Text(title, style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
                Text(message, style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        title: title,
        desc: message,
        autoDismiss: true,
        autoHide: Duration(seconds: 2),
        btnCancelText: Messages.CANCEL,
        btnOkText: Messages.OK,
        btnOkOnPress: () {
          directPrint = true;
        },
        btnCancelOnPress: () {
          directPrint = false;
          ref.read(directPrintWithLastPrinterProvider.notifier).state = false;
          return;
        }
    ).show().then((value) {
      if(!directPrint) return;
      var printerState = ref.read(printerScanProvider);
      String ip = printerState.ipController.text.trim();
      String port = printerState.portController.text.trim();
      String type = printerState.typeController.text.trim();
      String name = printerState.nameController.text.trim();
      if(ip.isEmpty || port.isEmpty || type.isEmpty || name.isEmpty){
        showWarningMessage(context, ref, Messages.ERROR_SAVE_PRINTER);
        return;
      }

      String qrData = '$ip:$port:$type:$name:END';
      print('QR Data: $qrData');
      ref.read(printerScanProvider.notifier).updateFromScan(qrData, ref);
    });
  }
  Widget editableField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14), // texto más pequeño
      onTap: () {
        ref.read(enableScannerKeyboardProvider.notifier).state = false;
        _focusNode.unfocus();
      },
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
        ref.read(enableScannerKeyboardProvider.notifier).state = true;
        _focusNode.requestFocus();
      },

      // --- 💡 Hacerlo compacto ---
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),

        // reduce espacio superior/inferior
        isDense: true,

        // controla altura exacta
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }


  void popScopeAction(BuildContext context, WidgetRef ref) async {
    print('popScopeAction----------------------------');
    ref.read(productsHomeCurrentIndexProvider.notifier).state =
        Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN;
    actionScan.state = Memory.ACTION_FIND_MOVEMENT_BY_ID;
    context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$movementId/1');
  }
  List<MOPrinter> _loadSavedPrinters() {
    final box = GetStorage();
    final raw = box.read(kSavedPrintersKey);

    if (raw is List) {
      return raw.map<MOPrinter>((item) {
        if (item is Map) {
          final p = MOPrinter();
          p.name       = item['name']       as String?;
          p.ip         = item['ip']         as String?;
          p.port       = item['port']       as String?;
          p.type       = item['type']       as String?;
          p.serverIp   = item['serverIp']   as String?;
          p.serverPort = item['serverPort'] as String?;
          p.noDelete   = item['noDelete']   as bool? ?? false; // 👈 AQUI
          return p;
        }
        if (item is String) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          final p = MOPrinter();
          p.name       = map['name']       as String?;
          p.ip         = map['ip']         as String?;
          p.port       = map['port']       as String?;
          p.type       = map['type']       as String?;
          p.serverIp   = map['serverIp']   as String?;
          p.serverPort = map['serverPort'] as String?;
          p.noDelete   = map['noDelete']   as bool? ?? false; // 👈 AQUI
          return p;
        }
        return MOPrinter();
      }).toList();
    }

    return <MOPrinter>[];
  }

  Future<void> _savePrinterToStorage(WidgetRef ref, MOPrinter printer) async {
    final box  = GetStorage();
    final list = _loadSavedPrinters();

    // 🔑 unicidad por ip+port
    final index = list.indexWhere(
          (p) => (p.ip ?? '') == (printer.ip ?? '') && (p.port ?? '') == (printer.port ?? ''),
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
    final pinned  = list.where((p) => p.noDelete == true).toList();
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
    ref.read(savedPrintersProvider.notifier).state = List<MOPrinter>.from(finalList);
  }


  Future<void> _deletePrinterFromStorage(WidgetRef ref, MOPrinter printer) async {
    final box  = GetStorage();
    final list = _loadSavedPrinters();

    list.removeWhere(
          (p) =>
      (p.ip ?? '')   == (printer.ip ?? '') &&
          (p.port ?? '') == (printer.port ?? ''),
    );

    final jsonList = list.map((p) => p.toJson()).toList();

    await box.write(kSavedPrintersKey, jsonList);
    ref.read(savedPrintersProvider.notifier).state = List<MOPrinter>.from(list);
  }

  void _applyPrinterToFields(WidgetRef ref, MOPrinter printer) {
    final printerState = ref.read(printerScanProvider);

    printerState.nameController.text       = printer.name       ?? '';
    printerState.ipController.text         = printer.ip         ?? '';
    printerState.portController.text       = printer.port       ?? '';
    printerState.typeController.text       = printer.type       ?? '';
    printerState.serverIpController.text   = printer.serverIp   ?? '';
    printerState.serverPortController.text = printer.serverPort ?? '';
  }
  Future<void> _printWithSavedPrinter(WidgetRef ref, MOPrinter printer) async {
    _applyPrinterToFields(ref, printer);
    // esto usa los datos que ya pusimos en printerProvider
    await printPdf(ref, direct: true);
  }
  String get zplHeaderCompact => r'''
^PW800
^CI28
^LH0,0
^LS0

^FX HEADER compacto ~25mm (200 dots) - QR izquierda
^FX Area efectiva: 93mm (=744 dots) por resta 7mm
^FX Variables: {{QRDATA}} {{DOCNO}} {{DATE}} {{STATUS}} {{COMPANY}} {{TITLE}}

^FO20,20
^BQN,2,8
^FDLA,{{QRDATA}}^FS

^FO192,24^FB572,1,0,R^A0N,44,32^FD{{DOCNO}}^FS
^FO192,76^FB286,1,0,C^A0N,24,18^FD{{DATE}}^FS
^FO478,76^FB286,1,0,R^A0N,24,18^FD{{STATUS}}^FS
^FO192,108^FB572,1,0,R^A0N,26,20^FD{{COMPANY}}^FS
^FO192,140^FB572,1,0,R^A0N,30,22^FD{{TITLE}}^FS

^FO20,218^GB744,2,2^FS
''';

  String get tsplHeaderCompact => r'''
SIZE 100 mm,150 mm
GAP 3 mm,0 mm
DENSITY 12
SPEED 4
DIRECTION 1
REFERENCE 0,0
CLS

; HEADER compacto ~25mm (200 dots) - QR izquierda
; Area efectiva: 93mm (=744 dots) por resta 7mm
; Variables: {{QRDATA}} {{DOCNO}} {{DATE}} {{STATUS}} {{COMPANY}} {{TITLE}}

QRCODE 20,20,L,6,A,0,"{{QRDATA}}"

BLOCK 192,24,572,40,"0",0,2,2,0,2,"{{DOCNO}}"
BLOCK 192,76,286,30,"0",0,1,1,0,1,"{{DATE}}"
BLOCK 478,76,286,30,"0",0,1,1,0,2,"{{STATUS}}"
BLOCK 192,108,572,30,"0",0,1,1,0,2,"{{COMPANY}}"
BLOCK 192,140,572,34,"0",0,1,1,0,2,"{{TITLE}}"

BAR 20,218,744,2
PRINT 1,1
''';

  String buildCommandsPackText() {
    return '''
=== ZPL (Header compacto) ===

$zplHeaderCompact

=== TSPL (Header compacto) ===

$tsplHeaderCompact
''';
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

  Future<void> saveAndShareCommands(BuildContext context, ZplLabelType current) async {
    final movementAndLinesNow = MovementAndLines.fromJson(jsonDecode(widget.argument));
   int id = movementAndLinesNow.id ?? 00 ;
    // Ejemplo configuración (o usa tu perfil guardado)
    final int rowsPerLabel = 8;
    final int rowPerProductName = 1;
    final int marginX = 20;
    final int marginY = 20;

    final text = buildTspl100x150TemplateNoLogoAll(
      marginX: marginX,
      marginY: marginY,
    );

    final file = await saveTxtToDownloadsOrAppDir(
      filename: 'mv_${id}_tspl_commands.txt',
      content: text,
    );

    // Compartir por WhatsApp/Drive/etc
    final params = ShareParams(
      text: 'Comandos TSPL',
      files: [XFile(file.path)],
    );
    await SharePlus.instance.share(
      params
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Guardado: ${file.path}')),
    );
  }

  Future<void> onCreateZplTemplate(
      BuildContext context,
      WidgetRef ref,
      ) async {
    try {
      final store = ZplTemplateStore(GetStorage());

      final created = await showZplTemplateEditorDialogMode(
        context: context,
        ref: ref,
        store: store,
        initial: null,
      );

      if (created == null) return;
    } catch (e) {
      showWarningMessage(context, ref, 'Error creando template: $e');
    }
  }
  /*Future<void> onCreateZplTemplate(
      BuildContext context,
      WidgetRef ref,
      ) async {
    try {
      final store = ZplTemplateStore(GetStorage());

      final created = await showZplTemplateEditorDialogMode(
        context: context,
        store: store,
        initial: null, // explícito: crear nuevo
      );

      // Si canceló o cerró
      if (created == null) return;

      // (Opcional) feedback simple
      // showSuccessMessage(ref.context, ref, 'Template guardado: ${created.templateFileName}');
    } catch (e) {
      showWarningMessage(context, ref, 'Error creando template: $e');
    }
  }*/
  Future<void> onUseZplTemplate(
      BuildContext context,
      WidgetRef ref,
      ) async {
    try {
      final store = ZplTemplateStore(GetStorage());

      final selected = await showUseZplTemplateSheet(
        context: context,
        ref: ref,
        store: store,
      );

      if (selected == null) return;

      // Si al “usar” quieres imprimir directo, hazlo aquí (opcional):
      // final movementAndLines = ref.read(movementAndLinesProvider);
      // await printTemplateSmart(ref: ref, template: selected, movementAndLines: movementAndLines);

    } catch (e) {
      showWarningMessage(context, ref, 'Error usando template: $e');
    }
  }




  Future<void> printZplString(String zpl) async {
    // aquí llamas tu pipeline real de impresión (Bluetooth/WiFi/USB/etc)
    // ej: printerService.sendRaw(zpl);
  }
  String exportMovementByCategoryAsTemplateZpl({
    required int rowsPerLabel,
    required int rowPerProductName, // si no se usa, déjalo
    required int marginX,
    required int marginY,
  }) {
    // OJO: esto es tu ZPL “layout” fijo.
    // Pega aquí la misma estructura que ya generas,
    // pero sustituyendo variables por {{FNx}}.
    // Para que sea corto, te dejo un “header-only” de ejemplo.

    const int pw = 800;
    const int ll = 1200;
    const int reduceWidthDots = 56;
    final int usableWidth = pw - reduceWidthDots;
    const int qrSize = 160;
    const int gap = 12;

    const int headerHeight = 480;
    const int tableHeaderHeight = 80;
    const int footerHeight = 80;

    return '''
    ^XA
    ^CI28
    ^PW$pw
    ^LL$ll
    ^LH0,0
    ^LS0
    ^PR3
    
    ^FO$marginX,$marginY
    ^BQN,2,8
    ^FDLA,{{FN1}}^FS
    
    ^FO${marginX + qrSize + gap},${marginY + 4}
    ^FB${usableWidth - qrSize - gap},1,0,R^A0N,44,32^FD{{FN1}}^FS
    
    ^FO${marginX + qrSize + gap},${marginY + 56}
    ^FB${((usableWidth - qrSize - gap) / 2).round()},1,0,C^A0N,24,18^FD{{FN2}}^FS
    
    ^FO${marginX + qrSize + gap + ((usableWidth - qrSize - gap) / 2).round()},${marginY + 56}
    ^FB${((usableWidth - qrSize - gap) / 2).round()},1,0,R^A0N,24,18^FD{{FN3}}^FS
    
    ^FO${marginX + qrSize + gap},${marginY + 88}
    ^FB${usableWidth - qrSize - gap},1,0,R^A0N,26,20^FD{{FN4}}^FS
    
    ^FO${marginX + qrSize + gap},${marginY + 120}
    ^FB${usableWidth - qrSize - gap},1,0,R^A0N,30,22^FD{{FN5}}^FS
    
    ^FO${marginX + qrSize + gap},${marginY + 156}
    ^FB${usableWidth - qrSize - gap},1,0,R^A0N,22,18^FDDireccion: {{FN6}}^FS
    
    ^FO${marginX + qrSize + gap},${marginY + 184}
    ^FB${usableWidth - qrSize - gap},1,0,R^A0N,22,18^FDFrom: {{FN7}}^FS
    
    ^FO${marginX + qrSize + gap},${marginY + 212}
    ^FB${usableWidth - qrSize - gap},1,0,R^A0N,22,18^FDTO: {{FN8}}^FS
    
    ^FO$marginX,${marginY + headerHeight - 2}^GB$usableWidth,2,2^FS
    
    ^FO$marginX,${ll - marginY - footerHeight}^GB$usableWidth,2,2^FS
    ^XZ
    ''';
  }


}

