import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:xpense/features/analytics/presentation/providers/reports_provider.dart';

/// Line chart showing spending trend over time.
class TrendLineChart extends StatelessWidget {
  const TrendLineChart({
    required this.data,
    this.onSpotTap,
    super.key,
  });

  final List<DailySpend> data;
  final void Function(DailySpend)? onSpotTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final maxY = data
            .map((d) => d.amountCents / 100)
            .reduce((a, b) => a > b ? a : b)
            .ceil()
            .toDouble();

    return LineChart(
      LineChartData(
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
              interval: _xInterval,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                final date = data[index].date;
                return Text(
                  '${date.month}/${date.day}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              return FlSpot(
                e.key.toDouble(),
                e.value.amountCents / 100,
              );
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipBgColor: colorScheme.surfaceContainerHighest,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final spend = data[index];
                return LineTooltipItem(
                  '\$${(spend.amountCents / 100).toStringAsFixed(2)}',
                  theme.textTheme.labelMedium!.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
          touchCallback: (event, response) {
            if (event is FlTapUpEvent &&
                response != null &&
                response.lineBarSpots != null &&
                response.lineBarSpots!.isNotEmpty) {
              final index = response.lineBarSpots!.first.x.toInt();
              if (index >= 0 && index < data.length) {
                onSpotTap?.call(data[index]);
              }
            }
          },
        ),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY > 0 ? maxY * 1.2 : 10,
      ),
      duration: const Duration(milliseconds: 800),
    );
  }

  double get _xInterval {
    if (data.length <= 7) return 1;
    if (data.length <= 14) return 2;
    if (data.length <= 31) return 5;
    return (data.length / 6).ceil().toDouble();
  }
}
