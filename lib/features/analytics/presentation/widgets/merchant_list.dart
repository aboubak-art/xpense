import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:xpense/features/analytics/presentation/providers/reports_provider.dart';

/// List showing merchant spending analysis.
class MerchantList extends StatelessWidget {
  const MerchantList({
    required this.data,
    this.onMerchantTap,
    super.key,
  });

  final List<MerchantData> data;
  final void Function(MerchantData)? onMerchantTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final maxAmount = data.first.amountCents.toDouble();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final merchant = data[index];
        final pct = maxAmount > 0 ? merchant.amountCents / maxAmount : 0.0;

        return ListTile(
          onTap: () => onMerchantTap?.call(merchant),
          leading: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              '${index + 1}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(merchant.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(merchant.amountCents / 100),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${merchant.transactionCount} transactions',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
