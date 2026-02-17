import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/locator/search_locator_by_locator_body.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/locator/search_locator_by_warehouse_body.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';

class SearchLocatorDialog extends ConsumerStatefulWidget {
  String? title;
  final bool readOnly;
  final bool forCreateLine;
  SearchLocatorDialog({
    required this.readOnly,
    required this.forCreateLine,
    this.title,
    super.key});

  @override
  ConsumerState<SearchLocatorDialog> createState() => SearchLocatorDialogState();


}

class SearchLocatorDialogState extends ConsumerState<SearchLocatorDialog> {

 late int actionScanType ;
  late int oldAction;
  @override
  Widget build(BuildContext context){
    if(widget.readOnly){
      actionScanType = Memory.ACTION_GET_LOCATOR_VALUE ;
    } else {
      actionScanType = Memory.ACTION_NO_SCAN_ACTION ;
    }
    oldAction = ref.read(actionScanProvider);
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
                    Tab(text:'${Messages.BY} ${Messages.LOCATOR}',),
                  ],
                  labelColor: Colors.purple,
                  unselectedLabelColor: Colors.grey,
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
                    readOnly: widget.readOnly),
                SearchLocatorByLocatorBody(
                  readOnly: widget.readOnly,
                ),

              ]
          ),
        ),
      ),
    );
  }

  void popScopeAction(BuildContext context, WidgetRef ref) {
    FocusScope.of(context).unfocus();
    ref.read(actionScanProvider.notifier).update((state) =>oldAction);
    Navigator.pop(context);
  }



}
