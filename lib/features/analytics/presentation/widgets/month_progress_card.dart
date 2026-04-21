import 'package:flutter/material.dart';

import 'package:xpense/features/analytics/presentation/widgets/animated_count_up.dart';
import 'package:xpense/features/analytics/presentation/widgets/dashboard_card.dart';

/// Card showing this month's spending with trend indicator.
class MonthProgressCard extends StatelessWidget {
  const MonthProgressCard({
    required this.monthSpendCents,
    required this.monthTrendPercent,
    required this.monthTrendUp,
    this.onTap,
    super.key,
  });

  final int monthSpendCents;
  final double monthTrendPercent;
  final bool monthTrendUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendColor = monthTrendUp ? Colors.orange : Colors.green;
    final trendIcon = monthTrendUp ? Icons.trending_up : Icons.trending_down;

    final trendPercent = monthTrendPercent.abs() * 100;
    final hasLastMonthData = monthTrendPercent != 0 || monthSpendCents == 0;

    return DashboardCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MetricCardHeader(
            icon: Icons.calendar_month,
            label: 'This Month',
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
              Icon(trendIcon, size: 14, color: trendColor),
              const SizedBox(width: 4),
              Text(
                hasLastMonthData
                    ? '${trendPercent.round()}% vs last month'
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
