import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/locator_provider.dart';

import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';
import '../../widget/input_string_dialog.dart';
import 'locator_card.dart';


class SearchLocatorByWarehouseBody extends ConsumerStatefulWidget {
  // send result to state provider to display selection
  String? title;
  final bool searchLocatorFrom;
  final bool forCreateLine;
  SearchLocatorByWarehouseBody( {
    required this.searchLocatorFrom,
    required this.forCreateLine,
    this.title,
    super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => SearchLocatorByWarehouseBodyState();


}

class SearchLocatorByWarehouseBodyState extends ConsumerState<SearchLocatorByWarehouseBody> {
  late AsyncValue locatorAsync;
  late var resultState;
  late var textToSearch;
  late String searchTip='';
  late String searchTip2='';
  bool isSearchWarehouseDefaultLocator = false ;
  @override
  Widget build(BuildContext context){
    widget.title = Messages.DEFAULT_WAREHOUSES_LOCATOR;
    searchTip = Messages.SEARCH_BY_WAREHOUSE_VALUE;
    searchTip2 = Messages.ZERO_FOR_ALL;
    isSearchWarehouseDefaultLocator = true;
    locatorAsync = ref.watch(findDefaultLocatorOfWarehouseByWarehouseNameProvider);

    final double width = MediaQuery.of(context).size.width;
    final double bodyHeight = MediaQuery.of(context).size.height - 100;
    return Scaffold(

      body: Container(
        //margin: const EdgeInsets.symmetric(horizontal: 15),
        width: width,
        height: bodyHeight,
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            getSearchBar(context),
            locatorAsync.when(
              data: (locators) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  ref.read(isScanningProvider.notifier).update((state) => false);
                });

                return Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) => SizedBox(height: 5,),
                    //shrinkWrap: true, // Important to prevent unbounded height
                    itemCount: locators.length,
                    itemBuilder: (context, index) =>Center(
                      child: Center(
                        child: LocatorCard(
                            forCreateLine: widget.forCreateLine,
                            searchLocatorFrom: widget.searchLocatorFrom,
                            data: locators[index],width: width,
                            index: index),
                      ),
                    ),

                  ),
                );
              },
              error: (error, stackTrace) => Text('Error: $error'),
              loading: () => const LinearProgressIndicator(minHeight: 100,),
            )
          ],
        ),
      ),
    );
  }



  Widget getSearchBar(BuildContext context){
    return  SizedBox(
        width: double.infinity,
        //width: MediaQuery.of(context).size.width - 25,
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
                IconButton(onPressed: (){
                  ref.read(filterWarehouseValueForSearchLocatorProvider.notifier).state = '0';
                },icon:  Icon(Icons.list_alt,color: Colors.purple,)),
                InputStringDialog(title: Messages.FIND_LOCATOR, textStateProvider: filterWarehouseValueForSearchLocatorProvider, dialogType: Memory.TYPE_DIALOG_SEARCH),
                InputStringDialog(title: Messages.FIND_LOCATOR, textStateProvider: filterWarehouseValueForSearchLocatorProvider, dialogType: Memory.TYPE_DIALOG_HISTOY),

              ],
            ),
      );

  }


}