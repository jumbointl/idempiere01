import 'package:flutter/material.dart';

import '../../domain/idempiere/response_async_value_ui_model.dart';

class ResponseAsyncValueMessagesCardAnimated extends StatelessWidget {
  final ResponseAsyncValueUiModel ui;

  const ResponseAsyncValueMessagesCardAnimated({
    super.key,
    required this.ui,
  });

  @override
  Widget build(BuildContext context) {
    // English comment: "KeyedSubtree guarantees AnimatedSwitcher sees a 'different child' per state"
    return Column(
      spacing: 10,
      children: [
        _AnimatedIcon(ui: ui),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            // English comment: "Fade + slight slide for a soft state transition"
            final fade = FadeTransition(opacity: animation, child: child);

            final slide = SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: fade,
            );

            return slide;
          },
          child: KeyedSubtree(
            key: ValueKey<ResponseUiState>(ui.state),
            child: _AnimatedShell(ui: ui),
          ),
        ),
      ],
    );
  }
}

class _AnimatedShell extends StatelessWidget {
  final ResponseAsyncValueUiModel ui;

  const _AnimatedShell({required this.ui});

  @override
  Widget build(BuildContext context) {
    // English comment: "AnimatedContainer smooths color/border changes without manual controllers"
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: ui.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ui.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: _CardBody(ui: ui),
    );
  }
}

class _CardBody extends StatelessWidget {
  final ResponseAsyncValueUiModel ui;

  const _CardBody({required this.ui});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [

            Expanded(
              child: Text(
                ui.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          ui.subtitle,
          style: const TextStyle(fontWeight: FontWeight.w500,color: Colors.white,),
        ),
        const SizedBox(height: 8),

        // English comment: "Scrollable message area with bounded height (safe inside parent ScrollView)"
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 120),
          child: SingleChildScrollView(
            child: Text(
              ui.message,
              style: const TextStyle(fontSize: 14,color: Colors.white,),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedIcon extends StatelessWidget {
  final ResponseAsyncValueUiModel ui;

  const _AnimatedIcon({required this.ui});

  @override
  Widget build(BuildContext context) {
    // English comment: "Idle state gets a subtle pulse to suggest 'waiting'"
    if (ui.state == ResponseUiState.idle) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.95, end: 1.0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        // English comment: "Restart pulse each rebuild without needing a controller"
        onEnd: () {},
        child: Icon(ui.icon, size: 48, color: ui.borderColor),
      );
    }

    // English comment: "Other states just animate color/size changes smoothly"
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Icon(ui.icon, size: 48, color: ui.borderColor),
    );
  }
}
