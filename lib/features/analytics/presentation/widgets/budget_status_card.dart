import 'package:flutter/material.dart';

import 'package:xpense/features/analytics/presentation/widgets/dashboard_card.dart';

/// Card summarizing overall budget health.
class BudgetStatusCard extends StatelessWidget {
  const BudgetStatusCard({
    required this.activeBudgetCount,
    required this.overBudgetCount,
    this.onTap,
    super.key,
  });

  final int activeBudgetCount;
  final int overBudgetCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (statusColor, statusText) = _status(
      activeBudgetCount,
      overBudgetCount,
      colorScheme,
    );

    return DashboardCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MetricCardHeader(
            icon: Icons.account_balance_wallet,
            label: 'Budgets',
          ),
          const SizedBox(height: 8),
          Text(
            '$activeBudgetCount',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                _statusIcon(activeBudgetCount, overBudgetCount),
                size: 14,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (Color, String) _status(
    int active,
    int over,
    ColorScheme colorScheme,
  ) {
    if (active == 0) return (colorScheme.outline, 'No budgets set');
    if (over > 0) return (Colors.red, '$over over budget');
    return (Colors.green, 'All on track');
  }

  IconData _statusIcon(int active, int over) {
    if (active == 0) return Icons.info;
    if (over > 0) return Icons.warning;
    return Icons.check_circle;
  }
}
