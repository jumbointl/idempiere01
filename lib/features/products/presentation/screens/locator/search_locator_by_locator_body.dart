import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/locator_provider.dart';

import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';
import '../../widget/input_string_dialog.dart';
import 'locator_card.dart';


class SearchLocatorByLocatorBody extends ConsumerStatefulWidget {
  final bool searchLocatorFrom;
  final bool forCreateLine;
  const SearchLocatorByLocatorBody( {
    required this.forCreateLine,
    required this.searchLocatorFrom, super.key });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => SearchLocatorByLocatorBodyState();

}

class SearchLocatorByLocatorBodyState extends ConsumerState<SearchLocatorByLocatorBody> {
  late AsyncValue locatorListAsync;
  late String searchTip='';
  late String searchTip2='';
  @override
  Widget build(BuildContext context){
    searchTip = Messages.SEARCH_BY_LOCATOR_VALUE;
    locatorListAsync = ref.watch(findLocatorsListProvider);

    final double width = double.infinity;
    return Scaffold(

      body: Container(
        //margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.all(10),
        color: Colors.grey[200],
        width: width,
        child: Column(
          children: [
            getSearchBar(context),
            locatorListAsync.when(
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
        //width: double.infinity,
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
                InputStringDialog(title: Messages.FIND_LOCATOR, textStateProvider: scannedLocatorsListProvider, dialogType: Memory.TYPE_DIALOG_SEARCH),
                InputStringDialog(title: Messages.FIND_LOCATOR, textStateProvider: scannedLocatorsListProvider, dialogType: Memory.TYPE_DIALOG_HISTOY),

              ],
            ),
      );

  }


}