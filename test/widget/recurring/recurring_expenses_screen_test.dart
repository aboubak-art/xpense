import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/data/datasources/category_dao.dart';
import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/data/datasources/recurring_expense_dao.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/domain/entities/recurring_expense.dart';
import 'package:xpense/features/recurring/presentation/screens/recurring_expenses_screen.dart';

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
  Future<List<Expense>> getAll({int limit = 50, int offset = 0}) async =>
      [];

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

class _FakeRecurringExpenseDao implements RecurringExpenseDao {
  final List<RecurringExpense> _items = [];

  @override
  Future<List<RecurringExpense>> getAll() async =>
      _items.where((r) => r.deletedAt == null).toList();

  @override
  Future<RecurringExpense?> getById(String id) async => null;

  @override
  Future<List<RecurringExpense>> getActive(DateTime asOf) async => [];

  @override
  Future<RecurringExpense> create(RecurringExpenseInput input) async {
    final item = RecurringExpense(
      id: 'rec_${_items.length + 1}',
      amountCents: input.amountCents,
      categoryId: input.categoryId,
      frequency: input.frequency,
      startDate: input.startDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      note: input.note,
      merchant: input.merchant,
      endDate: input.endDate,
      maxOccurrences: input.maxOccurrences,
    );
    _items.add(item);
    return item;
  }

  @override
  Future<void> updateRecurringExpense(String id, RecurringExpenseInput input) async {}

  @override
  Future<void> deleteRecurringExpense(String id) async {
    final index = _items.indexWhere((r) => r.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(deletedAt: DateTime.now());
    }
  }
}

void main() {
  group('RecurringExpensesScreen', () {
    late _FakeRecurringExpenseDao fakeRecurringDao;

    setUp(() {
      fakeRecurringDao = _FakeRecurringExpenseDao();
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryDaoProvider.overrideWithValue(_FakeCategoryDao()),
            expenseDaoProvider.overrideWithValue(_FakeExpenseDao()),
            recurringExpenseDaoProvider.overrideWithValue(fakeRecurringDao),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const RecurringExpensesScreen(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows empty state when no recurring expenses', (tester) async {
      await pumpScreen(tester);

      expect(find.text('No Recurring Expenses'), findsOneWidget);
      expect(find.text('Add Recurring'), findsOneWidget);
    });

    testWidgets('displays recurring expenses in list', (tester) async {
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1500,
          categoryId: 'cat_food',
          frequency: RecurringFrequency.monthly,
          startDate: DateTime(2024, 1, 1),
          note: 'Netflix',
        ),
      );

      await pumpScreen(tester);

      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text(r'$15.00'), findsOneWidget);
      expect(find.textContaining('Every month'), findsOneWidget);
    });

    testWidgets('shows correct frequency labels', (tester) async {
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1000,
          categoryId: 'cat_food',
          frequency: RecurringFrequency.weekly,
          startDate: DateTime(2024, 1, 1),
          note: 'Gym',
        ),
      );

      await pumpScreen(tester);

      expect(find.text('Gym'), findsOneWidget);
      expect(find.textContaining('Every week'), findsOneWidget);
    });

    testWidgets('delete confirmation dialog appears on long press',
        (tester) async {
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1000,
          categoryId: 'cat_food',
          frequency: RecurringFrequency.monthly,
          startDate: DateTime(2024, 1, 1),
          note: 'Rent',
        ),
      );

      await pumpScreen(tester);

      await tester.longPress(find.text('Rent'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Recurring Expense'), findsOneWidget);
      expect(
        find.text(
          'This will stop future occurrences from being generated. '
          'Existing expenses will not be deleted.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping FAB opens form bottom sheet', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add Recurring'));
      await tester.pumpAndSettle();

      expect(find.text('New Recurring'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('form allows selecting frequency', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add Recurring'));
      await tester.pumpAndSettle();

      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);
    });

    testWidgets('form allows entering amount via keypad', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Add Recurring'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('5'));
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();

      expect(find.text(r'$50'), findsOneWidget);
    });
  });
}
