import 'package:flutter/material.dart';

import 'package:xpense/core/utils/color_utils.dart';
import 'package:xpense/features/analytics/presentation/providers/analytics_provider.dart';

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
    final colorScheme = theme.colorScheme;

    return _DashboardCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Top Categories',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (categories.isEmpty)
            Text(
              'No spending yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
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
                '\$${(metric.amountCents / 100).toStringAsFixed(0)}',
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
