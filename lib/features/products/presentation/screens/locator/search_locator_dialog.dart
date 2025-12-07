import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/locator/search_locator_by_locator_body.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/locator/search_locator_by_warehouse_body.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';
import '../movement/provider/products_home_provider.dart';

class SearchLocatorDialog extends ConsumerStatefulWidget {
  String? title;
  final bool searchLocatorFrom;
  final bool forCreateLine;
  SearchLocatorDialog({
    required this.searchLocatorFrom,
    required this.forCreateLine,
    this.title,
    super.key});

  @override
  ConsumerState<SearchLocatorDialog> createState() => SearchLocatorDialogState();


}

class SearchLocatorDialogState extends ConsumerState<SearchLocatorDialog> {


  @override
  Widget build(BuildContext context){
    int defaultTabIndex = 0;
    if(widget.searchLocatorFrom ?? false){
      //ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_GET_LOCATOR_FROM_VALUE);
      defaultTabIndex = 0;
    } else {
      //ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_GET_LOCATOR_TO_VALUE);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading:IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              popScopeAction(context, ref);
            },
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(36),
            child: Row(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: '${Messages.BY} ${Messages.WAREHOUSE}'),
                    Tab(text:'${Messages.BY} ${Messages.LOCATOR}'),
                  ],
                  isScrollable: true,
                  indicatorWeight: 4,
                  indicatorColor: themeColorPrimary,
                  dividerColor: themeColorPrimary,
                  tabAlignment: TabAlignment.start,
                  labelStyle: TextStyle(
                      fontSize: themeFontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: themeColorPrimary),
                  unselectedLabelStyle: TextStyle(fontSize: themeFontSizeLarge),
                ),
              ],
            ),
          ),


        ),
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {

            if (didPop) {

              return;
            }
            popScopeAction(context, ref);

          },
          child: TabBarView(
              children: [
                SearchLocatorByWarehouseBody(
                    forCreateLine: widget.forCreateLine,
                    searchLocatorFrom: widget.searchLocatorFrom),
                //Center(child: Text(Messages.NOT_IMPLEMENTED)),
                SearchLocatorByLocatorBody(
                  forCreateLine: widget.forCreateLine,
                  searchLocatorFrom: widget.searchLocatorFrom,
                ),

              ]
          ),
        ),
      ),
    );
  }

  void popScopeAction(BuildContext context, WidgetRef ref) {
    FocusScope.of(context).unfocus();

    if(widget.searchLocatorFrom){
      ref.read(actionScanProvider.notifier).update((state) =>Memory.ACTION_GET_LOCATOR_FROM_VALUE);
    } else {
      ref.read(actionScanProvider.notifier).update((state) =>Memory.ACTION_GET_LOCATOR_TO_VALUE);
    }

    ref.read(usePhoneCameraToScanForLineProvider.notifier).state = MemoryProducts.lastUsePhoneCameraState ;
    ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND;
    Navigator.pop(context);
  }



}
