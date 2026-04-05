
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';

import 'package:riverpod_printer/riverpod_printer.dart';
import 'niimbot_page.dart';
import 'niimbot_page_helper.dart';
import 'niimbot_silence_page_provider.dart';

class NiimbotPrintSilencePage extends ConsumerStatefulWidget {
  final dynamic dataToPrint;
  final LabelProfile? profile;
  final String bluetoothAddress;

  const NiimbotPrintSilencePage({
    super.key,
    required this.dataToPrint,
    required this.profile,
    required this.bluetoothAddress,
  });

  @override
  ConsumerState<NiimbotPrintSilencePage> createState() =>
      _NiimbotPrintSilencePageState();
}

class _NiimbotPrintSilencePageState
    extends ConsumerState<NiimbotPrintSilencePage> {
  Uint8List? _preview;
  bool _initDone = false;
  int _copies = 1;
  LabelProfile? _activeProfile;
  late final NiimbotController _ctrl;
  bool autoConnectDone = false;

  @override
  void initState() {
    super.initState();

    _activeProfile = widget.profile;
    _copies = (widget.profile?.copies ?? 1);
    if (_copies < 1) _copies = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final box = GetStorage();
      await initPacketIntervalForAddress(
        ref: ref,
        bluetoothAddress: widget.bluetoothAddress,
        box: box,
      );
      await initMtuForAddress(
        ref: ref,
        bluetoothAddress: widget.bluetoothAddress,
        box: box,
      );
      _ctrl = ref.read(niimbotControllerProvider.notifier);
      await _initPayloadAndPreview();
      if (!mounted) return;
      autoConnectIfNeeded(context, ref, autoConnectDone: autoConnectDone,
          bluetoothAddress: widget.bluetoothAddress);
    });
  }

  LabelProfile _profileWithCopies(LabelProfile base, int copies) {
    return base.copyWith(copies: copies);
  }

  Widget _copiesStepper(bool disabled) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        children: [
          const Text(
            'Copies',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            onPressed: disabled || _copies <= 1
                ? null
                : () async {
              setState(() => _copies--);
              await _refreshPayloadProfileOnly();
              // opcional: await _refreshPreview(); // si querés que cambie la preview
            },
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$_copies',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: disabled
                ? null
                : () async {
              setState(() => _copies++);
              await _refreshPayloadProfileOnly();
              // opcional: await _refreshPreview();
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
  Future<void> _refreshPayloadProfileOnly() async {
    final ctrl = ref.read(niimbotControllerProvider.notifier);
    final base = _activeProfile ?? widget.profile ?? ctrl.defaultProfile();
    final renewed = _profileWithCopies(base, _copies);

    _activeProfile = renewed;

    ref.read(niimbotSilentPayloadProvider.notifier).state =
        NiimbotSilentPrintPayload(
          dataToPrint: widget.dataToPrint,
          profile: renewed,
          bluetoothAddress: widget.bluetoothAddress,
        );
  }
  Future<void> _initPayloadAndPreview() async {
    if (_initDone) return;
    _initDone = true;
    // 1) Set payload provider
    ref.read(niimbotSilentPayloadProvider.notifier).state =
        NiimbotSilentPrintPayload(
          dataToPrint: widget.dataToPrint,
          profile: widget.profile,
          bluetoothAddress: widget.bluetoothAddress,
        );

    // 2) Build preview (sin imprimir)
    try {
      final ctrl = ref.read(niimbotControllerProvider.notifier);
      final p = widget.profile ?? ctrl.defaultProfile();

      // Creamos el job para poder generar preview
      await ctrl.queuePendingJobForDataSilence(data: widget.dataToPrint, profile: p);

      final job = ref.read(niimbotControllerProvider).pendingJob;
      if (job == null) return;

      final img = await job.page.toPreviewImage();
      if (!mounted) return;
      setState(() => _preview = img);
    } catch (e) {
      debugPrint('[NIIMBOT] preview build failed: $e');
      // Preview es opcional. Igual puede imprimir.
    }
  }

  Future<void> _firePrint() async {
    await _refreshPayloadProfileOnly();
    ref.read(niimbotSilentTriggerProvider.notifier).state++;
    if(!context.mounted) return ;
    ref.read(niimbotSilentPrintControllerProvider.notifier).run(context);
  }


  final bool _autoCloseFired = false;
  @override
  Widget build(BuildContext context) {
    final savedInterval = ref.watch(niimbotPacketIntervalSavedProvider) ?? 0;
    final editInterval = ref.watch(niimbotPacketIntervalEditProvider);
    final async = ref.watch(niimbotSilentPrintControllerProvider);
    final isLoading = async.isLoading;
    final savedMtu = ref.watch(niimbotMtuSavedProvider) ?? 0;
    final editMtu = ref.watch(niimbotMtuEditProvider);
    var state = ref.watch(niimbotControllerProvider);
    final client = state.client;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () async => await popScopAction(context, ref),
          icon: const Icon(Icons.arrow_back),
        ),
        title:Column(
            children: [
              getClientStatusPanel(state,onReconnect:() async {

                  String address = widget.bluetoothAddress;
                  _ctrl.reconnect(context:context,address: address,state: state);

                }
              ),
              if((state.client!=null && state.client!.isConnected()))
              Row(
                children: [
                  Expanded(child: batteryChip(ref,isConnected: client?.isConnected() ?? false)),
                  SizedBox(width: 20,),
                  getBluetoothIndicatorPanel(state),
                ],
              ),
            ],
          ),

        actions: [
          if((state.client!=null && state.client!.isConnected()))
          printerInfoIcon(context, ref, ref.read(niimbotControllerProvider)),



        ],
      ),

      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) return;
          await popScopAction(context, ref);
        },
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Preview image (mismo estilo que _PreviewModal)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          color: themeColorPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                          child: Container(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: _preview != null
                                  ? Image.memory(
                                _preview!,
                                fit: BoxFit.contain,
                                height: MediaQuery.of(context).size.height * 0.20,
                              )
                                  : SizedBox(
                                height: MediaQuery.of(context).size.height * 0.20,
                                child: const Center(
                                  child: Text(
                                    'No preview',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10,),
                      if(!state.isPrinting)
                        getPrintPanel(context,ref,vertical: true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if(!state.isPrinting)
                  _copiesStepper(isLoading),

                  if(!state.isPrinting)
                  packetIntervalEditor(
                    ref: ref,
                    disabled: isLoading,
                    saved: savedInterval,
                    edit: editInterval,
                    onSave: () async {
                      final box = GetStorage();
                      await savePacketIntervalForAddress(
                        ref: ref,
                        bluetoothAddress: widget.bluetoothAddress,
                        box: box,
                      );

                      if (context.mounted) {
                        final message = 'Packet Interval(ms) saved';
                        showSuccessCenterToast(context, message);
                      }
                    },
                    onDec: () {
                      final v = ref.read(niimbotPacketIntervalEditProvider);
                      ref.read(niimbotPacketIntervalEditProvider.notifier).state =
                          (v - 1).clamp(minPacketIntervalMs, maxPacketIntervalMs);
                    },
                    onInc: () {
                      final v = ref.read(niimbotPacketIntervalEditProvider);
                      ref.read(niimbotPacketIntervalEditProvider.notifier).state =
                          (v + 1).clamp(minPacketIntervalMs, maxPacketIntervalMs);
                    },
                  ),
                  if(!state.isPrinting)
                  mtuEditor(
                    disabled: isLoading,
                    saved: savedMtu,
                    edit: editMtu,
                    onChanged: (v) {
                      if (v == null) return;
                      ref.read(niimbotMtuEditProvider.notifier).state = v;
                    },
                    onSave: () async {
                      final box = GetStorage();
                      await saveMtuForAddress(
                        ref: ref,
                        bluetoothAddress: widget.bluetoothAddress,
                        box: box,
                      );
                      if (context.mounted) {
                        showSuccessCenterToast(context, 'MTU saved');
                      }
                    },
                  ),
                  //autoDisconnectPanel(ref: ref),
                  if(!state.isPrinting)
                  const SizedBox(height: 6),



                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> popScopAction(BuildContext context, WidgetRef ref, {bool? action}) async {
    try{
      await _ctrl.handleDisconnect(context);
    }catch(_){

    }
    action ??=false;
    if (!context.mounted) return;
    Navigator.pop(context,action);
  }

  Widget getPrintPanel(BuildContext context, WidgetRef ref,{bool? vertical}) {
    final state = ref.watch(niimbotControllerProvider);
    final width = 100.0 ;
    if(vertical==true){
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if((state.client!=null && state.client!.isConnected()))
            Row(
              children: [
                printerInfoRefresh(context, ref, ref.read(niimbotControllerProvider),color:Colors.purple),
                IconButton(onPressed: () async {
                  if(widget.bluetoothAddress.isEmpty) return ;
                  await _ctrl.reconnect(context: context, address: widget.bluetoothAddress,
                      state: state);
                }, icon: Icon(Symbols.autorenew,color: Colors.purple,)),
              ],
            ),

          SizedBox(
            width: width,
            child: ElevatedButton(
              onPressed: state.isPrinting ? null : () async {
                if (!(state.client?.isConnected() ?? false) ||
                    state.client?.getModelMetadata() == null
                    || state.client
                        ?.getPrinterInfo()
                        .modelId == null) {
                  String message = 'Model = null, please exit page, to re connect';
                  await showWarningCenterToast(context, message);
                  return;
                }
                _firePrint();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                padding: const EdgeInsets.symmetric(
                  //horizontal: 30,
                  vertical: 6,
                ),
              ),
              child: const Text(
                'Print',
                style: TextStyle(color: Colors.white, fontSize: 13,fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: ElevatedButton(
              onPressed: state.isPrinting ? null : () async {
                if (!(state.client?.isConnected() ?? false) ||
                    state.client?.getModelMetadata() == null
                    || state.client
                        ?.getPrinterInfo()
                        .modelId == null) {
                  String message = 'Model = null, please exit page, to re connect';
                  await showWarningCenterToast(context, message);
                  return;
                }
                await popScopAction(context, ref, action: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  //horizontal: 30,
                  vertical: 6,
                ),
              ),
              child: const Text(
                'Ok',
                style: TextStyle(color: themeColorPrimary, fontSize: 13,fontWeight: FontWeight.w600),
              ),
            ),
          ),
          /*SizedBox(
            width: width,
            child: TextButton(
              style: TextButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 1), // Color y grosor
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Esquinas redondeadas
                ),
              ),
              onPressed: state.isPrinting
                  ? null
                  : () async {
                await popScopAction(context, ref, action: true);
              },
              child: const Text(
                'Ok',
                style: TextStyle(color: themeColorPrimary, fontSize: 16),
              ),
            ),
          ),*/

        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: state.isPrinting
                ? null
                : () async {
              await popScopAction(context, ref, action: false);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),

          ElevatedButton(
            onPressed: state.isPrinting ? null : () async {
              if (!(state.client?.isConnected() ?? false) ||
                  state.client?.getModelMetadata() == null
                  || state.client
                      ?.getPrinterInfo()
                      .modelId == null) {
                String message = 'Model = null, please exit page, to re connect';
                await showWarningCenterToast(context, message);
                return;
              }
              _firePrint();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 12,
              ),
            ),
            child: const Text(
              'Print',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: state.isPrinting
                ? null
                : () async {
              await popScopAction(context, ref, action: true);
            },
            child: const Text(
              'Ok',
              style: TextStyle(color: themeColorPrimary, fontSize: 16),
            ),
          ),

        ],
      );
    }
  }




}