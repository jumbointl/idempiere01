import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/no_data_create_state.dart';
class NoDataPutAwayCreatedCard extends ConsumerStatefulWidget {
  final double width ;
  const NoDataPutAwayCreatedCard({required this.width,super.key});

  @override
  ConsumerState<NoDataPutAwayCreatedCard> createState() => NoDataPutAwayCreatedCardState();
}

class NoDataPutAwayCreatedCardState extends NoDataCreateState<NoDataPutAwayCreatedCard> {

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      children: [
        Icon(Icons.error,size: 100,color: Colors.red,),
        Text(Messages.NO_DATA_CREATED, overflow: TextOverflow.ellipsis,),
        TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
            ),
            onPressed: (){

              action(context, ref);


            },
            child: Text(Messages.BACK,style: TextStyle(fontSize: themeFontSizeLarge,
                color: Colors.white,fontWeight: FontWeight.bold),))
      ],
    ),);
  }

  @override
  void action(BuildContext context, WidgetRef ref) {
    //ref.invalidate(startedCreateNewPutAwayMovementProvider);
    if (context.mounted) {
      DateTime now = DateTime.now();
      String today =   now.toIso8601String();
      String movementDateFilter = today.substring(0,10);
      context.go('${AppRouter.PAGE_MOVEMENTS_LIST}/$movementDateFilter');
    }
  }

}