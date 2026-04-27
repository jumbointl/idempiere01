import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/router/app_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../products/common/time_utils.dart';
import '../../../products/common/widget/date_range_filter_row_panel.dart';
import '../../../products/common/widget/show_document_type_filter_sheet.dart';
import '../../../products/presentation/screens/movement/provider/new_movement_provider.dart';
import '../../../shared/data/messages.dart';
import '../../domain/entities/m_in_out.dart';
import '../../infrastructure/repositories/m_in_out_repository_impl.dart';
import '../providers/m_in_out_list_provider.dart';
import '../providers/m_in_out_type.dart';

/// =============================================================
/// Alphabetically-sorted MInOutType list shown in the dropdown.
/// Index 0 (PICK CONFIRM) is the default for the first run.
/// =============================================================
const List<MInOutType> mInOutTypesAlphabetical = [
  MInOutType.pickConfirm,       // 0 - default
  MInOutType.qaConfirm,         // 1
  MInOutType.receipt,           // 2
  MInOutType.receiptConfirm,    // 3
  MInOutType.shipment,          // 4
  MInOutType.shipmentConfirm,   // 5
  MInOutType.shipmentPrepare,   // 6
];

String mInOutTypeLabel(MInOutType t) {
  switch (t) {
    case MInOutType.pickConfirm:
      return DateRangeFilterRowPanel.PICK_CONFIRM;
    case MInOutType.qaConfirm:
      return DateRangeFilterRowPanel.QA_CONFIRM;
    case MInOutType.receipt:
      return DateRangeFilterRowPanel.RECEIPT;
    case MInOutType.receiptConfirm:
      return DateRangeFilterRowPanel.RECEIPT_CONFIRM;
    case MInOutType.shipment:
      return DateRangeFilterRowPanel.SHIPMENT;
    case MInOutType.shipmentConfirm:
      return DateRangeFilterRowPanel.SHIPMENT_CONFIRM;
    case MInOutType.shipmentPrepare:
      return DateRangeFilterRowPanel.SHIPMENT_PREPARE;
    case MInOutType.move:
    case MInOutType.moveConfirm:
      return t.name;
  }
}

MInOutType? mInOutTypeFromLabel(String label) {
  for (final t in mInOutTypesAlphabetical) {
    if (mInOutTypeLabel(t) == label) return t;
  }
  return null;
}

/// =============================================================
/// Persisted last-selected label (SharedPreferences). Default index = 0.
/// `selectionFilterProvider` of DateRangeFilterRowPanel writes to this
/// provider directly via `.state = value`; the listener below mirrors
/// every state change to SharedPreferences.
/// =============================================================
const String _kPrefsLastTypeIndex = 'm_in_out_by_type_last_index';

int _initialMInOutTypeIndexFromPrefs(SharedPreferences? prefs) {
  if (prefs == null) return 0;
  final saved = prefs.getInt(_kPrefsLastTypeIndex) ?? 0;
  if (saved < 0 || saved >= mInOutTypesAlphabetical.length) return 0;
  return saved;
}

/// Hot-load future used by [mInOutByTypeLabelProvider] to seed the
/// initial label on first build (without async).
SharedPreferences? _cachedPrefs;
Future<void> _ensurePrefsLoaded() async {
  _cachedPrefs ??= await SharedPreferences.getInstance();
}

final mInOutByTypeLabelProvider = StateProvider<String>((ref) {
  final idx = _initialMInOutTypeIndexFromPrefs(_cachedPrefs);
  return mInOutTypeLabel(mInOutTypesAlphabetical[idx]);
});

/// Convenience: current MInOutType derived from the label provider.
MInOutType currentMInOutType(WidgetRef ref) {
  final label = ref.read(mInOutByTypeLabelProvider);
  return mInOutTypeFromLabel(label) ?? mInOutTypesAlphabetical[0];
}

Future<void> _persistLabel(String label) async {
  final type = mInOutTypeFromLabel(label);
  if (type == null) return;
  final idx = mInOutTypesAlphabetical.indexOf(type);
  if (idx < 0) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kPrefsLastTypeIndex, idx);
}

/// =============================================================
/// SCREEN
/// =============================================================
class MInOutByTypeListScreen extends ConsumerStatefulWidget {
  const MInOutByTypeListScreen({super.key});

  @override
  ConsumerState<MInOutByTypeListScreen> createState() =>
      _MInOutByTypeListScreenState();
}

class _MInOutByTypeListScreenState
    extends ConsumerState<MInOutByTypeListScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_initialized) return;
      _initialized = true;
      // Load saved index, seed the label provider with the persisted choice,
      // then trigger the first fetch.
      await _ensurePrefsLoaded();
      final idx = _initialMInOutTypeIndexFromPrefs(_cachedPrefs);
      final label = mInOutTypeLabel(mInOutTypesAlphabetical[idx]);
      ref.read(mInOutByTypeLabelProvider.notifier).state = label;
      _reload();
    });
  }

  void _reload() {
    final dates = ref.read(selectedMInOutDatesProvider);
    final type = currentMInOutType(ref);
    ref.read(mInOutListProvider.notifier).findByMInOutType(
          ref: ref,
          dates: dates,
          type: type,
        );
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(mInOutListProvider);
    final docType = ref.watch(documentTypeListMInOutFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('M IN OUT'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.white,
              ),
              onPressed: () async {
                showDocumentTypeFilterMultipleDatesSheet(
                  context: context,
                  ref: ref,
                  onDataChange: ({
                    required WidgetRef ref,
                    required DateTimeRange dates,
                    required String inOut,
                  }) async {
                    _reload();
                  },
                  title: 'M IN OUT ${Messages.DOCUMENT_TYPE}',
                  documentTypeOptions: documentTypeOptionsAll,
                  selectedProvider: documentTypeListMInOutFilterProvider,
                  datesRangeProvider: selectedMInOutDatesProvider,
                );
              },
              child: Text(
                docType,
                style: const TextStyle(color: Colors.purple),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          DateRangeFilterRowPanel(
            useDropdown: true,
            onReloadButtonPressed: _reload,
            selectionFilterProvider: mInOutByTypeLabelProvider,
            selectedDatesProvider: selectedMInOutDatesProvider,
            values:
                mInOutTypesAlphabetical.map((t) => mInOutTypeLabel(t)).toList(),
            onScanButtonPressed: null,
            onOk: (dates, label) {
              final type = mInOutTypeFromLabel(label);
              if (type == null) return;
              // The DateRangeFilterRowPanel already wrote to
              // mInOutByTypeLabelProvider; mirror it to disk and reload.
              _persistLabel(label);
              ref.read(mInOutListProvider.notifier).findByMInOutType(
                    ref: ref,
                    dates: dates,
                    type: type,
                  );
            },
          ),
          Expanded(
            child: _buildList(context, ref, listState),
          ),
        ],
      ),
    );
  }
}

Widget _buildList(BuildContext context, WidgetRef ref, MInOutListStatus state) {
  if (state.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  if (state.errorMessage.isNotEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          state.errorMessage,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  if (state.list.isEmpty) {
    return const Center(child: Text('Sin datos'));
  }

  return ListView.separated(
    itemCount: state.list.length,
    separatorBuilder: (_, _) => const SizedBox(height: 2),
    itemBuilder: (ctx, index) {
      final item = state.list[index];
      return _MInOutByTypeCard(item: item);
    },
  );
}

/// Card whose layout follows MovementListScreen's card visual:
/// - leading dot (doc-status color)
/// - title: documentNo
/// - subtitle: date
/// - trailing arrow icon (in/out)
/// - tap card -> MInOutScreen (correct type)
/// - print icon -> PrinterSetupScreen (with MInOut as dataToPrint)
/// - qr icon -> MInOutBarcodeListScreen
class _MInOutByTypeCard extends ConsumerWidget {
  final MInOut item;
  const _MInOutByTypeCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docNo = item.documentNo ?? '';
    final dateText = item.movementDate != null
        ? DateFormat('dd/MM/yyyy').format(item.movementDate!)
        : '';
    final IconData arrow = (item.isSoTrx == true)
        ? Icons.arrow_upward
        : Icons.arrow_downward;
    final Color arrowColor =
        (item.isSoTrx == true) ? Colors.red : Colors.green;

    final docStatus = item.docStatus.id ?? '';
    final Color statusColor = _statusColor(docStatus);
    final Color borderColor = (docStatus == 'IP')
        ? themeColorWarningLight
        : Colors.white;

    final type = currentMInOutType(ref);

    return GestureDetector(
      onTap: () {
        if ((item.id ?? -1) <= 0) return;
        context.push('${AppRouter.PAGE_M_IN_OUT}/${type.name}/$docNo');
      },
      child: Card(
        elevation: 2.0,
        color: borderColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: borderColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.circle, color: statusColor, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docNo,
                      style: const TextStyle(fontSize: themeFontSizeLarge),
                    ),
                    Text(
                      '${Messages.DATE}: $dateText',
                      style: TextStyle(
                        fontSize: themeFontSizeSmall,
                        color: themeColorGray,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.print),
                color: themeColorPrimary,
                tooltip: 'Print',
                onPressed: () async {
                  final id = item.id ?? -1;
                  if (id <= 0) return;

                  // Lines are not loaded by the list query; fetch them now
                  // before navigating so the print screen has data to render.
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final lines =
                        await MInOutRepositoryImpl().getLinesMInOut(id, ref);
                    item.lines = lines;

                    if (!context.mounted) return;
                    Navigator.of(context, rootNavigator: true).pop();

                    context.push(AppRouter.PAGE_M_IN_OUT_PRINTER_SETUP,
                        extra: item);
                  } catch (e) {
                    if (!context.mounted) return;
                    Navigator.of(context, rootNavigator: true).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${Messages.ERROR}: $e')),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.qr_code),
                color: themeColorPrimary,
                tooltip: 'QR',
                onPressed: () async {
                  final id = item.id ?? -1;
                  if (id <= 0) return;

                  // Lines are not loaded by the list query; fetch them now
                  // before navigating so the barcode screen has data to render.
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final lines =
                        await MInOutRepositoryImpl().getLinesMInOut(id, ref);
                    item.lines = lines;

                    if (!context.mounted) return;
                    Navigator.of(context, rootNavigator: true).pop();

                    context.push(AppRouter.PAGE_M_IN_OUT_BARCODE_LIST,
                        extra: item);
                  } catch (e) {
                    if (!context.mounted) return;
                    Navigator.of(context, rootNavigator: true).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${Messages.ERROR}: $e')),
                    );
                  }
                },
              ),
              Icon(arrow, color: arrowColor),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String code) {
    switch (code) {
      case 'DR':
        return Colors.grey;
      case 'IP':
        return Colors.cyan;
      case 'CO':
        return Colors.green;
      case 'VO':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
