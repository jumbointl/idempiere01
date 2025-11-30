import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/providers/common_provider.dart';

class AppInitializerOverlay extends ConsumerWidget {
  final Widget child;

  const AppInitializerOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initializing = ref.watch(initializingProvider);

    return Stack(
      children: [
        child,
        if (initializing)
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
