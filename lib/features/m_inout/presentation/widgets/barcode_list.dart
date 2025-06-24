import 'package:flutter/material.dart';
import 'package:monalisa_app_001/config/theme/app_theme.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/barcode.dart';

class BarcodeList extends StatefulWidget {
  final Barcode barcode;
  final VoidCallback onPressedrepetitions;
  final VoidCallback onPressedDelete;
  const BarcodeList({
    super.key,
    required this.barcode,
    required this.onPressedrepetitions,
    required this.onPressedDelete,
  });

  @override
  ScrollingTextWidgetState createState() => ScrollingTextWidgetState();
}

class ScrollingTextWidgetState extends State<BarcodeList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mueve el scroll al final cuando el widget se inicializa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: widget.barcode.coloring ? Colors.blue[100] : null,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Text(
                  widget.barcode.index.toString(),
                  style:
                      TextStyle(fontSize: themeFontSizeSmall, color: themeColorGray),
                ),
              ),
              Expanded(
                  child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.barcode.code.toString(),
                    style: TextStyle(fontSize: themeFontSizeLarge),
                  ),
                ),
              )),
              GestureDetector(
                onTap: widget.onPressedrepetitions,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    widget.barcode.repetitions.toString(),
                    style: TextStyle(fontSize: themeFontSizeLarge, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onPressedDelete,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.clear_rounded,
                    color: themeColorError,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 0),
      ],
    );
  }
}
