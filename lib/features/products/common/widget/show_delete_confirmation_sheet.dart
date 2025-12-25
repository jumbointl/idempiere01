import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

import '../../../../config/router/app_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';

void showDeleteConfirmationSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Future<void> Function({required BuildContext context, required WidgetRef ref}) onConfirm,
}) {
  final screenHeight = MediaQuery.of(context).size.height * 0.8;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // permite ver el borde redondeado
    builder: (context) {
      return Container(
        height: screenHeight * 0.7,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,               // fondo del modal
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Consumer(
          builder: (context, ref, _) {

            return Column(
              spacing: 20,
              children: [
                Text(Messages.SLIDE_TO_CANCEL,style: TextStyle(color: Colors.red,
                    fontSize: themeFontSizeTitle,fontWeight: FontWeight.bold),),
                SizedBox(
                  height: 45,
                  width: double.infinity,
                  child: ConfirmationSlider(
                    height: 45,
                    backgroundColor: Colors.red[100]!,
                    backgroundColorEnd: Colors.red[800]!,
                    foregroundColor: Colors.red,
                    text: Messages.SLIDE_TO_CANCEL,
                    textStyle: TextStyle(
                      fontSize: themeFontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                    onConfirmation: () {
                      onConfirm(context: context, ref: ref);
                      /*print('MovementCancelScreenState card') ;
                      GoRouterHelper(context).go(
                          AppRouter.PAGE_MOVEMENTS_CANCEL_SCREEN,
                          extra: widget.movementAndLines);*/
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
