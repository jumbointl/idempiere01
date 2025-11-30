// Clase de estado abstracta para lógica común
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action.dart';

import '../../../config/router/app_router.dart';
import '../../../config/theme/app_theme.dart';
import '../../home/presentation/screens/home_screen.dart';
import '../../shared/data/memory.dart';
import '../../shared/data/messages.dart';
import '../domain/idempiere/movement_and_lines.dart';
import '../presentation/providers/common_provider.dart';
import '../presentation/screens/store_on_hand/memory_products.dart';
import 'app_initializer_overlay.dart';
import 'input_data_processor.dart';
import 'input_dialog.dart';
import 'package:intl/intl.dart';

abstract class CommonConsumerState<T extends ConsumerStatefulWidget> extends ConsumerState<T>
    implements InputDataProcessor {


  /*late var isScanning = ref.watch(isScanningProvider.notifier);
  late var usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
  late AsyncValue mainDataAsync  = getMainDataAsync;
  late AsyncValue mainDataListAsync = getMainDataListAsync;
  late var isDialogShowed = ref.watch(isDialogShowedProvider.notifier);
  late var scrollToTop = ref.watch(scrollToUpProvider.notifier);
  late ScrollController scrollController = ScrollController();*/

  late var isScanning ;
  late var usePhoneCamera ;
  AsyncValue get mainDataAsync ;
  //AsyncValue get mainDataListAsync;
  late var isDialogShowed;
  late var scrollToTop ;
  late var inputString;
  late var pageIndexProdiver;
  late var actionScan;
  late ScrollController scrollController;
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
  String get hinText;
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
  Widget build(BuildContext context){
    initialSetting(context,ref);

    return AppInitializerOverlay(
      child: Scaffold(
      
        appBar: getAppBar(context,ref),
        /*floatingActionButton: FloatingActionButton(
          onPressed: () {
            double positionAdd= scrollController.position.maxScrollExtent;
            if(scrollToTop.state){
              goToPosition -= positionAdd;
              if(goToPosition <= 0){
                goToPosition = 0;
                ref.read(scrollToUpProvider.notifier).update((state) => !state);
              }
            } else {
              goToPosition+= positionAdd;
              if(goToPosition >= scrollController.position.maxScrollExtent){
                goToPosition = scrollController.position.maxScrollExtent;
                ref.read(scrollToUpProvider.notifier).update((state) => !state);
              }
            }
      
            setState(() {});
            scrollController.animateTo(
              goToPosition,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          },
          child: Icon(scrollToTop.state ? Icons.arrow_upward :Icons.arrow_downward),
        ),*/
        bottomNavigationBar: isDialogShowed.state ? Container(
          height: Memory.BOTTOM_BAR_HEIGHT,
          color: themeColorPrimary,
          child: Center(
            child: Text(Messages.DIALOG_SHOWED,
              style: TextStyle(color: Colors.white,fontSize: themeFontSizeLarge
                  ,fontWeight: FontWeight.bold),),
          ),
        ) : getBottomAppBar(context,ref),
      
        body: SafeArea(
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              if (didPop) {
                return;
              }
              popScopeAction(context,ref);
      
      
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  spacing: 10,
                  children: [
                    if(showSearchBar) getSearchBar(context,ref,hinText,this),
                    getMainDataCard(context, ref),
                    //getMainDataList(context, ref),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  void executeAfterShown();

  Widget getMainDataCard(BuildContext context,WidgetRef ref);
  //Widget getMainDataList(BuildContext context,WidgetRef ref);





  void iconBackPressed(BuildContext context, WidgetRef ref) {
    print('iconBackPressed----------------------------');
    Navigator.pop(context);
  }

  void popScopeAction(BuildContext context, WidgetRef ref) async {
    /*ref.read(isScanningProvider.notifier).update((state) => false);
    ref.read(actionScanProvider.notifier).update((state)
    => Memory.ACTION_FIND_MOVEMENT_BY_ID);*/
    print('popScopeAction----------------------------');
    ref.invalidate(homeScreenTitleProvider);
    //context.go(AppRouter.PAGE_HOME);
    Navigator.pop(context);

  }

  BottomAppBar getBottomAppBar(BuildContext context, WidgetRef ref) {
    return BottomAppBar(
        height: Memory.BOTTOM_BAR_HEIGHT,
        color: getColorByActionScan() ,
        child: usePhoneCamera.state ? buttonScanWithPhone(context,ref,this)
            : getScanButton(context,ref)
    );


  }
  void initialSetting(BuildContext context, WidgetRef ref);




  Widget getScanButton(BuildContext context, WidgetRef ref) {
    //return EnterSubmitScreen(processor: this,);
    print('actionScan.state ${actionScan.state}');
    return ScanButtonByAction(
        color: getColorByActionScan(),
        actionTypeInt: actionScan.state,
        processor: this);



  }


  AppBar? getAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: getAppBarBackgroundColor(context,ref),
      automaticallyImplyLeading: true,
      leading:IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async =>
          {
            print('iconBackPressed----------------------------'),
            popScopeAction(context, ref),
          }
        //
      ),

      title: getAppBarTitle(context,ref),
      actions: [
        getActionButtons(context,ref),

      ],

    );
  }

  Widget? getAppBarTitle(BuildContext context, WidgetRef ref);

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
    int action = actionScan.state;
    if(action == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
      return Colors.cyan[800];
    }else if(action == Memory.ACTION_GET_LOCATOR_TO_VALUE){
      return Colors.yellow[800];

    }
    return themeColorPrimary;

  }

  void findMovementAfterDate(DateTime date, {required bool isIn}) {}

  Widget getActionButtons(BuildContext context, WidgetRef ref) {
    return usePhoneCamera.state ? IconButton(
      icon: const Icon(Icons.barcode_reader),
      onPressed: () => {
        usePhoneCamera.state = false,
        isDialogShowed.state = false,
        setState(() {}),
      },

    ) :  IconButton(
      icon: const Icon(Icons.qr_code_scanner),
      onPressed: () => {
        usePhoneCamera.state = true,
        isDialogShowed.state = false,
        setState(() {}),
      },

    );
  }
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref);

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
  const MovementDateFilterRow({
    super.key,
    required this.onOk,
  });

  final void Function(DateTime date, bool? isIn) onOk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final isIn = ref.watch(inOutProvider); // bool?
    final dateText = DateFormat('dd/MM/yyyy').format(selectedDate);

    return Column(
      children: [
        Row(
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
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
                }
              },
              child: Text(dateText, style: TextStyle(color: Colors.purple)),
              ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              onPressed: () {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                ref.read(selectedDateProvider.notifier).state = today;
              },
              child: Text(
                Messages.TODAY,
                style: const TextStyle(color: Colors.purple),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // SegmentedButton con 3 opciones: ALL / IN / OUT
            SegmentedButton<bool?>(
              segments: <ButtonSegment<bool?>>[
                ButtonSegment<bool?>(
                  value: null,
                  icon: const Icon(Icons.swap_vert, size: 20),
                  label: Text(Messages.ALL), // crea Messages.ALL = 'ALL' o lo que quieras
                ),
                ButtonSegment<bool?>(
                  value: true,
                  icon: Icon(Icons.arrow_downward, size: 20),
                  label: Text(Messages.IN),
                ),
                ButtonSegment<bool?>(
                  value: false,
                  icon: Icon(Icons.arrow_upward, size: 20),
                  label: Text(Messages.OUT),
                ),
              ],
              // selected no puede estar vacío, así que siempre metemos el valor actual (aunque sea null)
              selected: <bool?>{isIn},
              onSelectionChanged: (newSelection) {
                // newSelection.first es bool? (null / true / false)
                ref.read(inOutProvider.notifier).state = newSelection.first;
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                final date = ref.read(selectedDateProvider);
                final isIn = ref.read(inOutProvider); // bool?

                // Cambia la firma de onOk para aceptar bool?
                // onOk(date, isIn);  // DateTime, bool?

                // Si todavía no cambiaste onOk, puedes mapear a algo:
                // null = ALL -> por ejemplo, tratar como IN por defecto
                // onOk(date, isIn ?? true);
                onOk(date, isIn);
              },
              icon: const Icon(
                Icons.search,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }


}






