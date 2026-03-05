import 'dart:async';

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
import 'm_in_out_type.dart';
import 'shipment_confirm_provider.dart';


Future<void> showMInOutResultModalBottomSheet({required WidgetRef ref,
  required MInOut data, required MInOutType type}) async {
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
      final height = MediaQuery.of(ctx).size.height * 0.8;
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
                Text(type.name,style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),),
                Text(
                  'Documento actualizado : ${data.documentNo}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Documento id : ${data.docStatus.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Documento status : ${data.docStatus.identifier}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // 🔽 GRID DE LÍNEAS (SCROLLABLE)
                if (lines.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // ---------- HEADER (fixed) ----------
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: const [
                                Expanded(
                                  child: Text('Line',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Expanded(
                                  child: Text('Diff Qty',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Expanded(
                                  child: Text('Conf Qty',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Expanded(
                                  child: Text('Targ Qty',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                          const Divider(thickness: 1),

                          // ---------- GRID (scrollable) ----------
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 2.8,
                              ),
                              itemCount: lines.length * 4,
                              itemBuilder: (context, index) {
                                final row = index ~/ 4; // which line
                                final col = index % 4;  // which column

                                final lc = lines[row];
                                final lin = lc.id ?? 0;
                                final dif = lc.differenceQty ?? 0;
                                final conf = lc.confirmedQty ?? 0;
                                final targ = lc.targetQty ?? 0;

                                String value;
                                switch (col) {
                                  case 0: value = lin.toString(); break;
                                  case 1: value = dif.toString(); break;
                                  case 2: value = conf.toString(); break;
                                  default: value = targ.toString(); break;
                                }

                                return Center(
                                  child: Text(
                                    value,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Text('Sin líneas para mostrar.', style: TextStyle(fontSize: 12)),


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

Future<void> showMInOutConfirmResultModalBottomSheet({required WidgetRef ref,
  required MInOutConfirm data, required MInOutType type}) async {
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
      final height = MediaQuery.of(ctx).size.height * 0.8;
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
                Text(type.name,style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),),
                Text(
                  'Documento actualizado : ${data.documentNo}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Documento id : ${data.docStatus.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Documento status : ${data.docStatus.identifier}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // 🔽 GRID DE LÍNEAS (SCROLLABLE)
                if (lines.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // ---------- HEADER (fixed) ----------
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: const [
                                Expanded(
                                  child: Text('Line',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Expanded(
                                  child: Text('Diff Qty',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Expanded(
                                  child: Text('Conf Qty',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Expanded(
                                  child: Text('Targ Qty',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                          const Divider(thickness: 1),

                          // ---------- GRID (scrollable) ----------
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 2.8,
                              ),
                              itemCount: lines.length * 4,
                              itemBuilder: (context, index) {
                                final row = index ~/ 4; // which line
                                final col = index % 4;  // which column

                                final lc = lines[row];
                                final lin = lc.id ?? 0;
                                final dif = lc.differenceQty ?? 0;
                                final conf = lc.confirmedQty ?? 0;
                                final targ = lc.targetQty ?? 0;

                                String value;
                                switch (col) {
                                  case 0: value = lin.toString(); break;
                                  case 1: value = dif.toString(); break;
                                  case 2: value = conf.toString(); break;
                                  default: value = targ.toString(); break;
                                }

                                return Center(
                                  child: Text(
                                    value,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Text('Sin líneas para mostrar.', style: TextStyle(fontSize: 12)),


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
                            ref2.read(fireCreateShipmentConfirmProvider.notifier).state++;
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
Future<void> showCreateReceiptConfirmModalBottomSheet({
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
          print('showCreateReceiptConfirmModalBottomSheet');
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
                    Messages.CREATE_RECEIPT_CONFIRM,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    Messages.TO_CREATE_RECEIPT_CONFIRM_DOC_STATUS_MUST_EQUAL_DR,
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
                            ref2.read(fireCreateShipmentConfirmProvider.notifier).state++;
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
