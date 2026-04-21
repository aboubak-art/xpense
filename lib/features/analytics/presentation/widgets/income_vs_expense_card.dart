import 'package:flutter/material.dart';

import 'package:xpense/features/analytics/presentation/widgets/animated_count_up.dart';

/// Card showing income vs expense summary with a visual bar.
class IncomeVsExpenseCard extends StatelessWidget {
  const IncomeVsExpenseCard({
    required this.incomeCents,
    required this.expenseCents,
    this.onTap,
    super.key,
  });

  final int incomeCents;
  final int expenseCents;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final total = incomeCents + expenseCents;
    final incomeRatio = total > 0 ? incomeCents / total : 0.0;
    final hasData = incomeCents > 0 || expenseCents > 0;

    return _DashboardCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Income vs Expense',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasData)
            Text(
              'No data yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
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
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Expanded(
                      flex: (incomeRatio * 100).round(),
                      child: const ColoredBox(
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      flex: ((1 - incomeRatio) * 100).round(),
                      child: const ColoredBox(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (incomeCents > 0)
              Text(
                'Saved ${_savingsRate(incomeCents, expenseCents)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ],
      ),
    );
  }

  int _savingsRate(int income, int expense) {
    if (income <= 0) return 0;
    return ((income - expense) / income * 100).round().clamp(0, 100);
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
