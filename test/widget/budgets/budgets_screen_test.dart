import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/data/datasources/budget_dao.dart';
import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/domain/entities/budget.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/features/budgets/presentation/screens/budgets_screen.dart';

class _FakeBudgetDao implements BudgetDao {
  final List<Budget> _budgets = [];
  int _nextId = 1;

  @override
  Future<List<Budget>> getAll() async {
    return _budgets.where((b) => b.deletedAt == null).toList();
  }

  @override
  Future<Budget?> getById(String id) async {
    try {
      return _budgets.firstWhere((b) => b.id == id && b.deletedAt == null);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Budget> create(BudgetInput input) async {
    final budget = Budget(
      id: 'budget_${_nextId++}',
      name: input.name,
      amountCents: input.amountCents,
      startDate: input.startDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      currency: input.currency,
      period: input.period,
      categoryId: input.categoryId,
      endDate: input.endDate,
      rolloverUnused: input.rolloverUnused,
      alertThresholdPercent: input.alertThresholdPercent,
    );
    _budgets.add(budget);
    return budget;
  }

  @override
  Future<void> updateBudget(String id, BudgetInput input) async {
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index >= 0) {
      _budgets[index] = _budgets[index].copyWith(
        name: input.name,
        amountCents: input.amountCents,
        startDate: input.startDate,
        period: input.period,
        categoryId: input.categoryId,
        endDate: input.endDate,
        rolloverUnused: input.rolloverUnused,
        alertThresholdPercent: input.alertThresholdPercent,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    final index = _budgets.indexWhere((b) => b.id == id);
    if (index >= 0) {
      _budgets[index] = _budgets[index].copyWith(deletedAt: DateTime.now());
    }
  }
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
  Future<List<Expense>> getByCategory(String categoryId) async => [];

  @override
  Future<List<Expense>> getByDateRange(DateTime start, DateTime end) async => [];

  @override
  Future<List<Expense>> getByRecurringExpenseId(String recurringExpenseId) async => [];

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

  @override
  Future<List<Expense>> getByCategoryAndDateRange(
    String categoryId,
    DateTime start,
    DateTime end,
  ) async => [];
}

void main() {
  group('BudgetsScreen', () {
    late _FakeBudgetDao fakeBudgetDao;

    setUp(() {
      fakeBudgetDao = _FakeBudgetDao();
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            budgetDaoProvider.overrideWithValue(fakeBudgetDao),
            expenseDaoProvider.overrideWithValue(_FakeExpenseDao()),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const BudgetsScreen(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows empty state when no budgets', (tester) async {
      await pumpScreen(tester);

      expect(find.text('No budgets yet'), findsOneWidget);
      expect(find.text('Set spending limits to stay on track'), findsOneWidget);
      expect(find.text('Create Budget'), findsOneWidget);
    });

    testWidgets('displays budgets in list', (tester) async {
      await fakeBudgetDao.create(
        BudgetInput(
          name: 'Groceries',
          amountCents: 50000,
          startDate: DateTime.now(),
        ),
      );

      await pumpScreen(tester);

      expect(find.text('Groceries'), findsOneWidget);
    });

    testWidgets('shows budget period and amount', (tester) async {
      await fakeBudgetDao.create(
        BudgetInput(
          name: 'Food',
          amountCents: 30000,
          startDate: DateTime.now(),
          period: BudgetPeriod.weekly,
        ),
      );

      await pumpScreen(tester);

      expect(find.text('Food'), findsOneWidget);
      expect(find.textContaining('Weekly'), findsOneWidget);
    });

    testWidgets('FAB is present', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New Budget'), findsOneWidget);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      await fakeBudgetDao.create(
        BudgetInput(
          name: 'ToDelete',
          amountCents: 10000,
          startDate: DateTime.now(),
        ),
      );

      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Budget'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
