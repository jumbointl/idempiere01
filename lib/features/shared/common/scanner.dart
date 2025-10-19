import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class Scanner{
  void inputFromScanner(String scannedData);
  void scanButtonPressed(BuildContext context, WidgetRef ref);

}