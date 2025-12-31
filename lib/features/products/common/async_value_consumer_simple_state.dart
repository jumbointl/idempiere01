import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action_fixed_short.dart';

import '../domain/idempiere/response_async_value.dart';
import '../presentation/providers/common_provider.dart';
import 'app_initializer_overlay.dart';
import 'common_consumer_state.dart';
import 'input_dialog.dart';

abstract class AsyncValueConsumerSimpleState<T extends ConsumerStatefulWidget>
    extends CommonConsumerState<T> {

  // ---------- Providers / state ----------
  late final bool isScanning;
  late final bool isDialogShowed;
  late final String inputString;
  late final int actionScan;

  /// Main async data for the screen
  AsyncValue<ResponseAsyncValue> get mainDataAsync;

  /// Scroll controller for main content
  final ScrollController scrollController = ScrollController();

  /// Minimum items to enable scroll FAB
  int get qtyOfDataToAllowScroll => 2;

  /// UI flags
  bool get showSearchBar => true;
  bool get scrollMainDataCard => true;

  // ---------- Abstract API ----------
  double getWidth();
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref);
  int get actionScanTypeInt;

  Widget getMainDataCard(BuildContext context, WidgetRef ref);
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref);

  Future<void> setDefaultValuesOnInitState(
      BuildContext context,
      WidgetRef ref,
      );

  void initialSettingOnBuild(BuildContext context, WidgetRef ref);
  void executeAfterShown();

  // ---------- Lifecycle ----------
  @override
  void initState() {
    super.initState();

    // English: Initialize default state values
    setDefaultValuesOnInitState(context, ref);

    // English: Execute logic after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      executeAfterShown();
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // ---------- Scroll helpers ----------
  bool get isNearBottom {
    if (!scrollController.hasClients) return false;
    final position = scrollController.position;
    return (position.maxScrollExtent - position.pixels) < 80;
  }

  void toggleScrollPosition() {
    if (!scrollController.hasClients) return;

    final position = scrollController.position;
    final isAtBottom =
        (position.maxScrollExtent - position.pixels) < 50;

    final target = isAtBottom
        ? position.minScrollExtent
        : position.maxScrollExtent;

    scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  FloatingActionButton get floatingActionButton {
    return FloatingActionButton(
      onPressed: toggleScrollPosition,
      child: const Icon(Icons.swap_vert),
    );
  }

  // ---------- Navigation ----------
  void popScopeAction(BuildContext context, WidgetRef ref) {

    goHome();
  }

  // ---------- AppBar ----------
  bool get showLeading => false;

  Widget? get leadingIcon => showLeading
      ? IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => popScopeAction(context, ref),
  )
      : null;

  AppBar? getAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: getAppBarBackgroundColor(context, ref),
      automaticallyImplyLeading: showLeading,
      leading: leadingIcon,
      title: getAppBarTitle(context, ref),
      actions: getActionButtons(context, ref),
    );
  }

  // ---------- Actions ----------
  List<Widget> getActionButtons(BuildContext context, WidgetRef ref) {
    final showScan =
    ref.watch(showScanFixedButtonProvider(actionScanTypeInt));

    final buttons = <Widget>[];

    if (showScan) {
      buttons.add(
        ScanButtonByActionFixedShort(
          actionTypeInt: actionScanTypeInt,
          onOk: handleInputString,
        ),
      );
    }

    buttons.add(
      IconButton(
        icon: const Icon(Icons.keyboard, color: Colors.purple),
        onPressed: () {
          openInputDialogWithAction(
            ref: ref,
            history: false,
            onOk: handleInputString,
            actionScan: actionScanTypeInt,
          );
        },
      ),
    );

    return buttons;
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    initialSettingOnBuild(context, ref);
    final showFab = ref.watch(allowScrollFabProvider);

    return AppInitializerOverlay(
      child: Scaffold(
        appBar: getAppBar(context, ref),
        floatingActionButton: showFab ? floatingActionButton : null,
        bottomNavigationBar: getBottomAppBar(context, ref),
        body: SafeArea(
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (_, __) =>
                popScopeAction(context, ref),
            child: scrollMainDataCard
                ? SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(10),
              child: getMainDataCard(context, ref),
            )
                : getMainDataCard(context, ref),
          ),
        ),
      ),
    );
  }

  BottomAppBar? getBottomAppBar(
      BuildContext context,
      WidgetRef ref,
      ) =>
      null;
}
