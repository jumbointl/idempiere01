
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/src/pages/common/scanner.dart';

class UnfocusedScanButton extends ConsumerStatefulWidget {
  String scannedData = "";
  final Scanner scanner;
  UnfocusedScanButton({required this.scanner,super.key});

  @override
  ConsumerState<UnfocusedScanButton> createState() => UnfocusedScanButtonState();
}


class UnfocusedScanButtonState extends ConsumerState<UnfocusedScanButton> {


  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed:() {widget.scanner.scanButtonPressed(context, ref);},
        icon: Icon( Icons.barcode_reader, color: Colors.grey),
    );
  }
}
