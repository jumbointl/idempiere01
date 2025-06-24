import 'package:flutter/material.dart';
import 'package:monalisa_app_001/config/config.dart';

class EnterBarcodeBox extends StatefulWidget {
  final ValueChanged<String> onValue;
  final String hintText;
  const EnterBarcodeBox({
    super.key,
    required this.onValue,
    this.hintText = 'Enter barcode',
  });

  @override
  EnterBarcodeBoxState createState() => EnterBarcodeBoxState();
}

class EnterBarcodeBoxState extends State<EnterBarcodeBox> {
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outlineInputBorder = UnderlineInputBorder(
        borderSide: BorderSide(color: themeColorPrimary),
        borderRadius: BorderRadius.circular(10));
    final inputDecoration = InputDecoration(
        hintText: widget.hintText,
        enabledBorder: outlineInputBorder,
        focusedBorder: outlineInputBorder,
        fillColor: Colors.white,
        filled: true,
        prefixIcon: Icon(Icons.qr_code_scanner_rounded),
        suffixIcon: IconButton(
            icon: Icon(Icons.send_rounded),
            color: themeColorPrimary,
            onPressed: () {
              if (textController.text.isNotEmpty) {
                final textValue = textController.text;
                textController.clear();
                widget.onValue(textValue);
              }
              focusNode.requestFocus();
            }));
    return TextFormField(
      autofocus: true,
      focusNode: focusNode,
      onTapOutside: (event) {
        focusNode.unfocus();
      },
      controller: textController,
      decoration: inputDecoration,
      showCursor: true,
      onFieldSubmitted: (value) {
        if (value.isNotEmpty) {
          textController.clear();
          widget.onValue(value);
        }
        focusNode.requestFocus();
      },
    );
  }
}
