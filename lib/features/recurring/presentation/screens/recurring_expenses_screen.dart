import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xpense/core/haptics/haptic_service.dart';
import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/domain/entities/recurring_expense.dart';
import 'package:xpense/features/recurring/presentation/widgets/recurring_expense_form.dart';

final _recurringListProvider =
    FutureProvider.autoDispose<List<RecurringExpense>>((ref) async {
  final dao = ref.watch(recurringExpenseDaoProvider);
  return dao.getAll();
});

class RecurringExpensesScreen extends ConsumerWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recurringAsync = ref.watch(_recurringListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Expenses'),
      ),
      body: recurringAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState(colorScheme: colorScheme, theme: theme);
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _RecurringExpenseTile(
                item: item,
                onEdit: () => _showForm(context, ref, item: item),
                onDelete: () => _confirmDelete(context, ref, item),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Recurring'),
      ),
    );
  }

  Future<void> _showForm(
    BuildContext context,
    WidgetRef ref, {
    RecurringExpense? item,
  }) async {
    final result = await showModalBottomSheet<RecurringExpenseInput>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RecurringExpenseForm(expense: item),
    );

    if (result == null) return;

    final dao = ref.read(recurringExpenseDaoProvider);
    if (item != null) {
      await dao.updateRecurringExpense(item.id, result);
    } else {
      await dao.create(result);
    }
    ref.invalidate(_recurringListProvider);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RecurringExpense item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Expense'),
        content: const Text(
          'This will stop future occurrences from being generated. '
          'Existing expenses will not be deleted.',
        ),
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

    if (confirmed ?? false) {
      unawaited(HapticService.warning());
      await ref.read(recurringExpenseDaoProvider).deleteRecurringExpense(item.id);
      ref.invalidate(_recurringListProvider);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colorScheme, required this.theme});

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.repeat,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Recurring Expenses',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Set up recurring expenses like rent, subscriptions, '
              'or salaries so they are tracked automatically.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringExpenseTile extends StatelessWidget {
  const _RecurringExpenseTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringExpense item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _frequencyLabel {
    return switch (item.frequency) {
      RecurringFrequency.daily => 'Every day',
      RecurringFrequency.weekly => 'Every week',
      RecurringFrequency.biWeekly => 'Every 2 weeks',
      RecurringFrequency.monthly => 'Every month',
      RecurringFrequency.quarterly => 'Every 3 months',
      RecurringFrequency.yearly => 'Every year',
      RecurringFrequency.custom => 'Custom',
    };
  }

  String get _amountText {
    final amount = item.amountCents / 100;
    return '\$${amount.toStringAsFixed(2)}';
  }

  String get _title {
    return item.note?.isNotEmpty ?? false
        ? item.note!
        : (item.merchant?.isNotEmpty ?? false ? item.merchant! : 'Recurring');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.repeat, color: colorScheme.primary, size: 22),
        ),
        title: Text(
          _title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$_frequencyLabel · Started ${_formatDate(item.startDate)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          _amountText,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: onEdit,
        onLongPress: () {
          HapticService.mediumImpact();
          onDelete();
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(date.year, date.month, date.day);

    if (start == today) return 'today';
    if (start == today.subtract(const Duration(days: 1))) return 'yesterday';
    return '${date.month}/${date.day}/${date.year}';
  }
}
