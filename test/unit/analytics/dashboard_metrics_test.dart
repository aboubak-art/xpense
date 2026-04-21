import 'package:flutter_test/flutter_test.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/features/analytics/presentation/providers/analytics_provider.dart';

void main() {
  group('DashboardMetrics', () {
    final foodCategory = Category(
      id: 'cat_food',
      name: 'Food',
      iconName: 'restaurant',
      colorHex: '#EF4444',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    final transportCategory = Category(
      id: 'cat_transport',
      name: 'Transport',
      iconName: 'directions_car',
      colorHex: '#3B82F6',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    test('monthTrendUp returns true when current month > last month', () {
      final metrics = DashboardMetrics(
        todaySpendCents: 100,
        dailyAverageCents: 50,
        monthSpendCents: 5000,
        lastMonthSpendCents: 4000,
        topCategories: const [],
        biggestExpense: null,
        incomeCents: 10000,
        expenseCents: 5000,
        activeBudgetCount: 2,
        overBudgetCount: 0,
      );

      expect(metrics.monthTrendUp, isTrue);
    });

    test('monthTrendUp returns false when current month < last month', () {
      final metrics = DashboardMetrics(
        todaySpendCents: 100,
        dailyAverageCents: 50,
        monthSpendCents: 3000,
        lastMonthSpendCents: 4000,
        topCategories: const [],
        biggestExpense: null,
        incomeCents: 10000,
        expenseCents: 3000,
        activeBudgetCount: 2,
        overBudgetCount: 0,
      );

      expect(metrics.monthTrendUp, isFalse);
    });

    test('monthTrendPercent calculates correctly', () {
      final metrics = DashboardMetrics(
        todaySpendCents: 100,
        dailyAverageCents: 50,
        monthSpendCents: 5000,
        lastMonthSpendCents: 4000,
        topCategories: const [],
        biggestExpense: null,
        incomeCents: 0,
        expenseCents: 0,
        activeBudgetCount: 0,
        overBudgetCount: 0,
      );

      expect(metrics.monthTrendPercent, closeTo(0.25, 0.001));
    });

    test('monthTrendPercent returns 0 when last month is 0', () {
      final metrics = DashboardMetrics(
        todaySpendCents: 100,
        dailyAverageCents: 50,
        monthSpendCents: 5000,
        lastMonthSpendCents: 0,
        topCategories: const [],
        biggestExpense: null,
        incomeCents: 0,
        expenseCents: 0,
        activeBudgetCount: 0,
        overBudgetCount: 0,
      );

      expect(metrics.monthTrendPercent, 0);
    });

    test('savingsRate calculates correctly', () {
      final metrics = DashboardMetrics(
        todaySpendCents: 0,
        dailyAverageCents: 0,
        monthSpendCents: 0,
        lastMonthSpendCents: 0,
        topCategories: const [],
        biggestExpense: null,
        incomeCents: 10000,
        expenseCents: 3000,
        activeBudgetCount: 0,
        overBudgetCount: 0,
      );

      expect(metrics.savingsRate, closeTo(0.7, 0.001));
    });

    test('savingsRate returns 0 when income is 0', () {
      final metrics = DashboardMetrics(
        todaySpendCents: 0,
        dailyAverageCents: 0,
        monthSpendCents: 0,
        lastMonthSpendCents: 0,
        topCategories: const [],
        biggestExpense: null,
        incomeCents: 0,
        expenseCents: 3000,
        activeBudgetCount: 0,
        overBudgetCount: 0,
      );

      expect(metrics.savingsRate, 0);
    });

    test('CategorySpendMetric holds correct values', () {
      final metric = CategorySpendMetric(
        category: foodCategory,
        amountCents: 5000,
        percentage: 0.5,
      );

      expect(metric.category.id, 'cat_food');
      expect(metric.amountCents, 5000);
      expect(metric.percentage, 0.5);
    });
  });
}
