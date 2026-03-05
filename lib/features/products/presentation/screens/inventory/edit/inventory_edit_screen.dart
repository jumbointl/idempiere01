import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../config/router/app_router.dart';
import '../../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/async_value_consumer_simple_state.dart';
import '../../../../domain/idempiere/inventory_and_lines.dart';
import '../../../../domain/idempiere/response_async_value.dart';
import '../../../providers/actions/find_inventory_by_id_action.dart';
import '../../../providers/actions/find_inventory_by_id_action_provider.dart';
import '../../../providers/common/code_and_fire_action_notifier.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../../store_on_hand/memory_products.dart';
import 'new_inventory_card_with_locator.dart';
import 'new_inventory_line_card.dart';

class InventoryEditScreen extends ConsumerStatefulWidget {
  int countScannedCamera = 0;
  final int actionTypeInt = Memory.ACTION_FIND_INVENTORY_BY_ID;
  late var allowedLocatorId;
  final int pageIndex = Memory.PAGE_INDEX_INVENTORY_EDIT_SCREEN;
  String? inventoryId;
  bool isInventorySearchedShowed = false;
  String fromPage;

  static const String waitForScanInventory = '-1';
  static const String fromPageHome = '-1';
  static const String fromPageInventoryList = '1';

  InventoryEditScreen({
    required this.fromPage,
    this.inventoryId,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      InventoryEditScreenState();
}

class InventoryEditScreenState
    extends AsyncValueConsumerSimpleState<InventoryEditScreen> {
  late InventoryAndLines inventoryAndLines;

  bool asyncResultHandled= false;

  @override
  Future<void> executeAfterShown() async {
    MemoryProducts.inventoryAndLines?.clearData();
    ref.read(actionScanProvider.notifier).state = Memory.ACTION_FIND_INVENTORY_BY_ID;

    ref.invalidate(newScannedInventoryIdForSearchProvider);
    ref.read(isScanningProvider.notifier).state = false;

    await Future.delayed(const Duration(milliseconds: 100));

    if (widget.inventoryId != null &&
        widget.inventoryId!.isNotEmpty &&
        widget.inventoryId != '-1') {
      handleInputString(
        ref: ref,
        inputData: widget.inventoryId!,
        actionScan: actionScanTypeInt,
      );
    }
  }

  @override
  double getWidth() => MediaQuery.of(context).size.width;

  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    if (inventoryAndLines.hasInventory && inventoryAndLines.canCompleteInventory) {
      return Colors.cyan[200];
    }
    if (inventoryAndLines.hasInventory) {
      return Colors.green[200];
    }
    return Colors.white;
  }

  @override
  AsyncValue<ResponseAsyncValue> get mainDataAsync {
    final notifier = ref.read(findInventoryByIdActionProvider);
    return ref.watch(notifier.responseAsyncValueProvider);
  }

  @override
  int get qtyOfDataToAllowScroll => 2;

  @override
  int get actionScanTypeInt => widget.actionTypeInt;

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    asyncResultHandled = false;
    ref.invalidate(inventoryAndLinesProvider);
    await Future.delayed(const Duration(milliseconds: 100));
    mainNotifier.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: widget.actionTypeInt,
    );
  }

  Widget getAddButton(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: themeColorPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () async {
        ref.read(isScanningProvider.notifier).state = false;

        if (MemoryProducts.inventoryAndLines?.hasInventory ?? false) {
          final inv = InventoryAndLines();
          inv.cloneInventoryAndLines(MemoryProducts.inventoryAndLines!);

          if (context.mounted) {
            context.push(
              '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_INVENTORY_LINE}/-1',
              extra: inv,
            );
          }
        }
      },
      icon: const Icon(Icons.add_circle, color: Colors.white),
      label: Text(
        'Add Inventory Line',
        style: TextStyle(
          fontSize: themeFontSizeLarge,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  AppBar? getAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: getAppBarBackgroundColor(context, ref),
      automaticallyImplyLeading: showLeading,
      leading: leadingIcon,
      title: getAppBarTitle(context, ref),
      actions: getActionButtons(context, ref),
    );
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    inventoryAndLines = ref.watch(inventoryAndLinesProvider);

    if (widget.inventoryId != null &&
        widget.inventoryId != '-1' &&
        inventoryAndLines.hasInventory) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => popScopeAction(context, ref),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  inventoryAndLines.documentNo ?? '',
                  style: textStyleLarge,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '${inventoryAndLines.id ?? ''}   ${inventoryAndLines.docStatus?.id ?? ''}',
                  style: textStyleSmallBold,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => popScopeAction(context, ref),
        ),
        Text('Inventory Search', style: textStyleLarge),
      ],
    );
  }

  @override
  BottomAppBar? getBottomAppBar(BuildContext context, WidgetRef ref) {
    final showBottomBar = ref.watch(showBottomBarProvider);
    return showBottomBar
        ? BottomAppBar(
      height: Memory.BOTTOM_BAR_HEIGHT,
      color: themeColorPrimary,
      child: getAddButton(context, ref),
    )
        : null;
  }

  @override
  Future<void> setDefaultValuesOnInitState(
      BuildContext context,
      WidgetRef ref,
      ) async {}

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) async {
    ref.invalidate(newScannedInventoryIdForSearchProvider);
    final int pageFrom = ref.read(pageFromProvider);
    if (pageFrom <= 0) {
      context.go(AppRouter.PAGE_HOME);
    } else {
      context.go('${AppRouter.PAGE_INVENTORY_LIST}/-1');
    }
  }

  CodeAndFireActionNotifier get mainNotifier =>
      ref.read(findInventoryByIdActionProvider);

  @override
  void initialSettingOnBuild(BuildContext context, WidgetRef ref) {
    inventoryAndLines = ref.watch(inventoryAndLinesProvider);
  }
  Widget buildInventoryBody({
    required InventoryAndLines inventoryAndLines,
    required bool canEdit,
  }) {
    final double contentWidth = getWidth();
    final lines = inventoryAndLines.inventoryLines ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NewInventoryCardWithLocator(
          inventoryAndLines: inventoryAndLines,
          width: contentWidth,
          bgColor: themeColorPrimary
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lines.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final line = lines[index];
            return NewInventoryLineCard(
              inventoryLine: line,
              width: contentWidth,
              index: index,
              totalLength: lines.length,
              canEdit: canEdit,
            );
          },
        ),
      ],
    );
  }
  @override
  Widget getMainDataCard(BuildContext context, WidgetRef ref) {
    return mainDataAsync.when(
      data: (result) {
        if (!result.success || result.data == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(result.message ?? Messages.NO_DATA_FOUND),
            ),
          );
        }

        final InventoryAndLines data = result.data;

        if (!data.hasInventory) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(Messages.NO_DATA_FOUND),
            ),
          );
        }


        return buildInventoryBody(inventoryAndLines: inventoryAndLines,
            canEdit: data.canCompleteInventory);

      },
      error: (error, stackTrace) => Text('Error: $error'),
      loading: () => const LinearProgressIndicator(minHeight: 36),
    );
  }

}

