import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/domain/entities/budget.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/expense.dart';

/// Metrics for a single category's spending.
class CategorySpendMetric {
  const CategorySpendMetric({
    required this.category,
    required this.amountCents,
    required this.percentage,
  });

  final Category category;
  final int amountCents;
  final double percentage;
}

/// Dashboard metrics data class.
class DashboardMetrics {
  const DashboardMetrics({
    required this.todaySpendCents,
    required this.dailyAverageCents,
    required this.monthSpendCents,
    required this.lastMonthSpendCents,
    required this.topCategories,
    required this.biggestExpense,
    required this.incomeCents,
    required this.expenseCents,
    required this.activeBudgetCount,
    required this.overBudgetCount,
  });

  final int todaySpendCents;
  final int dailyAverageCents;
  final int monthSpendCents;
  final int lastMonthSpendCents;
  final List<CategorySpendMetric> topCategories;
  final Expense? biggestExpense;
  final int incomeCents;
  final int expenseCents;
  final int activeBudgetCount;
  final int overBudgetCount;

  bool get monthTrendUp => monthSpendCents > lastMonthSpendCents;

  double get monthTrendPercent {
    if (lastMonthSpendCents == 0) return 0;
    return (monthSpendCents - lastMonthSpendCents) / lastMonthSpendCents;
  }

  double get savingsRate {
    if (incomeCents == 0) return 0;
    return (incomeCents - expenseCents) / incomeCents;
  }
}

/// Provider that computes all dashboard metrics.
final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  final expenseDao = ref.watch(expenseDaoProvider);
  final categoryDao = ref.watch(categoryDaoProvider);
  final budgetDao = ref.watch(budgetDaoProvider);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart
      .add(const Duration(days: 1))
      .subtract(const Duration(seconds: 1));

  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 1)
      .subtract(const Duration(seconds: 1));

  final lastMonthStart = DateTime(now.year, now.month - 1, 1);
  final lastMonthEnd = DateTime(now.year, now.month, 1)
      .subtract(const Duration(seconds: 1));

  // Fetch independent data concurrently
  final results = await Future.wait([
    expenseDao.totalAmountCentsByDateRange(todayStart, todayEnd),
    expenseDao.getByDateRange(
      todayStart.subtract(const Duration(days: 30)),
      todayEnd,
    ),
    expenseDao.getByDateRange(monthStart, monthEnd),
    expenseDao.totalAmountCentsByDateRange(lastMonthStart, lastMonthEnd),
    categoryDao.getAll(),
    budgetDao.getAll(),
  ]);

  final todaySpendCents = results[0] as int;
  final last30DaysExpenses = results[1] as List<Expense>;
  final monthExpenses = results[2] as List<Expense>;
  final lastMonthSpendCents = results[3] as int;
  final categories = results[4] as List<Category>;
  final budgets = results[5] as List<Budget>;

  // Daily average
  final last30DaysTotal = last30DaysExpenses.fold<int>(
    0,
    (sum, e) => sum + e.amountCents,
  );
  final uniqueDays = <String>{};
  for (final e in last30DaysExpenses) {
    uniqueDays.add('${e.date.year}-${e.date.month}-${e.date.day}');
  }
  final dailyAverageCents = uniqueDays.isEmpty
      ? 0
      : (last30DaysTotal / uniqueDays.length).round();

  // Month total
  final monthSpendCents = monthExpenses.fold<int>(
    0,
    (sum, e) => sum + e.amountCents,
  );

  // Categories mapping
  final categoryMap = {for (final c in categories) c.id: c};

  // Top 3 categories
  final categoryTotals = <String, int>{};
  for (final e in monthExpenses) {
    categoryTotals[e.categoryId] =
        (categoryTotals[e.categoryId] ?? 0) + e.amountCents;
  }
  final sortedCategories = categoryTotals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topCategories = <CategorySpendMetric>[];
  for (final entry in sortedCategories.take(3)) {
    final cat = categoryMap[entry.key];
    if (cat != null) {
      topCategories.add(
        CategorySpendMetric(
          category: cat,
          amountCents: entry.value,
          percentage: monthSpendCents > 0 ? entry.value / monthSpendCents : 0,
        ),
      );
    }
  }

  // Biggest expense
  Expense? biggestExpense;
  for (final e in monthExpenses) {
    if (biggestExpense == null || e.amountCents > biggestExpense.amountCents) {
      biggestExpense = e;
    }
  }

  // Income vs expense
  var incomeCents = 0;
  var expenseCents = 0;
  for (final e in monthExpenses) {
    final cat = categoryMap[e.categoryId];
    if (cat != null && cat.isIncome) {
      incomeCents += e.amountCents;
    } else {
      expenseCents += e.amountCents;
    }
  }

  // Budget status — compute concurrently per budget
  var activeBudgetCount = 0;
  var overBudgetCount = 0;
  final budgetFutures = <Future<(bool, int)>>[];
  for (final budget in budgets) {
    activeBudgetCount++;
    final (start, end) = _budgetPeriodBounds(budget, now);
    budgetFutures.add(
      _budgetSpent(
        expenseDao: expenseDao,
        budget: budget,
        start: start,
        end: end,
      ),
    );
  }
  final budgetResults = await Future.wait(budgetFutures);
  for (final (isOver, _) in budgetResults) {
    if (isOver) overBudgetCount++;
  }

  return DashboardMetrics(
    todaySpendCents: todaySpendCents,
    dailyAverageCents: dailyAverageCents,
    monthSpendCents: monthSpendCents,
    lastMonthSpendCents: lastMonthSpendCents,
    topCategories: topCategories,
    biggestExpense: biggestExpense,
    incomeCents: incomeCents,
    expenseCents: expenseCents,
    activeBudgetCount: activeBudgetCount,
    overBudgetCount: overBudgetCount,
  );
});

Future<(bool, int)> _budgetSpent({
  required ExpenseDao expenseDao,
  required Budget budget,
  required DateTime start,
  required DateTime end,
}) async {
  int spent;
  if (budget.categoryId != null) {
    final expenses = await expenseDao.getByCategoryAndDateRange(
      budget.categoryId!,
      start,
      end,
    );
    spent = expenses.fold<int>(0, (sum, e) => sum + e.amountCents);
  } else {
    final expenses = await expenseDao.getByDateRange(start, end);
    spent = expenses.fold<int>(0, (sum, e) => sum + e.amountCents);
  }
  return (spent > budget.amountCents, spent);
}

(DateTime, DateTime) _budgetPeriodBounds(Budget budget, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);

  switch (budget.period) {
    case BudgetPeriod.daily:
      final end = today
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));
      return (today, end);
    case BudgetPeriod.weekly:
      final daysSinceStart = today.difference(budget.startDate).inDays;
      final weekStart = today.subtract(Duration(days: daysSinceStart % 7));
      final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final end = start
          .add(const Duration(days: 7))
          .subtract(const Duration(seconds: 1));
      return (start, end);
    case BudgetPeriod.monthly:
      final daysSinceStart = today.difference(budget.startDate).inDays;
      final monthsSinceStart = daysSinceStart ~/ 30;
      final startMonth = DateTime(
        budget.startDate.year,
        budget.startDate.month + monthsSinceStart,
        budget.startDate.day,
      );
      final start = DateTime(startMonth.year, startMonth.month, startMonth.day);
      final endMonth =
          DateTime(startMonth.year, startMonth.month + 1, startMonth.day);
      final end = endMonth.subtract(const Duration(seconds: 1));
      return (start, end);
    case BudgetPeriod.custom:
      final end = budget.endDate ?? today;
      return (budget.startDate, end);
  }
}
