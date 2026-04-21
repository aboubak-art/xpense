import 'package:flutter/material.dart';

import 'package:xpense/features/analytics/presentation/providers/reports_provider.dart';

/// Calendar heatmap showing daily spending intensity.
class CalendarHeatmap extends StatelessWidget {
  const CalendarHeatmap({
    required this.data,
    this.onDayTap,
    super.key,
  });

  final List<DailySpend> data;
  final void Function(DailySpend)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final maxAmount = data
        .map((d) => d.amountCents)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final firstDay = data.first.date;
    final weekdayOffset = firstDay.weekday % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weekday labels
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: weekdayOffset + data.length,
          itemBuilder: (context, index) {
            if (index < weekdayOffset) {
              return const SizedBox.shrink();
            }
            final dataIndex = index - weekdayOffset;
            final spend = data[dataIndex];
            final intensity = maxAmount > 0
                ? (spend.amountCents / maxAmount).clamp(0.0, 1.0)
                : 0.0;

            return InkWell(
              onTap: () => onDayTap?.call(spend),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                decoration: BoxDecoration(
                  color: spend.amountCents > 0
                      ? colorScheme.primary.withValues(alpha: 0.1 + intensity * 0.9)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${spend.date.day}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: intensity > 0.5
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Less',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(width: 4),
            _LegendDot(color: colorScheme.primary.withValues(alpha: 0.1)),
            _LegendDot(color: colorScheme.primary.withValues(alpha: 0.4)),
            _LegendDot(color: colorScheme.primary.withValues(alpha: 0.7)),
            _LegendDot(color: colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              'More',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
