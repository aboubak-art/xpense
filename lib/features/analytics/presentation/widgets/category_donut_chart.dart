import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:xpense/core/utils/color_utils.dart';
import 'package:xpense/features/analytics/presentation/providers/reports_provider.dart';

/// Donut chart showing category spending breakdown.
class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({
    required this.data,
    this.onSectionTap,
    super.key,
  });

  final List<CategoryBreakdown> data;
  final void Function(CategoryBreakdown)? onSectionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: data.asMap().entries.map((e) {
                  final item = e.value;
                  final color = hexToColor(item.category.colorHex);
                  return PieChartSectionData(
                    color: color,
                    value: item.amountCents.toDouble(),
                    title: '',
                    radius: 50,
                    badgeWidget: item.percentage >= 0.15
                        ? _PercentageBadge(
                            percentage: item.percentage,
                            color: color,
                          )
                        : null,
                    badgePositionPercentageOffset: 1.1,
                  );
                }).toList(),
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent &&
                        response != null &&
                        response.touchedSection != null) {
                      final index = response.touchedSection!.touchedSectionIndex;
                      if (index >= 0 && index < data.length) {
                        onSectionTap?.call(data[index]);
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.take(5).map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: hexToColor(item.category.colorHex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.category.name,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(item.percentage * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PercentageBadge extends StatelessWidget {
  const _PercentageBadge({
    required this.percentage,
    required this.color,
  });

  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${(percentage * 100).round()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
