import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:xpense/domain/entities/budget.dart';
import 'package:xpense/features/budgets/presentation/providers/budget_provider.dart';
import 'package:xpense/features/budgets/presentation/widgets/budget_progress_ring.dart';

/// Horizontal scrolling budget summary shown on the home screen.
class BudgetSummaryBar extends ConsumerWidget {
  const BudgetSummaryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetListNotifierProvider);

    return budgetsAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: budgets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final budget = budgets[index];
              return _BudgetSummaryCard(budget: budget);
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BudgetSummaryCard extends ConsumerWidget {
  const _BudgetSummaryCard({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final spentAsync = ref.watch(budgetSpentProvider(budget.id));

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/budgets'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              spentAsync.when(
                data: (spent) => BudgetProgressRing(
                  spentCents: spent,
                  totalCents: budget.amountCents,
                  size: 56,
                  strokeWidth: 5,
                  showPercentage: false,
                ),
                loading: () => const SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(strokeWidth: 5),
                ),
                error: (_, __) => const SizedBox(width: 56, height: 56),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budget.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  spentAsync.when(
                    data: (spent) {
                      final remaining = budget.amountCents - spent;
                      final color = remaining < 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.outline;
                      return Text(
                        '${remaining >= 0 ? 'Left' : 'Over'}: ${currency.format(remaining.abs() / 100)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
