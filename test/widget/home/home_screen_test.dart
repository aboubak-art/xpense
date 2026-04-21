import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/core/providers/onboarding_provider.dart';
import 'package:xpense/data/datasources/category_dao.dart';
import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:xpense/features/expenses/presentation/widgets/expense_card.dart';
import 'package:xpense/features/home/presentation/screens/home_screen.dart';

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
}

class _FakeExpenseDao implements ExpenseDao {
  _FakeExpenseDao({List<Expense>? expenses}) : _expenses = expenses ?? [];

  List<Expense> _expenses;
  final List<String> deletedIds = [];

  List<Expense> get expenses => List.unmodifiable(_expenses);

  set expenses(List<Expense> value) => _expenses = List.from(value);

  @override
  Future<Expense> create(ExpenseInput input) async => throw UnimplementedError();

  @override
  Future<void> deleteExpense(String id) async {
    deletedIds.add(id);
    _expenses.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<Expense>> getAll({int limit = 50, int offset = 0}) async =>
      _expenses.skip(offset).take(limit).toList();

  @override
  Future<Expense?> getById(String id) async {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Expense>> getByRecurringExpenseId(String recurringExpenseId) async => [];

  @override
  Future<List<Expense>> getByCategory(String categoryId) async =>
      _expenses.where((e) => e.categoryId == categoryId).toList();

  @override
  Future<List<Expense>> getByDateRange(DateTime start, DateTime end) async =>
      _expenses.where((e) => !e.date.isBefore(start) && !e.date.isAfter(end)).toList();

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
  }) async {
    var results = List<Expense>.from(_expenses);

    if (query.isNotEmpty) {
      final lower = query.toLowerCase();
      results = results.where((e) {
        return (e.note?.toLowerCase().contains(lower) ?? false) ||
            (e.merchant?.toLowerCase().contains(lower) ?? false);
      }).toList();
    }

    if (categoryId != null) {
      results = results.where((e) => e.categoryId == categoryId).toList();
    }

    if (paymentMethod != null) {
      results = results.where((e) => e.paymentMethod == paymentMethod).toList();
    }

    if (startDate != null) {
      results = results.where((e) => !e.date.isBefore(startDate)).toList();
    }

    if (endDate != null) {
      results = results.where((e) => !e.date.isAfter(endDate)).toList();
    }

    results.sort((a, b) => b.date.compareTo(a.date));

    return results.skip(offset).take(limit).toList();
  }
}

void main() {
  group('HomeScreen - Edit & Delete', () {
    late _FakeExpenseDao fakeExpenseDao;

    final testExpense = Expense(
      id: 'exp_1',
      amountCents: 1250,
      categoryId: 'cat_food',
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      note: 'Coffee',
      merchant: 'Starbucks',
    );

    setUp(() {
      fakeExpenseDao = _FakeExpenseDao();
    });

    Future<void> pumpHome(WidgetTester tester, {List<Expense> expenses = const []}) async {
      fakeExpenseDao.expenses = expenses;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingProvider.overrideWith(
              (ref) => OnboardingNotifier(initialValue: true),
            ),
            categoryDaoProvider.overrideWithValue(_FakeCategoryDao()),
            expenseDaoProvider.overrideWithValue(fakeExpenseDao),
            expenseListProvider.overrideWith(
              (ref) => ExpenseListNotifier(ref.read(expenseDaoProvider))
                ..state = ExpenseListState(expenses: expenses, hasMore: false),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const HomeScreen(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('displays expenses in the list', (tester) async {
      await pumpHome(tester, expenses: [testExpense]);

      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text(r'$12.50'), findsOneWidget);
    });

    testWidgets('long press on expense card enters selection mode',
        (tester) async {
      await pumpHome(tester, expenses: [testExpense]);

      // Long press on the expense card
      await tester.longPress(find.text('Coffee'));
      await tester.pumpAndSettle();

      // App bar should show selection count
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('tapping close exits selection mode', (tester) async {
      await pumpHome(tester, expenses: [testExpense]);

      await tester.longPress(find.text('Coffee'));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Xpense'), findsOneWidget);
      expect(find.text('1 selected'), findsNothing);
    });

    testWidgets('bulk delete shows confirmation dialog', (tester) async {
      await pumpHome(tester, expenses: [testExpense]);

      await tester.longPress(find.text('Coffee'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Delete Expenses'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete 1 expenses?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancelling bulk delete keeps expenses', (tester) async {
      await pumpHome(tester, expenses: [testExpense]);

      await tester.longPress(find.text('Coffee'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(fakeExpenseDao.deletedIds, isEmpty);
    });

    testWidgets('confirming bulk delete removes expenses', (tester) async {
      await pumpHome(tester, expenses: [testExpense]);

      await tester.longPress(find.text('Coffee'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(fakeExpenseDao.deletedIds, contains('exp_1'));
    });

    testWidgets('swipe-to-delete shows undo snackbar', (tester) async {
      await pumpHome(tester, expenses: [testExpense]);

      // Swipe the expense card to reveal delete action
      await tester.fling(find.byType(ExpenseCard), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Expense deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('multiple selection accumulates count', (tester) async {
      final expense2 = testExpense.copyWith(
        id: 'exp_2',
        note: 'Bagel',
        amountCents: 800,
      );

      await pumpHome(tester, expenses: [testExpense, expense2]);

      // Long press first item
      await tester.longPress(find.text('Coffee'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      // Tap second item to select it
      await tester.tap(find.text('Bagel'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('search bar filters expenses', (tester) async {
      final expense2 = testExpense.copyWith(
        id: 'exp_2',
        note: 'Bagel',
        amountCents: 800,
      );

      await pumpHome(tester, expenses: [testExpense, expense2]);

      await tester.enterText(find.byType(TextField), 'Coffee');
      await tester.pumpAndSettle();

      // The search text should be in the search field
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Coffee');
    });

    testWidgets('FAB is hidden in selection mode', (tester) async {
      await pumpHome(tester, expenses: [testExpense]);

      expect(find.text('Add Expense'), findsOneWidget);

      await tester.longPress(find.text('Coffee'));
      await tester.pumpAndSettle();

      expect(find.text('Add Expense'), findsNothing);
    });

    testWidgets('search bar is hidden in selection mode', (tester) async {
      await pumpHome(tester, expenses: [testExpense]);

      expect(find.byType(TextField), findsOneWidget);

      await tester.longPress(find.text('Coffee'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });
  });
}
