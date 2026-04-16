import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/response_async_value_messages_card.dart';

import '../../../config/theme/app_theme.dart';
import '../../auth/domain/entities/warehouse.dart';
import '../../shared/data/messages.dart';
import '../domain/idempiere/idempiere_locator.dart';
import '../domain/idempiere/idempiere_movement.dart';
import '../domain/idempiere/idempiere_movement_confirm.dart';
import '../domain/idempiere/idempiere_movement_line.dart';
import '../domain/idempiere/movement_and_lines.dart';
import '../domain/idempiere/response_async_value.dart';
import '../domain/idempiere/response_async_value_ui_model.dart';
import '../presentation/providers/common_provider.dart';
import '../presentation/providers/product_provider_common.dart';
import '../presentation/screens/movement/edit_new/new_movement_card_with_locator.dart';
import '../presentation/screens/movement/edit_new/new_movement_line_card.dart';
import '../presentation/screens/movement/movement_no_data_card.dart';
import '../presentation/screens/movement/provider/new_movement_provider.dart';
import 'async_value_consumer_screen_state.dart';

abstract class MovementAndLinesConsumerState<T extends ConsumerStatefulWidget>
    extends AsyncValueConsumerState<T> {
  IdempiereMovement? movement;
  IdempiereLocator? lastSavedLocatorFrom;
  Color colorBackgroundHasMovementId = Colors.cyan[200]!;
  Color colorBackgroundNoMovementId = Colors.white;
  int sameLocator = 0;
  final double singleProductDetailCardHeight = 160;
  Warehouse? userWarehouse;
  late var movementAndLines;
  int movementId = -1;

  @override
  late var isDialogShowed;

  late String fromPage;

  final List<GlobalKey> movementLineKeys = <GlobalKey>[];
  int highlightedMovementLineIndex = -1;

  Color? getColorByMovementAndLines(MovementAndLines? data) {
    if (data == null || !data.hasMovement) return Colors.white;
    if (data.canComplete) return Colors.cyan[200];
    return Colors.green[200];
  }

  void findMovementAfterDate(DateTime date, {required String inOut}) {}

  @override
  Widget asyncValueErrorHandle(WidgetRef ref, {required ResponseAsyncValue result}) {
    final uiModel = mapResponseAsyncValueToUi(
      result: result,
      title: Messages.MOVEMENT,
      subtitle: Messages.FIND_MOVEMENT_BY_ID_OR_DOCUMENT_NO,
    );

    return ResponseAsyncValueMessagesCardAnimated(ui: uiModel);
  }

  @override
  void afterAsyncValueAction(WidgetRef ref, {required ResponseAsyncValue result}) {
    if (!result.success || result.data == null) {
      return;
    }

    final current = ref.read(movementAndLinesProvider);
    final incoming = movementAndLines;

    if (current.id != incoming.id ||
        (current.movementLines?.length ?? -1) !=
            (incoming.movementLines?.length ?? -1)) {
      ref.read(movementAndLinesProvider.notifier).state = incoming;
    }

    if (!movementAndLines.isOnInitialState) {
      changeMovementAndLineState(ref, movementAndLines);
      ref.read(showBottomBarProvider.notifier).state =
          movementAndLines.canCompleteMovement;
    }
  }

  @override
  Widget asyncValueSuccessPanel(WidgetRef ref, {required ResponseAsyncValue result}) {
    if (result.data == null || result.data.hasMovement == false) {
      return asyncValueErrorHandle(ref, result: result);
    }

    movementAndLines = result.data;
    setWidgetMovementId(movementAndLines.id?.toString() ?? '-1');
    movementId = movementAndLines.id!;
    final String argument = jsonEncode(movementAndLines.toJson());
    final List<IdempiereMovementLine>? lines = movementAndLines.movementLines;

    movementLineKeys
      ..clear()
      ..addAll(List.generate(lines?.length ?? 0, (_) => GlobalKey()));

    return Column(
      spacing: 5,
      children: [
        movementAndLines.hasMovement
            ? NewMovementCardWithLocator(
          argument: argument,
          bgColor: themeColorPrimary,
          width: double.infinity,
          movementAndLines: movementAndLines,
        )
            : MovementNoDataCard(response: result),
        if (movementAndLines.hasMovementConfirms)
          getMovementConfirm(movementAndLines.movementConfirms!),
        lines == null || lines.isEmpty
            ? Center(child: Text(Messages.NO_DATA_FOUND))
            : getMovementLines(lines, getWidth()),
      ],
    );
  }

  void setWidgetMovementId(String id);

  Widget getMovementConfirm(List<IdempiereMovementConfirm> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final data = list[index];
        final String documentStatus = data.docStatus?.id ?? '';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black),
          ),
          child: ListTile(
            leading: Text('$documentStatus :${index + 1}', style: textStyleLarge),
            title: Text(data.documentNo ?? '', style: textStyleLarge),
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) =>
      const SizedBox(height: 5),
    );
  }

  Widget getMovementLines(List<IdempiereMovementLine> storages, double width) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: storages.length,
      itemBuilder: (context, index) {
        final product = storages[index];
        final bool isHighlighted = highlightedMovementLineIndex == index;

        return Container(
          key: movementLineKeys[index],
          child: NewMovementLineCard(
            index: index + 1,
            totalLength: storages.length,
            width: width - 10,
            movementLine: product,
            canEdit: movementAndLines.canCompleteMovement,
            showLocators: true,
            isHighlighted: isHighlighted,
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) =>
      const SizedBox(height: 5),
    );
  }

  Future<bool> scrollToMovementLineAt(int index) async {
    if (index < 0 || index >= movementLineKeys.length) {
      return false;
    }

    final BuildContext? itemContext = movementLineKeys[index].currentContext;
    if (itemContext == null) {
      return false;
    }

    await Scrollable.ensureVisible(
      itemContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.15,
    );

    return true;
  }

  void changeMovementAndLineState(WidgetRef ref, MovementAndLines? movementAndLines) async {
    final int len = movementAndLines?.movementLines?.length ?? 0;

    if (len > 0) {
      final bool allow = len > qtyOfDataToAllowScroll;
      final notifier = ref.read(allowScrollFabProvider.notifier);

      if (notifier.state != allow) {
        notifier.state = allow;
      }

      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }

    ref.read(isScanningProvider.notifier).update((state) => false);

    if (movementAndLines != null && movementAndLines.hasMovement) {
      setWidgetMovementId(movementAndLines.id?.toString() ?? '-1');
    }
  }

  @override
  void initialSettingAtBuild(BuildContext context, WidgetRef ref) {
    fromPage = ref.read(pageFromProvider).toString();
    isScanning = ref.watch(isScanningProvider);
    isDialogShowed = ref.watch(isDialogShowedProvider);
    inputString = ref.watch(inputStringProvider);
    actionScan = ref.read(actionScanProvider);
    movementAndLines = ref.watch(movementAndLinesProvider);
  }
}