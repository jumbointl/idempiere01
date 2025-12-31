import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_line.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/store_on_hand_for_put_away_movement.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/movement_card_without_controller.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/create/movement_line_card_without_controller.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/new_movement_provider.dart';

import '../../../../../../../config/router/app_router.dart';
import '../../../../../../../config/theme/app_theme.dart';
import '../../../../../../shared/data/memory.dart';
import '../../../../../../shared/data/messages.dart';
import '../../../../providers/product_provider_common.dart';
import '../../../store_on_hand/memory_products.dart';
import '../../../../providers/products_scan_notifier.dart';
import '../movement_line_card_for_create.dart';
import '../no_data_created_put_away_movement_card.dart';
import '../putAway_validation_result.dart';

class PutAwayCreateFlowView extends ConsumerStatefulWidget {
  final PutAwayMovement? putAwayMovement;
  final PutAwayCloseMode closeMode;

  const PutAwayCreateFlowView({
    super.key,
    required this.putAwayMovement,
    required this.closeMode,
  });

  @override
  ConsumerState<PutAwayCreateFlowView> createState() =>
      _PutAwayCreateFlowViewState();
}

class _PutAwayCreateFlowViewState extends ConsumerState<PutAwayCreateFlowView> {
  late final ProductsScanNotifier productsNotifier;
  late AsyncValue movementAsync;

  final double singleProductDetailCardHeight = 160;
  double width = 0;

  bool startCreate = false;
  String? productUPC;

  @override
  void initState() {
    super.initState();

    productsNotifier = ref.read(scanHandleNotifierProvider.notifier);
    productUPC = widget.putAwayMovement?.movementLineToCreate?.uPC ?? '-1';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.putAwayMovement != null && mounted && !startCreate) {
        startCreate = true;
        widget.putAwayMovement!.startCreate = true;

        // English: Trigger backend creation
        productsNotifier.createPutAwayMovement(ref, widget.putAwayMovement!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    movementAsync = ref.watch(newPutAwayMovementProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text(
          '${Messages.MOVEMENT} : ${Messages.CREATE}',
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _close(context),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: Memory.BOTTOM_BAR_HEIGHT,
        color: themeColorPrimary,
        child: Center(
          child: Text(
            Messages.PLEASE_WAIT,
            style: TextStyle(
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
          onPopInvokedWithResult: (_, __) => _close(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return movementAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 36),
      error: (e, _) => Text('Error: $e'),
      data: (result) {
        if (result == null || result.id == null || result.id! <= 0) {
          return startCreate ? _noDataCreated() : _dataToCreate();
        }

        final MovementAndLines data = result;

        // English: After creation completes and allCreated is true, you might decide to close automatically
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          ref.read(isDialogShowedProvider.notifier).state = false;
          ref.read(isScanningProvider.notifier).state = false;

          // Optional: keep your delay behavior
          await Future.delayed(Duration(seconds: MemoryProducts.delayOnSwitchPageInSeconds));

          if (data.allCreated) {
            // English: In modal mode, prefer closing. In page mode, keep navigation behavior if needed.
            if (!mounted) return;
            // Keep your original navigation if this view is used as a page
            ref.read(actionScanProvider.notifier).state =
                Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

            // NOTE: your original code navigated to PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE
            if(context.mounted) {
              ref.invalidate(productStoreOnHandCacheProvider);
              context.go(
              '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/-1',
              extra: data,
            );
            }
          }
        });

        return _resultContent(context, data);
      },
    );
  }

  Widget _resultContent(BuildContext context, MovementAndLines data) {
    if (data.nothingCreated) return _noDataCreated();

    final IdempiereMovement movement = data;
    final int id = movement.id!;

    if (data.onlyMovementCreated) {
      return SingleChildScrollView(
        child: Column(
          spacing: 10,
          children: [
            const Icon(Icons.error_rounded, size: 50, color: Colors.orange),
            Text(
              '${Messages.ID} : $id',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: themeFontSizeTitle,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            MovementCardWithoutController(
              bgColor: Colors.cyan[800]!,
              height: singleProductDetailCardHeight,
              width: double.infinity,
              movement: movement,
            ),
            Text(
              Messages.MOVEMENT_LINE_NOT_CREATED,
              style: TextStyle(
                fontSize: themeFontSizeTitle,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            _primaryCloseButton(),
          ],
        ),
      );
    }

    final IdempiereMovementLine line = data.movementLines!.first;

    return SingleChildScrollView(
      child: Column(
        spacing: 10,
        children: [
          const Icon(Icons.check_circle, size: 100, color: Colors.green),
          Text(
            '${Messages.ID} : $id',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: themeFontSizeTitle,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          MovementCardWithoutController(
            bgColor: Colors.cyan[800]!,
            height: singleProductDetailCardHeight,
            width: double.infinity,
            movement: movement,
          ),
          MovementLineCardWithoutController(width: width, movementLine: line),
          _primaryCloseButton(),
        ],
      ),
    );
  }

  Widget _dataToCreate() {
    return MovementLineCardForCreate(
      width: width,
      movementLine: MemoryProducts.newSqlDataMovementLineToCreate,
    );
  }

  Widget _noDataCreated() {
    return NoDataPutAwayCreatedCard(width: width);
  }

  Widget _primaryCloseButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.green[800],
          foregroundColor: Colors.white,
        ),
        onPressed: () => _close(context),
        child: Text(
          Messages.OK,
          style: TextStyle(
            fontSize: themeFontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _close(BuildContext context) {
    ref.read(isScanningProvider.notifier).state = false;
    ref.read(isDialogShowedProvider.notifier).state = false;

    if (widget.closeMode == PutAwayCloseMode.closeOnly) {
      Navigator.pop(context); // English: Close modal only
      return;
    }

    // English: Default page behavior (keep your original navigation)
    context.go('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/$productUPC');
  }
}
