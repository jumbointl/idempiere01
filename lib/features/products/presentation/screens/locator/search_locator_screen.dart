import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/locator/search_locator_by_locator_body.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/locator/search_locator_by_warehouse_body.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../common/scan_button_by_action_fixed_short.dart';
import '../../providers/common_provider.dart';
import '../../providers/locator_provider.dart';
import '../../providers/product_provider_common.dart';


class SearchLocatorScreen extends ConsumerStatefulWidget {
  String? title;
  final bool readOnly;

  SearchLocatorScreen( {required this.readOnly,
    this.title, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => SearchLocatorScreenState();


}

class SearchLocatorScreenState extends ConsumerState<SearchLocatorScreen> {
  late var resultState;
  late var textToSearch;
  late String searchTip='';
  late String searchTip2='';
  late final int oldAction;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldAction = ref.read(actionScanProvider);
      ref.read(actionScanProvider.notifier).state = Memory.ACTION_GET_LOCATOR_VALUE;
      ref.read(locatorScreenInputModeProvider.notifier).state = PrinterInputMode.manual;

    });

  }
  @override
  Widget build(BuildContext context) {
    final inputMode = ref.watch(locatorScreenInputModeProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: 1, // ✅ default tab = 1 (Locator)
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
          ),
          title: SegmentedButton<PrinterInputMode>(
            segments: const [
              ButtonSegment(
                value: PrinterInputMode.scan,
                label: Text('SCAN'),
                icon: Icon(Icons.qr_code_scanner, size: 16),
              ),
              ButtonSegment(
                value: PrinterInputMode.manual,
                label: Text('MANUAL'),
                icon: Icon(Icons.edit, size: 16),
              ),
            ],
            selected: {inputMode},
            onSelectionChanged: (set) {
              final mode = set.first;

              ref.read(locatorScreenInputModeProvider.notifier).state = mode;

              
            },
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 12),
              ),
            ),
          ),
          actions: [
            if (inputMode == PrinterInputMode.scan)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ScanButtonByActionFixedShort(
                  onOk: handleInputString,
                  actionTypeInt: Memory.ACTION_GET_LOCATOR_VALUE,
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(36),
            child: Row(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: '${Messages.BY} ${Messages.WAREHOUSE}'),
                    Tab(text: '${Messages.BY} ${Messages.LOCATOR}'),
                  ],
                  isScrollable: true,
                  indicatorWeight: 4,
                  indicatorColor: themeColorPrimary,
                  dividerColor: themeColorPrimary,
                  tabAlignment: TabAlignment.start,
                  labelStyle: TextStyle(
                    fontSize: themeFontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: themeColorPrimary,
                  ),
                  unselectedLabelStyle: TextStyle(fontSize: themeFontSizeLarge),
                ),
              ],
            ),
          ),
        ),
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) return;
            ref.read(actionScanProvider.notifier).state = Memory.ACTION_GET_LOCATOR_VALUE;
            Navigator.pop(context);
          },
          child: TabBarView(
            children: [
              SearchLocatorByWarehouseBody(readOnly: widget.readOnly),
              SearchLocatorByLocatorBody(readOnly: widget.readOnly),
            ],
          ),
        ),
      ),
    );
  }

// ✅ handleInputString: escribe en provider según tab actual
  void handleInputString({
    required int actionScan,
    required String inputData,
    required WidgetRef ref,
  }) {
    if (actionScan != Memory.ACTION_GET_LOCATOR_VALUE) return;

    final value = inputData.trim();
    if (value.isEmpty) return;

    final tabController = DefaultTabController.of(context);
    final tabIndex = tabController.index; // fallback a Locator

    if (tabIndex == 0) {
      // Warehouse
      ref.read(filterWarehouseValueForSearchLocatorProvider.notifier).state = value;
      ref.read(fireWarehouseSearchLocatorProvider.notifier).state++;
    } else {
      // Locator
      ref.read(scannedLocatorsListProvider.notifier).state = value;
      ref.read(fireSearchLocatorListProvider.notifier).state++;
    }
  }

}