import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Animates a numeric value counting up from zero to [value].
///
/// The [builder] receives the animated value as a double and should
/// format it for display (e.g. as currency).
class AnimatedCountUp extends StatefulWidget {
  const AnimatedCountUp({
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 1200),
    this.curve = Curves.easeOutCubic,
    super.key,
  });

  final double value;
  final Widget Function(BuildContext context, double animatedValue) builder;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedCountUp> createState() => _AnimatedCountUpState();
}

class _AnimatedCountUpState extends State<AnimatedCountUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCountUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final displayValue =
            _controller.isCompleted ? widget.value : _animation.value;
        return widget.builder(context, displayValue);
      },
    );
  }
}

/// A convenience widget that formats cents as currency with count-up.
class CountUpCurrency extends StatelessWidget {
  const CountUpCurrency({
    required this.cents,
    this.duration = const Duration(milliseconds: 1200),
    this.style,
    super.key,
  });

  final int cents;
  final Duration duration;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return AnimatedCountUp(
      value: cents / 100,
      duration: duration,
      builder: (context, value) {
        final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
        return Text(
          formatter.format(value),
          style: style,
        );
      },
    );
  }
}
