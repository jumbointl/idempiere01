import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/data/messages.dart';

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

void showSuccessMessage(BuildContext context, WidgetRef ref, String message) {
  if (!context.mounted) {
    Future.delayed(const Duration(seconds: 1));
    if(!context.mounted) return;
  }
  AwesomeDialog(
    context: context,
    animType: AnimType.scale,
    dialogType: DialogType.success,
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
/*Future<void> showSuccessMessageThenGoTo({
  required WidgetRef ref,
  required String message,
  required String goToPage,
}) async {
  final BuildContext context = ref.context;

  if (!context.mounted) return;

  // Esperamos a que el bottom sheet se cierre
  await showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return FractionallySizedBox(
        heightFactor: 0.5,
        widthFactor: 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 40, color: Colors.green),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // ---- BOTÓN OK ----
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(sheetContext).pop(); // Cerrar bottom sheet
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    },
  );

  // Cuando el sheet ya se cerró, recién ahí navegamos
  if (!context.mounted) return;
  context.go(goToPage);
}*/




Future<void> showSuccessMessageThenGoTo({required WidgetRef ref,required String message,required String goToPage})  async{
  BuildContext context = ref.context ;
  if (!context.mounted) {
    Future.delayed(const Duration(microseconds: 500));
    if(!context.mounted) return;
  }
  AwesomeDialog(
    dismissOnTouchOutside: false,
    dismissOnBackKeyPress: false,
    context: context,
    animType: AnimType.scale,
    dialogType: DialogType.success,
    body: Center(child: Column(
      children: [
        Text(message,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    ),),
    title:  Messages.SUCCESS,
    desc:   '',
    btnOkOnPress: () {
      if(context.mounted) {
        context.go(goToPage);
      }
    },
    btnOkColor: Colors.amber,
    btnCancelText: Messages.CANCEL,
    btnOkText: Messages.OK,
  );
  return;
}

void showWarningMessage(BuildContext context, WidgetRef ref, String message) {
  if (!context.mounted) {
    Future.delayed(const Duration(seconds: 1));
    if(!context.mounted) return;
  }
  AwesomeDialog(
    context: context,
    animType: AnimType.scale,
    dialogType: DialogType.warning,
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
void showAutoCloseErrorDialog(BuildContext context, WidgetRef ref, String message,int seconds) {
  while (!context.mounted) {
    Future.delayed(const Duration(milliseconds: 500));

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
    autoHide: Duration(seconds: seconds),
    btnOkOnPress: () {},
    btnOkColor: Colors.amber,
    btnCancelText: Messages.CANCEL,
    btnOkText: Messages.OK,
  ).show();
  return;
}

