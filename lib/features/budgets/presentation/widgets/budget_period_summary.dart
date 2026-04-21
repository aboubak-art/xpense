import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:xpense/domain/entities/budget.dart';
import 'package:xpense/features/budgets/presentation/providers/budget_provider.dart';

/// End-of-period budget summary card.
class BudgetPeriodSummary extends ConsumerWidget {
  const BudgetPeriodSummary({required this.budget, super.key});

  final Budget budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final spentAsync = ref.watch(budgetSpentProvider(budget.id));

    return spentAsync.when(
      data: (spent) {
        final remaining = budget.amountCents - spent;
        final pct = budget.amountCents > 0
            ? (spent / budget.amountCents).clamp(0.0, 1.0)
            : 0.0;
        final isOver = remaining < 0;

        final (statusText, statusColor) = switch (pct) {
          >= 1.0 => ('Over budget', Colors.red),
          >= 0.8 => ('Near limit', Colors.orange),
          >= 0.5 => ('On track', Colors.blue),
          _ => ('Under budget', Colors.green),
        };

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryItem(
                        label: 'Budget',
                        value: currency.format(budget.amountCents / 100),
                      ),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        label: 'Spent',
                        value: currency.format(spent / 100),
                        valueColor: theme.colorScheme.error,
                      ),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        label: isOver ? 'Over' : 'Left',
                        value: currency.format(remaining.abs() / 100),
                        valueColor: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0, 1.0),
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
