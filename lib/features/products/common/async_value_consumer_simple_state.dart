// Clase de estado abstracta para lógica común
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action_fixed_short.dart';

import '../../../config/router/app_router.dart';
import '../../../config/theme/app_theme.dart';
import '../../shared/data/memory.dart';
import '../domain/idempiere/response_async_value.dart';
import '../presentation/providers/common_provider.dart';
import 'app_initializer_overlay.dart';
import 'common_consumer_state.dart';
import 'input_dialog.dart';

abstract class AsyncValueConsumerSimpleState<T extends ConsumerStatefulWidget>
    extends CommonConsumerState<T>  {

  late var isScanning ;
  AsyncValue<ResponseAsyncValue> get mainDataAsync ;
  late var isDialogShowed;
  late var inputString;
  late var pageIndexProdiver;
  late var actionScan;
  late ScrollController scrollController = ScrollController();
  double goToPosition =0.0;
  int get qtyOfDataToAllowScroll => 2;
  bool asyncResultHandled = false;


  double getWidth();
  Color? getAppBarBackgroundColor(BuildContext context,WidgetRef ref);
  bool get showSearchBar => true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      executeAfterShown();
    });
  }
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
  bool get isNearBottom {
    if (!scrollController.hasClients) return false;
    final pos = scrollController.position;
    const threshold = 80.0; // píxeles de tolerancia
    return pos.maxScrollExtent - pos.pixels < threshold;
  }
  FloatingActionButton get floatingActionButton {
    return FloatingActionButton(
      onPressed: () {
        if (!scrollController.hasClients) return;

        final position = scrollController.position;

        // Estamos "cerca" del fondo?
        final bool isAtBottom =
            (position.maxScrollExtent - position.pixels) < 50;

        final double target = isAtBottom
            ? position.minScrollExtent   // si ya estoy abajo → subo arriba
            : position.maxScrollExtent;  // si no → bajo al fondo

        scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      child: Builder(
        builder: (_) {
          /*if (!scrollController.hasClients) {
                return const Icon(Icons.arrow_downward);
              }

              final position = scrollController.position;
              final bool isAtBottom =
                  (position.maxScrollExtent - position.pixels) < 50;

              // Si estoy abajo → muestro flecha hacia arriba
              return Icon(isAtBottom ? Icons.arrow_upward : Icons.arrow_downward);*/
          return Icon(Icons.swap_vert);
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context){
    initialSetting(context,ref);
    final showFab = ref.watch(allowScrollFabProvider);
    return AppInitializerOverlay(
      child: Scaffold(
      
        appBar: getAppBar(context,ref),
        floatingActionButton: showFab
            ?  floatingActionButton: null,

        bottomNavigationBar: getBottomAppBar(context,ref),
        body: SafeArea(
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              if (didPop) {
                return;
              }
              popScopeAction(context,ref);
      
      
            },
            child: scrollManinDataCard ? SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: getMainDataCard(context, ref),
              ),
            ) : getMainDataCard(context, ref),
          ),
        ),
      ),
    );
  }
  void executeAfterShown();
  bool get scrollManinDataCard => true ;

  Widget getMainDataCard(BuildContext context, WidgetRef ref);

  void iconBackPressed(BuildContext context, WidgetRef ref) {
    popScopeAction(context, ref);
  }

  void popScopeAction(BuildContext context, WidgetRef ref) async {
    context.go(AppRouter.PAGE_HOME);
  }

  BottomAppBar? getBottomAppBar(BuildContext context, WidgetRef ref) {
    return null ;
  }
  void initialSetting(BuildContext context, WidgetRef ref);

  bool get showLeading => false;
  Widget? get leadingIcon {
    return showLeading ?IconButton(
      onPressed: () {
        popScopeAction(context, ref);
      }, icon: Icon(Icons.arrow_back),
    ) : null;
  }

  AppBar? getAppBar(BuildContext context, WidgetRef ref) {

    return AppBar(
      backgroundColor: getAppBarBackgroundColor(context,ref),
      automaticallyImplyLeading: showLeading,
      leading: leadingIcon ,
      title: getAppBarTitle(context,ref),
      actions: getActionButtons(context,ref),

    );
  }

  Color? getColorByActionScan() {
    int action = actionScan;
    if(action == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
      return Colors.cyan[800];
    }else if(action == Memory.ACTION_GET_LOCATOR_TO_VALUE){
      return Colors.yellow[800];

    }
    return themeColorPrimary;

  }


  Future<void> setDefaultValues(BuildContext context, WidgetRef ref);

  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {return null;}

  int get actionScanTypeInt ;
  List<Widget> getActionButtons(BuildContext context, WidgetRef ref) {
    final showScan = ref.watch(showScanFixedButtonProvider(actionScanTypeInt));

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

}

















