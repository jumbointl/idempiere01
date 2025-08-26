import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/locator_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/locator/search_locator_by_locator_body.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/locator/search_locator_by_warehouse_body.dart';

import '../../../../../config/theme/app_theme.dart';
import '../movement/products_home_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';


class SearchLocatorScreen extends ConsumerStatefulWidget {
  String? title;
  final bool searchLocatorFrom;

  SearchLocatorScreen( {required this.searchLocatorFrom,this.title, super.key});

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
     if(widget.searchLocatorFrom ?? false){
       //ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_GET_LOCATOR_FROM_VALUE);
       defaultTabIndex = 0;
     } else {
       //ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_GET_LOCATOR_TO_VALUE);
     }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Optionally, add a delay before calling DefaultTabController.of(context)?.animateTo
        /*if(defaultTabIndex>0){
          Future.delayed(Duration(milliseconds: 100), () {
            DefaultTabController.of(context).animateTo(defaultTabIndex);
          });
        }*/
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading:IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              FocusScope.of(context).unfocus();

              ref.read(isLocatorScreenShowedProvider.notifier).state = false;
              print('------------------ memory pagefrom ${Memory.pageFromIndex}');
              if(widget.searchLocatorFrom){
                ref.read(actionScanProvider.notifier).update((state) =>Memory.ACTION_GET_LOCATOR_FROM_VALUE);
              } else {
                ref.read(actionScanProvider.notifier).update((state) =>Memory.ACTION_GET_LOCATOR_TO_VALUE);
              }
              ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.pageFromIndex;
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
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) {

              return;
            }
            print('------------------ memory pagefrom ${Memory.pageFromIndex}');
            ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.pageFromIndex;
            ref.read(isLocatorScreenShowedProvider.notifier).state = false;
            Navigator.pop(context);
          },
          child: TabBarView(
            children: [
              SearchLocatorByWarehouseBody(
                searchLocatorFrom: widget.searchLocatorFrom),
              //Center(child: Text(Messages.NOT_IMPLEMENTED)),
              SearchLocatorByLocatorBody(
                searchLocatorFrom: widget.searchLocatorFrom,
                ),

           ]
          ),
        ),
      ),
    );
  }






}