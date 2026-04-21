import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xpense/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:xpense/features/analytics/presentation/widgets/biggest_expense_card.dart';
import 'package:xpense/features/analytics/presentation/widgets/budget_status_card.dart';
import 'package:xpense/features/analytics/presentation/widgets/income_vs_expense_card.dart';
import 'package:xpense/features/analytics/presentation/widgets/month_progress_card.dart';
import 'package:xpense/features/analytics/presentation/widgets/today_spend_card.dart';
import 'package:xpense/features/analytics/presentation/widgets/top_categories_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: metricsAsync.when(
        data: (metrics) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardMetricsProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TodaySpendCard(
                              todaySpendCents: metrics.todaySpendCents,
                              dailyAverageCents: metrics.dailyAverageCents,
                              onTap: () => context.push('/'),
                            ),
                          ),
                          Expanded(
                            child: MonthProgressCard(
                              monthSpendCents: metrics.monthSpendCents,
                              lastMonthSpendCents: metrics.lastMonthSpendCents,
                              onTap: () => context.push('/'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TopCategoriesCard(
                              categories: metrics.topCategories,
                              onTap: () => context.push('/categories'),
                            ),
                          ),
                          Expanded(
                            child: BiggestExpenseCard(
                              expense: metrics.biggestExpense,
                              onTap: () => context.push('/'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: BudgetStatusCard(
                              activeBudgetCount: metrics.activeBudgetCount,
                              overBudgetCount: metrics.overBudgetCount,
                              onTap: () => context.push('/budgets'),
                            ),
                          ),
                          Expanded(
                            child: IncomeVsExpenseCard(
                              incomeCents: metrics.incomeCents,
                              expenseCents: metrics.expenseCents,
                              onTap: () => context.push('/'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Failed to load dashboard: $e'),
            ],
          ),
        ),
      ),
    );
  }
}
