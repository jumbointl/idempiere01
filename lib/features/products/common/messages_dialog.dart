import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/data/messages.dart';

Future<void> showErrorMessage(BuildContext context, WidgetRef ref, String message) async {
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
    btnOkColor: Colors.red,
    btnCancelText: Messages.CANCEL,
    btnOkText: Messages.OK,
  ).show();
  return;
}

Future<void> showSuccessMessage(BuildContext context, WidgetRef ref, String message) async {
  if (!context.mounted) {
    await Future.delayed(const Duration(seconds: 1));
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
    btnOkColor: Colors.green,
    btnCancelText: Messages.CANCEL,
    btnOkText: Messages.OK,
  ).show();
  return;
}

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

Future<void> showWarningMessage(BuildContext context, WidgetRef ref, String message) async {
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
Future<void> showAutoCloseErrorDialog(BuildContext context, WidgetRef ref, String message,int seconds) async {
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

