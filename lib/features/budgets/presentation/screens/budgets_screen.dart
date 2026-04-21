import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:xpense/core/haptics/haptic_service.dart';
import 'package:xpense/domain/entities/budget.dart';
import 'package:xpense/features/budgets/presentation/providers/budget_provider.dart';
import 'package:xpense/features/budgets/presentation/widgets/budget_progress_ring.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(budgetListNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: state.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return _EmptyState(
              onCreate: () => context.push('/budgets/add'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              return _BudgetCard(
                budget: budget,
                onTap: () => context.push('/budgets/add', extra: budget),
                onDelete: () => _confirmDelete(budget),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/budgets/add'),
        icon: const Icon(Icons.add),
        label: const Text('New Budget'),
      ),
    );
  }

  Future<void> _confirmDelete(Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to delete "${budget.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      HapticService.warning();
      await ref.read(budgetListNotifierProvider.notifier).delete(budget.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No budgets yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set spending limits to stay on track',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create Budget'),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({
    required this.budget,
    required this.onTap,
    required this.onDelete,
  });

  final Budget budget;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final spentAsync = ref.watch(budgetSpentProvider(budget.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              spentAsync.when(
                data: (spent) => BudgetProgressRing(
                  spentCents: spent,
                  totalCents: budget.amountCents,
                  size: 72,
                  strokeWidth: 6,
                ),
                loading: () => const SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(strokeWidth: 6),
                ),
                error: (_, __) => const SizedBox(width: 72, height: 72),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_periodLabel(budget.period)} · ${currency.format(budget.amountCents / 100)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _periodLabel(BudgetPeriod period) {
    return switch (period) {
      BudgetPeriod.daily => 'Daily',
      BudgetPeriod.weekly => 'Weekly',
      BudgetPeriod.monthly => 'Monthly',
      BudgetPeriod.custom => 'Custom',
    };
  }
}
