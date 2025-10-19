import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/locator_provider.dart';

import '../movement/products_home_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';
import '../../widget/input_string_dialog.dart';
import 'locator_card.dart';


class SearchLocatorScreen extends ConsumerStatefulWidget {
  static const int TYPE_DIALOG_SEARCH = 1;
  static const int TYPE_DIALOG_SERACH_WAREHOUSES_DEFAULT_LOCATORS = 2;
  // send result to state provider to display selection
  final StateProvider resultStateProvider;
  // send text to future provider watched state provider, to activate search
  final StateProvider textToSearchStateProvider;
  String? title;
  final int typeOfDialog;

  SearchLocatorScreen( { required this.textToSearchStateProvider, required this.typeOfDialog,this.title, required this.resultStateProvider, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => SearchLocatorScreenState();


}

class SearchLocatorScreenState extends ConsumerState<SearchLocatorScreen> {
  late AsyncValue locatorAsync;
  late var resultState;
  late var textToSearch;
  late String searchTip='';
  late String searchTip2='';
  bool isSearchWarehouseDefaultLocator = false ;
  @override
  Widget build(BuildContext context){
    if(widget.title == null){
      switch (widget.typeOfDialog) {
        case SearchLocatorScreen.TYPE_DIALOG_SEARCH:
          widget.title = Messages.FIND_LOCATOR;
          searchTip = Messages.SEARCH_BY_LOCATOR_VALUE;
          break;
        case SearchLocatorScreen.TYPE_DIALOG_SERACH_WAREHOUSES_DEFAULT_LOCATORS:
          widget.title = Messages.DEFAULT_WAREHOUSES_LOCATOR;
          searchTip = Messages.SEARCH_BY_WAREHOUSE_VALUE;
          searchTip2 = Messages.ZERO_FOR_ALL;
          isSearchWarehouseDefaultLocator = true;
          break;
        default:
          widget.title = Messages.FIND_LOCATOR;
          searchTip = Messages.SEARCH_BY_LOCATOR_VALUE;
      }
    }
    switch (widget.typeOfDialog) {
      case SearchLocatorScreen.TYPE_DIALOG_SEARCH:
        locatorAsync = ref.watch(findLocatorsListProvider);
        break;
      case SearchLocatorScreen.TYPE_DIALOG_SERACH_WAREHOUSES_DEFAULT_LOCATORS:
        locatorAsync = ref.watch(findDefaultLocatorOfWarehouseByWarehouseNameProvider);
        break;
      default:
        locatorAsync = ref.watch(findLocatorsListProvider);

    }

    resultState = ref.watch(widget.resultStateProvider.notifier);
    textToSearch = ref.watch(widget.textToSearchStateProvider);
    final double width = MediaQuery.of(context).size.width - 30;
    final double bodyHeight = MediaQuery.of(context).size.height - 200;
    final isScanning = ref.watch(isScanningProvider);
    Color foreGroundProgressBar = Colors.purple;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading:IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => {
            FocusScope.of(context).unfocus(),
            ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.pageFromIndex,
            Navigator.pop(context),
            //dispose(),
          },
        ),
        title: Text(searchTip ?? Messages.LOCATORS),
        /*bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: isScanning
              ? LinearProgressIndicator(
            backgroundColor: Colors.cyan,
            color: foreGroundProgressBar,
            minHeight: 60,
          )
            : getSearchBar(context),
        ),*/
      ),
      body: PopScope(
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {

            return;
          }
          ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.pageFromIndex;
          Navigator.pop(context);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          width: width,
          height: bodyHeight,
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
                              forCreateLine: false,
                              searchLocatorFrom: false,
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
                if(isSearchWarehouseDefaultLocator) IconButton(onPressed: (){
                  ref.read(widget.textToSearchStateProvider.notifier).state = '0';
                },icon:  Icon(Icons.list_alt,color: Colors.purple,)),
                InputStringDialog(title: Messages.FIND_LOCATOR, textStateProvider: widget.textToSearchStateProvider, dialogType: Memory.TYPE_DIALOG_SEARCH),
                InputStringDialog(title: Messages.FIND_LOCATOR, textStateProvider: widget.textToSearchStateProvider, dialogType: Memory.TYPE_DIALOG_HISTOY),

              ],
            ),
      );

  }


}