import 'package:flutter/material.dart';

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

    final isHealthy = overBudgetCount == 0 && activeBudgetCount > 0;
    final statusColor = isHealthy
        ? Colors.green
        : overBudgetCount > 0
            ? Colors.red
            : colorScheme.outline;

    final statusText = activeBudgetCount == 0
        ? 'No budgets set'
        : overBudgetCount > 0
            ? '$overBudgetCount over budget'
            : 'All on track';

    return _DashboardCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Budgets',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
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
                isHealthy
                    ? Icons.check_circle
                    : overBudgetCount > 0
                        ? Icons.warning
                        : Icons.info,
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
