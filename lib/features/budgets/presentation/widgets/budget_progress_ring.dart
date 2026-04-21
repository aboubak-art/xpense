import 'package:flutter/material.dart';

import 'package:xpense/core/utils/color_utils.dart';

/// Color-coded budget progress ring.
/// - green: 0-50%
/// - blue: 50-80%
/// - orange: 80-100%
/// - red: 100%+
class BudgetProgressRing extends StatelessWidget {
  const BudgetProgressRing({
    required this.spentCents,
    required this.totalCents,
    this.size = 80,
    this.strokeWidth = 8,
    this.showPercentage = true,
    super.key,
  });

  final int spentCents;
  final int totalCents;
  final double size;
  final double strokeWidth;
  final bool showPercentage;

  double get _progress => totalCents > 0 ? spentCents / totalCents : 0;

  Color get _progressColor {
    final pct = _progress;
    if (pct >= 1.0) return const Color(0xFFEF4444);
    if (pct >= 0.8) return const Color(0xFFF97316);
    if (pct >= 0.5) return const Color(0xFF3B82F6);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_progress * 100).clamp(0, 999).round();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: _progress.clamp(0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
            ),
          ),
          if (showPercentage)
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: size * 0.22,
                fontWeight: FontWeight.w700,
                color: _progressColor,
              ),
            ),
        ],
      ),
    );
  }
}
