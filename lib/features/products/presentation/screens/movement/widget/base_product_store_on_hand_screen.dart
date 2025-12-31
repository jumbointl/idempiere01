import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// English:
/// Base screen for Product Store On Hand flows.
/// This is NOT a concrete screen, only shared behavior.
abstract class BaseProductStoreOnHandScreen
    extends ConsumerStatefulWidget {
  const BaseProductStoreOnHandScreen({super.key});

  /// English: Scan action used by this screen
  int get actionScanTypeInt;

  /// English: Custom pop navigation logic
  void popScopeAction(BuildContext context, WidgetRef ref);
}
