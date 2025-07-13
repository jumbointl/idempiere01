import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class GetActionButton {
  Widget getActionButton(BuildContext context, WidgetRef ref);
  Future<void> fireActionButton(dynamic data, BuildContext context, WidgetRef ref);
}