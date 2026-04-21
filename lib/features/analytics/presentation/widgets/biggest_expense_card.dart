import 'package:flutter/material.dart';

import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/features/analytics/presentation/widgets/animated_count_up.dart';
import 'package:xpense/features/analytics/presentation/widgets/dashboard_card.dart';

/// Card showing the biggest expense of the current period.
class BiggestExpenseCard extends StatelessWidget {
  const BiggestExpenseCard({
    this.expense,
    this.onTap,
    super.key,
  });

  final Expense? expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MetricCardHeader(
            icon: Icons.receipt_long,
            label: 'Biggest Expense',
          ),
          const SizedBox(height: 8),
          if (expense == null)
            Text(
              'No expenses yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          else ...[
            CountUpCurrency(
              cents: expense!.amountCents,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              expense!.note ?? expense!.merchant ?? 'Unnamed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }
}
