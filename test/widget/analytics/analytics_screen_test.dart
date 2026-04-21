import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/data/datasources/budget_dao.dart';
import 'package:xpense/data/datasources/category_dao.dart';
import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/domain/entities/budget.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:xpense/features/analytics/presentation/screens/analytics_screen.dart';

class _FakeBudgetDao implements BudgetDao {
  @override
  Future<List<Budget>> getAll() async => [];

  @override
  Future<Budget?> getById(String id) async => null;

  @override
  Future<Budget> create(BudgetInput input) async => throw UnimplementedError();

  @override
  Future<void> updateBudget(String id, BudgetInput input) async {}

  @override
  Future<void> deleteBudget(String id) async {}
}

class _FakeCategoryDao implements CategoryDao {
  @override
  Future<List<Category>> getAll({bool includeArchived = false}) async => [
    Category(
      id: 'cat_food',
      name: 'Food',
      iconName: 'restaurant',
      colorHex: '#EF4444',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
    Category(
      id: 'cat_transport',
      name: 'Transport',
      iconName: 'directions_car',
      colorHex: '#3B82F6',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
  ];

  @override
  Future<Category?> getById(String id) async => null;

  @override
  Future<Category> create(CategoryInput input) async => throw UnimplementedError();

  @override
  Future<void> updateCategory(String id, CategoryInput input) async {}

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<int> count() async => 2;

  @override
  Future<List<Category>> getSubcategories(String parentId) async => [];

  @override
  Future<void> toggleArchive(String id, bool isArchived) async {}

  @override
  Future<void> updateSortOrder(String id, int sortOrder) async {}
}

class _FakeExpenseDao implements ExpenseDao {
  @override
  Future<Expense> create(ExpenseInput input) async => throw UnimplementedError();

  @override
  Future<void> deleteExpense(String id) async {}

  @override
  Future<List<Expense>> getAll({int limit = 50, int offset = 0}) async => [];

  @override
  Future<Expense?> getById(String id) async => null;

  @override
  Future<List<Expense>> getByRecurringExpenseId(String recurringExpenseId) async => [];

  @override
  Future<List<Expense>> getByCategory(String categoryId) async => [];

  @override
  Future<List<Expense>> getByCategoryAndDateRange(
    String categoryId,
    DateTime start,
    DateTime end,
  ) async => [];

  @override
  Future<List<Expense>> getByDateRange(DateTime start, DateTime end) async => [];

  @override
  Future<void> updateExpense(String id, ExpenseInput input) async {}

  @override
  Future<int> totalAmountCentsByDateRange(DateTime start, DateTime end) async => 0;

  @override
  Future<List<Expense>> search(
    String query, {
    String? categoryId,
    String? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
    String sortBy = 'date',
    int limit = 50,
    int offset = 0,
  }) async => [];
}

void main() {
  group('AnalyticsScreen', () {
    Future<void> pumpAnalytics(WidgetTester tester, {DashboardMetrics? metrics}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            budgetDaoProvider.overrideWithValue(_FakeBudgetDao()),
            categoryDaoProvider.overrideWithValue(_FakeCategoryDao()),
            expenseDaoProvider.overrideWithValue(_FakeExpenseDao()),
            if (metrics != null)
              dashboardMetricsProvider.overrideWith((ref) async => metrics),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/analytics',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const Scaffold(body: Text('Home')),
                ),
                GoRoute(
                  path: '/analytics',
                  builder: (_, __) => const AnalyticsScreen(),
                ),
                GoRoute(
                  path: '/budgets',
                  builder: (_, __) => const Scaffold(body: Text('Budgets')),
                ),
                GoRoute(
                  path: '/categories',
                  builder: (_, __) => const Scaffold(body: Text('Categories')),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders all dashboard cards with data', (tester) async {
      final metrics = DashboardMetrics(
        todaySpendCents: 1250,
        dailyAverageCents: 800,
        monthSpendCents: 15000,
        lastMonthSpendCents: 12000,
        topCategories: [
          CategorySpendMetric(
            category: Category(
              id: 'cat_food',
              name: 'Food',
              iconName: 'restaurant',
              colorHex: '#EF4444',
              createdAt: DateTime(2024),
              updatedAt: DateTime(2024),
            ),
            amountCents: 5000,
            percentage: 0.33,
          ),
        ],
        biggestExpense: Expense(
          id: 'exp_1',
          amountCents: 5000,
          categoryId: 'cat_food',
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          note: 'Grocery run',
        ),
        incomeCents: 20000,
        expenseCents: 15000,
        activeBudgetCount: 2,
        overBudgetCount: 0,
      );

      await pumpAnalytics(tester, metrics: metrics);

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Top Categories'), findsOneWidget);
      expect(find.text('Biggest Expense'), findsOneWidget);
      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text('Income vs Expense'), findsOneWidget);
    });

    testWidgets('shows empty states when no data', (tester) async {
      final metrics = DashboardMetrics(
        todaySpendCents: 0,
        dailyAverageCents: 0,
        monthSpendCents: 0,
        lastMonthSpendCents: 0,
        topCategories: const [],
        biggestExpense: null,
        incomeCents: 0,
        expenseCents: 0,
        activeBudgetCount: 0,
        overBudgetCount: 0,
      );

      await pumpAnalytics(tester, metrics: metrics);

      expect(find.text('No spending yet'), findsOneWidget);
      expect(find.text('No expenses yet'), findsOneWidget);
      expect(find.text('No data yet'), findsNWidgets(2));
      expect(find.text('No budgets set'), findsOneWidget);
    });

    testWidgets('navigates to home when Today card tapped', (tester) async {
      final metrics = DashboardMetrics(
        todaySpendCents: 1000,
        dailyAverageCents: 800,
        monthSpendCents: 10000,
        lastMonthSpendCents: 8000,
        topCategories: const [],
        biggestExpense: null,
        incomeCents: 0,
        expenseCents: 0,
        activeBudgetCount: 0,
        overBudgetCount: 0,
      );

      await pumpAnalytics(tester, metrics: metrics);

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('navigates to budgets when Budgets card tapped', (tester) async {
      final metrics = DashboardMetrics(
        todaySpendCents: 0,
        dailyAverageCents: 0,
        monthSpendCents: 0,
        lastMonthSpendCents: 0,
        topCategories: const [],
        biggestExpense: null,
        incomeCents: 0,
        expenseCents: 0,
        activeBudgetCount: 1,
        overBudgetCount: 0,
      );

      await pumpAnalytics(tester, metrics: metrics);

      await tester.tap(find.text('Budgets'));
      await tester.pumpAndSettle();

      expect(find.text('Budgets'), findsOneWidget);
    });
  });
}
