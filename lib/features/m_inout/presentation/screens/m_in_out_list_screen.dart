import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common_provider.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

import '../../../../config/router/app_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../products/common/time_utils.dart';
import '../../../products/common/widget/date_range_filter_row_panel.dart';
import '../../../products/common/widget/show_document_type_filter_sheet.dart';
import '../../../products/domain/models/m_in_out_list_type.dart';
import '../../../products/presentation/screens/movement/provider/new_movement_provider.dart';
import '../../../shared/data/messages.dart';
import '../providers/m_in_out_list_provider.dart';

class MInOutListScreen extends ConsumerStatefulWidget {
  final bool isMovement;
  MInOutListScreen({super.key,required this.isMovement});

  @override
  ConsumerState<MInOutListScreen> createState() => _MInOutListScreenState();
}

class _MInOutListScreenState extends ConsumerState<MInOutListScreen> {
  bool _initialized = false;
  int count = 0;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async{
      if (_initialized) return;
      _initialized = true;
      count++;
      print('$count MInOutListScreen initState $_initialized $count');
      final dates = ref.read(selectedDatesProvider);
      final inOut = ref.read(inOutFilterProvider);

      // ✅ en initState: usar read, NO watch
      ref.read(mInOutListProvider.notifier).findBetweenDates(
        ref: ref,
        dates: dates,
        inOut: inOut,
        isMovement: widget.isMovement,
      );
    });
  }
  StateProvider<DateTimeRange> selectedDatesProvider = selectedMInOutDatesProvider ;

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(mInOutListProvider);
    final listNotifier = ref.read(mInOutListProvider.notifier);
    final docType = ref.watch(documentTypeListMInOutFilterProvider);
    final selectedIds = ref.watch(selectedMInOutIdsProvider);

    return Scaffold(
      bottomNavigationBar: selectedIds.isNotEmpty ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                final selectedIds = ref.read(selectedMInOutIdsProvider);
                if (selectedIds.isEmpty) {
                  showNoSelectionSheet(context); // tu bottomsheet de OK
                  return;
                }

                showGenerateJobsSheet(
                  context: context,
                  ref: ref,
                  allItems: listState.list,
                  onConfirm: (ref, selectedItems, selectedJobs) {
                    actionForSelectedItems(ref, selectedItems, selectedJobs);


                  },
                );
              },
              child: Text(Messages.GENERATE_JOBS),
            ),
          ),
        ),
      ) : null,
      appBar: AppBar(title: const Text('M IN OUT'),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.white,
              ),
              onPressed: ()  async {
                showDocumentTypeFilterMultipleDatesSheet(context: context, ref: ref,
                    onDataChange:({required WidgetRef ref,required DateTimeRange dates,
                                    required String inOut})async{
                      listNotifier.findBetweenDates(ref :ref,
                        dates : dates, inOut: inOut, isMovement: widget.isMovement);

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
            selectionFilterProvider: selectedMInOutTypeProvider,
            selectedDatesProvider: selectedDatesProvider,
            values:  MInOutListTypeX.mInOutTypes,
            onScanButtonPressed: null,
            onOk: (dates, inOut) {
              listNotifier.findBetweenDates(
                ref: ref,
                dates: dates,
                inOut: inOut,
                isMovement: widget.isMovement,
              );
            },
          ),
          Expanded(
            child: _buildMInOutList(context, ref, listState, isMovement: widget.isMovement),
          ),
        ],
      ),
    );
  }
}

Widget _buildMInOutList(
    BuildContext context,
    WidgetRef ref,
    MInOutListStatus stateNow, {
      required bool isMovement,
    }) {
  final mInOutList = stateNow.list;

  if (stateNow.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (mInOutList.isEmpty) {
    return const Center(child: Text('Sin datos'));
  }

  return Consumer(
    builder: (context, ref, _) {
      final selectedIds = ref.watch(selectedMInOutIdsProvider);

      return ListView.builder(
        itemCount: mInOutList.length,
        itemBuilder: (ctx, index) {
          final item = mInOutList[index];
          final int? id = item.id;

          // si no hay id, no se puede seleccionar
          final bool canSelect = id != null;
          final bool isSelected = canSelect && selectedIds.contains(id);

          final IconData icon =
          (item.isSoTrx == true) ? Icons.arrow_upward : Icons.arrow_downward;

          return Column(
            children: [
              const Divider(height: 0),
              Container(
                color: item.docStatus.id == 'IP' ? themeColorWarningLight : null,
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: !canSelect
                          ? null
                          : (v) {
                        final next = {...ref.read(selectedMInOutIdsProvider)};
                        if (v == true) {
                          next.add(id!);
                        } else {
                          next.remove(id!);
                        }
                        ref.read(selectedMInOutIdsProvider.notifier).state =
                            next;
                      },
                    ),
                    Icon(icon, color: themeColorPrimary),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      child: Text(
                        item.movementDate != null
                            ? DateFormat('dd/MM/yyyy').format(item.movementDate!)
                            : '',
                        style: TextStyle(
                          fontSize: themeFontSizeSmall,
                          color: themeColorGray,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          item.documentNo.toString(),
                          style: const TextStyle(fontSize: themeFontSizeLarge),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code),
                      color: themeColorPrimary,
                      onPressed: (){
                        context.push(AppRouter.PAGE_M_IN_OUT_BARCODE_LIST,
                            extra: item);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
            ],
          );
        },
      );
    },
  );
}

void showNoSelectionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    builder: (ctx) {
      return FractionallySizedBox(
        heightFactor: 0.7,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Messages.SELECT_DATA_TO_GENERATE,
                style: TextStyle(
                  fontSize: themeFontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showGenerateJobsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required List<MInOut> allItems,
  required void Function(
      WidgetRef ref,
      List<MInOut> selectedItems,
      List<mInOutJobs> selectedJobs,
      ) onConfirm,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final selectedJobs = ref.watch(selectedMInOutJobsProvider);
          final showSlider = ref.watch(showConfirmationSliderProvider);
          final selectedIds = ref.watch(selectedMInOutIdsProvider);

          final selectedItems = allItems
              .where((e) => (e.id != null) && selectedIds.contains(e.id!))
              .toList();

          // ✅ Contadores y condiciones para mostrar jobs
          final int recordsSoTrxTrue =
              selectedItems.where((e) => e.isSoTrx == true).length;
          final int recordsSoTrxFalse =
              selectedItems.where((e) => e.isSoTrx == false).length;

          final bool showPickConfirm = recordsSoTrxTrue > 0;
          final bool showShipConfirm = recordsSoTrxTrue > 0;
          final bool showReceiveConfirm = recordsSoTrxFalse > 0;

          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          Messages.SELECT_DATA_TO_GENERATE,
                          style: TextStyle(
                            fontSize: themeFontSizeLarge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      )
                    ],
                  ),
                  const Divider(),

                  // ✅ Jobs: mostrar solo cuando corresponda por isSoTrx y con contador en el title
                  if (showPickConfirm)
                    CheckboxListTile(
                      value: selectedJobs.contains(mInOutJobs.createPickConfirm),
                      title: Text(
                        '${mInOutJobs.createPickConfirm.label} ($recordsSoTrxTrue)',
                      ),
                      onChanged: (v) {
                        final set = {...ref.read(selectedMInOutJobsProvider)};
                        v == true
                            ? set.add(mInOutJobs.createPickConfirm)
                            : set.remove(mInOutJobs.createPickConfirm);
                        ref.read(selectedMInOutJobsProvider.notifier).state = set;
                      },
                    ),

                  if (showShipConfirm)
                    CheckboxListTile(
                      value: selectedJobs.contains(mInOutJobs.createShipConfirm),
                      title: Text(
                        '${mInOutJobs.createShipConfirm.label} ($recordsSoTrxTrue)',
                      ),
                      onChanged: (v) {
                        final set = {...ref.read(selectedMInOutJobsProvider)};
                        v == true
                            ? set.add(mInOutJobs.createShipConfirm)
                            : set.remove(mInOutJobs.createShipConfirm);
                        ref.read(selectedMInOutJobsProvider.notifier).state = set;
                      },
                    ),

                  if (showReceiveConfirm)
                    CheckboxListTile(
                      value: selectedJobs.contains(mInOutJobs.createReceiveConfirm),
                      title: Text(
                        '${mInOutJobs.createReceiveConfirm.label} ($recordsSoTrxFalse)',
                      ),
                      onChanged: (v) {
                        final set = {...ref.read(selectedMInOutJobsProvider)};
                        v == true
                            ? set.add(mInOutJobs.createReceiveConfirm)
                            : set.remove(mInOutJobs.createReceiveConfirm);
                        ref.read(selectedMInOutJobsProvider.notifier).state = set;
                      },
                    ),

                  const SizedBox(height: 8),

                  // ===== LISTA DE ITEMS SELECCIONADOS =====
                  Text(
                    '${Messages.SELECTED_ITEMS}: ${selectedItems.length}',
                    style: TextStyle(
                      fontSize: themeFontSizeSmall,
                      color: themeColorGray,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: ListView.separated(
                      itemCount: selectedItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (context, index) {
                        final item = selectedItems[index];
                        final icon = (item.isSoTrx == true)
                            ? Icons.arrow_upward
                            : Icons.arrow_downward;

                        final dateText = item.movementDate != null
                            ? DateFormat('dd/MM/yyyy').format(item.movementDate!)
                            : '';

                        return ListTile(
                          dense: true,
                          leading: Icon(icon, color: themeColorPrimary),
                          title: Text(
                            item.documentNo.toString(),
                            style: const TextStyle(
                              fontSize: themeFontSizeLarge,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            dateText,
                            style: TextStyle(
                              fontSize: themeFontSizeSmall,
                              color: themeColorGray,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (showSlider)
                    ConfirmationSlider(
                      height: 45,
                      backgroundColor: Colors.green[100]!,
                      backgroundColorEnd: Colors.green[800]!,
                      foregroundColor: Colors.green,
                      text: Messages.SLIDE_TO_CREATE,
                      textStyle: TextStyle(
                        fontSize: themeFontSizeLarge,
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                      onConfirmation: () {
                        onConfirm(ref, selectedItems, selectedJobs.toList());
                        // Navigator.of(ctx).pop();
                      },
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




void _showMInOutData(BuildContext context, MInOut item) {
  context.push(AppRouter.PAGE_M_IN_OUT_BARCODE_LIST,
      extra: item);
}
void actionForSelectedItems(
    WidgetRef ref,
    List<MInOut> selectedItems,
    List<mInOutJobs> selectedJobs,
    ) {
  // TODO: implementar tu lógica real
  debugPrint('Selected items: ${selectedItems.length}');
  debugPrint('Selected jobs: ${selectedJobs.map((e) => e.label).toList()}');
  String message = Messages.NOT_IMPLEMENTED_YET ;
  showWarningMessage(ref.context, ref, message);

  // opcional: limpiar selección luego de generar
  //ref.read(selectedMInOutIdsProvider.notifier).state = <int>{};
  //ref.read(selectedMInOutJobsProvider.notifier).state = <mInOutJobs>{};
}