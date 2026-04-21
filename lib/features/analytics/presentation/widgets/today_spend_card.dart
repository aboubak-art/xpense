import 'package:flutter/material.dart';

import 'package:xpense/features/analytics/presentation/widgets/animated_count_up.dart';
import 'package:xpense/features/analytics/presentation/widgets/dashboard_card.dart';

/// Card showing today's spending vs daily average.
class TodaySpendCard extends StatelessWidget {
  const TodaySpendCard({
    required this.todaySpendCents,
    required this.dailyAverageCents,
    this.onTap,
    super.key,
  });

  final int todaySpendCents;
  final int dailyAverageCents;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isAboveAverage =
        dailyAverageCents > 0 && todaySpendCents > dailyAverageCents;
    final comparisonColor = isAboveAverage ? Colors.orange : Colors.green;

    final comparisonText = dailyAverageCents > 0
        ? '${isAboveAverage ? '+' : ''}${_pctDiff(todaySpendCents, dailyAverageCents)}% vs avg'
        : 'No data yet';

    return DashboardCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MetricCardHeader(icon: Icons.today, label: 'Today'),
          const SizedBox(height: 8),
          CountUpCurrency(
            cents: todaySpendCents,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isAboveAverage ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: comparisonColor,
              ),
              const SizedBox(width: 4),
              Text(
                comparisonText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: comparisonColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _pctDiff(int current, int baseline) {
    if (baseline == 0) return 0;
    return ((current - baseline) / baseline * 100).round();
  }
}
