import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';
import 'package:monalisa_app_001/src/components/navigation_bar.dart';
import 'package:monalisa_app_001/src/core/routes/route_export.dart';
import 'package:monalisa_app_001/src/pages/my_cards/cards_view.dart';
import 'package:monalisa_app_001/src/pages/dashboard/dashboard.dart';
import 'package:monalisa_app_001/src/pages/profile_page/profile_view.dart';
import 'package:monalisa_app_001/src/pages/statistics_page/statistic_view.dart';

import '../../../features/products/presentation/providers/product_provider_common.dart';


abstract class HomePageModel extends ConsumerStatefulWidget{
  HomePageModel({this.actionScanner,super.key});
  int pageLength = 4; // Adjusted to be total pages - 1 for zero-based indexing
  int indexOfScanButton = 2;
  int? actionScanner = 0;
  late var currentIndex;
  late var usePhoneCamera;
  @override
  ConsumerState<HomePageModel> createState() => HomePageModelState();
  AutoDisposeStateProvider<int> getIndexProvider();
  AutoDisposeStateProvider<int> getIsLoadingProvider();
  int getIndexOfScanButton();
  int getPageLength();
  List<NavItemData> getNavItemData(BuildContext context,WidgetRef ref){

    IconData icon = TablerIcons.list_details;
    /*if(ref.read(usePhoneCameraToScanProvider.notifier).state){
      icon = TablerIcons.barcode;
    }*/
    if(getIndexOfScanButton() == 0){
      icon = TablerIcons.barcode;
    }
    return [
      NavItemData(icon: TablerIcons.home, title: Messages.HOME),
      NavItemData(icon: TablerIcons.chart_dots, title: Messages.CHAR_DOTS),
      NavItemData(icon: TablerIcons.list_details, title: Messages.SCAN),
      NavItemData(icon: TablerIcons.wallet, title: Messages.WALLET),
      NavItemData(icon: TablerIcons.user, title: Messages.PROFILE),
    ];
  }
  List<Widget> getScreens() {
    return [
      Dashboard(),
      StatisticView(),
      CardsView(),
      ProfileView(),];
  }

  Color getIconColor(currentIndex, int i, WidgetRef ref) {
    if (currentIndex == i) {
      return Colors.purple;
    } else {
      return Colors.grey;
    }

  }

  void actionOnTap(BuildContext context,WidgetRef ref,int index);
  void button3Pressed(BuildContext context,WidgetRef ref);
  void showErrorMessage(BuildContext context, WidgetRef ref, String message) {
    if (!context.mounted) {
      Future.delayed(const Duration(seconds: 1));
      if(!context.mounted) return;
    }
    AwesomeDialog(
      context: context,
      animType: AnimType.scale,
      dialogType: DialogType.error,
      body: Center(child: Column(
        children: [
          Text(message,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),),
      title:  message,
      desc:   '',
      autoHide: const Duration(seconds: 3),
      btnOkOnPress: () {},
      btnOkColor: Colors.amber,
      btnCancelText: Messages.CANCEL,
      btnOkText: Messages.OK,
    ).show();
    return;
  }

}

class HomePageModelState extends ConsumerState<HomePageModel> {
  @override
  Widget build(BuildContext context) {
    widget.usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    widget.currentIndex = ref.watch(widget.getIndexProvider());
    final List<Widget> screens = widget.getScreens();
    widget.actionOnTap(context,ref,0);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: widget.currentIndex, children: screens),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: widget.currentIndex,

        onTap: (index) {

          widget.actionOnTap(context,ref,index);

          if (index == widget.indexOfScanButton) {
            // Handle QR Navigation Separately
            widget.button3Pressed(context,ref);
          } else {
            // Update selected tab
            ref.read(widget.getIndexProvider().notifier).state = index > 2
                ? index - 1
                : index;
          }
        },
        navItems: widget.getNavItemData(context,ref),
      ) ,
    );
  }




}
