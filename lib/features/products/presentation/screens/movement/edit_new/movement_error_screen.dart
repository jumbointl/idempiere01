import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';

import '../../../../../shared/data/messages.dart';


class MovementErrorScreen extends ConsumerStatefulWidget {

  const MovementErrorScreen({super.key,});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>MovementErrorScreenState();

}

class MovementErrorScreenState extends ConsumerState<MovementErrorScreen> {

  @override
  Widget build(BuildContext context){



    String title ='${Messages.ERROR
    } : ${Messages.MOVEMENT}';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading:IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
            {
              context.pop(),
            }
          //
        ),
        title: Text(title, overflow: TextOverflow.ellipsis,),

      ),

      body: SafeArea(
        child: PopScope(
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) {
              return;
            }
            Navigator.pop(context);
          },
          child: SingleChildScrollView(
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Text(title,style: TextStyle(fontSize: themeFontSizeLarge,
                    color: Colors.red,fontWeight: FontWeight.bold) ,)
            ),
          ),
        ),
      ),
    );
  }

}