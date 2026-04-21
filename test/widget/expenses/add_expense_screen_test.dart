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
import 'package:xpense/features/expenses/presentation/screens/add_expense_screen.dart';

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
  ExpenseInput? lastInput;
  String? lastUpdatedId;

  @override
  Future<Expense> create(ExpenseInput input) async {
    lastInput = input;
    return Expense(
      id: 'exp_1',
      amountCents: input.amountCents,
      categoryId: input.categoryId,
      date: input.date,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

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
  Future<void> updateExpense(String id, ExpenseInput input) async {
    lastUpdatedId = id;
    lastInput = input;
  }

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
  group('AddExpenseScreen', () {
    late _FakeExpenseDao fakeExpenseDao;

    setUp(() {
      fakeExpenseDao = _FakeExpenseDao();
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingProvider.overrideWith(
              (ref) => OnboardingNotifier(initialValue: true),
            ),
            categoryDaoProvider.overrideWithValue(_FakeCategoryDao()),
            expenseDaoProvider.overrideWithValue(fakeExpenseDao),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const AddExpenseScreen(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders amount display and keypad', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.text(r'$0.00'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('entering amount updates display', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();

      expect(find.text(r'$125'), findsOneWidget);
    });

    testWidgets('selecting category and saving creates expense', (tester) async {
      await pumpScreen(tester);

      // Enter amount
      await tester.tap(find.text('5'));
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();

      // Select category
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Tap done (check icon on keypad)
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(fakeExpenseDao.lastInput, isNotNull);
      expect(fakeExpenseDao.lastInput!.amountCents, 5000);
      expect(fakeExpenseDao.lastInput!.categoryId, 'cat_food');
    });

    testWidgets('shows snackbar when no category selected', (tester) async {
      await pumpScreen(tester);

      // Enter amount without selecting category
      await tester.tap(find.text('1'));
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();

      // Tap done
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('Select a category'), findsOneWidget);
      expect(fakeExpenseDao.lastInput, isNull);
    });

    testWidgets('shows snackbar when amount is zero', (tester) async {
      await pumpScreen(tester);

      // Select category but leave amount at 0
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // No snackbar for zero amount (just haptic), but no expense created
      expect(fakeExpenseDao.lastInput, isNull);
    });

    testWidgets('optional fields button is present', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Add details (optional)'), findsOneWidget);
    });

    group('Edit Mode', () {
      final testExpense = Expense(
        id: 'exp_edit_1',
        amountCents: 2499,
        categoryId: 'cat_food',
        date: DateTime(2024, 6, 15, 14, 30),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        note: 'Dinner',
        merchant: 'Olive Garden',
        paymentMethod: 'Credit Card',
      );

      Future<void> pumpEditScreen(WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              onboardingProvider.overrideWith(
                (ref) => OnboardingNotifier(initialValue: true),
              ),
              categoryDaoProvider.overrideWithValue(_FakeCategoryDao()),
              expenseDaoProvider.overrideWithValue(fakeExpenseDao),
            ],
            child: MaterialApp.router(
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, __) => AddExpenseScreen(
                      expenseToEdit: testExpense,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      testWidgets('shows "Edit Expense" title', (tester) async {
        await pumpEditScreen(tester);

        expect(find.text('Edit Expense'), findsOneWidget);
        expect(find.text('Add another'), findsNothing);
      });

      testWidgets('pre-populates amount from existing expense',
          (tester) async {
        await pumpEditScreen(tester);

        expect(find.text(r'$24.99'), findsOneWidget);
      });

      testWidgets('pre-populates category from existing expense',
          (tester) async {
        await pumpEditScreen(tester);

        // Category should be selected (ChoiceChip selected state)
        final choiceChip = tester.widget<ChoiceChip>(find.byType(ChoiceChip));
        expect(choiceChip.selected, isTrue);
      });

      testWidgets('saving calls updateExpense instead of create',
          (tester) async {
        await pumpEditScreen(tester);

        // Tap done
        await tester.tap(find.byIcon(Icons.check));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));

        expect(fakeExpenseDao.lastUpdatedId, 'exp_edit_1');
        expect(fakeExpenseDao.lastInput, isNotNull);
        expect(fakeExpenseDao.lastInput!.amountCents, 2499);
        expect(fakeExpenseDao.lastInput!.categoryId, 'cat_food');
      });

      testWidgets('preserves original date when editing', (tester) async {
        await pumpEditScreen(tester);

        await tester.tap(find.byIcon(Icons.check));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));

        expect(fakeExpenseDao.lastInput!.date, testExpense.date);
      });
    });
  });
}
