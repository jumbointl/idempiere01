import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/locator/search_locator_by_locator_body.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/locator/search_locator_by_warehouse_body.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
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
  @override
  Widget build(BuildContext context){
    int defaultTabIndex = 0;
     if(widget.readOnly ?? false){
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
              FocusScope.of(context).unfocus();

              if(widget.readOnly){
                ref.read(actionScanProvider.notifier).update((state) =>Memory.ACTION_GET_LOCATOR_FROM_VALUE);
              } else {
                ref.read(actionScanProvider.notifier).update((state) =>Memory.ACTION_GET_LOCATOR_TO_VALUE);
              }
              Navigator.pop(context);

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
            Navigator.pop(context);
          },
          child: TabBarView(
            children: [
              SearchLocatorByWarehouseBody(
                readOnly: widget.readOnly),
              SearchLocatorByLocatorBody(
                searchLocatorFrom: widget.readOnly,
                ),

           ]
          ),
        ),
      ),
    );
  }






}