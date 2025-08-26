import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/movement_provider.dart';
import 'package:monalisa_app_001/src/pages/common/header_card.dart';
import 'package:monalisa_app_001/src/widgets/card_header_section.dart';

import '../../../features/products/presentation/providers/product_provider_common.dart';
import '../../../features/products/presentation/screens/movement/products_home_provider.dart';
import '../../../features/shared/data/messages.dart';
import '../../widgets/half_circle.dart';

class HeadersView extends ConsumerStatefulWidget {
  HeadersView({super.key});
  late var isLoading ;
  double headerCardHeight = 110.0;
  double headerCardWidth = double.infinity;
  @override
  ConsumerState<HeadersView> createState() => _HeadersViewState();

  Widget getHeaderCard(BuildContext context,WidgetRef ref) {
    headerCardWidth = MediaQuery.of(context).size.width-30 ;
    return HeaderCard(
        width: headerCardWidth,
        height: headerCardHeight,
        id: '123456789',
        bgColor: Colors.grey[800]!,
        amount: 105,
        titleRight: 'TO: LOCATOR',
        titleLeft: 'From: Test Card',
        expiry: '11/27');
  }
  Widget addPageTitle(BuildContext context,WidgetRef ref) {
        return Row(
          spacing: 5,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () {
                ref.read(usePhoneCameraToScanProvider.notifier).update((state) => false);
              },
              icon: Icon(Icons.history, size: 24.sp),
              color: Colors.purple,
              //color: Colors.white,
              /*style: IconButton.styleFrom(
              //backgroundColor: context.primaryColor.withValues(alpha: .15),
              backgroundColor: themeColorPrimary,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: context.primaryColor, width: 1),
              ),
             ), */
            ),
            IconButton(
              onPressed: () {
                ref.read(usePhoneCameraToScanProvider.notifier).update((state) => true);
              },
              icon: Icon(Icons.search, size: 24.sp),
              //color: context.primaryColor,
              color: Colors.purple,
              /*style: IconButton.styleFrom(
                //backgroundColor: context.primaryColor.withValues(alpha: .15),
                backgroundColor: themeColorPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: context.primaryColor, width: 1),
                ),
              ), */
            ),
            IconButton(
              onPressed: () {  },
              icon: Icon(Icons.add, size: 24.sp),
              //color: context.primaryColor,
              color: Colors.purple,
              /*style: IconButton.styleFrom(
                //backgroundColor: context.primaryColor.withValues(alpha: .15),
                backgroundColor: themeColorPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: context.primaryColor, width: 1),
                ),
              ), */
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                //padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: context.primaryColor, width: 1),
                ),
              ),
              child: Text(Messages.CONFIRM_SHORT, style: context.bodySmall.bold.k(context.titleInverse)),
            ),
          ],
    );
  }
}

class _HeadersViewState extends ConsumerState<HeadersView> {

  @override
  Widget build(BuildContext context) {
    widget.headerCardWidth = MediaQuery.of(context).size.width-30 ;
    widget.isLoading = ref.watch(productsHomeIsLoadingProvider);
    final AsyncValue asyncTable = ref.watch(findMovementLinesByMovementIdProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        //title: buildNewAppBar(context, child: widget.isLoading ? LinearProgressIndicator() : widget.addPageTitle(context,ref)),
        centerTitle: true,
        title: widget.addPageTitle(context,ref),

        bottom: PreferredSize(preferredSize: Size.fromHeight(widget.headerCardHeight.h),
        child: Column(
          children: [
            SizedBox(height:  10.h),
            widget.getHeaderCard(context,ref),
            SizedBox(height:  10.h),
          ],
        )),
    ),
      body: Container()//SingleChildScrollView(child: Center(child: Mo(asyncValue:asyncTable,width: widget.headerCardWidth))),
    );
  }

  Widget _buildYourBudget(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeaderSection(
            title: 'Your Budget',
            subtitle: 'for airpay card',
            trailing: Text(
              'Add Budget',
              style: context.bodyLarge.bold.k(context.primaryColor),
            ),
          ),
          16.s,
          Center(
            child: HalfCircleProgress(
              radius: 152,
              progress: 0.62,
              label: "\$42 / \$100",
              progressColor: context.primaryColor,
              backgroundColor: context.outline,
              widget: Container(
                margin: 32.mt,
                child: Column(
                  children: [
                    Icon(
                      TablerIcons.credit_card,
                      color: context.primaryColor,
                      size: 28.sp,
                    ),
                    10.s,
                    Text('You Spent', style: context.bodySmall.thin),
                    Text(7900.50.toDollar(), style: context.titleMedium.bold),
                    Text('of \$ 8,000.80', style: context.bodySmall.thin),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }





}
