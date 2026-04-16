import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common/code_and_fire_action_notifier.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/new_movement_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../common/movement_and_lines_consumer_state.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../domain/idempiere/response_async_value.dart';
import '../../../providers/actions/find_movement_by_id_action_provider.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/store_on_hand/action_notifier.dart';

class NewMovementEditScreen extends ConsumerStatefulWidget {
  final int actionTypeInt = Memory.ACTION_FIND_MOVEMENT_BY_ID;
  final int pageIndex = Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN;
  final String? movementId;
  final String fromPage;

  static const String WAIT_FOR_SCAN_MOVEMENT = '-1';
  static const String FROM_PAGE_HOME = '-1';
  static const String FROM_PAGE_MOVEMENT_LIST = '1';

  NewMovementEditScreen({
    required this.fromPage,
    this.movementId,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      NewMovementEditScreenState();
}

class NewMovementEditScreenState
    extends MovementAndLinesConsumerState<NewMovementEditScreen> {
  String? _movementId;
  bool _searchItemInLines = false;

  @override
  void initState() {
    _movementId = widget.movementId;
    super.initState();
  }

  @override
  Future<void> executeAfterShown() async {
    ref.invalidate(allowedMovementDocumentTypeProvider);
    MemoryProducts.movementAndLines.clearData();

    ref.read(actionScanProvider.notifier).update(
          (state) => Memory.ACTION_FIND_MOVEMENT_BY_ID,
    );

    ref.invalidate(newScannedMovementIdForSearchProvider);
    ref.read(isScanningProvider.notifier).update((state) => false);

    await Future.delayed(const Duration(milliseconds: 100));

    if (_movementId != null &&
        _movementId!.isNotEmpty &&
        _movementId != '-1') {
      await handleInputString(
        ref: ref,
        inputData: _movementId!,
        actionScan: actionScanTypeInt,
      );
    }
  }

  @override
  double getWidth() {
    return MediaQuery.of(context).size.width - 30;
  }

  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return getColorByMovementAndLines(movementAndLines);
  }

  @override
  AsyncValue<ResponseAsyncValue> get mainDataAsync {
    final notifier = ref.read(findMovementByIdActionProvider);
    return ref.watch(notifier.responseAsyncValueProvider);
  }

  @override
  int get qtyOfDataToAllowScroll => 2;

  @override
  int get actionScanTypeInt => widget.actionTypeInt;

  bool _matchesMovementLine(IdempiereMovementLine line, String scannedString) {
    final String scanned = scannedString.trim().toLowerCase();
    if (scanned.isEmpty) return false;

    final String upc = (line.uPC ?? '').trim().toLowerCase();
    final String sku = (line.sKU ?? '').trim().toLowerCase();

    return upc.contains(scanned) || scanned == sku;
  }

  int _findMovementLineIndex(String scannedString) {
    final data = ref.read(movementAndLinesProvider);
    final lines = data.movementLines;

    if (lines == null || lines.isEmpty) {
      return -1;
    }

    for (int i = 0; i < lines.length; i++) {
      if (_matchesMovementLine(lines[i], scannedString)) {
        return i;
      }
    }

    return -1;
  }

  Future<void> _handleSearchInsideLoadedLines({
    required WidgetRef ref,
    required String scannedString,
  }) async {
    final int foundIndex = _findMovementLineIndex(scannedString);

    if (foundIndex < 0) {
      await showErrorMessage(
        context,
        ref,
        '$scannedString ${Messages.NOT_FOUND}',
        durationSeconds: 2,
      );
      return;
    }

    setState(() {
      highlightedMovementLineIndex = foundIndex;
    });

    await Future.delayed(const Duration(milliseconds: 80));
    await scrollToMovementLineAt(foundIndex);

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (highlightedMovementLineIndex == foundIndex) {
        setState(() {
          highlightedMovementLineIndex = -1;
        });
      }
    });
  }

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    setState(() {
      highlightedMovementLineIndex = -1;
    });
    asyncResultHandled = false;

    final String scannedString = inputData.trim();
    final currentMovement = ref.read(movementAndLinesProvider);

    if (_searchItemInLines && currentMovement.hasMovement) {

      await _handleSearchInsideLoadedLines(
        ref: ref,
        scannedString: scannedString,
      );
      return;
    }

    ref.invalidate(movementAndLinesProvider);
    await Future.delayed(const Duration(milliseconds: 100));

    mainNotifier.handleInputString(
      ref: ref,
      inputData: scannedString,
      actionScan: widget.actionTypeInt,
    );
  }

  Widget getAddButton(BuildContext context, WidgetRef ref) {

    return SizedBox(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: themeColorPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () async {
          ref.read(isScanningProvider.notifier).update((state) => false);

          if (MemoryProducts.movementAndLines.hasMovement) {
            MemoryProducts.movementAndLines.nextProductIdUPC = '-1';

            final MovementAndLines movementAndLines = MovementAndLines();
            movementAndLines.cloneMovementAndLines(
              MemoryProducts.movementAndLines,
            );

            ref.read(actionScanProvider.notifier).state =
                Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

            final String route =
                '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/-1';

            if (context.mounted) {
              context.push(
                route,
                extra: movementAndLines,
              );
            }
          }
        },
        icon: const Icon(Icons.add_circle, color: Colors.white),
        label: Text(
          Messages.ADD_MOVEMENT_LINE,
          style: TextStyle(
            fontSize: themeFontSizeLarge,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchItemCheckbox() {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _searchItemInLines = !_searchItemInLines;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: _searchItemInLines,
            onChanged: (value) {
              setState(() {
                _searchItemInLines = value ?? false;
              });
            },
            visualDensity: VisualDensity.compact,
            side: const BorderSide(color: Colors.white),
            checkColor: Colors.white,
            activeColor: Colors.green,
          ),
          Text(
            Messages.FIND_ITEM,
            style: TextStyle(
              fontSize: themeFontSizeLarge,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  AppBar? getAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: getAppBarBackgroundColor(context, ref),
      automaticallyImplyLeading: false,
      title: getAppBarTitle(context, ref),
      actions: getActionButtons(context, ref),
    );
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    final MovementAndLines m = ref.watch(movementAndLinesProvider);

    final bool hasMovementLoaded =
        _movementId != null && _movementId != '-1' && m.hasMovement;

    final TextStyle styleMain =
    m.documentNo != null && (m.documentNo?.length ?? 0) > 20
        ? textStyleTitleMore20C
        : textStyleLarge;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          onPressed: () => popScopeAction(context, ref),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: hasMovementLoaded
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                m.documentNo ?? '',
                style: styleMain,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                '${m.id ?? ''}   ${m.docStatus?.id ?? ''}',
                style: textStyleSmallBold,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
              : Text(
            Messages.MOVEMENT_SEARCH,
            style: textStyleLarge,
          ),
        ),
      ],
    );
  }

  @override
  BottomAppBar? getBottomAppBar(BuildContext context, WidgetRef ref) {
    final bool showBottomBar = ref.watch(showBottomBarProvider);

    if (!showBottomBar) {
      return null;
    }

    return BottomAppBar(
      height: Memory.BOTTOM_BAR_HEIGHT,
      color: themeColorPrimary,
      child: Row(
        children: [
          Expanded(
            child: getAddButton(context, ref),
          ),
          const SizedBox(width: 12),
          _buildSearchItemCheckbox(),


        ],
      ),
    );
  }

  @override
  Future<void> setDefaultValuesOnInitState(
      BuildContext context,
      WidgetRef ref,
      ) async {}

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) async {
    ref.invalidate(newScannedMovementIdForSearchProvider);

    final int pageFrom = ref.read(pageFromProvider);

    if (pageFrom <= 0) {
      context.go(AppRouter.PAGE_HOME);
    } else {
      context.go('${AppRouter.PAGE_MOVEMENTS_LIST}/-1');
    }
  }

  @override
  void setWidgetMovementId(String id) {
    _movementId = id;
  }

  @override
  CodeAndFireActionNotifier get mainNotifier =>
      ref.read(findMovementByIdActionProvider);
}