
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_inventory_line.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/store_on_hand_for_put_away_movement.dart';

import '../../../../domain/idempiere/idempiere_inventory.dart';
import '../../../../domain/idempiere/idempiere_inventory_line.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/inventory_and_lines.dart';
import '../../../providers/actions/create_inventory_line_action.dart';
import '../../../providers/product_provider_common.dart';
import '../../store_on_hand/memory_products.dart';
import 'inventory_provider_for_line.dart';
import 'new_inventory_card_with_locator.dart';
import 'new_inventory_line_card.dart';

class InventoryLinesCreateScreen extends ConsumerStatefulWidget {
  final int pageIndex = Memory.PAGE_INDEX_MOVEMENTE_CREATE_SCREEN;
  final InventoryAndLines inventoryAndLines;
  final double width;
  final String argument;

  const InventoryLinesCreateScreen({
    super.key,
    required this.inventoryAndLines,
    required this.width,
    required this.argument,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      InventoryLinesCreateScreenState();
}

class InventoryLinesCreateScreenState
    extends ConsumerState<InventoryLinesCreateScreen> {
  final double singleInventoryDetailCardHeight = 160;
  bool startCreate = false;
  late double width;
  late InventoryAndLines inventoryAndLines;

  @override
  void initState() {
    super.initState();
    inventoryAndLines = widget.inventoryAndLines;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(isDialogShowedProvider.notifier).state = true;

      final SqlDataInventoryLine inventoryLine =
          inventoryAndLines.inventoryLineToCreate ?? SqlDataInventoryLine();

      if (mounted && inventoryAndLines.canCreateInventoryLine()) {
        if (!startCreate) {
          startCreate = true;
          final act = ref.read(createInventoryLineActionProvider);
          await act.setAndFire(inventoryLine);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    debugPrint('InventoryLinesCreateScreenState ${inventoryAndLines.inventoryLineToCreate?.toJson()}');
    width = MediaQuery.of(context).size.width;

    final String title = 'Inventory Line : ${Messages.CREATE}';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            popScopeAction(context, ref);
          },
        ),
        title: Text(title, overflow: TextOverflow.ellipsis),
      ),
      bottomNavigationBar: BottomAppBar(
        height: Memory.BOTTOM_BAR_HEIGHT,
        color: themeColorPrimary,
        child: Center(
          child: Text(
            Messages.PLEASE_WAIT,
            style: const TextStyle(
              fontSize: themeFontSizeLarge,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) return;
            popScopeAction(context, ref);
          },
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: getBody(context, ref),
            ),
          ),
        ),
      ),
    );
  }

  Widget getDataToCreate(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: getInventoryLines(
        [MemoryProducts.newSqlDataInventoryLineToCreate],
        width,
      ),
    );
  }

  Widget getBody(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(createNewInventoryLineProvider);

    return inventoryAsync.when(
      data: (data) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (data != null && data.id != null && data.id! > 0) {
            if (context.mounted) {
              await Future.delayed(
                Duration(
                  seconds: MemoryProducts.delayOnSwitchPageInSeconds,
                ),
              );

              inventoryAndLines.inventoryLines ??= [];
              inventoryAndLines.inventoryLines!.add(data);

              if (context.mounted) {
                ref.invalidate(productStoreOnHandCacheProvider);
                context.go(
                  '${AppRouter.PAGE_INVENTORY_EDIT}/${inventoryAndLines.id ?? -1}/1',
                );
              }
            }
          }
        });

        if (data == null) {
          if (startCreate) {
            return getNoDataCreated(context, ref);
          } else {
            return getDataToCreate(context, ref);
          }
        }

        IdempiereInventory inventory = IdempiereInventory();
        IdempiereInventoryLine inventoryLine = IdempiereInventoryLine();

        if (data.id == null || data.id! <= 0) {
          return getNoDataCreated(context, ref);
        } else {
          inventory = inventoryAndLines;
          inventoryLine = data;
          final id = inventory.id ?? -1;

          return Column(
            spacing: 10,
            children: [
              const Icon(Icons.check_circle, size: 50, color: Colors.green),
              Text(
                '${Messages.ID} : $id',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: themeFontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              NewInventoryCardWithLocator(
                bgColor: Colors.cyan[800]!,
                width: double.infinity,
                inventoryAndLines: inventoryAndLines,
              ),
              NewInventoryLineCard(
                width: width,
                inventoryLine: inventoryLine,
                index: 1,
                totalLength: 1,
                canEdit: false,
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.yellow[800],
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (context.mounted) {
                    ref.invalidate(productStoreOnHandCacheProvider);
                    context.go('${AppRouter.PAGE_INVENTORY_EDIT}/$id/1');
                  }
                },
                child: const Text(
                  'Inventory',
                  style: TextStyle(
                    fontSize: themeFontSizeLarge,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }
      },
      error: (error, stackTrace) => Text('Error: $error'),
      loading: () => const LinearProgressIndicator(minHeight: 36),
    );
  }

  Widget getNoDataCreated(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error, size: 100, color: Colors.red),
          Text(Messages.NO_DATA_CREATED, overflow: TextOverflow.ellipsis),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(
              Messages.BACK,
              style: TextStyle(
                fontSize: themeFontSizeLarge,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getInventoryLines(List<IdempiereInventoryLine> lines, double width) {
    return NewInventoryLineCard(
      width: width,
      inventoryLine: lines[0],
      index: 1,
      totalLength: 1,
      canEdit: false,
    );
  }

  void popScopeAction(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop();
  }
}

final createInventoryLineActionProvider = Provider<CreateInventoryLineAction>((ref) {
  return CreateInventoryLineAction(ref: ref);
});