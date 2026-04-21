import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import 'package:xpense/core/haptics/haptic_service.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/expense.dart';

/// Card displaying a single expense in the list with slide-to-edit and
/// slide-to-delete actions.
class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    required this.expense,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    this.isSelected,
    this.onToggleSelect,
    super.key,
  });

  final Expense expense;
  final Category? category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool? isSelected;
  final VoidCallback? onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = _hexToColor(category?.colorHex ?? '#6B7280');
    final icon = _iconFromName(category?.iconName ?? 'more_horiz');

    final displayTitle = (expense.note?.isNotEmpty ?? false)
        ? expense.note!
        : ((expense.merchant?.isNotEmpty ?? false)
            ? expense.merchant!
            : 'Expense');

    final displaySubtitle = [
      category?.name ?? 'Uncategorized',
      _formatDate(expense.date),
    ].join(' · ');

    final isRecurring = expense.recurringExpenseId != null;

    final amount = expense.amountCents / 100;
    final amountText = '\$${amount.toStringAsFixed(2)}';

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (isSelected != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggleSelect?.call(),
                ),
              ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: categoryColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displaySubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRecurring)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.repeat,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                Text(
                  amountText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (isSelected != null) {
      return GestureDetector(
        onLongPress: () {},
        onTap: onToggleSelect,
        child: card,
      );
    }

    return Slidable(
      key: ValueKey(expense.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticService.mediumImpact();
              onEdit();
            },
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: Icons.edit,
            label: 'Edit',
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
          ),
          SlidableAction(
            onPressed: (_) {
              HapticService.warning();
              onDelete();
            },
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(16),
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: () {
          HapticService.mediumImpact();
          onToggleSelect?.call();
        },
        child: card,
      ),
    );
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _iconFromName(String name) {
    return switch (name) {
      'restaurant' => Icons.restaurant,
      'directions_car' => Icons.directions_car,
      'shopping_bag' => Icons.shopping_bag,
      'movie' => Icons.movie,
      'bolt' => Icons.bolt,
      'favorite' => Icons.favorite,
      'school' => Icons.school,
      'flight' => Icons.flight,
      'receipt' => Icons.receipt,
      'card_giftcard' => Icons.card_giftcard,
      'more_horiz' => Icons.more_horiz,
      _ => Icons.category,
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(date.year, date.month, date.day);

    if (expenseDate == today) {
      return DateFormat.jm().format(date);
    } else if (expenseDate == yesterday) {
      return 'Yesterday, ${DateFormat.jm().format(date)}';
    } else {
      return DateFormat.MMMd().add_jm().format(date);
    }
  }
}
