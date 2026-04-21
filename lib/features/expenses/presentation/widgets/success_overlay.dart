import 'package:flutter/material.dart';

/// A brief celebratory overlay shown after an expense is saved.
class SuccessOverlay extends StatefulWidget {
  const SuccessOverlay({super.key});

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.check_circle,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
