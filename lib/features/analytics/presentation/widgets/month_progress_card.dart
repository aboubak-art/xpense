import 'package:flutter/material.dart';

import 'package:xpense/features/analytics/presentation/widgets/animated_count_up.dart';

/// Card showing this month's spending with trend indicator.
class MonthProgressCard extends StatelessWidget {
  const MonthProgressCard({
    required this.monthSpendCents,
    required this.lastMonthSpendCents,
    this.onTap,
    super.key,
  });

  final int monthSpendCents;
  final int lastMonthSpendCents;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final trendUp = monthSpendCents > lastMonthSpendCents;
    final trendColor = trendUp ? Colors.orange : Colors.green;
    final trendIcon = trendUp ? Icons.trending_up : Icons.trending_down;

    final trendPercent = lastMonthSpendCents > 0
        ? ((monthSpendCents - lastMonthSpendCents) /
                lastMonthSpendCents *
                100)
            .abs()
            .round()
        : 0;

    return _DashboardCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'This Month',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CountUpCurrency(
            cents: monthSpendCents,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                trendIcon,
                size: 14,
                color: trendColor,
              ),
              const SizedBox(width: 4),
              Text(
                lastMonthSpendCents > 0
                    ? '$trendPercent% vs last month'
                    : 'No last month data',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: trendColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
