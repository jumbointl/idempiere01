import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class SearchDialog {
  AutoDisposeStateProvider<String> getSearchStringProvider();
}