import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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