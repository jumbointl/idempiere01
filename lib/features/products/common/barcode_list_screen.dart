
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:monalisa_app_001/features/products/common/async_value_consumer_screen_state.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';

import 'barcode_list_screen_helper.dart';
import '../domain/models/barcode_models.dart';
import '../presentation/providers/product_provider_common.dart';

abstract class BarcodeListScreen<T> extends ConsumerStatefulWidget {
  final String argument;
  final T initialModel;

  const BarcodeListScreen({
    super.key,
    required this.argument,
    required this.initialModel,
  });

  /// Parsear desde argument (json string)
  T parseArgument(String argument);
}

abstract class BarcodeListScreenState<W extends BarcodeListScreen<T>, T>
    extends AsyncValueConsumerState<W> with SingleTickerProviderStateMixin {
  late T model;

  BarcodeViewSection _selectedSection = BarcodeViewSection.document;
  // Muestra spinner visual
  static const int listLengthToShowProgressBar = 60;

// A partir de aquí, usa isolate (compute)
  static const int listLengthToUseCompute = 250;

  /// ====== ADAPTADORES (cada hijo implementa) ======
  bool get hasDocument;
  bool get hasProducts;
  bool get hasLocations;

  String get documentTitle;
  String get documentNo;
  String get documentStatusText;
  Color get documentCardColor;

  /// Si hay “confirm docs” u otros QRs bajo el documento
  List<DocumentQrItem> get documentExtraQrs;

  /// UPC/EAN list
  List<BarcodeItem> get productBarcodes;
  List<BarcodeItem>? _processedProductBarcodes;
  List<int> get lostLines{
    final lines = productBarcodes ?? [];
    if (lines.length <= 1) return const [];

    // Extraer y ordenar números de línea
    final List<int> lineNumbers = lines
        .map((l) => l.line)
        .whereType<int>()
        .toList()
      ..sort();

    final List<int> missing = [];

    for (int i = 1; i < lineNumbers.length; i++) {
      final prev = lineNumbers[i - 1];
      final curr = lineNumbers[i];

      final diff = curr - prev;

      // saltos de 10 → detectar faltantes
      if (diff > 10) {
        for (int v = prev + 10; v < curr; v += 10) {
          missing.add(v);
        }
      }
    }
    return missing;
  }

  /// Locator QR list
  List<LocatorQrItem> get locatorQrs;

  /// Texto de cada tab
  String get tabDocumentLabel => 'Documento';
  String get tabProductsLabel => 'Productos';
  String get tabLocationsLabel => 'Ubicaciones';

  @override
  void initState() {
    super.initState();

    model = widget.initialModel;
    if (widget.argument.isNotEmpty) {
      model = widget.parseArgument(widget.argument);
    }
  }

  // Tu template requiere esto; lo dejamos como en tu screen actual
  @override
  AsyncValue<ResponseAsyncValue> get mainDataAsync => throw UnimplementedError();

  @override

  Widget getMainDataCard(BuildContext context, WidgetRef ref) {
    final showDocument = hasDocument && _selectedSection == BarcodeViewSection.document;
    final showProducts = hasProducts && _selectedSection == BarcodeViewSection.products;
    final showLocations = hasLocations && _selectedSection == BarcodeViewSection.locations;
    isScanning = ref.watch(isScanningProvider);
    const double fontSizeSmall = 12;



    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<BarcodeViewSection>(
          segments: [
            ButtonSegment(
              value: BarcodeViewSection.document,
              icon: const Icon(Icons.description, size: 18),
              label: Text(tabDocumentLabel, style: const TextStyle(fontSize: fontSizeSmall)),
            ),
            ButtonSegment(
              value: BarcodeViewSection.products,
              icon: const Icon(Icons.inventory_2, size: 18),
              label: isScanning
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CupertinoActivityIndicator(),
              )
                  : Text(
                tabProductsLabel,
                style: const TextStyle(fontSize: fontSizeSmall),
              ),
            ),
            ButtonSegment(
              value: BarcodeViewSection.locations,
              icon: const Icon(Icons.location_on, size: 18),
              label: Text(tabLocationsLabel, style: const TextStyle(fontSize: fontSizeSmall)),
            ),
          ],
          selected: {_selectedSection},
          onSelectionChanged: (newSelection) async {
            if (newSelection.first != BarcodeViewSection.products) {
              setState(() => _selectedSection = newSelection.first);
              return;
            }

            final int count = productBarcodes.length;

            final bool showSpinner = count >= listLengthToShowProgressBar;
            final bool useCompute = count >= listLengthToUseCompute;

            if (showSpinner) {
              ref.read(isScanningProvider.notifier).state = true;
              // dejar pintar overlay
              await Future.delayed(const Duration(milliseconds: 16));
            }

            if (useCompute) {
              final processed = await compute(
                buildBarcodeModels,
                productBarcodes,
              );

              if (!mounted) return;

              setState(() {
                _processedProductBarcodes = processed;
                _selectedSection = BarcodeViewSection.products;
              });
            } else {
              setState(() {
                _processedProductBarcodes = null; // usar lista directa
                _selectedSection = BarcodeViewSection.products;
              });
            }

            if (showSpinner && mounted) {
              ref.read(isScanningProvider.notifier).state = false;
            }
          },

          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (showDocument) ...[
          _buildDocumentSection(context, ref),
          const SizedBox(height: 20),
        ],

        if (showProducts) ...[
          isScanning ? CupertinoActivityIndicator() : _buildProductsSection(context, ref),
          const SizedBox(height: 20),
        ],

        if (showLocations) ...[
          _buildLocationsSection(context, ref),
        ],
      ],
    );
  }

  Widget _buildDocumentSection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          height: 130,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: documentCardColor,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(documentTitle, style: const TextStyle(color: Colors.black, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(
                      documentNo,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      documentStatusText,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                height: 100,
                child: _getQrCode(documentNo),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (documentExtraQrs.isNotEmpty)
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: documentExtraQrs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = documentExtraQrs[index];
              return Container(
                height: 130,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.title, style: const TextStyle(color: Colors.black, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(item.code, style: const TextStyle(color: Colors.black, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(item.subtitle, style: const TextStyle(color: Colors.black, fontSize: 12)),
                        ],
                      ),
                    ),
                    SizedBox(width: 100, height: 100, child: _getQrCode(item.code)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildProductsSection(BuildContext context, WidgetRef ref) {
    final list = _processedProductBarcodes ?? productBarcodes;
    final filtered = list.where((e) => e.code.trim().isNotEmpty).toList();
    if (filtered.isEmpty) {
      return const SizedBox.shrink();
    }
    
    ListView view = ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final item = filtered[index];

        return Card(
          elevation: 2.0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
          child: Container(
            height: 130,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: _getBarcode(item.code),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(isScanningProvider.notifier).state = false;
      }
    });
    return view;
  }

  Widget _buildLocationsSection(BuildContext context, WidgetRef ref) {
    if (locatorQrs.isEmpty) return const SizedBox.shrink();

    // Unicidad por locator
    final map = <String, LocatorQrItem>{};
    for (final l in locatorQrs) {
      map.putIfAbsent(l.locator, () => l);
    }
    final unique = map.values.toList();

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: unique.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final item = unique[index];

        return Container(
          height: 130,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: item.backgroundColor,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.locator, style: const TextStyle(color: Colors.black, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(item.warehouse, style: const TextStyle(color: Colors.black, fontSize: 12)),
                  ],
                ),
              ),
              SizedBox(width: 100, height: 100, child: _getQrCode(item.locator)),
            ],
          ),
        );
      },
    );
  }

  /// ====== HELPERS BARCODE / QR ======
  Widget _getBarcode(String codeRaw) {
    final code = codeRaw.trim();
    if (code.isEmpty) return const SizedBox.shrink();

    // Si tu lógica EAN13 estaba en otro lado, aquí puedes replicarla.
    // Para simplificar, dejamos Code128 por defecto y EAN13 cuando sea 13.
    final Barcode barcode = (code.length == 13) ? Barcode.ean13() : Barcode.code128();

    return Container(
      padding: const EdgeInsets.all(4),
      color: Colors.white,
      child: BarcodeWidget(
        barcode: barcode,
        data: code,
        width: 120,
        height: 40,
        drawText: false,
      ),
    );
  }

  Widget _getQrCode(String data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: QrImageView(
        data: data,
        size: 80,
        backgroundColor: Colors.white,
      ),
    );
  }
  @override
  List<Widget> getActionButtons(BuildContext context, WidgetRef ref) {
    return [];
  }
  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return Colors.cyan[200];
  }
  @override
  void popScopeAction(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
  }
  @override
  bool get showLeading => true;
  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    String missing = '';
    if(lostLines.isNotEmpty){
      missing = lostLines.map((e) => e.toString()).join(', ');
      missing='(M: $missing)';
    }
    String title = '$documentNo $missing';
    double fontSize = 18;
    if(title.length > 20) fontSize = 16 ;
    return Text(title,style: TextStyle(color: Colors.black,fontSize: fontSize),);

  }
}
