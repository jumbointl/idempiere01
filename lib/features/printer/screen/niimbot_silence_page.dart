
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';

import '../../products/domain/models/label_profile.dart';
import 'niimbot_page.dart';
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
  final bool _updatingPreview = false;
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

      await _initPayloadAndPreview();
    });
  }
  LabelProfile _profileWithCopies(LabelProfile base, int copies) {
    return base.copyWith(copies: copies);
  }
  Widget _copiesStepper(bool disabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
    // 1) Actualizar payload con copias actuales ANTES del run
    await _refreshPayloadProfileOnly();

    // 2) trigger (opcional)
    ref.read(niimbotSilentTriggerProvider.notifier).state++;

    // 3) iniciar AsyncValue
    ref.read(niimbotSilentPrintControllerProvider.notifier).run(context);
  }
  Widget _packetIntervalEditor({
    required bool disabled,
    required int saved,
    required int edit,
    required VoidCallback onSave,
    required VoidCallback onDec,
    required VoidCallback onInc,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Packet Interval Ms',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
              'Saved: $saved   |   Editing: $edit',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final savedInterval = ref.watch(niimbotPacketIntervalSavedProvider) ?? 0;
    final editInterval = ref.watch(niimbotPacketIntervalEditProvider);
    final async = ref.watch(niimbotSilentPrintControllerProvider);
    final isLoading = async.isLoading;
    final packetIntervalMs = ref.watch(packetIntervalMsProvider);
    final exitOnSuccess = ref.watch(exitPrintPageOnSuccessProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Preview',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),

                      // ✅ checkbox compacto a la derecha
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => ref
                            .read(exitPrintPageOnSuccessProvider.notifier)
                            .setValue(!exitOnSuccess),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: exitOnSuccess,
                              onChanged:  (v) => ref
                                  .read(exitPrintPageOnSuccessProvider.notifier)
                                  .setValue(v ?? false),
                              visualDensity: VisualDensity.compact,
                              activeColor: themeColorPrimary,
                            ),
                            const Text(
                              'Salir al OK',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
        
                // Preview image (mismo estilo que _PreviewModal)
                Container(
                  color: themeColorPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Container(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: _preview != null
                          ? Image.memory(
                        _preview!,
                        fit: BoxFit.contain,
                        width: MediaQuery.of(context).size.width * 0.8,
                      )
                          : SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
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
        
                const Divider(height: 1),
                const SizedBox(height: 10),
        
                // AsyncValue UI
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: async.when(
                    data: (res) {
                      if (res == null) {
                        return const SizedBox.shrink();
                      }
                      final ok = res.success == true;
                      final exitOnSuccess = ref.read(exitPrintPageOnSuccessProvider);
                      if (ok && exitOnSuccess) {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          await Future.delayed(const Duration(milliseconds: 200));
                          if (context.mounted) Navigator.pop(context, true);
                        });
                      }
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ok ? Colors.green : Colors.red),
                        ),
                        child: Text(
                          ok ? (res.message ?? 'Print done') : (res.message ?? 'Print failed'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ok ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                    loading: () => Column(
                      children: [
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          color: themeColorPrimary,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Printing...', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 10),
                            const Text('Packet interval:', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.purple),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${packetIntervalMs <= 0 ? 0 : packetIntervalMs} ms',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    error: (e, st) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        e.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
        
                const SizedBox(height: 10),
                _copiesStepper(isLoading),
                const SizedBox(height: 10),
                _packetIntervalEditor(
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
                        (v - 1).clamp(0, 200);
                  },
                  onInc: () {
                    final v = ref.read(niimbotPacketIntervalEditProvider);
                    ref.read(niimbotPacketIntervalEditProvider.notifier).state =
                        (v + 1).clamp(0, 200);
                  },
                ),
                const SizedBox(height: 6),
        
                // Buttons (igual al modal)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                        Navigator.pop(context,false);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isLoading ? null : _firePrint,
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
                      onPressed: isLoading
                          ? null
                          : () {
                        Navigator.pop(context,true);
                      },
                      child: const Text(
                        'Ok',
                        style: TextStyle(color: themeColorPrimary, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}