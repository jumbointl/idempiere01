import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/async_value_consumer_simple_state.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../common/time_utils.dart';
import '../../../../common/widget/date_range_filter_row_panel.dart';
import '../../../../domain/idempiere/idempiere_document_status.dart';
import '../../../../domain/idempiere/idempiere_inventory.dart';
import '../../../../domain/idempiere/idempiere_warehouse.dart';
import '../../../../domain/idempiere/inventory_and_lines.dart';
import '../../../../domain/idempiere/response_async_value.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../provider/new_inventory_provider.dart';
import '../../movement/provider/new_movement_provider.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  String inventoryDateFilter;
  int actionTypeInt = 0;

  InventoryListScreen({
    super.key,
    required this.inventoryDateFilter,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      InventoryListScreenState();
}

class InventoryListScreenState
    extends AsyncValueConsumerSimpleState<InventoryListScreen> {
  @override
  void executeAfterShown() {
    ref.read(isScanningProvider.notifier).state = false;
    final dates = ref.read(selectedDatesProvider);
    final inOut = ref.read(inOutFilterProvider);
    findInventoryAfterDates(dates, inOut: inOut);
    ref.read(pageFromProvider.notifier).state = 1;
  }

  @override
  double getWidth() => MediaQuery.of(context).size.width - 30;

  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return Colors.cyan[200];
  }

  @override
  AsyncValue<ResponseAsyncValue> get mainDataAsync =>
      ref.watch(findInventoryNotCompletedByDateProvider);

  @override
  Widget getMainDataCard(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        DateRangeFilterRowPanel(
          onReloadButtonPressed: null,
          selectionFilterProvider: inOutFilterProvider,
          selectedDatesProvider: selectedDatesProvider,
          values: const [
            DateRangeFilterRowPanel.ALL,
            DateRangeFilterRowPanel.IN,
            DateRangeFilterRowPanel.OUT,
            DateRangeFilterRowPanel.SWAP,
          ],
          onOk: (date, inOut) {
            findInventoryAfterDates(date, inOut: inOut);
          },
          onScanButtonPressed: () {
            context.go('${AppRouter.PAGE_INVENTORY_EDIT}/-1/-1');
          },
        ),
        mainDataAsync.when(
          data: (ResponseAsyncValue response) {
            if (!response.isInitiated) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(Messages.NO_DATA_FOUND),
                ),
              );
            }

            final List<IdempiereInventory> list = response.data ?? [];
            if (list.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(Messages.NO_DATA_FOUND),
                ),
              );
            }

            return getInventories(list);
          },
          error: (error, stackTrace) => Text('Error'),
          loading: () => const LinearProgressIndicator(minHeight: 36),
        ),
      ],
    );
  }

  Widget getInventories(List<IdempiereInventory> inventories) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: inventories.length,
      itemBuilder: (context, index) {
        final inventory = inventories[index];
        final inventoryId = inventory.id ?? -1;

        final docColor = inventory.colorInventoryStatusDark ?? Colors.red[800]!;
        final borderColor = inventory.colorInventoryStatus ?? Colors.white;
        final fontSize = themeFontSizeSmall;

        return GestureDetector(
          onTap: () {
            if (inventoryId <= 0) {
              showErrorMessage(context, ref, Messages.NOT_ENABLED);
              return;
            }

            Clipboard.setData(ClipboardData(text: inventory.documentNo ?? ''));
            context.go('${AppRouter.PAGE_INVENTORY_EDIT}/$inventoryId/1');
          },
          child: Card(
            elevation: 2,
            color: borderColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: borderColor, width: 1),
            ),
            child: ListTile(
              dense: true,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              leading: Icon(Icons.circle, color: docColor),
              trailing: inventoryId > 0
                  ? const Icon(Icons.inventory_2, color: Colors.purple)
                  : null,
              title: Text(
                inventory.documentNo ?? '$inventoryId',
                style: TextStyle(color: Colors.black, fontSize: fontSize),
              ),
              subtitle: Text(
                '${Messages.DATE}: ${inventory.movementDate ?? ''}',
                style: TextStyle(color: Colors.black, fontSize: fontSize),
              ),
            ),
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 2),
    );
  }

  void findInventoryAfterDates(DateTimeRange dates, {required String inOut}) {
    final startDateString = dates.start.toString().substring(0, 10);
    final endDateString = dates.end.toString().substring(0, 10);

    final IdempiereWarehouse warehouse = Memory.sqlUsersData.mWarehouseID!;
    final filter = InventoryAndLines();

    filter.filterMovementDateStartAt = startDateString;
    filter.filterMovementDateEndAt = endDateString;

    switch (inOut) {
      case 'IN':
      case 'OUT':
      case 'SWAP':
      case 'ALL':
        filter.mWarehouseID = warehouse;
        break;
    }

    final docType = ref.read(documentTypeFilterProvider);
    widget.inventoryDateFilter = startDateString;

    filter.docStatus = IdempiereDocumentStatus(id: docType);
    filter.filterDocumentStatus = IdempiereDocumentStatus(id: docType);

    ref.read(inventoryNotCompletedToFindByDateProvider.notifier).state = filter;
  }

  @override
  void initialSettingOnBuild(BuildContext context, WidgetRef ref) {}

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {}

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    return mainDataAsync.when(
      data: (ResponseAsyncValue response) {
        if (!response.isInitiated) {
          return Text('Inventory Search', style: textStyleLarge);
        }

        final List<IdempiereInventory> list = response.data ?? [];
        return Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => popScopeAction(context, ref),
            ),
            Text('${Messages.RECORDS} : ${list.length}', style: textStyleLarge),
          ],
        );
      },
      error: (error, stackTrace) => Text('Error: $error'),
      loading: () => const LinearProgressIndicator(minHeight: 36),
    );
  }

  @override
  List<Widget> getActionButtons(BuildContext context, WidgetRef ref) {
    final String docType = ref.watch(documentTypeFilterProvider);

    return [
      Padding(
        padding: const EdgeInsets.only(right: 10),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.white,
          ),
          onPressed: () {
            _showDocumentTypeFilterSheet(context, ref);
          },
          child: Text(
            docType,
            style: const TextStyle(color: Colors.purple),
          ),
        ),
      ),
    ];
  }

  void _showDocumentTypeFilterSheet(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    final documentTypeOptions = documentTypeOptionsAll;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: screenHeight * 0.7,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Consumer(
            builder: (context, ref, _) {
              final String selected = ref.watch(documentTypeFilterProvider);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Inventory ${Messages.DOCUMENT_TYPE}',
                      style: TextStyle(
                        fontSize: themeFontSizeLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView(
                      children: documentTypeOptions.map((type) {
                        final color = _colorForDocType(type);

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            tileColor: color,
                            title: Text(
                              type,
                              style: TextStyle(
                                fontWeight: type == selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                            trailing: type == selected
                                ? const Icon(
                              Icons.check_circle,
                              color: Colors.purple,
                              size: 26,
                            )
                                : null,
                            onTap: () {
                              ref.read(documentTypeFilterProvider.notifier).state = type;
                              final dates = ref.read(selectedDatesProvider);
                              final inOut = ref.read(inOutFilterProvider);
                              findInventoryAfterDates(dates, inOut: inOut);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Color _colorForDocType(String code) {
    switch (code) {
      case 'DR':
        return Colors.grey.shade200;
      case 'CO':
        return Colors.green.shade200;
      case 'IP':
        return Colors.cyan.shade200;
      case 'VO':
        return Colors.amber.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Future<void> setDefaultValuesOnInitState(
      BuildContext context,
      WidgetRef ref,
      ) async {}

  @override
  int get actionScanTypeInt => widget.actionTypeInt;

  @override
  bool get showSearchBar => false;
}