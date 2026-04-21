import 'package:flutter/material.dart';

import 'package:xpense/features/analytics/presentation/widgets/animated_count_up.dart';
import 'package:xpense/features/analytics/presentation/widgets/dashboard_card.dart';

/// Card showing income vs expense summary with a visual bar.
class IncomeVsExpenseCard extends StatelessWidget {
  const IncomeVsExpenseCard({
    required this.incomeCents,
    required this.expenseCents,
    required this.savingsRate,
    this.onTap,
    super.key,
  });

  final int incomeCents;
  final int expenseCents;
  final double savingsRate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final total = incomeCents + expenseCents;
    final incomeRatio = total > 0 ? incomeCents / total : 0.0;
    final hasData = incomeCents > 0 || expenseCents > 0;

    return DashboardCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MetricCardHeader(
            icon: Icons.compare_arrows,
            label: 'Income vs Expense',
          ),
          const SizedBox(height: 12),
          if (!hasData)
            Text(
              'No data yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _AmountLabel(
                    label: 'Income',
                    cents: incomeCents,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _AmountLabel(
                    label: 'Expense',
                    cents: expenseCents,
                    color: Colors.red,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SplitBar(incomeRatio: incomeRatio),
            const SizedBox(height: 8),
            if (incomeCents > 0)
              Text(
                'Saved ${(savingsRate * 100).round().clamp(0, 100)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.incomeRatio});

  final double incomeRatio;

  @override
  Widget build(BuildContext context) {
    // Avoid rounding errors by using one flex derived from the other
    final incomeFlex = (incomeRatio * 100).round();
    final expenseFlex = 100 - incomeFlex;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            Expanded(
              flex: incomeFlex,
              child: const ColoredBox(color: Colors.green),
            ),
            Expanded(
              flex: expenseFlex,
              child: const ColoredBox(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountLabel extends StatelessWidget {
  const _AmountLabel({
    required this.label,
    required this.cents,
    required this.color,
    this.alignEnd = false,
  });

  final String label;
  final int cents;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        CountUpCurrency(
          cents: cents,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
