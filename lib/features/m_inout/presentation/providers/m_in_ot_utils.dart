import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/m_inout/presentation/providers/pick_confirm_provider.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

import '../../domain/entities/line.dart';
import '../../domain/entities/line_confirm.dart';
import '../../domain/entities/m_in_out.dart';
import '../../domain/entities/m_in_out_confirm.dart';
import 'm_in_out_providers.dart';
import 'shipment_confirm_provider.dart';

Future<void> showMInOutResultModalBottomSheet({
  required WidgetRef ref,
  required MInOut data,
  required MInOutType type,
  required String text,
  required Future<void> Function() onOk,
}) async {
  String doc = data.docStatus.id ?? 'NULL';
  Color color = Colors.grey.shade200;

  if (doc == 'CO') {
    color = Colors.green.shade200;
  } else if (doc == 'IP') {
    color = Colors.cyan.shade200;
    if (type == MInOutType.moveConfirm) color = Colors.red.shade200;
  } else if (doc == 'DR') {
    color = Colors.red.shade200;
  }

  final List<Line> lines = data.lines;

  await showModalBottomSheet(
    isDismissible: false,
    enableDrag: false,
    context: ref.context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final height = MediaQuery.of(ctx).size.height * 0.7;

      return SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Documento actualizado : ${data.documentNo}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Documento id : ${data.docStatus.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Documento status : ${data.docStatus.identifier}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // 🔽 NUEVO GRID DE LÍNEAS
                if (lines.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // -------- CABECERA --------
                        Row(
                          children: const [
                            Expanded(
                              child: Text(
                                'Line',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Move Qty',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Conf Qty',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Targ Qty',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const Divider(thickness: 1),

                        // -------- LINEAS --------
                        ...lines.map((line) {
                          final lin = line.id ?? 0;
                          final mov = line.movementQty ?? 0;
                          final conf = line.confirmedQty ?? 0;
                          final targ = line.targetQty ?? 0;

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      lin.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      mov.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      conf.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      targ.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(thickness: 1),
                            ],
                          );
                        }),
                      ],
                    ),
                  )
                else
                  const Text('Sin líneas para mostrar.', style: TextStyle(fontSize: 12)),

                /*const SizedBox(height: 8),

                // texto largo / json / debug
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      text,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),*/

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onOk();
                    },
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


Future<void> showMInOutConfirmResultModalBottomSheet({required WidgetRef ref,
  required MInOutConfirm data, required MInOutType type}) async {
  final prettyJson =
  const JsonEncoder.withIndent('  ').convert(data.docStatus.toJson());
  String doc = data.docStatus.id ?? 'NULL';
  Color color = Colors.grey.shade200;
  if(doc == 'CO') {
    color = Colors.green.shade200;
  } else if(doc == 'IP'){
    color = Colors.cyan.shade200;
    if(type == MInOutType.moveConfirm) color = Colors.red.shade200;
  } else if(doc == 'DR'){
    color = Colors.red.shade200;
  }
  final List<LineConfirm> lines = data.linesConfirm;
  await showModalBottomSheet(
    isDismissible: false,
    enableDrag: false,
    context: ref.context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final height = MediaQuery.of(ctx).size.height * 0.7;
      return SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(16.0),

          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(prettyJson),
                Text(
                  'Documento actualizado : ${data.documentNo}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Documento id : ${data.docStatus.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Documento status : ${data.docStatus.identifier}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // 🔽 NUEVO GRID DE LÍNEAS
                if (lines.isNotEmpty)
                  SizedBox(
                    height: 140, // ajusta si quieres más o menos alto
                    child: GridView.count(
                      crossAxisCount: 4,
                      // header + 3 columnas por cada línea
                      childAspectRatio: 2.8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        const Text(
                          'Line',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        // cabecera
                        const Text(
                          'DifferenceQty',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          'ConfirmedQty',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          'TargetQty',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),

                        // datos de cada línea
                        ...lines.expand((line) {
                          final lin = line.id?? 0;
                          final mov = line.differenceQty?? 0;
                          final conf = line.confirmedQty ?? 0;
                          final targ = line.targetQty ?? 0;

                          return [
                            Text(
                              lin.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              mov.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              conf.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              targ.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ];
                        }),
                      ],
                    ),
                  )
                else
                  const Text(
                    'Sin líneas para mostrar.',
                    style: TextStyle(fontSize: 12),
                  ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

}

Future<void> showCreateShipmentConfirmModalBottomSheet({
  required WidgetRef ref,
  required String mInOutId,
  required String documentNo,
  required MInOutType type,
  required Future<void> Function() onResultSuccess,
}) async {
  final color = Colors.grey.shade200;

  await showModalBottomSheet(
    isDismissible: false,
    enableDrag: false,
    context: ref.context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final height = MediaQuery.of(ctx).size.height * 0.9;
      bool started =false ;
      return Consumer(
        builder: (context, ref2, _) {
          final asyncValue = ref2.watch(createShipmentConfirmProvider);
          final result = asyncValue.value;
          print('showCreateShipmentConfirmModalBottomSheet');
          return SizedBox(
            height: height,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    Messages.CREATE_SHIPMENT_CONFIRM,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    Messages.TO_CREATE_SHIPMENT_CONFIRM_DOC_STATUS_MUST_EQUAL_DR,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Document No: $documentNo',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: SingleChildScrollView(
                      child: asyncValue.when(
                        data: (res) {
                          // res puede ser null cuando scannedCode == ''
                          if (res == null) return const SizedBox.shrink();

                          final actionSuccess = res.success && res.data != null;

                          if (actionSuccess) {
                            // Evitar hacer lógica pesada durante el build
                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              await Future.delayed(const Duration(seconds: 2));
                              if(ctx.mounted){
                                if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                                print('onResultSuccess');
                                await onResultSuccess();
                              }

                            });
                          }
                          print('Card');
                          return Card(

                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Icon(
                                    actionSuccess ? Icons.check_circle : Icons.error_outline,
                                    color: actionSuccess ? Colors.green : Colors.red,
                                    size: 60,
                                  ),
                                  if(actionSuccess)  Text(
                                    "${Messages.SUMMARY} : ${res.data}",
                                  ),
                                  Text(
                                    actionSuccess
                                        ? '${Messages.DOCUMENT_ADDED}, ${Messages.PLEASE_WAIT}'
                                        : res.message ?? Messages.ERROR_DOCUMENT_NOT_ADDED,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        error: (error, _) => Text(error.toString()),
                        loading: () => const LinearProgressIndicator(minHeight: 36),
                      ),
                    ),
                  ),


                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {

                             if(result!=null && result.success == true) {
                                if (ctx.mounted && Navigator.of(ctx).canPop()) {
                                  Navigator.of(ctx).pop();
                                  await onResultSuccess();
                                }
                             } else {
                                if (ctx.mounted && Navigator.of(ctx).canPop()) {
                                  Navigator.of(ctx).pop();
                                }
                             }
                          },
                          child: Text(Messages.CANCEL),
                        ),
                      ),
                      if(!started)const SizedBox(width: 10),

                      if(!started)Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColorPrimary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            // Dispara el FutureProvider
                            print('creating shipment confirm pressed $started');
                            if(started) {
                              String message = Messages.SHIPMENT_CONFIRM_ALREADY_STARTED;
                              showErrorMessage(context, ref, message);
                              return;
                            }
                            started = true ;
                            ref2.read(idForCreateShipmentConfirmProvider.notifier).state = mInOutId;
                            print('creating shipment confirm pressed ${result?.success}');
                          },
                          child: Text(Messages.CREATE),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showCreatePickOrQaConfirmModalBottomSheet({
  required WidgetRef ref,
  required String mInOutId,
  required String documentNo,
  required MInOutType type,
  required Future<void> Function() onResultSuccess,
  required bool isQaConfirm,
}) async {
  final color = Colors.grey.shade200;

  await showModalBottomSheet(
    isDismissible: false,
    enableDrag: false,
    context: ref.context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final height = MediaQuery.of(ctx).size.height * 0.9;
      bool started =false ;
      return Consumer(
        builder: (context, ref2, _) {
          final asyncValue = ref2.watch(createPickConfirmProvider);
          final result = asyncValue.value;
          print('creating pick or qa confirm 1');
          return SizedBox(
            height: height,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isQaConfirm ? Messages.CREATE_QA_CONFIRM : Messages.CREATE_PICK_CONFIRM,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isQaConfirm ? Messages.TO_CREATE_QA_CONFIRM_DOC_STATUS_MUST_EQUAL_DR
                        : Messages.TO_CREATE_PICK_CONFIRM_DOC_STATUS_MUST_EQUAL_DR,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Document No: $documentNo',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'ID: $mInOutId',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: SingleChildScrollView(
                      child: asyncValue.when(
                        data: (res) {
                          // res puede ser null cuando scannedCode == ''
                          if (res == null) return const SizedBox.shrink();

                          final actionSuccess = res.success && res.data != null;

                          if (actionSuccess) {
                            // Evitar hacer lógica pesada durante el build
                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              await Future.delayed(const Duration(seconds: 2));
                              if(ctx.mounted) {
                                if (Navigator.of(ctx).canPop()) {
                                  Navigator.of(
                                    ctx).pop();
                                }
                                print('onResultSuccess');
                                await onResultSuccess();
                              }
                            });
                          }
                          print('Card');
                          return Card(

                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Icon(
                                    actionSuccess ? Icons.check_circle : Icons.error_outline,
                                    color: actionSuccess ? Colors.green : Colors.red,
                                    size: 60,
                                  ),
                                  if(actionSuccess)  Text(
                                    "${Messages.SUMMARY} : ${res.data}",
                                  ),
                                  Text(
                                    actionSuccess
                                        ? '${Messages.DOCUMENT_ADDED}, ${Messages.PLEASE_WAIT}'
                                        : res.message ?? Messages.ERROR_DOCUMENT_NOT_ADDED,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        error: (error, _) => Text(error.toString()),
                        loading: () => const LinearProgressIndicator(minHeight: 36),
                      ),
                    ),
                  ),


                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {

                            if(result!=null && result.success == true) {
                              if (ctx.mounted && Navigator.of(ctx).canPop()) {
                                Navigator.of(
                                    ctx).pop();

                                await onResultSuccess();
                              }

                            } else {
                              if (ctx.mounted && Navigator.of(ctx).canPop()) {
                                Navigator.of(
                                    ctx).pop();
                              }
                            }


                          },
                          child: Text(Messages.CANCEL),
                        ),
                      ),
                      if(!started)const SizedBox(width: 10),

                      if(!started)Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColorPrimary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            // Dispara el FutureProvider
                            print('creating pick confirm pressed $started');
                            if(started) {
                              String message = Messages.PICK_CONFIRM_ALREADY_STARTED;
                              showErrorMessage(context, ref, message);
                              return;
                            }
                            started = true ;
                            ref2.read(idForCreatePickConfirmProvider.notifier).state = mInOutId;
                            print('creating pick confirm pressed ${result?.success}');
                          },
                          child: Text(Messages.CREATE),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
