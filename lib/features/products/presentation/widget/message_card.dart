import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../../config/theme/app_theme.dart';
class MessageCard extends ConsumerStatefulWidget {
  Color? backgroundColor;
  String message;
  String title;
  String subtitle;

  MessageCard({super.key,
    this.backgroundColor,
    required this.message,
    required this.title,
    required this.subtitle,
  });


  @override
  ConsumerState<MessageCard> createState() => NoDataCardState();
}

class NoDataCardState extends ConsumerState<MessageCard> {

  @override
  Widget build(BuildContext context) {



    Color color = Colors.grey[200]!;
    Color textColor = Colors.purple;
    IconData icon = Icons.warning;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
      child:  Column(
              spacing: 5,
              children: [
                Text(widget.title, style: TextStyle(fontSize: themeFontSizeNormal,
                    fontWeight: FontWeight.bold,color: Colors.black),),
                ListTile(
                  leading: Icon(Symbols.barcode, size: 30, color: textColor,),
                  title:Text(widget.subtitle, style: TextStyle(fontSize: themeFontSizeSmall,
                      fontWeight: FontWeight.bold,color: Colors.black),),

                ),ListTile(
                  leading: Icon(Symbols.arrow_back, size: 30, color: textColor,),
                  title:Text(widget.message, style: TextStyle(fontSize: themeFontSizeSmall,
                      fontWeight: FontWeight.bold,color: Colors.black),),

                ),


              ],
            ),
    );
  }
}