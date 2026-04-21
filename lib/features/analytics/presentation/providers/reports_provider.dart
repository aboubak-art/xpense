import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/expense.dart';

/// A date range for reports.
class ReportDateRange {
  const ReportDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get dayCount => end.difference(start).inDays + 1;

  bool get isSingleMonth =>
      start.year == end.year && start.month == end.month;
}

/// Notifier for the selected report date range.
class ReportDateRangeNotifier extends StateNotifier<ReportDateRange> {
  ReportDateRangeNotifier() : super(_thisMonth());

  static ReportDateRange _thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return ReportDateRange(start: start, end: end);
  }

  void setThisWeek() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final start = DateTime(now.year, now.month, now.day - (weekday - 1));
    final end = start.add(const Duration(days: 6));
    state = ReportDateRange(start: start, end: end);
  }

  void setThisMonth() {
    state = _thisMonth();
  }

  void setLastMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 0);
    state = ReportDateRange(start: start, end: end);
  }

  void setLast3Months() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, 0);
    final start = DateTime(now.year, now.month - 3, 1);
    state = ReportDateRange(start: start, end: end);
  }

  void setCustom(DateTime start, DateTime end) {
    state = ReportDateRange(start: start, end: end);
  }
}

final reportDateRangeProvider =
    StateNotifierProvider<ReportDateRangeNotifier, ReportDateRange>(
  (ref) => ReportDateRangeNotifier(),
);

/// Provider for expenses within the selected date range.
final reportExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final range = ref.watch(reportDateRangeProvider);
  final dao = ref.watch(expenseDaoProvider);
  return dao.getByDateRange(range.start, range.end);
});

/// Daily spending data point for trend chart.
class DailySpend {
  const DailySpend({required this.date, required this.amountCents});

  final DateTime date;
  final int amountCents;
}

/// Provider for daily spending trend.
final spendingTrendProvider = FutureProvider<List<DailySpend>>((ref) async {
  final range = ref.watch(reportDateRangeProvider);
  final expensesAsync = ref.watch(reportExpensesProvider);

  return expensesAsync.when(
    data: (expenses) {
      final totals = <String, int>{};
      for (final e in expenses) {
        final key = '${e.date.year}-${e.date.month}-${e.date.day}';
        totals[key] = (totals[key] ?? 0) + e.amountCents;
      }

      final result = <DailySpend>[];
      for (var i = 0; i <= range.end.difference(range.start).inDays; i++) {
        final date = range.start.add(Duration(days: i));
        final key = '${date.year}-${date.month}-${date.day}';
        result.add(DailySpend(date: date, amountCents: totals[key] ?? 0));
      }
      return result;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Category breakdown data point.
class CategoryBreakdown {
  const CategoryBreakdown({
    required this.category,
    required this.amountCents,
    required this.percentage,
  });

  final Category category;
  final int amountCents;
  final double percentage;
}

/// Provider for category breakdown.
final categoryBreakdownProvider =
    FutureProvider<List<CategoryBreakdown>>((ref) async {
  final expensesAsync = ref.watch(reportExpensesProvider);
  final categoryDao = ref.watch(categoryDaoProvider);

  final expenses = expensesAsync.when(
    data: (list) => list,
    loading: () => <Expense>[],
    error: (_, __) => <Expense>[],
  );
  if (expenses.isEmpty) return [];

  final categories = await categoryDao.getAll();
  final categoryMap = {for (final c in categories) c.id: c};

  final totals = <String, int>{};
  for (final e in expenses) {
    totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amountCents;
  }

  final totalSpend = totals.values.fold<int>(0, (sum, v) => sum + v);
  final breakdown = <CategoryBreakdown>[];
  for (final entry in totals.entries) {
    final cat = categoryMap[entry.key];
    if (cat != null) {
      breakdown.add(
        CategoryBreakdown(
          category: cat,
          amountCents: entry.value,
          percentage: totalSpend > 0 ? entry.value / totalSpend : 0,
        ),
      );
    }
  }
  breakdown.sort((a, b) => b.amountCents.compareTo(a.amountCents));
  return breakdown;
});

/// Cash flow data point.
class CashFlowData {
  const CashFlowData({
    required this.date,
    required this.incomeCents,
    required this.expenseCents,
  });

  final DateTime date;
  final int incomeCents;
  final int expenseCents;
}

/// Provider for cash flow (income vs expense over time).
final cashFlowProvider = FutureProvider<List<CashFlowData>>((ref) async {
  final range = ref.watch(reportDateRangeProvider);
  final expensesAsync = ref.watch(reportExpensesProvider);
  final categoryDao = ref.watch(categoryDaoProvider);

  final expenses = expensesAsync.when(
    data: (list) => list,
    loading: () => <Expense>[],
    error: (_, __) => <Expense>[],
  );
  if (expenses.isEmpty) return [];

  final categories = await categoryDao.getAll();
  final incomeCategoryIds = <String>{};
  for (final c in categories) {
    if (c.isIncome) incomeCategoryIds.add(c.id);
  }

  final incomeMap = <String, int>{};
  final expenseMap = <String, int>{};
  for (final e in expenses) {
    final key = '${e.date.year}-${e.date.month}-${e.date.day}';
    if (incomeCategoryIds.contains(e.categoryId)) {
      incomeMap[key] = (incomeMap[key] ?? 0) + e.amountCents;
    } else {
      expenseMap[key] = (expenseMap[key] ?? 0) + e.amountCents;
    }
  }

  final result = <CashFlowData>[];
  for (var i = 0; i <= range.end.difference(range.start).inDays; i++) {
    final date = range.start.add(Duration(days: i));
    final key = '${date.year}-${date.month}-${date.day}';
    result.add(
      CashFlowData(
        date: date,
        incomeCents: incomeMap[key] ?? 0,
        expenseCents: expenseMap[key] ?? 0,
      ),
    );
  }
  return result;
});

/// Merchant analysis data point.
class MerchantData {
  const MerchantData({
    required this.name,
    required this.amountCents,
    required this.transactionCount,
  });

  final String name;
  final int amountCents;
  final int transactionCount;
}

/// Provider for merchant analysis.
final merchantAnalysisProvider = FutureProvider<List<MerchantData>>((ref) async {
  final expensesAsync = ref.watch(reportExpensesProvider);

  final expenses = expensesAsync.when(
    data: (list) => list,
    loading: () => <Expense>[],
    error: (_, __) => <Expense>[],
  );
  if (expenses.isEmpty) return [];

  final merchants = <String, MerchantData>{};
  for (final e in expenses) {
    final name = e.merchant ?? e.note ?? 'Unnamed';
    final existing = merchants[name];
    if (existing != null) {
      merchants[name] = MerchantData(
        name: name,
        amountCents: existing.amountCents + e.amountCents,
        transactionCount: existing.transactionCount + 1,
      );
    } else {
      merchants[name] = MerchantData(
        name: name,
        amountCents: e.amountCents,
        transactionCount: 1,
      );
    }
  }

  final result = merchants.values.toList()
    ..sort((a, b) => b.amountCents.compareTo(a.amountCents));
  return result;
});
