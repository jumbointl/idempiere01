import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/line.dart';
import '../../domain/entities/line_confirm.dart';
import '../../domain/entities/m_in_out.dart';
import '../../domain/entities/m_in_out_confirm.dart';
import 'm_in_out_providers.dart';

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