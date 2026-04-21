import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:xpense/features/analytics/presentation/providers/reports_provider.dart';
import 'package:xpense/features/analytics/presentation/widgets/calendar_heatmap.dart';
import 'package:xpense/features/analytics/presentation/widgets/cash_flow_bar_chart.dart';
import 'package:xpense/features/analytics/presentation/widgets/category_donut_chart.dart';
import 'package:xpense/features/analytics/presentation/widgets/merchant_list.dart';
import 'package:xpense/features/analytics/presentation/widgets/trend_line_chart.dart';

enum _ReportTab { trend, categories, cashFlow, calendar, merchants }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _ReportTab.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final range = ref.read(reportDateRangeProvider);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: range.start,
        end: range.end,
      ),
    );

    if (picked != null) {
      ref.read(reportDateRangeProvider.notifier).setCustom(
        picked.start,
        picked.end,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(reportDateRangeProvider);
    final dateFormat = DateFormat('MMM d');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Trend', icon: Icon(Icons.show_chart)),
            Tab(text: 'Categories', icon: Icon(Icons.pie_chart_outline)),
            Tab(text: 'Cash Flow', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Calendar', icon: Icon(Icons.calendar_today)),
            Tab(text: 'Merchants', icon: Icon(Icons.store)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date range selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _PresetChip(
                        label: 'This Week',
                        onTap: () => ref
                            .read(reportDateRangeProvider.notifier)
                            .setThisWeek(),
                      ),
                      _PresetChip(
                        label: 'This Month',
                        onTap: () => ref
                            .read(reportDateRangeProvider.notifier)
                            .setThisMonth(),
                      ),
                      _PresetChip(
                        label: 'Last Month',
                        onTap: () => ref
                            .read(reportDateRangeProvider.notifier)
                            .setLastMonth(),
                      ),
                      _PresetChip(
                        label: '3 Months',
                        onTap: () => ref
                            .read(reportDateRangeProvider.notifier)
                            .setLast3Months(),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _showDateRangePicker,
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(
                    '${dateFormat.format(range.start)} - ${dateFormat.format(range.end)}',
                  ),
                ),
              ],
            ),
          ),

          // Chart area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _ReportTab.values.map((tab) => _buildTab(tab)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(_ReportTab tab) {
    switch (tab) {
      case _ReportTab.trend:
        return _TrendTab();
      case _ReportTab.categories:
        return _CategoriesTab();
      case _ReportTab.cashFlow:
        return _CashFlowTab();
      case _ReportTab.calendar:
        return _CalendarTab();
      case _ReportTab.merchants:
        return _MerchantsTab();
    }
  }
}

class _TrendTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(spendingTrendProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: trendAsync.when(
        data: (data) => TrendLineChart(
          data: data,
          onSpotTap: (spend) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${DateFormat('MMM d').format(spend.date)}: '
                  '\$${(spend.amountCents / 100).toStringAsFixed(2)}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(categoryBreakdownProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: breakdownAsync.when(
        data: (data) => CategoryDonutChart(
          data: data,
          onSectionTap: (item) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${item.category.name}: '
                  '\$${(item.amountCents / 100).toStringAsFixed(2)} '
                  '(${(item.percentage * 100).round()}%)',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CashFlowTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashFlowAsync = ref.watch(cashFlowProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: cashFlowAsync.when(
        data: (data) => CashFlowBarChart(
          data: data,
          onBarTap: (item) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${DateFormat('MMM d').format(item.date)}: '
                  'Income \$${(item.incomeCents / 100).toStringAsFixed(2)}, '
                  'Expense \$${(item.expenseCents / 100).toStringAsFixed(2)}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CalendarTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(spendingTrendProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: trendAsync.when(
        data: (data) => CalendarHeatmap(
          data: data,
          onDayTap: (spend) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${DateFormat('MMM d').format(spend.date)}: '
                  '\$${(spend.amountCents / 100).toStringAsFixed(2)}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _MerchantsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantsAsync = ref.watch(merchantAnalysisProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: merchantsAsync.when(
        data: (data) => MerchantList(
          data: data,
          onMerchantTap: (merchant) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${merchant.name}: '
                  '\$${(merchant.amountCents / 100).toStringAsFixed(2)} '
                  'across ${merchant.transactionCount} transactions',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: colorScheme.outlineVariant),
    );
  }
}
