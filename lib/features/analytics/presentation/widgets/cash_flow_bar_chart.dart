import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:xpense/features/analytics/presentation/providers/reports_provider.dart';

/// Bar chart showing income vs expense over time.
class CashFlowBarChart extends StatelessWidget {
  const CashFlowBarChart({
    required this.data,
    this.onBarTap,
    super.key,
  });

  final List<CashFlowData> data;
  final void Function(CashFlowData)? onBarTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final maxAmount = data
        .map((d) => [d.incomeCents, d.expenseCents].reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final maxY = (maxAmount / 100).ceilToDouble();

    // Group data by week if range > 14 days
    final groupedData = _groupData(data);

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY > 0 ? maxY / 4 : 1,
              getTitlesWidget: (value, _) {
                return Text(
                  '\$${value.toInt()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: groupedData.length > 10
                  ? (groupedData.length / 6).ceil().toDouble()
                  : 1,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= groupedData.length) {
                  return const SizedBox.shrink();
                }
                final date = groupedData[index].date;
                return Text(
                  '${date.month}/${date.day}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: groupedData.asMap().entries.map((e) {
          final index = e.key;
          final item = e.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item.incomeCents / 100,
                color: Colors.green,
                width: 8,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: item.expenseCents / 100,
                color: Colors.red,
                width: 8,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipBgColor: colorScheme.surfaceContainerHighest,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final isIncome = rodIndex == 0;
              return BarTooltipItem(
                '${isIncome ? 'Income' : 'Expense'}: '
                '\$${(rod.toY).toStringAsFixed(2)}',
                theme.textTheme.labelMedium!.copyWith(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          touchCallback: (event, response) {
            if (event is FlTapUpEvent &&
                response != null &&
                response.spot != null) {
              final index = response.spot!.touchedBarGroupIndex;
              if (index >= 0 && index < groupedData.length) {
                onBarTap?.call(groupedData[index]);
              }
            }
          },
        ),
        minY: 0,
        maxY: maxY > 0 ? maxY * 1.2 : 10,
      ),
    );
  }

  List<CashFlowData> _groupData(List<CashFlowData> data) {
    if (data.length <= 14) return data;

    final result = <CashFlowData>[];
    const groupSize = 7;
    for (var i = 0; i < data.length; i += groupSize) {
      var income = 0;
      var expense = 0;
      final end = (i + groupSize < data.length) ? i + groupSize : data.length;
      for (var j = i; j < end; j++) {
        income += data[j].incomeCents;
        expense += data[j].expenseCents;
      }
      result.add(
        CashFlowData(
          date: data[i].date,
          incomeCents: income,
          expenseCents: expense,
        ),
      );
    }
    return result;
  }
}
