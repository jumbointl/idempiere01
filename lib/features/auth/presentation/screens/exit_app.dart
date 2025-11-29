import 'package:flutter/material.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/messages.dart';

void exitApp(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(Messages.LEAVE_APP),
        content: Text(Messages.READY_TO_EXIT),
        actions: <Widget>[
          TextButton(
            child: Text(Messages.CANCEL),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(Messages.EXIT),
            onPressed: () async {
              await FlutterExitApp.exitApp();
            },
          ),
        ],
      );
    },
  );

  // Schedule a dismiss after 5 seconds
  Future.delayed(const Duration(seconds: 5), () {
    if(context.mounted){
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

  });
}