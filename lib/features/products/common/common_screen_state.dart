// Clase de estado abstracta para lógica común
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action_fixed_short.dart';

import '../../../config/router/app_router.dart';
import '../../../config/theme/app_theme.dart';
import '../../shared/data/memory.dart';
import '../../shared/data/messages.dart';
import '../domain/idempiere/movement_and_lines.dart';
import '../presentation/providers/common_provider.dart';
import 'app_initializer_overlay.dart';
import 'input_data_processor.dart';
import 'input_dialog.dart';
import 'package:intl/intl.dart';

abstract class CommonConsumerState<T extends ConsumerStatefulWidget> extends ConsumerState<T>
    implements InputDataProcessor {



  late var isScanning ;
  AsyncValue get mainDataAsync ;
  late var isDialogShowed;
  late var inputString;
  late var pageIndexProdiver;
  late var actionScan;
  late ScrollController scrollController = ScrollController();
  double goToPosition =0.0;
  double? get fontSizeTitle =>themeFontSizeTitle;
  double? get fontSizeLarge =>themeFontSizeLarge;
  double? get fontSizeMedium=>themeFontSizeNormal;
  double? get fontSizeSmall=>themeFontSizeSmall;
  Color? get fontBackgroundColor=>Colors.white;
  Color? get fontForegroundColor=>Colors.black;
  Color? get backgroundColor=>Colors.white;
  Color? get foregroundColor=>Colors.black;
  Color? get hintTextColor=>Colors.purple;
  Color? get resultColor=>Colors.purple;
  Color? get borderColor=>Colors.black;
  int get qtyOfDataToAllowScroll => 2;
  late TextStyle textStyleTitle = TextStyle(fontSize: fontSizeTitle,
      color: fontForegroundColor);
  late TextStyle textStyleTitleMore20C = TextStyle(fontSize: 13,
      color: fontForegroundColor);
  late TextStyle textStyleLarge = TextStyle(fontSize: fontSizeLarge,
      color: fontForegroundColor);
  late TextStyle textStyleLargeBold = TextStyle(fontSize: fontSizeLarge,
      color: fontForegroundColor, fontWeight: FontWeight.bold);
  late TextStyle textStyleMedium = TextStyle(fontSize: fontSizeMedium,
      color: fontForegroundColor);
  late TextStyle textStyleMediumBold = TextStyle(fontSize: fontSizeMedium,
      color: fontForegroundColor, fontWeight: FontWeight.bold);
  late TextStyle textStyleSmall = TextStyle(fontSize: fontSizeSmall,
      color: fontForegroundColor);
  late TextStyle textStyleSmallBold = TextStyle(fontSize: fontSizeSmall,
      color: fontForegroundColor, fontWeight: FontWeight.bold);
  late TextStyle textStyleBold = TextStyle(
      color: fontForegroundColor, fontWeight: FontWeight.bold);
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

  Widget getMainDataCard(BuildContext context,WidgetRef ref);
  //Widget getMainDataList(BuildContext context,WidgetRef ref);





  void iconBackPressed(BuildContext context, WidgetRef ref) {
    print('iconBackPressed----------------------------');
    popScopeAction(context, ref);
  }

  void popScopeAction(BuildContext context, WidgetRef ref) async {
    context.go(AppRouter.PAGE_HOME);
  }





  BottomAppBar? getBottomAppBar(BuildContext context, WidgetRef ref) {
    return null ;
    /*return BottomAppBar(
        height: Memory.BOTTOM_BAR_HEIGHT,
        color: getColorByActionScan() ,
        child: Container(),
    );*/
  }
  void initialSetting(BuildContext context, WidgetRef ref);



  bool get showLeading => false;
  Widget? get leadingIcon {
    print('showLeading: $showLeading');
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


  Future<MovementAndLines> getSavedMovementAndLines () async {
    var movementAndLines = await GetStorage().read(Memory.KEY_MOVEMENT_AND_LINES);
    if(movementAndLines != null){
      if(movementAndLines is MovementAndLines) return movementAndLines;
      return MovementAndLines.fromJson(movementAndLines);
    } else {
      MovementAndLines data = MovementAndLines();
      data.setUser(Memory.sqlUsersData);
      return data ;
    }
  }
  Future<void> saveMovementAndLines(MovementAndLines? movementAndLines) async {
    if(movementAndLines==null){
      GetStorage().remove(Memory.KEY_MOVEMENT_AND_LINES);
      return;
    }
      await GetStorage().write(Memory.KEY_MOVEMENT_AND_LINES, movementAndLines.toJson());
  }
  void removeMovementAndLines(){
    GetStorage().remove(Memory.KEY_MOVEMENT_AND_LINES);
  }
  Color? getColorByMovementAndLines(MovementAndLines? data){
     if(data==null ||!data.hasMovement) return Colors.white;
     if(data.canComplete) return Colors.cyan[200];
     return Colors.green[200];
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

  void findMovementAfterDate(DateTime date, {required String inOut}) {}
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
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref);

  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {return null;}



}


/// Helper: subtract business days (skip Saturday/Sunday)
DateTime subtractBusinessDays(DateTime from, int days) {
  var date = DateTime(from.year, from.month, from.day); // strip time
  var remaining = days;

  while (remaining > 0) {
    date = date.subtract(const Duration(days: 1));
    if (date.weekday != DateTime.saturday &&
        date.weekday != DateTime.sunday) {
      remaining--;
    }
  }
  return date;
}

/// Initial date = today - 3 business days
DateTime initialBusinessDate() {
  final now = DateTime.now();
  return subtractBusinessDays(now, 3);
}

/// Riverpod provider to hold the selected date
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return initialBusinessDate();
});


/// Widget: date selector with "Hoy" and "OK" in one row
class MovementDateFilterRow extends ConsumerWidget {
  final bool orientationUpper;

  const MovementDateFilterRow({
    super.key,
    required this.onOk,
    this.orientationUpper = true,
  });

  /// Agora o callback recebe `String inOut` em vez de `bool?`
  final void Function(DateTime date, String inOut) onOk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final inOutValue = ref.watch(inOutFilterProvider); // 'ALL', 'IN', 'OUT', 'SWAP'
    final dateText = DateFormat('dd/MM/yyyy').format(selectedDate);

    // --------- PRIMEIRA LINHA (data / hoje / scan) ----------
    final firstRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.white,
          ),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              ref.read(selectedDateProvider.notifier).state = picked;
              final date = ref.read(selectedDateProvider);
              final inOut = ref.read(inOutFilterProvider);
              onOk(date, inOut);
            }
          },
          child: Text(
            dateText,
            style: const TextStyle(color: Colors.purple),
          ),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.white,
          ),
          onPressed: () {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            ref.read(selectedDateProvider.notifier).state = today;
            final date = ref.read(selectedDateProvider);
            final inOut = ref.read(inOutFilterProvider);
            onOk(date, inOut);
          },
          child: Text(
            Messages.TODAY,
            style: const TextStyle(color: Colors.purple),
          ),
        ),
        OutlinedButton(
          onPressed: () {
            context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/-1/-1');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: themeColorPrimary,
            visualDensity: VisualDensity.compact,
          ),
          child: const Text(
            'SCAN',
            style: TextStyle(color: Colors.white),
          ),
        ),

        Container(
          height: 32, // Altura similar a OutlinedButton con VisualDensity.compact
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh, color: Colors.purple),
            onPressed: () {
              final date = ref.read(selectedDateProvider);
              final inOut = ref.read(inOutFilterProvider);
              onOk(date, inOut);
            },
          ),
        ),
        /*OutlinedButton(
          onPressed: () {
            final date = ref.read(selectedDateProvider);
            final inOut = ref.read(inOutFilterProvider);
            onOk(date, inOut);
          },
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.white,
          ),
          child: const Icon(Icons.refresh, color: Colors.purple),
        ),*/
      ],
    );

    // --------- SEGUNDA LINHA (filtro IN/OUT/...) ----------
    final secondRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SegmentedButton<String>(
            segments: <ButtonSegment<String>>[
              ButtonSegment<String>(
                value: 'ALL',
                icon: const Icon(Icons.all_inclusive, size: 20),
                label: Text(
                  'ALL',
                  style: TextStyle(fontSize: themeFontSizeSmall),
                ),
              ),
              ButtonSegment<String>(
                value: 'IN',
                icon: const Icon(Icons.arrow_downward, size: 20),
                label: Text(
                  'IN',
                  style: TextStyle(fontSize: themeFontSizeSmall),
                ),
              ),
              ButtonSegment<String>(
                value: 'OUT',
                icon: const Icon(Icons.arrow_upward, size: 20),
                label: Text(
                  'OUT',
                  style: TextStyle(fontSize: themeFontSizeSmall),
                ),
              ),
              ButtonSegment<String>(
                value: 'SWAP',
                icon: const Icon(Icons.swap_horiz, size: 20),
                label: Text(
                  'SWAP',
                  style: TextStyle(fontSize: themeFontSizeSmall),
                ),
              ),
            ],
            selected: <String>{inOutValue},
            onSelectionChanged: (newSelection) {
              final value = newSelection.first; // 'ALL' | 'IN' | 'OUT' | 'SWAP'
              ref.read(inOutFilterProvider.notifier).state = value;

              final date = ref.read(selectedDateProvider);
              onOk(date, value);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ),

      ],
    );

    return Column(
      children: orientationUpper ? [secondRow, firstRow] : [firstRow, secondRow],
    );
  }
}







