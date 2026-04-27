import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../../config/config.dart';
import '../../../products/common/input_dialog.dart';
import '../../../products/common/scan_button_by_action_fixed_short.dart';
import '../../../shared/data/messages.dart';
import '../../domain/entities/line.dart';
import '../../domain/entities/m_in_out.dart';
import '../providers/multi_m_in_out_providers.dart';
import '../providers/multi_m_in_out_session.dart';
import '../utils/multi_receipt_colors.dart';
import '../utils/multi_receipt_excel_export.dart';

/// Multi-Receipt screen: lets the user scan barcodes against several MInOut
/// documents in the same session.
///
/// Tab 0 — Recepciones: list of session cards (color-coded).
/// Tab 1 — Líneas: pending lines from every active session, color-coded.
/// Tab 2 — Scan: global scanned-barcode list.
/// Tab 3 — Completados: collapsible per-MInOut completed list.
class MultiMInOutScreen extends ConsumerStatefulWidget {
  final String type;

  const MultiMInOutScreen({super.key, required this.type});

  @override
  ConsumerState<MultiMInOutScreen> createState() =>
      _MultiMInOutScreenState();
}

class _MultiMInOutScreenState extends ConsumerState<MultiMInOutScreen> {
  final _docCtrl = TextEditingController();
  final _scanCtrl = TextEditingController();
  final _scanFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(multiMInOutProvider.notifier);
      notifier.primeForType(widget.type, ref);
      await notifier.restoreFromStorage();
    });
  }

  @override
  void dispose() {
    _docCtrl.dispose();
    _scanCtrl.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(multiMInOutProvider);
    final notifier = ref.read(multiMInOutProvider.notifier);

    ref.listen<MultiMInOutState>(multiMInOutProvider, (prev, next) {
      if (next.errorMessage.isNotEmpty &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage)),
        );
        notifier.clearError();
      }
    });

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Multiple Receipt'),
          bottom: TabBar(
            isScrollable: true,
            indicatorWeight: 4,
            indicatorColor: themeColorPrimary,
            labelColor: themeColorPrimary,
            tabs: [
              Tab(text: 'Recepciones (${state.activeSessions.length})'),
              Tab(text: 'Líneas'),
              Tab(text: 'Scan (${state.globalScans.length})'),
              Tab(text: 'Completados (${state.completedSessions.length})'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Grabar',
              icon: const Icon(Icons.save_alt),
              onPressed: () async {
                await notifier.save();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sesión guardada')),
                );
              },
            ),
            IconButton(
              tooltip: 'Agregar recepción',
              icon: const Icon(Icons.add),
              onPressed: () => _showAddSessionDialog(context),
            ),
          ],
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _SessionsTab(
                    state: state,
                    notifier: notifier,
                    onComplete: (s) => _confirmComplete(context, s),
                    onRemove: (s) => _confirmRemove(context, s),
                  ),
                  _LinesTab(state: state, notifier: notifier),
                  _ScanTab(
                    state: state,
                    notifier: notifier,
                    scanCtrl: _scanCtrl,
                    scanFocus: _scanFocus,
                  ),
                  _CompletedTab(state: state),
                ],
              ),
        bottomNavigationBar: BottomAppBar(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _exportOnly(context, state),
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: const Text(
                    'Solo guardar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeColorPrimary,
                    side: BorderSide(color: themeColorPrimary),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportAndShare(context, state),
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text(
                    'Guardar y enviar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColorPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportOnly(
    BuildContext context,
    MultiMInOutState state,
  ) async {
    if (state.activeSessions.isEmpty && state.completedSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay recepciones para exportar')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final file =
          await MultiReceiptExcelExport.build(state, persistent: true);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            'Guardado en:\n${file.path}',
            style: const TextStyle(fontSize: 12),
          ),
          action: SnackBarAction(
            label: 'COPIAR RUTA',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: file.path));
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando Excel: $e')),
      );
    }
  }

  Future<void> _exportAndShare(
    BuildContext context,
    MultiMInOutState state,
  ) async {
    if (state.activeSessions.isEmpty && state.completedSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay recepciones para exportar')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final file = await MultiReceiptExcelExport.build(state);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final allDocs = [
        ...state.activeSessions.map((s) => s.documentNo),
        ...state.completedSessions.map((s) => '${s.documentNo} (CO)'),
      ];
      final subject = 'Multiple Receipt: ${allDocs.take(5).join(', ')}'
          '${allDocs.length > 5 ? ' …' : ''}';
      final body =
          'Adjunto Excel con el detalle de ${allDocs.length} recepción(es):\n'
          '${allDocs.join('\n')}';

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: subject,
          text: body,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generando Excel: $e')),
      );
    }
  }

  Future<void> _showAddSessionDialog(BuildContext context) async {
    _docCtrl.clear();
    final result = await showDialog<_AddDialogResult>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Agregar recepción'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _docCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'DocumentNo',
                        hintText: 'Ej. 1000123',
                      ),
                      onSubmitted: (v) => Navigator.of(ctx)
                          .pop(_AddDialogResult.manual(v.trim())),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Escanear con cámara',
                    icon: const Icon(Icons.camera_alt),
                    color: themeColorPrimary,
                    onPressed: () async {
                      final scanned = await SimpleBarcodeScanner.scanBarcode(
                        ctx,
                        barcodeAppBar: BarcodeAppBar(
                          appBarTitle: Messages.SCANNING,
                          centerTitle: false,
                          enableBackButton: true,
                          backButtonIcon: const Icon(Icons.arrow_back_ios),
                        ),
                        isShowFlashIcon: true,
                        delayMillis: 300,
                        cameraFace: CameraFace.back,
                      );
                      final code = scanned?.trim();
                      if (code != null && code.isNotEmpty) {
                        Navigator.of(ctx)
                            .pop(_AddDialogResult.manual(code));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar de lista'),
                  onPressed: () =>
                      Navigator.of(ctx).pop(_AddDialogResult.search()),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx)
                  .pop(_AddDialogResult.manual(_docCtrl.text.trim())),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final notifier = ref.read(multiMInOutProvider.notifier);
    if (result.openSearch) {
      if (!mounted) return;
      final picked = await _showDocSearchDialog(context);
      if (picked != null) {
        await notifier.addSessionFromMInOut(picked);
      }
    } else if (result.documentNo.isNotEmpty) {
      await notifier.addSessionByDocumentNo(result.documentNo, ref);
    }
  }

  Future<MInOut?> _showDocSearchDialog(BuildContext context) async {
    final notifier = ref.read(multiMInOutProvider.notifier);
    final docs = await notifier.fetchAvailableDocs(ref);
    if (!mounted) return null;
    return showDialog<MInOut>(
      context: context,
      builder: (ctx) => _DocSearchDialog(docs: docs),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    MultiMInOutSession s,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar recepción'),
        content: Text('¿Quitar el documento ${s.documentNo} de la sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(multiMInOutProvider.notifier).removeSession(s.sessionId);
    }
  }

  Future<void> _confirmComplete(
    BuildContext context,
    MultiMInOutSession s,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Completar recepción'),
        content: Text(
          'Completar el documento ${s.documentNo}? '
          'Se moverá a la pestaña Completados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(multiMInOutProvider.notifier)
          .completeSession(s.sessionId, ref);
    }
  }
}

// ============================================================
// Tab 0 — Recepciones (list of cards)
// ============================================================
class _SessionsTab extends StatelessWidget {
  final MultiMInOutState state;
  final MultiMInOutNotifier notifier;
  final void Function(MultiMInOutSession) onComplete;
  final void Function(MultiMInOutSession) onRemove;

  const _SessionsTab({
    required this.state,
    required this.notifier,
    required this.onComplete,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (state.activeSessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay recepciones agregadas. Tocá + para agregar una.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: state.activeSessions.length,
      itemBuilder: (ctx, i) {
        final s = state.activeSessions[i];
        return _SessionCard(
          session: s,
          onComplete: () => onComplete(s),
          onRemove: () => onRemove(s),
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final MultiMInOutSession session;
  final VoidCallback onComplete;
  final VoidCallback onRemove;

  const _SessionCard({
    required this.session,
    required this.onComplete,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bg = colorForSessionIndex(session.colorIndex);
    final accent = accentForSessionIndex(session.colorIndex);
    final label = labelForSessionIndex(session.colorIndex);
    final pending = session.pendingLines.length;
    final total = session.mInOut.lines.length;
    return Card(
      color: bg,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: accent, width: 1.4),
        borderRadius: BorderRadius.circular(themeBorderRadius),
      ),
      child: Padding(
        // Same right padding for row 1 (Complete) and row 2 (X) so they
        // line up on the right edge.
        padding: const EdgeInsets.fromLTRB(10, 6, 6, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: avatar + docNo + Complete (touches right edge) ──
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accent,
                  radius: 11,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.documentNo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text(
                    'Complete',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 26),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // ── Row 2: chips + X (right) ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 3,
                    children: [
                      _Chip(label: 'Líneas', value: '$total'),
                      _Chip(
                        label: 'Pendientes',
                        value: '$pending',
                        highlight: pending > 0,
                      ),
                      _Chip(
                        label: 'Scans',
                        value: '${session.scannedBarcodes.length}',
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Quitar',
                  child: InkWell(
                    onTap: onRemove,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _Chip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight ? Colors.red.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? Colors.red.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: highlight ? Colors.red.shade700 : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ============================================================
// Tab 1 — Líneas (all pending lines from all active sessions)
// ============================================================
class _LinesTab extends ConsumerWidget {
  final MultiMInOutState state;
  final MultiMInOutNotifier notifier;

  const _LinesTab({required this.state, required this.notifier});

  Future<void> _editQty(
    BuildContext context,
    WidgetRef ref,
    _LineEntry e,
  ) async {
    final current = e.line.confirmedQty ?? 0;
    await getDoubleDialog(
      ref: ref,
      quantity: current,
      minValue: 0,
      maxValue: null,
      targetProvider: multiReceiptEditQtyProvider,
    );
    final newQty = ref.read(multiReceiptEditQtyProvider);
    if (newQty != current) {
      await notifier.setLineQty(e.session.sessionId, e.line.id, newQty);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = <_LineEntry>[];
    for (final s in state.activeSessions) {
      for (final l in s.mInOut.lines) {
        entries.add(_LineEntry(session: s, line: l));
      }
    }
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No hay líneas. Agregá una recepción primero.'),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (ctx, i) {
        final e = entries[i];
        final bg = colorForSessionIndex(e.session.colorIndex);
        final accent = accentForSessionIndex(e.session.colorIndex);
        final confirmed = e.line.confirmedQty ?? 0;
        final movement = e.line.movementQty ?? 0;
        final pending = movement - confirmed;
        final qtyOk = pending <= 0;
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: accent,
                radius: 9,
                child: Text(
                  labelForSessionIndex(e.session.colorIndex),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.line.productName ?? '(sin nombre)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${e.line.upc ?? '-'} · ${e.session.documentNo}',
                      style: const TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _QtyChip(
                confirmed: confirmed,
                movement: movement,
                accent: accent,
                ok: qtyOk,
                onTap: () => _editQty(context, ref, e),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Clickable quantity chip — shows confirmed/movement and opens the edit
/// dialog when tapped. Replaces the previous +/- buttons.
class _QtyChip extends StatelessWidget {
  final num confirmed;
  final num movement;
  final Color accent;
  final bool ok;
  final VoidCallback onTap;

  const _QtyChip({
    required this.confirmed,
    required this.movement,
    required this.accent,
    required this.ok,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = ok ? Colors.green.shade800 : Colors.red.shade800;
    final bg = ok ? Colors.green.shade50 : Colors.red.shade50;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$confirmed/$movement',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit, size: 13, color: fg),
          ],
        ),
      ),
    );
  }
}

class _LineEntry {
  final MultiMInOutSession session;
  final Line line;
  _LineEntry({required this.session, required this.line});
}

// ============================================================
// Tab 2 — Scan (global barcode list + input)
// ============================================================
class _ScanTab extends ConsumerStatefulWidget {
  final MultiMInOutState state;
  final MultiMInOutNotifier notifier;
  final TextEditingController scanCtrl;
  final FocusNode scanFocus;

  const _ScanTab({
    required this.state,
    required this.notifier,
    required this.scanCtrl,
    required this.scanFocus,
  });

  @override
  ConsumerState<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends ConsumerState<_ScanTab> {
  Future<void> _onScan(String code) async {
    if (code.trim().isEmpty) return;
    widget.scanCtrl.clear();
    widget.scanFocus.requestFocus();

    final outcome =
        await widget.notifier.dispatchBarcodeAsync(code, ref);
    if (!mounted) return;

    switch (outcome.mode) {
      case DispatchMode.choice:
        final picked = await showDialog<_DispatchPick>(
          context: context,
          builder: (ctx) => _DispatchChooserDialog(
            code: code.trim(),
            candidates: outcome.candidates,
          ),
        );
        if (picked != null) {
          await widget.notifier.resolveChoice(
            code.trim(),
            picked.sessionId,
            picked.lineId,
            qty: picked.qty,
          );
        }
        break;
      case DispatchMode.documentAdded:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Recepción ${outcome.documentNo} agregada por scan'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case DispatchMode.unmatched:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código no encontrado en líneas ni documentos'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case DispatchMode.auto:
      case DispatchMode.empty:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.scanCtrl,
                  focusNode: widget.scanFocus,
                  decoration: InputDecoration(
                    labelText: 'Escanear / ingresar código',
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: _onScan,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ScanButtonByActionFixedShort(
                  actionTypeInt: 0,
                  onOk: ({required ref, required inputData, required actionScan}) {
                    _onScan(inputData);
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: widget.state.globalScans.isEmpty
              ? const Center(child: Text('Aún no se escaneó nada'))
              : ListView.builder(
                  reverse: true,
                  itemCount: widget.state.globalScans.length,
                  itemBuilder: (ctx, idx) {
                    final scan = widget.state.globalScans[
                        widget.state.globalScans.length - 1 - idx];
                    final colorIdx = scan.sessionColorIndex;
                    final bg = colorIdx != null
                        ? colorForSessionIndex(colorIdx)
                        : Colors.grey.shade100;
                    final accent = colorIdx != null
                        ? accentForSessionIndex(colorIdx)
                        : Colors.grey;
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: accent.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          if (colorIdx != null)
                            CircleAvatar(
                              backgroundColor: accent,
                              radius: 9,
                              child: Text(
                                labelForSessionIndex(colorIdx),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            const Icon(Icons.help_outline,
                                size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              scan.code,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Text(
                            scan.resolution == 'unmatched'
                                ? '⚠ no encontrado'
                                : scan.resolution == 'pending_choice'
                                    ? '… pendiente'
                                    : '✓',
                            style: TextStyle(
                              fontSize: 11,
                              color: scan.resolution == 'unmatched'
                                  ? Colors.red.shade700
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DispatchPick {
  final String sessionId;
  final int? lineId;
  final double qty;
  _DispatchPick(this.sessionId, this.lineId, this.qty);
}

class _DispatchChooserDialog extends StatefulWidget {
  final String code;
  final List<MapEntry<MultiMInOutSession, List<Line>>> candidates;

  const _DispatchChooserDialog({
    required this.code,
    required this.candidates,
  });

  @override
  State<_DispatchChooserDialog> createState() => _DispatchChooserDialogState();
}

class _DispatchChooserDialogState extends State<_DispatchChooserDialog> {
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  String? _qtyError;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  // Returns the parsed qty if valid (>= 0); otherwise sets _qtyError and
  // returns null. Called when the user taps a candidate row.
  double? _validateQty() {
    final raw = _qtyCtrl.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      setState(() => _qtyError = 'Cantidad invalida');
      return null;
    }
    if (parsed < 0) {
      setState(() => _qtyError = 'Minimo 0');
      return null;
    }
    if (_qtyError != null) {
      setState(() => _qtyError = null);
    }
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Elegir destino para ${widget.code}'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Cantidad',
                errorText: _qtyError,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) {
                if (_qtyError != null) {
                  setState(() => _qtyError = null);
                }
              },
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final entry in widget.candidates)
                    for (final line in entry.value)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              accentForSessionIndex(entry.key.colorIndex),
                          child: Text(
                            labelForSessionIndex(entry.key.colorIndex),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(line.productName ?? '(sin nombre)'),
                        subtitle: Text(
                          'Doc: ${entry.key.documentNo}  ·  '
                          'UPC: ${line.upc}  ·  '
                          'Conf: ${line.confirmedQty ?? 0}/${line.movementQty ?? 0}',
                        ),
                        onTap: () {
                          final qty = _validateQty();
                          if (qty == null) return;
                          Navigator.of(context).pop(
                            _DispatchPick(
                                entry.key.sessionId, line.id, qty),
                          );
                        },
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

// ============================================================
// Tab 3 — Completados (collapsible per-MInOut)
// ============================================================
// ============================================================
// Add-session dialog result + Buscar list dialog
// ============================================================
class _AddDialogResult {
  final String documentNo;
  final bool openSearch;
  const _AddDialogResult._(this.documentNo, this.openSearch);
  factory _AddDialogResult.manual(String docNo) =>
      _AddDialogResult._(docNo, false);
  factory _AddDialogResult.search() => const _AddDialogResult._('', true);
}

class _DocSearchDialog extends StatefulWidget {
  final List<MInOut> docs;
  const _DocSearchDialog({required this.docs});

  @override
  State<_DocSearchDialog> createState() => _DocSearchDialogState();
}

class _DocSearchDialogState extends State<_DocSearchDialog> {
  final _filterCtrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _q.isEmpty
        ? widget.docs
        : widget.docs
            .where((m) =>
                (m.documentNo ?? '').toLowerCase().contains(_q.toLowerCase()))
            .toList();
    return AlertDialog(
      title: const Text('Recepciones disponibles'),
      content: SizedBox(
        width: 380,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _filterCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Filtrar por DocumentNo',
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final m = filtered[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.description),
                          title: Text(m.documentNo ?? '-'),
                          subtitle: Text(
                            'Status: ${m.docStatus.id ?? '-'}'
                            '${m.movementDate != null ? '  ·  ${m.movementDate!.toIso8601String().split('T').first}' : ''}',
                          ),
                          onTap: () => Navigator.of(context).pop(m),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

// ============================================================
// Tab 3 — Completados (collapsible per-MInOut)
// ============================================================
class _CompletedTab extends StatelessWidget {
  final MultiMInOutState state;
  const _CompletedTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.completedSessions.isEmpty) {
      return const Center(child: Text('Aún no hay recepciones completadas'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      itemCount: state.completedSessions.length,
      itemBuilder: (ctx, i) {
        final s = state.completedSessions[i];
        final bg = colorForSessionIndex(s.colorIndex);
        final accent = accentForSessionIndex(s.colorIndex);
        return Card(
          color: bg,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: accent, width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: accent,
              radius: 14,
              child: Text(
                labelForSessionIndex(s.colorIndex),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              s.documentNo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${s.mInOut.lines.length} líneas · '
              '${s.scannedBarcodes.length} scans',
            ),
            children: [
              for (final l in s.mInOut.lines)
                ListTile(
                  dense: true,
                  title: Text(l.productName ?? '(sin nombre)'),
                  subtitle: Text(
                    'UPC: ${l.upc ?? '-'} · '
                    'Conf ${l.confirmedQty ?? 0}/${l.movementQty ?? 0}',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
