import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';

import '../../../../common/barcode_list_screen.dart';
import '../../../../domain/models/barcode_models.dart';

import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_confirm.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_line.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

class MovementBarcodeListScreen extends BarcodeListScreen<MovementAndLines> {
  MovementBarcodeListScreen({
    super.key,
    required super.argument,
    required MovementAndLines movementAndLines,
  }) : super(initialModel: movementAndLines);

  @override
  MovementAndLines parseArgument(String argument) {
    return MovementAndLines.fromJson(jsonDecode(argument));
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MovementBarcodeListScreenState();
}

class _MovementBarcodeListScreenState
    extends BarcodeListScreenState<MovementBarcodeListScreen, MovementAndLines> {

  MovementAndLines get m => model;

  @override
  bool get hasDocument => m.hasMovement;

  @override
  bool get hasProducts => m.hasMovementLines;

  @override
  bool get hasLocations => m.hasMovementLines;

  @override
  String get documentTitle => Messages.MOVEMENT;

  @override
  String get documentNo => m.documentNo ?? '';

  @override
  String get documentStatusText => m.docStatus?.identifier ?? '';

  @override
  Color get documentCardColor => Colors.cyan[200]!;

  @override
  List<DocumentQrItem> get documentExtraQrs {
    final List<IdempiereMovementConfirm> confirms = m.movementConfirms ?? [];
    final filtered = confirms.where((c) => (c.documentNo ?? '').trim().isNotEmpty).toList();

    return filtered.map((c) {
      return DocumentQrItem(
        title: Messages.MOVEMENT_CONFIRM,
        code: c.documentNo ?? '',
        subtitle: c.docStatus?.identifier ?? '',
      );
    }).toList();
  }

  @override
  List<BarcodeItem> get productBarcodes {
    final List<IdempiereMovementLine> lines = m.movementLines ?? [];
    final filtered = lines.where((l) => (l.uPC ?? '').trim().isNotEmpty).toList();

    return filtered.map((l) {
      String name = l.mProductID?.identifier ?? '';
      if (name.contains('_')) name = name.split('_').last;
      final upc = l.uPC ?? '';

      return BarcodeItem(
        code: upc,
        title: upc,
        subtitle: name,
      );
    }).toList();
  }

  @override
  List<LocatorQrItem> get locatorQrs {
    final fromName = m.warehouseFrom?.identifier ?? 'FROM';
    final toName = m.warehouseTo?.identifier ?? 'TO';

    final List<IdempiereMovementLine> lines = m.movementLines ?? [];
    final result = <LocatorQrItem>[];

    for (final line in lines) {
      final locFrom = line.mLocatorID;
      final locTo = line.mLocatorToID;

      final fromValue = (locFrom?.value ?? locFrom?.identifier ?? '').trim();
      if (fromValue.isNotEmpty) {
        result.add(LocatorQrItem(
          locator: fromValue,
          warehouse: fromName,
          backgroundColor: Colors.cyan[200]!,
        ));
      }

      final toValue = (locTo?.value ?? locTo?.identifier ?? '').trim();
      if (toValue.isNotEmpty) {
        result.add(LocatorQrItem(
          locator: toValue,
          warehouse: toName,
          backgroundColor: Colors.white,
        ));
      }
    }
    return result;
  }

  @override
  // TODO: implement actionScanTypeInt
  int get actionScanTypeInt => throw UnimplementedError();

  @override
  void afterAsyncValueAction(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement afterAsyncValueAction
  }

  @override
  Widget asyncValueErrorHandle(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement asyncValueErrorHandle
    throw UnimplementedError();
  }

  @override
  Widget asyncValueSuccessPanel(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement asyncValueSuccessPanel
    throw UnimplementedError();
  }

  @override
  void executeAfterShown() {
    // TODO: implement executeAfterShown
  }


  @override
  double getWidth() {
    // TODO: implement getWidth
    throw UnimplementedError();
  }

  @override
  Future<void> handleInputString({required WidgetRef ref, required String inputData, required int actionScan}) {
    // TODO: implement handleInputString
    throw UnimplementedError();
  }

  @override
  void initialSetting(BuildContext context, WidgetRef ref) {
  }

  @override
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) async {
    print('setDefaultValues');
  }




}






/*

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_confirm.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/custom_app_bar.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/new_movement_edit_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';

import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/async_value_consumer_screen_state.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/products_home_provider.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../auth/domain/entities/warehouse.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/barcode_utils.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../domain/idempiere/response_async_value.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/persitent_provider.dart';
import '../../../providers/product_provider_common.dart';


class MovementBarcodeListScreen extends ConsumerStatefulWidget {

  MovementAndLines movementAndLines;
  String argument;

  int actionTypeInt=0;

  MovementBarcodeListScreen({super.key,
    required this.argument,
    required this.movementAndLines});


  @override
  ConsumerState<ConsumerStatefulWidget> createState() => MovementBarcodeListScreenState();



}
enum MovementViewSection {
  document,
  products,
  locations,
}


class MovementBarcodeListScreenState extends AsyncValueConsumerState<MovementBarcodeListScreen> with SingleTickerProviderStateMixin {
  Color colorBackgroundHasMovementId = Colors.cyan[200]!;
  Color colorBackgroundNoMovementId = Colors.white;
  int sameLocator = 0;
  final double singleProductDetailCardHeight = 160;
  Warehouse? userWarehouse;
  @override
  late var isDialogShowed;
  late MovementAndLines movementAndLines ;
  late String argument ;
  late String warehouseFrom ;
  late String warehouseTo ;


  MovementViewSection _selectedSection = MovementViewSection.document;
  @override
  void initState() {

    warehouseFrom = widget.movementAndLines.warehouseFrom?.identifier ?? 'NO DISPONIBLE FROM';
    warehouseTo = widget.movementAndLines.warehouseTo?.identifier ?? 'NO DISPONIBLE TO';
    if(widget.argument.isNotEmpty) {
      movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));
    }
    super.initState();
  }


  @override
  void executeAfterShown() {

    ref.read(isScanningProvider.notifier).update((state) => false);
  }

  @override
  double getWidth(){ return MediaQuery.of(context).size.width - 30;}




  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return Colors.cyan[200];
  }

  @override
  AsyncValue<ResponseAsyncValue> get mainDataAsync => throw UnimplementedError();
  @override
  Widget getMainDataCard(BuildContext context, WidgetRef ref) {
    final hasMovement        = movementAndLines.hasMovement;
    final hasMovementLines   = movementAndLines.hasMovementLines;
    final documentNo         = movementAndLines.documentNo ?? '';
    final docStatus          = movementAndLines.docStatus?.identifier ?? '';


    final showDocument  = hasMovement      && _selectedSection == MovementViewSection.document;
    final showProducts  = hasMovementLines && _selectedSection == MovementViewSection.products;
    final showLocations = hasMovementLines && _selectedSection == MovementViewSection.locations;
    double fontSizeSmall = 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<MovementViewSection>(
          // multiSelectionEnabled por defecto es false → selección simple
          segments: [
            ButtonSegment<MovementViewSection>(
              value: MovementViewSection.document,
              icon: const Icon(Icons.description, size: 18),
              label: Text('Documento',style: TextStyle(fontSize: fontSizeSmall),),
            ),
            ButtonSegment<MovementViewSection>(
              value: MovementViewSection.products,
              icon: Icon(Icons.inventory_2, size: 18),
              label: Text('Productos',style: TextStyle(fontSize: fontSizeSmall),),
            ),
            ButtonSegment<MovementViewSection>(
              value: MovementViewSection.locations,
              icon: Icon(Icons.location_on, size: 18),
              label: Text('Ubicaciones',style: TextStyle(fontSize: fontSizeSmall),),
            ),
          ],
          selected: {_selectedSection},
          onSelectionChanged: (newSelection) {
            // newSelection siempre tiene 1 elemento
            setState(() {
              _selectedSection = newSelection.first;
            });
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),


        const SizedBox(height: 12),

        // 🔹 Sección DOCUMENTO
        if (showDocument) ...[
          Column(
            children: [
              Container(
                height: 130,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.cyan[200],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // --------------------- TEXTOS ---------------------
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(Messages.MOVEMENT,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(documentNo,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 14)),

                          const SizedBox(height: 6),
                          Text(docStatus,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 12)),

                        ],
                      ),
                    ),

                    // --------------------- QR CODE ---------------------
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: getQrCode(ref, documentNo),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if(movementAndLines.hasMovementConfirms)
                getBarcodeMovementsConfirms(ref, movementAndLines.movementConfirms!),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // 🔹 Sección PRODUCTOS (códigos de barras UPC)
        if (showProducts) ...[
          getBarcodeMovementsLinesUPC(ref, movementAndLines.movementLines!),
          const SizedBox(height: 20),
        ],

        // 🔹 Sección UBICACIONES (QR de locators)
        if (showLocations) ...[
          getBarcodeMovementsLinesLocator(ref, movementAndLines.movementLines!),
        ],
      ],
    );
  }
  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return Colors.cyan[200];
  }
  @override
  AppBar? getAppBar(BuildContext context, WidgetRef ref) {

    return AppBar(
      backgroundColor: getAppBarBackgroundColor(context,ref),
      automaticallyImplyLeading: showLeading,
      title: getAppBarTitle(context,ref),
      actions: getActionButtons(context,ref),

    );
  }

  Widget getBarcode(WidgetRef ref, String upc) {
    if (upc.isEmpty) return const SizedBox.shrink();

    String code = upc.trim();

    // Si tiene 12 dígitos, probamos agregar '0' delante para EAN13
    if (code.length == 12) {
      final aux = '0$code';
      if (isValidEAN13(aux)) {
        code = aux;
      }
    }

    final bool useEan13 = code.length == 13 && isValidEAN13(code);

    final barcode = useEan13 ? Barcode.ean13() : Barcode.code128();

    return Container(
      padding: const EdgeInsets.all(4),
      color: Colors.white,
      child: BarcodeWidget(
        barcode: barcode,
        data: code,
        width: 120,
        height: 40,
        drawText: false, // si quieres texto debajo, pon true
      ),
    );
  }

  Widget getQrCode(WidgetRef ref, String data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: QrImageView(
        data: data,
        size: 80,               // para el tab "Documento"
        backgroundColor: Colors.white,
      ),
    );
  }
  @override
  bool get scrollManinDataCard => true;
  Widget getBarcodeMovementsConfirms(
      WidgetRef ref,
      List<IdempiereMovementConfirm> movementConfirms,
      ) {
    // Filtrar solo líneas con UPC válido
    final filtered = movementConfirms.where((confirms) {
      final docNo = confirms.documentNo ?? '';
      return docNo.trim().isNotEmpty;
    }).toList();

    if (filtered.isEmpty) {
      return const SizedBox.shrink(); // No mostrar nada
    }

    return Padding(
      padding: EdgeInsets.only(bottom: Memory.BOTTOM_BAR_HEIGHT+20),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final confirms = filtered[index];
          final docNo = confirms.documentNo ?? '';
          String docStatus = confirms.docStatus?.identifier ?? '';


          return Container(
            height: 130,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade400, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // --------------------- TEXTOS ---------------------
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Text(Messages.MOVEMENT_CONFIRM,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(docNo,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(docStatus,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 12)),
                    ],
                  ),
                ),

                // --------------------- QR CODE ---------------------
                SizedBox(
                  width: 100,
                  height: 100,
                  child: getQrCode(ref, docNo),
                ),
              ],
            ),
          );

        },
        separatorBuilder: (_, __) => const SizedBox(height: 20),
      ),
    );
  }
  Widget getBarcodeMovementsLinesUPC(
      WidgetRef ref,
      List<IdempiereMovementLine> movementLines,
      ) {
    // Filtrar solo líneas con UPC válido
    final filtered = movementLines.where((line) {
      final upc = line.uPC ?? '';
      return upc.trim().isNotEmpty;
    }).toList();

    if (filtered.isEmpty) {
      return const SizedBox.shrink(); // No mostrar nada
    }

    return Padding(
      padding: EdgeInsets.only(bottom: Memory.BOTTOM_BAR_HEIGHT+20),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final line = filtered[index];
          final upc = line.uPC ?? '';

          String name = line.mProductID?.identifier ?? '';
          if (name.contains('_')) {
            name = name.split('_').last;
          }

          const Color textColor = Colors.black;
          const double fontSize = 12;

          return Card(
            elevation: 2.0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
            child: Container(
              height: 130, // alto total del card
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

              child: Row(
                children: [
                  // ----- Texto -----
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          upc,
                          style: const TextStyle(
                            color: textColor,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          style: const TextStyle(
                            color: textColor,
                            fontSize: fontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8), // Espacio entre las columnas
                  // ----- Barcode con tamaño fijo -----
                  Expanded(
                    child: SizedBox(
                      height: 100, // Altura del barcode container
                      width: double.infinity, // Ocupa el ancho del Expanded
                      child: getBarcode(ref, upc),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 20),
      ),
    );
  }

  Widget getBarcodeMovementsLinesLocator(
      WidgetRef ref, List<IdempiereMovementLine> movementLines) {

    List<List<String>> locators=[[]];
    String colorFrom = '1';
    String colorTo = '2';

    // Crear lista de locators con warehouse y color
    for (var line in movementLines) {
      final locFrom = line.mLocatorID;
      final locTo = line.mLocatorToID;

      if (locFrom != null) {
        String value = locFrom.value?.trim().isNotEmpty == true
            ? locFrom.value!
            : locFrom.identifier ?? '';

        if (value.isNotEmpty) {
          locators.add([value,warehouseFrom,colorFrom]);
        }
      }

      if (locTo != null) {
        String value = locTo.value?.trim().isNotEmpty == true
            ? locTo.value!
            : locTo.identifier ?? '';

        if (value.isNotEmpty) {
          locators.add([value,warehouseTo,colorTo]);
        }
      }
    }

    if (locators.isEmpty) return const SizedBox.shrink();



    // Filtrar para que sea único por la posición [0] (el valor del locator)
    final uniqueLocatorsMap = <String, List<String>>{};
    for (var locator in locators) {
      if (locator.isNotEmpty) {
        // Usar el primer elemento como clave para asegurar unicidad
        if (!uniqueLocatorsMap.containsKey(locator[0])) {
          uniqueLocatorsMap[locator[0]] = locator;
        }
      }
    }
    final uniqueLocators = uniqueLocatorsMap.values.toList();


    return Padding(
      padding: EdgeInsets.only(bottom: Memory.BOTTOM_BAR_HEIGHT+20),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: uniqueLocators.length,
        itemBuilder: (context, index) {
          final locatorData = uniqueLocators[index];

          String locator = locatorData[0];
          String warehouse = locatorData.length > 1 ? locatorData[1] : '';
          String color = locatorData.length > 2 ? locatorData[2] : '';

          Color backgroundColor =
          color == '1' ? Colors.cyan[200]! : Colors.white;

          return Container(
            height: 130,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade400, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // --------------------- TEXTOS ---------------------
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(locator,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(warehouse,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 12)),
                    ],
                  ),
                ),

                // --------------------- QR CODE ---------------------
                SizedBox(
                  width: 100,
                  height: 100,
                  child: getQrCode(ref, locator),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 20),
      ),
    );
  }


  @override
  void initialSetting(BuildContext context, WidgetRef ref) {
    if(widget.argument.isNotEmpty) {
      movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));
    }
    ref.invalidate(persistentLocatorToProvider);
    isScanning = ref.watch(isScanningProvider);
    isDialogShowed = ref.watch(isDialogShowedProvider);
    inputString = ref.watch(inputStringProvider);
    pageIndexProdiver = ref.watch(productsHomeCurrentIndexProvider);
    actionScan = ref.watch(actionScanProvider);

  }

  @override
  Future<void> handleInputString({required WidgetRef ref, required String inputData,
    required int actionScan}) async {
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {

    return movementAppBarTitle(
        showBackButton: true,
        movementAndLines: movementAndLines,
        onBack: ()=>popScopeAction(context, ref),);

  }
  @override
  BottomAppBar? getBottomAppBar(BuildContext context, WidgetRef ref) {
    return null;
  }

  @override
  void addQuantityText(BuildContext context, WidgetRef ref,
      TextEditingController quantityController,int quantity) {
    if(quantity==-1){
      quantityController.text = '';
      return;
    }
    String s =  quantityController.text;
    String s1 = s;
    String s2 ='';
    if(s.contains('.')) {
      s1 = s.split('.').first;
      s2 = s.split('.').last;
    }

    String r ='';
    if(s.contains('.')){
      r='$s1$quantity.$s2';
    } else {
      r='$s1$quantity';
    }

    int? aux = int.tryParse(r);
    if(aux==null || aux<=0){
      String message =  '${Messages.ERROR_QUANTITY} $quantity';
      showErrorMessage(context, ref, message);
      return;
    }
    quantityController.text = aux.toString();

  }

  @override
  bool get showSearchBar => false;
  @override
  bool get showLeading => false;

  @override
  List<Widget> getActionButtons(BuildContext context, WidgetRef ref) {
    String date = widget.movementAndLines.movementDate ?? '-1';

    return [
      IconButton(onPressed: (){
        context.go(AppRouter.PAGE_HOME);
      }, icon: Icon(Symbols.home,color: Colors.purple),),
      IconButton(onPressed: (){
        context.go('${AppRouter.PAGE_MOVEMENTS_LIST}/$date');
      }, icon: Icon(Symbols.format_list_bulleted,color: Colors.purple),)
    ];
  }

  @override
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) async {
  }


  @override
  int get actionScanTypeInt => widget.actionTypeInt;

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) async {
    int movementId = movementAndLines.id ?? -1;
    String pageFrom = NewMovementEditScreen.FROM_PAGE_MOVEMENT_LIST;
    context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$movementId/$pageFrom');
  }

  @override
  void afterAsyncValueAction(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement afterAsyncValueAction
  }

  @override
  Widget asyncValueErrorHandle(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement asyncValueErrorHandle
    throw UnimplementedError();
  }

  @override
  Widget asyncValueSuccessPanel(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement asyncValueSuccessPanel
    throw UnimplementedError();
  }




}



*/
