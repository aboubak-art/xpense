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
import 'package:xpense/features/analytics/presentation/screens/reports_screen.dart';

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
  Future<int> count() async => 1;

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
  group('ReportsScreen', () {
    Future<void> pumpReports(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            budgetDaoProvider.overrideWithValue(_FakeBudgetDao()),
            categoryDaoProvider.overrideWithValue(_FakeCategoryDao()),
            expenseDaoProvider.overrideWithValue(_FakeExpenseDao()),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/reports',
              routes: [
                GoRoute(
                  path: '/reports',
                  builder: (_, __) => const ReportsScreen(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders with tab bar and date presets', (tester) async {
      await pumpReports(tester);

      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Trend'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Cash Flow'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Merchants'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Last Month'), findsOneWidget);
      expect(find.text('3 Months'), findsOneWidget);
    });

    testWidgets('switches tabs without errors', (tester) async {
      await pumpReports(tester);

      // Switch through all tabs — should not throw
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
      expect(find.text('Categories'), findsOneWidget);

      await tester.tap(find.text('Cash Flow'));
      await tester.pumpAndSettle();
      expect(find.text('Cash Flow'), findsOneWidget);

      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      expect(find.text('Calendar'), findsOneWidget);

      await tester.tap(find.text('Merchants'));
      await tester.pumpAndSettle();
      expect(find.text('Merchants'), findsOneWidget);
    });

    testWidgets('date preset chips update range', (tester) async {
      await pumpReports(tester);

      await tester.tap(find.text('This Week'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Last Month'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('3 Months'));
      await tester.pumpAndSettle();
    });
  });
}
