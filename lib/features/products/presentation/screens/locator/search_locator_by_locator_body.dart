import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/locator_provider.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../common/messages_dialog.dart';
import '../../providers/product_provider_common.dart';
import 'to_re_write/input_string_dialog.dart';
import 'locator_card.dart';

class SearchLocatorByLocatorBody extends ConsumerStatefulWidget {
  final bool readOnly;
  const SearchLocatorByLocatorBody({
    required this.readOnly,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      SearchLocatorByLocatorBodyState();
}

class SearchLocatorByLocatorBodyState
    extends ConsumerState<SearchLocatorByLocatorBody> {
  late final SelectedLocatorsNotifier _selectedLocatorsNotifier;
  late AsyncValue locatorListAsync;
  late String searchTip = '';
  late String searchTip2 = '';
  String _lastResultKey = '';
  @override
  void dispose() {
    if (widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectedLocatorsNotifier.clear();
      });

    }
    super.dispose();

  }
  @override
  void initState() {
    super.initState();
    _selectedLocatorsNotifier = ref.read(selectedLocatorsProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    searchTip = Messages.SEARCH_BY_LOCATOR_VALUE;
    locatorListAsync = ref.watch(findLocatorsListProvider);

    final double width = double.infinity;
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.grey[200],
        width: width,
        child: Column(
          children: [
            getSearchBar(context),

            // ✅ Toolbar multi-select (solo cuando readOnly)
            if (widget.readOnly)
              locatorListAsync.when(
                data: (locators) => _buildMultiSelectToolbar(context, locators),
                error: (_, _) => const SizedBox.shrink(),
                loading: () => const SizedBox(height: 8),
              ),

            locatorListAsync.when(
              data: (locators) {

                final resultKey = locators
                    .map<String>((e) => SelectedLocatorsNotifier.keyOf(e))
                    .where((String k) => k.isNotEmpty)
                    .join('|');

                if (widget.readOnly && resultKey != _lastResultKey) {
                  _lastResultKey = resultKey;

                  // ✅ limpiar selección al final del frame (evita setState durante build)
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(selectedLocatorsProvider.notifier).clear();
                  });
                }


                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  ref.read(isScanningProvider.notifier).update((state) => false);
                });

                return Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) => const SizedBox(height: 5),
                    itemCount: locators.length,
                    itemBuilder: (context, index) => Center(
                      child: LocatorCard(
                        readOnly: widget.readOnly,
                        data: locators[index],
                        width: width,
                        index: index,
                      ),
                    ),
                  ),
                );
              },
              error: (error, stackTrace) => Text('Error: $error'),
              loading: () => const LinearProgressIndicator(minHeight: 100),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectToolbar(BuildContext context, List<dynamic> locators) {
    final selected = ref.watch(selectedLocatorsProvider);
    final count = selected.length;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Column(

        children: [
          Text(
            'Seleccionados: $count',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          Row(
            children: [

              TextButton(
                onPressed: () =>
                    ref.read(selectedLocatorsProvider.notifier).selectAllFromList(locators),
                child: const Text('Todos'),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () => ref.read(selectedLocatorsProvider.notifier).clear(),
                child: const Text('Deseleccionar'),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Imprimir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                ),
                onPressed: () => _printSelectedLocators(context, locators),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _printSelectedLocators(BuildContext context, List<dynamic> locators) {
    final keys = ref.read(selectedLocatorsProvider);
    if (keys.isEmpty) {
      showWarningMessage(context, ref, 'No hay locators seleccionados');
      return;
    }

    final selectedList = <dynamic>[];
    for (final it in locators) {
      final k = SelectedLocatorsNotifier.keyOf(it);
      if (k.isNotEmpty && keys.contains(k)) selectedList.add(it);
    }

    if (selectedList.isEmpty) {
      showWarningMessage(context, ref, 'No hay locators válidos para imprimir');
      return;
    }

    final int oldAction = ref.read(actionScanProvider); // ✅ primero capturar
    ref.read(actionScanProvider.notifier).state = Memory.ACTION_FIND_PRINTER_BY_QR;

    context.push(
      AppRouter.PAGE_LOCATOR_PRINTER_SETUP,
      extra: {
        'data': selectedList, // ✅ lista
        'oldAction': oldAction,
      },
    );
  }

  Widget getSearchBar(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 30,
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 5,
        children: [
          Text(
            searchTip2,
            style: const TextStyle(color: Colors.purple),
            textAlign: TextAlign.right,
          ),
          InputStringDialog(
            title: Messages.FIND_LOCATOR,
            textStateProvider: scannedLocatorsListProvider,
            fireActionProvider: fireSearchLocatorListProvider,
            dialogType: Memory.TYPE_DIALOG_SEARCH,
          ),
        ],
      ),
    );
  }
}