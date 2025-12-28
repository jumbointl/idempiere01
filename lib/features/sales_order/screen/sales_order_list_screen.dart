import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/sales_order/screen/sales_order_barcode_list_screen.dart';
import 'package:monalisa_app_001/features/sales_order/screen/sales_order_no_data_card.dart';

import '../../products/common/async_value_consumer_screen_state.dart';
import '../../products/common/widget/date_range_filter_row_panel.dart';
import '../../products/domain/idempiere/idempiere_business_partner.dart';
import '../../products/domain/idempiere/response_async_value.dart';
import '../../products/domain/idempiere/sales_order_and_lines.dart';
import '../../products/presentation/screens/movement/edit_new/custom_app_bar.dart';
import '../../shared/data/memory.dart';
import '../../shared/data/messages.dart';
import '../provider/priority_color.dart';
import '../provider/sales_order_provider.dart';

class SalesOrderListScreen extends ConsumerStatefulWidget {
  const SalesOrderListScreen({super.key});

  @override
  ConsumerState<SalesOrderListScreen> createState() =>
      _SalesOrderListScreenState();

}
class _SalesOrderListScreenState
    extends AsyncValueConsumerState<SalesOrderListScreen> {
  bool searched = false;


  @override
  AsyncValue<ResponseAsyncValue> get mainDataAsync =>
      ref.watch(findSalesOrderToProcessByDateProvider);

  @override
  Widget getMainDataCard(BuildContext context, WidgetRef ref) {



    return Column(
      spacing: 8,
      children: [
        DateRangeFilterRowPanel(
          onReloadButtonPressed: () async {
            final dates = ref.read(selectedSalesOrderDatesProvider);
            ref.invalidate(selectDatesToFindSalesOrderProvider);
            await Future.delayed(const Duration(milliseconds: 100));
            ref.read(selectDatesToFindSalesOrderProvider.notifier).state = dates;
          },
          values: const[],
          selectedDatesProvider: selectedSalesOrderDatesProvider,
          onOk: (dates, _) {
            ref.read(selectDatesToFindSalesOrderProvider.notifier).state = dates;
          }, onScanButtonPressed: () {  },
          selectionFilterProvider: selectedSalesOrderWorkingStateProvider,
        ),
        mainDataAsync.when(
          data: (response) {
            if (!response.isInitiated) {
              return SalesOrderNoDataCard(response: response);
            }

            if (response.success &&
                response.data is List<SalesOrderAndLines>) {
              final list =
              response.data as List<SalesOrderAndLines>;
              if (list.isEmpty) {
                return SalesOrderNoDataCard(response: response);
              }
              return _buildSalesOrderList(list);
            }

            return SalesOrderNoDataCard(response: response);
          },
          /*loading: () {
            final p = ref.watch(salesOrderProgressProvider);
            return LinearProgressIndicator(
              minHeight: 36,
              value: (p > 0 && p < 1) ? p : null,
            );
          },*/
          loading: () {
            final p = ref.watch(salesOrderProgressProvider);
            final total = ref.watch(salesOrderTotalRecordsProvider);
            final extracted = ref.watch(salesOrderExtractedRecordsProvider);

            return SizedBox(
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  LinearProgressIndicator(
                    minHeight: 36,
                    value: total > 0 ? p : null,
                  ),
                  Text(
                    total > 0
                        ? 'Extraído: $extracted / $total'
                        : 'Cargando...',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
  Widget _buildSalesOrderList(List<SalesOrderAndLines> orders) {
    return DefaultTabController(
      length: 4,
      initialIndex: 1, // TO_DO default
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'ALL'),
              Tab(text: 'TO DO'),
              Tab(text: 'RUNNING'),
              Tab(text: 'DONE'),
            ],
          ),
          SizedBox(
            height: 600,
            child: TabBarView(
              children: [
                _buildTabList(_sortAll(orders)),
                _buildTabList(filteredOrders(orders, DateRangeFilterRowPanel.TO_DO)),
                _buildTabList(filteredOrders(orders, DateRangeFilterRowPanel.RUNNING)),
                _buildTabList(filteredOrders(orders, DateRangeFilterRowPanel.DONE)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  int _priorityOf(SalesOrderAndLines o) {
    return int.tryParse(o.priorityRule?.id ?? '999') ?? 999;
  }

  IconData _priorityIcon(int p) {
    if (p == 1) return Icons.local_fire_department; // 🔥
    if (p >= 2 && p <= 4) return Icons.warning_amber_rounded; // ⚠️
    return Icons.circle; // 🟡
  }

  Color _priorityIconColor(int p) {
    if (p == 1) {
      return PriorityColors.urgent;
    } else if (p == 3) {
      return PriorityColors.high;
    } else if (p == 5) {
      return PriorityColors.medium;
    } else if (p == 7) {
      return PriorityColors.low;
    } else if (p == 9) {
      return PriorityColors.minor;
    } else {
      return Colors.white;
    }
  }

  Widget _priorityBadge(SalesOrderAndLines order) {
    final p = _priorityOf(order);

    if (!order.hasToDoWorks) return _lineBadge(order);

    return _baseBadge(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            _priorityIcon(p),
            size: 16, // ⬅ control fino
            color: _priorityIconColor(p),
          ),
          const SizedBox(width: 4),
          Text(
            'P$p',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              height: 1.0,
              color: _priorityIconColor(p),
            ),
          ),
        ],
      ),
    );
  }
  Widget _lineBadge(SalesOrderAndLines order) {
    String aux ='';
    if(order.isRunning){
      aux = 'F:${order.inCompletedLines ?? 0}';
    }else if(order.isDone){
      aux = 'L:${order.salesOrderLines?.length ?? 0}';
    }

    return _baseBadge(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
           Text(
            aux,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrBadge(SalesOrderAndLines order) {

    return _baseBadge(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (ctx) {
              final h = MediaQuery.of(ctx).size.height;

              return SizedBox(
                height: h,
                child: ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Material(
                    color: Colors.white,
                    child: SalesOrderBarcodeListScreen(
                      argument: jsonEncode(order.toJson()),
                      salesOrder: order,
                    ),
                  ),
                ),
              );
            },
          );
        },
        child: const Icon(
          Icons.qr_code,
          size: 18, // ⬅ igualado visualmente
          color: Colors.purple,
        ),
      ),
    );
  }

  Widget _baseBadge({
    required Widget child,
  }) {
    return Container(
      width: 60,
      height: 28, // ⬅ ALTURA FIJA (ambos iguales)
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
  List<SalesOrderAndLines> _sortAll(List<SalesOrderAndLines> orders) {
    final todo = orders
        .where((o) => o.hasToDoWorks)
        .toList()
      ..sort(
            (a, b) => _priorityOf(a).compareTo(_priorityOf(b)), // ASC
      );
    final running = orders.where((o) => o.isRunning).toList();
    final done = orders.where((o) => o.isDone).toList();
    return [...todo, ...running, ...done];
  }
  int countOrdersByBusinessPartner(
      List<SalesOrderAndLines> orders,
      IdempiereBusinessPartner selectedBp,
      ) {
    if (selectedBp.id == Memory.INITIAL_STATE_ID) {
      return orders.length;
    }

    return orders
        .where((o) => o.cBPartnerID?.id == selectedBp.id)
        .length;
  }

  Widget _buildTabList(List<SalesOrderAndLines> orders) {
    return Consumer(
      builder: (context, ref, _) {
        final selected = ref.watch(selectedSalesOrdersProvider);
        final bp = ref.watch(salesOrderBusinessPartnerProvider);

        final filteredOrders = bp.id == Memory.INITIAL_STATE_ID
            ? orders
            : orders.where((o) => o.cBPartnerID?.id == bp.id).toList();

        return ListView.separated(
          itemCount: filteredOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            final isChecked = selected.any((o) => o.id == order.id);

            Color? bgColor;
            if (order.isDone) {bgColor = Colors.grey[200];}
            else if (order.isRunning) {bgColor = Colors.green[200];}
            else if (order.hasToDoWorks) {
              final p = _priorityOf(order);
              if (p == 1) {
                bgColor = PriorityColors.urgent;
              } else if (p == 3) {
                bgColor = PriorityColors.high;
              } else if (p == 5) {
                bgColor = PriorityColors.medium;
              } else if (p == 7) {
                bgColor = PriorityColors.low;
              } else if (p == 9) {
                bgColor = PriorityColors.minor;
              } else {
                bgColor = Colors.white;
              }

            }
            int incompletedLines = order.inCompletedLines ?? 0;
            String name = order.cBPartnerID?.identifier ?? '';
            String incompleted = '';
            if(incompletedLines>0) {
              incompleted = '$incompletedLines/${order.salesOrderLines?.length ?? 0}';
            } else {
              incompleted = '${order.salesOrderLines?.length ?? 0}';
            }


            return Card(
              color: bgColor,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10,left: 15,right: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('No: ${order.documentNo ?? ''}',
                          style: TextStyle(
                            fontSize: themeFontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,

                          ),overflow: TextOverflow.ellipsis,),
                        const SizedBox(width: 4),
                        Text('ID: ${order.id ?? ''}',overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: themeFontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CheckboxListTile(
                    value: isChecked,
                    enabled: order.hasToDoWorks,
                    onChanged: (v) =>
                        toggleOrderSelection(ref, order, v ?? false),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(order.dateOrdered ?? '',overflow: TextOverflow.ellipsis,),
                        Text(incompleted,overflow: TextOverflow.ellipsis,),
                      ],
                    ),
                    subtitle: Text(name,
                    ),
                    secondary:Column(
                      children: [
                        _priorityBadge(order),
                        _qrBadge(order),

                      ],
                    ),

                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void toggleOrderSelection(
      WidgetRef ref,
      SalesOrderAndLines order,
      bool selected,
      ) {
    final list = [...ref.read(selectedSalesOrdersProvider)];
    if (selected) {
      list.add(order);
    } else {
      list.removeWhere((o) => o.id == order.id);
    }
    ref.read(selectedSalesOrdersProvider.notifier).state = list;
  }


  Widget buildBusinessPartnerButton(
      BuildContext context,
      WidgetRef ref,
      ) {
    final async = ref.watch(findSalesOrderToProcessByDateProvider);
    final selectedBp = ref.watch(salesOrderBusinessPartnerProvider);

    int count = 0;

    if (async is AsyncData && async.value!=null && async.value!.data != null) {
      final orders = async.value!.data! as List<SalesOrderAndLines>;
      count = countOrdersByBusinessPartner(orders, selectedBp);
    }
    String name = selectedBp.identifier ?? '';
    if(name.length>18) name = '${name.substring(0,20)}...';

    final String title =
    selectedBp.id == Memory.INITIAL_STATE_ID
        ? '$allString ($count)'
        : '$name ($count)';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showBusinessPartnerModalSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.business, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  @override
  List<Widget> getActionButtons(BuildContext context, WidgetRef ref) {
    return [

      Padding(
        padding: const EdgeInsets.only(right: 10.0),
        child: buildBusinessPartnerButton(context, ref),
        /*child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.white,
          ),
          onPressed: () {

            showBusinessPartnerModalSheet(context, ref);

          },
          child: Text(
            businessPartner.identifier ?? '',
            style: const TextStyle(color: Colors.purple),
          ),
        ),*/
      ),
    ];
  }
  @override
  // TODO: implement actionScanTypeInt
  int get actionScanTypeInt => 0;

  @override
  void afterAsyncValueAction(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement afterAsyncValueAction
  }

  @override
  Widget asyncValueErrorHandle(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement asyncValueErrorHandle
    throw UnimplementedError();
  }

  @override
  Widget asyncValueSuccessPanel(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement asyncValueSuccessPanel
    throw UnimplementedError();
  }

  @override
  Future<void> executeAfterShown() async {
    if(searched) return ;
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // obliga a elegir
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.search,size: 36,color: Colors.purple,),
              const SizedBox(width: 8),
              Text(Messages.FIND),
            ],
          ),
          content: Text(Messages.SEARCH_SALES_ORDER,style: TextStyle(fontSize: themeFontSizeTitle),),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(Messages.CANCEL),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(Messages.CONFIRM),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      searched = true;
      final dates = ref.read(selectedSalesOrderDatesProvider);
      ref.read(selectDatesToFindSalesOrderProvider.notifier).state = dates;
    }

  }
  @override
  bool get showLeading => false;
  @override
  void popScopeAction(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // obliga a elegir
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.home,color: Colors.red,size: 36,),
              const SizedBox(width: 8),
              Text(Messages.GO_TO_HOME_PAGE,style: TextStyle(fontSize: themeFontSizeNormal),),
            ],
          ),
          content: Text(Messages.EXIT_THIS_PAGE,style: TextStyle(fontSize: themeFontSizeTitle),),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(Messages.CANCEL),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(Messages.QUIT),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }
  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return Colors.cyan[200];
  }
  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    return mainDataAsync.when(
      data: (ResponseAsyncValue response) {
        if(!response.isInitiated) {
          return Text(Messages.SALES_ORDER_SEARCH,style: textStyleLarge);
        }
        if(response.success && response.data!=null) {
          List<SalesOrderAndLines> list = response.data;
          String title = Messages.SALES_ORDER_SEARCH;
          if (list.isEmpty || list[0].id == null || list[0].id! < 0) {
            return commonAppBarTitle(
              onBack: () => popScopeAction(context, ref),
            );
          }
          title = '${Messages.RECORDS} : ${list.length}';
          return commonAppBarTitle(
            title: title,
            showBackButton: true,
            onBack: () => popScopeAction(context, ref),
          );
        } else {
          return Text(Messages.SALES_ORDER_SEARCH,style: textStyleLarge);
        }

      },error: (error, stackTrace) => Text('Error: $error'),
      loading: () => LinearProgressIndicator(
        minHeight: 36,
      ),
    );

  }

  @override
  double getWidth() {
   return double.infinity ;
  }

  @override
  Future<void> handleInputString({required WidgetRef ref, required String inputData, required int actionScan}) {
    // TODO: implement handleInputString
    throw UnimplementedError();
  }

  @override
  void initialSetting(BuildContext context, WidgetRef ref) {
    // TODO: implement initialSetting
  }

  @override
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) async {
  }

  List<SalesOrderAndLines> filteredOrders(List<SalesOrderAndLines> orders, String pag) {
    switch(pag) {
      case DateRangeFilterRowPanel.ALL:
        return orders;
      case DateRangeFilterRowPanel.TO_DO:
        List<SalesOrderAndLines> toDoOrders = [];
        for (SalesOrderAndLines order in orders) {
          if (order.hasToDoWorks) {
            toDoOrders.add(order);
          }
          toDoOrders.sort(
                (a, b) => _priorityOf(a).compareTo(_priorityOf(b)), // ASC
          );
        }

        return toDoOrders;
      case DateRangeFilterRowPanel.RUNNING:
        List<SalesOrderAndLines> runningOrders = [];
        for (SalesOrderAndLines order in orders) {
          if (order.isRunning) {
            runningOrders.add(order);
          }
        }
        return runningOrders;
      case DateRangeFilterRowPanel.DONE:
        List<SalesOrderAndLines> doneOrders = [];
        for (SalesOrderAndLines order in orders) {
          if (order.isDone) {
            doneOrders.add(order);
          }
        }
        return doneOrders;
      default:
        return<SalesOrderAndLines>[];

    }

  }
  @override
  BottomAppBar? getBottomAppBar(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedSalesOrdersProvider);
    return selected.isEmpty ? null : BottomAppBar(
      height: 50,
      color: Colors.cyan[200],
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColorPrimary,
          foregroundColor: Colors.white,
        ),
        onPressed: () => generateRegisters(ref),
        child: Text(Messages.GENERATE_REGISTER),
      ),

    );
  }
  Future<void> generateRegisters(WidgetRef ref) async {
    final selectedOrders = ref.read(selectedSalesOrdersProvider);

    await showModalBottomSheet(
      context: ref.context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final actions = SalesOrderAction.values;
        final selectedActions = <SalesOrderAction>{};

        return FractionallySizedBox(
          heightFactor: 0.9,
          child: StatefulBuilder(
            builder: (ctx, setState) {
              return Padding(
                // 👇 esto empuja el contenido si aparece teclado
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ========= CONTENIDO SCROLL =========
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Messages.SELECTED_ORDERS),
                            const SizedBox(height: 8),

                            ...selectedOrders.map(
                                  (o) => ListTile(
                                    leading: _priorityBadge(o),
                                    title: Text(o.documentNo ?? '—',
                                      style: TextStyle(
                                    color: Colors.purple,
                                    fontSize: themeFontSizeLarge,),
                                    ),
                                    subtitle: Text(o.cBPartnerID?.identifier ?? '',
                                       style: TextStyle(fontSize: themeFontSizeNormal),
                                    )
                                  ),
                            ),

                            const SizedBox(height: 16),
                            Text(Messages.AVAILABLE_ACTIONS),
                            const SizedBox(height: 8),

                            ...actions.map(
                                  (a) => CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: selectedActions.contains(a),
                                title: Text(
                                  actionLabel(a),
                                  style: TextStyle(color: themeColorPrimary),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    v == true
                                        ? selectedActions.add(a)
                                        : selectedActions.remove(a);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ========= BOTONES FIJOS ABAJO =========
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(Messages.CANCEL),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              showWarningMessage(
                                ref.context,
                                ref,
                                Messages.NOT_IMPLEMENTED_YET,
                              );
                            },
                            child: Text(Messages.CONFIRM),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }


  void showBusinessPartnerModalSheet(BuildContext context, WidgetRef ref) {
    final async = ref.read(findSalesOrderToProcessByDateProvider);

    if (async is! AsyncData || async.value == null || async.value!.data == null) {
      return;
    }

    final List<SalesOrderAndLines> orders =
    async.value!.data! as List<SalesOrderAndLines>;

    // ============================
    // 1) Extraer Business Partners únicos
    // ============================
    final Map<int, IdempiereBusinessPartner> uniqueBps = {};

    for (final o in orders) {
      final bp = o.cBPartnerID;
      if (bp != null && bp.id != null) {
        uniqueBps[bp.id!] = bp;
      }
    }

    // ============================
    // 2) Construir lista final (ALL primero)
    // ============================
    final List<IdempiereBusinessPartner> bpList = [
      IdempiereBusinessPartner(
        name: allString,
        id: Memory.INITIAL_STATE_ID,
      ),
      ...uniqueBps.values.toList()
        ..sort((a, b) => (a.identifier ?? a.name ?? '')
            .compareTo(b.identifier ?? b.name ?? '')),
    ];

    final selectedBp = ref.read(salesOrderBusinessPartnerProvider);

    // ============================
    // 3) Mostrar Modal
    // ============================
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Business Partner',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: bpList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final bp = bpList[index];
                    final bool isSelected = bp.id == selectedBp.id;

                    return ListTile(
                      leading: isSelected
                          ? const Icon(Icons.check, color: Colors.green)
                          : const SizedBox(width: 24),
                      title: Text(
                        bp.identifier ?? bp.name ?? '',
                        style: TextStyle(
                          color:
                          isSelected ? Colors.green : themeColorPrimary,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        // ============================
                        // 4) Actualizar provider
                        // ============================
                        ref
                            .read(salesOrderBusinessPartnerProvider.notifier)
                            .state = bp;

                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

