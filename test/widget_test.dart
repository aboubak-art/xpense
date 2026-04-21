import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xpense/app.dart';
import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/core/providers/onboarding_provider.dart';
import 'package:xpense/data/datasources/category_dao.dart';
import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/features/expenses/presentation/providers/expense_list_provider.dart';

class _FakeCategoryDao implements CategoryDao {
  @override
  Future<List<Category>> getAll({bool includeArchived = false}) async => [];

  @override
  Future<Category?> getById(String id) async => null;

  @override
  Future<Category> create(CategoryInput input) async => throw UnimplementedError();

  @override
  Future<void> updateCategory(String id, CategoryInput input) async {}

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<int> count() async => 0;
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
  testWidgets(
    'App renders home screen when onboarding complete',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingProvider.overrideWith(
              (ref) => OnboardingNotifier(initialValue: true),
            ),
            categoryDaoProvider.overrideWithValue(_FakeCategoryDao()),
            expenseDaoProvider.overrideWithValue(_FakeExpenseDao()),
            expenseListProvider.overrideWith(
              (ref) => ExpenseListNotifier(ref.read(expenseDaoProvider))
                ..state = const ExpenseListState(),
            ),
          ],
          child: const XpenseApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xpense'), findsOneWidget);
      expect(find.text('Start Tracking'), findsOneWidget);
    },
  );

  testWidgets(
    'App redirects to onboarding when not complete',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingProvider.overrideWith(
              (ref) => OnboardingNotifier(initialValue: false),
            ),
            categoryDaoProvider.overrideWithValue(_FakeCategoryDao()),
            expenseDaoProvider.overrideWithValue(_FakeExpenseDao()),
          ],
          child: const XpenseApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Xpense'), findsOneWidget);
      expect(find.byType(Icon), findsWidgets);
      expect(find.text('Continue'), findsOneWidget);
    },
  );

  testWidgets('App uses MaterialApp.router', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProvider.overrideWith(
            (ref) => OnboardingNotifier(initialValue: true),
          ),
          categoryDaoProvider.overrideWithValue(_FakeCategoryDao()),
          expenseDaoProvider.overrideWithValue(_FakeExpenseDao()),
          expenseListProvider.overrideWith(
            (ref) => ExpenseListNotifier(ref.read(expenseDaoProvider))
              ..state = const ExpenseListState(),
          ),
        ],
        child: const XpenseApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
