import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../common/async_value_consumer_simple_state.dart';
import '../../../domain/idempiere/idempiere_locator.dart';
import '../../../domain/idempiere/locator_product_stock.dart';
import '../../../domain/idempiere/locator_with_product_stocks.dart';
import '../../../domain/idempiere/response_async_value.dart';
import '../../providers/locator_stock/find_storage_by_locator_value_providers.dart';
import '../../providers/locator_stock/locator_stock_extract_providers.dart';
import '../../providers/locator_stock/locator_stock_input_providers.dart';
import '../../providers/product_provider_common.dart';
import 'locator_product_stock_card.dart';

class LocatorStockDetailScreen extends ConsumerStatefulWidget {
  const LocatorStockDetailScreen({super.key});

  @override
  ConsumerState<LocatorStockDetailScreen> createState() =>
      _LocatorStockDetailScreenState();
}

class _LocatorStockDetailScreenState
    extends AsyncValueConsumerSimpleState<LocatorStockDetailScreen> {
  @override
  int get actionScanTypeInt =>
      Memory.ACTION_FIND_BY_LOCATOR_VALUE_FOR_STOCK_DETAIL;

  @override
  bool get showLeading => true;

  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) =>
      Colors.cyan[50];

  @override
  double getWidth() => MediaQuery.of(context).size.width - 30;

  @override
  AsyncValue<ResponseAsyncValue> get mainDataAsync =>
      ref.watch(findProductsByLocatorValueProvider);

  @override
  Future<void> setDefaultValuesOnInitState(
    BuildContext context,
    WidgetRef ref,
  ) async {
    isScanning = false;
    isDialogShowed = false;
    inputString = '';
    actionScan = actionScanTypeInt;
  }

  @override
  void executeAfterShown() {
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_BY_LOCATOR_VALUE_FOR_STOCK_DETAIL;
  }

  @override
  void initialSettingOnBuild(BuildContext context, WidgetRef ref) {}

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    // Mirror the input into the read-only TextField shown in the screen
    // header so a scan, manual dialog or URL launcher all converge on the
    // same provider before firing the search.
    ref.read(locatorValueInputProvider.notifier).state =
        inputData.trim().toUpperCase();

    final action = ref.read(findStorageByLocatorValueActionProvider);
    await action.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
    );
  }

  /// Re-fires the search with whatever is currently in
  /// [locatorValueInputProvider] / [productIdInputProvider]. Bound to the
  /// search button next to the locator TextField.
  Future<void> _runSearchFromInputs() async {
    final locator = ref.read(locatorValueInputProvider).trim();
    if (locator.isEmpty) return;
    final action = ref.read(findStorageByLocatorValueActionProvider);
    await action.handleInputString(
      ref: ref,
      inputData: locator,
      actionScan: actionScanTypeInt,
    );
  }

  Future<void> _openLocatorInputDialog() async {
    final current = ref.read(locatorValueInputProvider);
    final controller = TextEditingController(text: current);
    // Suppress scan dispatch while the dialog is open so a stray scan
    // doesn't re-fire the screen's search handler. Restored on dialog
    // close via finally (covers OK, Cancel, dismiss, and exceptions).
    final oldAction = ref.read(actionScanProvider);
    ref.read(actionScanProvider.notifier).state = 0;
    String? result;
    try {
      result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Locator Value'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'Scan or type'),
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(Messages.CANCEL),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: Text(Messages.OK),
            ),
          ],
        ),
      );
    } finally {
      ref.read(actionScanProvider.notifier).state = oldAction;
    }
    if (result == null) return;
    final code = result.trim();
    if (code.isEmpty) return;
    await handleInputString(
      ref: ref,
      inputData: code,
      actionScan: actionScanTypeInt,
    );
  }

  Future<void> _openProductIdInputDialog() async {
    final current = ref.read(productIdInputProvider);
    final controller =
        TextEditingController(text: current?.toString() ?? '');
    // Same scan-suppression pattern as _openLocatorInputDialog.
    final oldAction = ref.read(actionScanProvider);
    ref.read(actionScanProvider.notifier).state = 0;
    String? result;
    try {
      result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('M_Product_ID'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(hintText: 'Numeric id'),
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(Messages.CANCEL),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: Text(Messages.OK),
            ),
          ],
        ),
      );
    } finally {
      ref.read(actionScanProvider.notifier).state = oldAction;
    }
    if (result == null) return;
    final parsed = int.tryParse(result.trim());
    ref.read(productIdInputProvider.notifier).state = parsed;
  }

  void _clearProductId() {
    ref.read(productIdInputProvider.notifier).state = null;
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    return const Text(
      'Locator Detail',
      style: TextStyle(fontSize: themeFontSizeLarge),
    );
  }

  @override
  Widget getMainDataCard(BuildContext context, WidgetRef ref) {
    final width = getWidth();
    final locatorValue = ref.watch(locatorValueInputProvider);
    final productId = ref.watch(productIdInputProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Locator value input row — read-only TextField mirroring the
        // provider; tap opens manual dialog; search button re-fires.
        Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: _openLocatorInputDialog,
                child: AbsorbPointer(
                  child: TextField(
                    readOnly: true,
                    controller: TextEditingController(text: locatorValue),
                    decoration: const InputDecoration(
                      labelText: 'Locator',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.purple),
              tooltip: 'BUSCAR',
              onPressed: _runSearchFromInputs,
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Optional `M_Product_ID` filter row.
        Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: _openProductIdInputDialog,
                child: AbsorbPointer(
                  child: TextField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: productId?.toString() ?? '',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'M_Product_ID (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.purple),
              tooltip: Messages.CLEAR,
              onPressed: _clearProductId,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _DateRangeSection(),
        const SizedBox(height: 8),
        mainDataAsync.when(
          data: (response) {
            if (!response.isInitiated) {
              return _hint('Scan a locator value to start.');
            }
            if (response.success != true || response.data == null) {
              return _msgCard(response.message);
            }

            final raw = response.data;
            if (raw is! LocatorWithProductStocks) {
              return _msgCard(response.message);
            }

            return _LocatorBody(payload: raw, width: width);
          },
          error: (e, _) => _msgCard('Error: $e'),
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: LinearProgressIndicator(),
          ),
        ),
      ],
    );
  }

  Widget _hint(String text) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(text),
        ),
      ),
    );
  }

  Widget _msgCard(String? msg) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(msg ?? ''),
        ),
      ),
    );
  }
}

class _LocatorBody extends ConsumerWidget {
  const _LocatorBody({required this.payload, required this.width});

  final LocatorWithProductStocks payload;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productIdFilter = ref.watch(productIdInputProvider);

    // Sort by UPC before showing. We can't `$orderby=UPC` in the iDempiere
    // REST query (it errors), so the sort lives here on the client side.
    // The find function already sorts but we re-sort defensively in case
    // the source list ever arrives unordered.
    final sortedProducts = List<LocatorProductStock>.from(payload.products)
      ..sort((a, b) =>
          (a.product.uPC ?? '').compareTo(b.product.uPC ?? ''));

    // Split products into the user-requested match (if any) and the rest.
    LocatorProductStock? matching;
    final others = <LocatorProductStock>[];
    for (final ps in sortedProducts) {
      if (productIdFilter != null && ps.product.id == productIdFilter) {
        matching = ps;
      } else {
        others.add(ps);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Header(payload: payload),
        const SizedBox(height: 8),
        if (productIdFilter != null)
          _ProductIdFilterBanner(
            productId: productIdFilter,
            found: matching != null,
          ),
        if (productIdFilter != null) const SizedBox(height: 8),
        if (sortedProducts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No products with stock in this locator.'),
              ),
            ),
          )
        else if (matching != null) ...<Widget>[
          // Filter set + match found: show matching alone, hide rest in
          // an ExpansionTile labelled "Otros (N)".
          LocatorProductStockCard(
            key: ValueKey('lps-${matching.product.id}'),
            locator: payload.locator,
            productStock: matching,
            width: width,
            highlight: true,
          ),
          if (others.isNotEmpty) _OthersExpansionTile(
            locator: payload.locator,
            products: others,
            width: width,
          ),
        ] else ...<Widget>[
          // No filter (or filter set with no match): list every product
          // in UPC order. The banner above already conveys "not found".
          ...sortedProducts.map(
            (ps) => LocatorProductStockCard(
              key: ValueKey('lps-${ps.product.id}'),
              locator: payload.locator,
              productStock: ps,
              width: width,
            ),
          ),
        ],
      ],
    );
  }
}

/// Banner shown above the products list when the user has a
/// `M_Product_ID` filter set. Green when the matching product was found
/// in this locator; red when not.
class _ProductIdFilterBanner extends StatelessWidget {
  const _ProductIdFilterBanner({
    required this.productId,
    required this.found,
  });

  final int productId;
  final bool found;

  @override
  Widget build(BuildContext context) {
    final color = found ? Colors.green.shade100 : Colors.red.shade100;
    final icon = found ? Icons.check_circle : Icons.error_outline;
    final iconColor = found ? Colors.green.shade700 : Colors.red.shade700;
    final text = found
        ? 'Producto $productId encontrado en este locator'
        : 'Producto $productId NO está en este locator';

    return Card(
      color: color,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Collapsible group that hides the non-matching products when the user
/// has a `M_Product_ID` filter applied and the match was found.
class _OthersExpansionTile extends StatelessWidget {
  const _OthersExpansionTile({
    required this.locator,
    required this.products,
    required this.width,
  });

  final IdempiereLocator locator;
  final List<LocatorProductStock> products;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text('Otros (${products.length})'),
        children: products
            .map(
              (ps) => LocatorProductStockCard(
                key: ValueKey('lps-other-${ps.product.id}'),
                locator: locator,
                productStock: ps,
                width: width,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DateRangeSection extends ConsumerWidget {
  const _DateRangeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFrom = ref.watch(dateFromProvider);
    final dateTo = ref.watch(dateToProvider);

    return _DateRangeRow(
      dateFrom: dateFrom,
      dateTo: dateTo,
      onPickFrom: () => _pickDate(context, ref, isFrom: true),
      onPickTo: () => _pickDate(context, ref, isFrom: false),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref, {
    required bool isFrom,
  }) async {
    final initial =
        isFrom ? ref.read(dateFromProvider) : ref.read(dateToProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    if (isFrom) {
      ref.read(dateFromProvider.notifier).state =
          DateTime(picked.year, picked.month, picked.day);
    } else {
      ref.read(dateToProvider.notifier).state =
          DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.payload});

  final LocatorWithProductStocks payload;

  @override
  Widget build(BuildContext context) {
    final loc = payload.locator;
    final wh = loc.mWarehouseID;
    final coords = <String?>[loc.x, loc.y, loc.z]
        .where((s) => s != null && s.toString().trim().isNotEmpty)
        .map((s) => s.toString())
        .toList();

    return Card(
      color: Colors.cyan[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              loc.value ?? loc.name ?? '(no value)',
              style: const TextStyle(
                fontSize: themeFontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            if ((loc.name ?? '').trim().isNotEmpty &&
                (loc.value ?? '').trim() != (loc.name ?? '').trim())
              Text(loc.name ?? ''),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              children: <Widget>[
                if (wh != null)
                  Text('Warehouse: ${wh.name ?? wh.id}',
                      style: const TextStyle(fontSize: themeFontSizeSmall)),
                if (coords.isNotEmpty)
                  Text('XYZ: ${coords.join('-')}',
                      style: const TextStyle(fontSize: themeFontSizeSmall)),
                Text('Products: ${payload.products.length}',
                    style: const TextStyle(fontSize: themeFontSizeSmall)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  const _DateRangeRow({
    required this.dateFrom,
    required this.dateTo,
    required this.onPickFrom,
    required this.onPickTo,
  });

  final DateTime dateFrom;
  final DateTime dateTo;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('IP:'),
            ),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                onPressed: onPickFrom,
                label: Text('From  ${_fmt(dateFrom)}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                onPressed: onPickTo,
                label: Text('To  ${_fmt(dateTo)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
