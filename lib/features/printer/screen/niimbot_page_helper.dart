




import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:niim_blue_flutter/niim_blue_flutter.dart';

import '../../../config/theme/app_theme.dart';
import '../../products/presentation/providers/common_provider.dart';
import 'niimbot_page.dart';
import 'niimbot_silence_page_provider.dart';

final niimbotPrinterInfoProvider =
StateProvider<PrinterInfo?>((ref) => null);

final niimbotBatteryChargeProvider =
StateProvider<BatteryChargeLevel?>((ref) => null);

final niimbotPrinterInfoLastReadAtProvider =
StateProvider<DateTime?>((ref) => null);

final niimbotPrinterInfoErrorProvider =
StateProvider<String?>((ref) => null);
Widget getBluetoothIndicatorPanel(NiimbotState state) {
  final client = state.client;
  Color color = (client?.isConnected() ??false) ? Colors.green : Colors.red ;
  if(state.isPrinting){
    return SizedBox(height: 20, width: 20,
      child: CircularProgressIndicator(color: themeColorPrimary,strokeWidth: 2,),
    );

  }
  return Row(
      children: [
        Icon((client?.isConnected() ??false) ? Icons.bluetooth_connected :Icons.bluetooth_disabled,
            color: color),
        SizedBox(width: 10,),

      ]);

}


Widget getClientStatusPanel(NiimbotState state,{Function? onReconnect}) {
  final client = state.client;
  String msg ='';
  if (client == null || !client.isConnected()) {
    msg = 'Disconnected';
  } else {
    msg = 'Id: ${client.getPrinterInfo().modelId} ,'
        'Model : ${client.getModelMetadata()?.model ?? 'null'}';
  }
  if(state.isPrinting){
    return Column(
      children: [
        LinearProgressIndicator(),
        SizedBox(width: double.infinity,
          child: Text(state.status,maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13,fontWeight: FontWeight.w600), ),
        ),
      ],
    );

  }
  if(client!=null && (client.getPrinterInfo().modelId==null || client.getModelMetadata()==null)) {
      return TextButton(onPressed: ()=>onReconnect,
      child: Text('Re-connect'),
    );
  }
  return SizedBox(
    width: double.infinity,
    child: Text(msg,maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13,fontWeight: FontWeight.w600), ),
  );

}
Future<void> autoConnectIfNeeded(BuildContext context,WidgetRef ref,{required bool autoConnectDone,required String bluetoothAddress}) async {
  debugPrint('[NIIMBOT] autoConnectIfNeeded $autoConnectDone');
  if (autoConnectDone) return;
  autoConnectDone = true;


  final address = (bluetoothAddress).trim();
  if (address.isEmpty) return;
  final ctrl = ref.read(niimbotControllerProvider.notifier);
  if(ctrl.isConnected()) return;
  ref.read(isPrintingProvider.notifier).state = true ;

  try {
    final ok = await ctrl.connectToAddressSilence(
      context,
      address: address,
    );
    await Future.delayed(Duration(milliseconds: 800));

    if(ok && ctrl.isConnected()){
      final state = ref.read(niimbotControllerProvider);
      final info = state.client!.getPrinterInfo() ;
      final device = state.client!.getDevice() ;
      ref.read(niimbotPrinterInfoProvider.notifier).state = info;
      ref.read(niimbotBatteryChargeProvider.notifier).state = info.charge;
      ref.read(niimbotPrinterInfoLastReadAtProvider.notifier).state = DateTime.now();

    }

  } catch (e) {
    debugPrint('[NIIMBOT] autoConnect error: $e');
  } finally {
    ref.read(isPrintingProvider.notifier).state = false ;
  }
}
Future<void> refreshPrinterInfoFromClient(WidgetRef ref, NiimbotBluetoothClient client) async {
  ref.read(niimbotPrinterInfoErrorProvider.notifier).state = null;
  final box = GetStorage();



  try {
    final info = client.getPrinterInfo(); // <- tu línea clave
    debugPrint('[NIIMBOT][INFO] ${client.getDevice()?.remoteId.str ?? 'device null'} charge=${info.charge}');
    initMtuForAddress(bluetoothAddress: client.getDevice()!.remoteId.str, ref: ref,
        box: box);


    ref.read(niimbotPrinterInfoProvider.notifier).state = info;
    ref.read(niimbotBatteryChargeProvider.notifier).state = info.charge;
    ref.read(niimbotPrinterInfoLastReadAtProvider.notifier).state = DateTime.now();

    debugPrint('[NIIMBOT][INFO] ${info.toString()} charge=${info.charge}');
  } catch (e) {
    ref.read(niimbotPrinterInfoErrorProvider.notifier).state = e.toString();
    debugPrint('[NIIMBOT][INFO] refresh ERROR: $e');
  }
}

Future<void> refreshPrinterInfoFromClientRef(Ref ref, NiimbotBluetoothClient client) async {
  ref.read(niimbotPrinterInfoErrorProvider.notifier).state = null;
  final box = GetStorage();



  try {
    final info = client.getPrinterInfo(); // <- tu línea clave
    ref.read(niimbotPrinterInfoProvider.notifier).state = info;
    ref.read(niimbotBatteryChargeProvider.notifier).state = info.charge;
    ref.read(niimbotPrinterInfoLastReadAtProvider.notifier).state = DateTime.now();

    debugPrint('[NIIMBOT][INFO] ${info.toString()} charge=${info.charge}');
  } catch (e) {
    ref.read(niimbotPrinterInfoErrorProvider.notifier).state = e.toString();
    debugPrint('[NIIMBOT][INFO] refresh ERROR: $e');
  }
}

String batteryChargeLabel(BatteryChargeLevel? c) {
  if (c == null) return '--';
  String aux = c.toString().split('.').last;
  aux = aux.toLowerCase();
  return '${aux.replaceAll('charge', '')} %'; // rápido y legible
}

double? batteryChargeToProgress(BatteryChargeLevel? c) {
  if (c == null) return null;

  // Ajustá según tu enum real:
  switch (c) {
    case BatteryChargeLevel.charge0:
      return 0;
    case BatteryChargeLevel.charge25:
      return 0.25;
    case BatteryChargeLevel.charge50:
      return 0.50;
    case BatteryChargeLevel.charge75:
      return 0.75;
    case BatteryChargeLevel.charge100:
      return 1.0;
  }
}

class PrinterInfoSheet extends StatelessWidget {
  final PrinterInfo? info;
  final int packageIntervalMs;
  final int savedMtu;

  const PrinterInfoSheet({super.key, required this.info, required this.packageIntervalMs, required this.savedMtu});

  Widget _row(String k, String? v) {
    final value = (v == null || v.trim().isEmpty) ? '--' : v.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(k, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i = info;
    if (i == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No printer info yet. Tap refresh after connecting.'),
      );
    }

    // Ajustá campos según tu DTO real
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NIIMBOT Printer Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              _row('Charge', i.charge?.toString()),
              _row('Model ID', i.modelId?.toString()),
              _row('Protocol', i.protocolVersion?.toString()),
              _row('Serial', i.serial),
              _row('MAC', i.mac),
              _row('LabelType', i.labelType?.toString()),
              _row('AutoShutdown', i.autoShutdownTime?.toString()),
              _row('Software', i.softwareVersion),
              _row('Hardware', i.hardwareVersion),
               Text('Saved parameters'),
              _row('MTU', savedMtu.toString()),
              _row('Packet Interval', '$packageIntervalMs ms'),

              const Divider(height: 22),
              const Text('Raw toString()', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SelectableText(i.toString()),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showNiimbotParamsInfoDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String bluetoothAddress,
}) async {

  final savedInterval = ref.read(niimbotPacketIntervalSavedProvider) ?? 0;
  final editInterval = ref.read(niimbotPacketIntervalEditProvider);

  final savedMtu = ref.read(niimbotMtuSavedProvider) ?? 0;
  final editMtu = ref.read(niimbotMtuEditProvider);

  final battery = ref.read(niimbotBatteryPercentProvider);
  final lastAt = ref.read(niimbotBatteryLastReadAtProvider);
  final batteryErr = ref.read(niimbotBatteryErrorProvider);

  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('NIIMBOT Params'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: $bluetoothAddress'),
            const SizedBox(height: 8),
            Text('PacketInterval saved: $savedInterval'),
            Text('PacketInterval edit: $editInterval'),
            const SizedBox(height: 8),
            Text('MTU saved: $savedMtu'),
            Text('MTU edit: $editMtu'),
            const SizedBox(height: 8),
            Text('Battery: ${battery == null ? '--' : '$battery%'}'),
            Text('Battery last: ${lastAt == null ? '--' : lastAt.toString()}'),
            if (batteryErr != null) ...[
              const SizedBox(height: 6),
              Text('Battery error: $batteryErr', style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

final niimbotBatteryPercentProvider = StateProvider.autoDispose<int?>((ref) => null);
final niimbotBatteryLastReadAtProvider = StateProvider.autoDispose<DateTime?>((ref) => null);
final niimbotBatteryErrorProvider = StateProvider.autoDispose<String?>((ref) => null);

Widget printerInfoIcon(BuildContext context, WidgetRef ref, NiimbotState st) {
  final info = ref.watch(niimbotPrinterInfoProvider);
  final color = (info == null) ? Colors.grey : Colors.green;
  final ctrl = ref.read(niimbotControllerProvider.notifier);
  final packageIntervalMs = ref.watch(niimbotPacketIntervalSavedProvider);



  return IconButton(
    tooltip: 'Printer info',
    icon: Icon(Icons.info, color: color),
    onPressed: () {
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => PrinterInfoSheet(info: info,packageIntervalMs: packageIntervalMs ?? 0
            , savedMtu:ctrl.savedMtu),
      );
    },
  );
}
Widget printerInfoRefresh(BuildContext context, WidgetRef ref, NiimbotState st,{Color? color}) {
  return IconButton(
    tooltip: 'Refresh printer info',
    icon: Icon(Icons.refresh,color: color,),
    onPressed: () async {
      final client = st.client;
      if (client == null || !client.isConnected()) return;
      await refreshPrinterInfoFromClient(ref, client);
    },
  );
}

Widget batteryChip(WidgetRef ref, {bool isConnected = false}) {
  final charge = ref.watch(niimbotBatteryChargeProvider);
  final lastAt = ref.watch(niimbotPrinterInfoLastReadAtProvider);

  final label = batteryChargeLabel(charge);

  double progress = (batteryChargeToProgress(charge) ?? 0.0).clamp(0.0, 1.0);
  progress = ((progress / 0.05).round() * 0.05).clamp(0.0, 1.0);

  Color barColor = Colors.grey;
  if (charge != null) {
    if (charge == BatteryChargeLevel.charge0 || charge == BatteryChargeLevel.charge25) {
      barColor = Colors.red;
    } else if (charge == BatteryChargeLevel.charge50) {
      barColor = Colors.yellow;
    } else {
      barColor = Colors.yellow;
    }
  }

  final bg = isConnected ? Colors.green : themeColorPrimary;

  return Container(
    height: 22, // 👈 igual al minHeight del botón
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6), // 👈 igual al botón
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.battery_std, size: 16, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 40,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white,
              color: barColor,
            ),
          ),
        ),
        if (lastAt != null) ...[
          const SizedBox(width: 6),
          Text(
            '${lastAt.hour.toString().padLeft(2,'0')}:${lastAt.minute.toString().padLeft(2,'0')}',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ],
    ),
  );
}
int get minPacketIntervalMs {
  return 10;
}
int get maxPacketIntervalMs {
  return 65;
}

bool get showPrintingResultMessage {
  return false;
}




Widget packetIntervalEditor({
  required bool disabled,
  required int saved,
  required int edit,
  required VoidCallback onSave,
  required VoidCallback onDec,
  required VoidCallback onInc,
  required WidgetRef ref,
  double paddingHorizontal = 12,
}) {

  if(paddingHorizontal==0){
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Packet Interval ms',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            // stepper estilo “spinner”
            IconButton(
              onPressed: disabled ? null : onDec,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            SizedBox(
              width: 30,
              child: Text(
                '$edit',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),
            IconButton(
              onPressed: disabled ? null : onInc,
              icon: const Icon(Icons.add_circle_outline),
            ),
            Spacer(),
            ElevatedButton.icon(
              onPressed: disabled ? null : onSave,
              icon: const Icon(Icons.save, size: 14),
              label: const Text(
                'Save',
                style: TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColorPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: const Size(0, 28), // 🔥 clave
                tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 🔥 elimina espacio extra
                visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Saved: $saved   |   Editing: $edit |   Saved ${ref.read(niimbotPacketIntervalSavedProvider)}',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
      ],
    );
  }
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
    child: Column(
      children: [
        Row(
          children: [
            Text(
              'Packet Interval ms',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            // stepper estilo “spinner”
            IconButton(
              onPressed: disabled ? null : onDec,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            SizedBox(
              width: 30,
              child: Text(
                '$edit',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),
            IconButton(
              onPressed: disabled ? null : onInc,
              icon: const Icon(Icons.add_circle_outline),
            ),
            const SizedBox(width: 8),
            Spacer(),
            ElevatedButton.icon(
              onPressed: disabled ? null : onSave,
              icon: const Icon(Icons.save, size: 14),
              label: const Text(
                'Save',
                style: TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColorPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: const Size(0, 28), // 🔥 clave
                tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 🔥 elimina espacio extra
                visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Saved: $saved   |   Editing: $edit |   Saved ${ref.read(niimbotPacketIntervalSavedProvider)}',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
      ],
    ),
  );
}
Widget autoDisconnectPanel({
  required WidgetRef ref,
}) {
  final state = ref.read(niimbotControllerProvider);
  final ctrl = ref.read(niimbotControllerProvider.notifier);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        Text(
          'Auto disconnect after print',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),

        Spacer(),
        SizedBox(
          height: 28,
          width: 60, // 👈 más ancho
          child: FittedBox(
            fit: BoxFit.fitHeight,
            alignment: Alignment.centerRight,
            child: Switch(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: state.autoDisconnectAfterPrint,
              onChanged:  (v) => ctrl.setAutoDisconnectAfterPrint(v),
            ),
          ),
        )
      ],
    ),
  );
}

Future<void> refreshPrinterInfoFromClientContainer(
    ProviderContainer container,
    NiimbotBluetoothClient client,
    ) async {
  container.read(niimbotPrinterInfoErrorProvider.notifier).state = null;

  try {
    final info = client.getPrinterInfo();
    container.read(niimbotPrinterInfoProvider.notifier).state = info;
    container.read(niimbotBatteryChargeProvider.notifier).state = info.charge;
    container.read(niimbotPrinterInfoLastReadAtProvider.notifier).state = DateTime.now();
  } catch (e) {
    container.read(niimbotPrinterInfoErrorProvider.notifier).state = e.toString();
  }
}

Widget mtuEditor({
  required bool disabled,
  required int saved,
  required int edit,
  required VoidCallback onSave,
  required ValueChanged<int?> onChanged,
  double paddingHorizontal = 12,
}) {
  const options = [0, 240, 185, 158];
  if(paddingHorizontal==0){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'MTU',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
            DropdownButton<int>(
              value: options.contains(edit) ? edit : 0,
              //isDense: true,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.purple,
              ),
              items: options
                  .map((v) => DropdownMenuItem<int>(
                value: v,
                child: Text(
                  v == 0 ? '0 (no ajustar)' : '$v',
                  style: const TextStyle(fontSize: 12),
                ),
              ))
                  .toList(),
              onChanged: disabled ? null : onChanged,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: disabled ? null : onSave,
              icon: const Icon(Icons.save, size: 14),
              label: const Text('Save', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColorPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Saved: $saved   |   Editing: $edit',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'MTU',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
            DropdownButton<int>(
              value: options.contains(edit) ? edit : 0,
              //isDense: true,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.purple,
              ),
              items: options
                  .map((v) => DropdownMenuItem<int>(
                value: v,
                child: Text(
                  v == 0 ? '0 (no ajustar)' : '$v',
                  style: const TextStyle(fontSize: 12),
                ),
              ))
                  .toList(),
              onChanged: disabled ? null : onChanged,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: disabled ? null : onSave,
              icon: const Icon(Icons.save, size: 14),
              label: const Text('Save', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColorPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Saved: $saved   |   Editing: $edit',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    ),
  );
}