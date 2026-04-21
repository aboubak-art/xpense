import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:xpense/core/utils/color_utils.dart';
import 'package:xpense/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:xpense/features/analytics/presentation/widgets/dashboard_card.dart';

/// Card showing top 3 spending categories with mini bar charts.
class TopCategoriesCard extends StatelessWidget {
  const TopCategoriesCard({
    required this.categories,
    this.onTap,
    super.key,
  });

  final List<CategorySpendMetric> categories;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MetricCardHeader(icon: Icons.category, label: 'Top Categories'),
          const SizedBox(height: 12),
          if (categories.isEmpty)
            Text(
              'No spending yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          else
            ...categories.map(
              (metric) => _CategoryBar(
                metric: metric,
                maxAmount: categories.first.amountCents,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.metric,
    required this.maxAmount,
  });

  final CategorySpendMetric metric;
  final int maxAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hexToColor(metric.category.colorHex);
    final pct = maxAmount > 0 ? metric.amountCents / maxAmount : 0.0;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.category.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                currency.format(metric.amountCents / 100),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
