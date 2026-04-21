import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/data/datasources/category_dao.dart';
import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/features/categories/presentation/screens/categories_screen.dart';

class _FakeCategoryDao implements CategoryDao {
  final List<Category> _categories = [];
  int _nextId = 1;

  @override
  Future<List<Category>> getAll({bool includeArchived = false}) async {
    return _categories
        .where((c) =>
            c.deletedAt == null && (includeArchived || !c.isArchived))
        .toList();
  }

  @override
  Future<Category?> getById(String id) async => null;

  @override
  Future<Category> create(CategoryInput input) async {
    final category = Category(
      id: 'cat_${_nextId++}',
      name: input.name,
      iconName: input.iconName,
      colorHex: input.colorHex,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isIncome: input.isIncome,
      isArchived: input.isArchived,
      sortOrder: input.sortOrder,
      parentId: input.parentId,
    );
    _categories.add(category);
    return category;
  }

  @override
  Future<void> updateCategory(String id, CategoryInput input) async {}

  @override
  Future<void> deleteCategory(String id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _categories[index] = _categories[index].copyWith(deletedAt: DateTime.now());
    }
  }

  @override
  Future<int> count() async => _categories.length;

  @override
  Future<List<Category>> getSubcategories(String parentId) async => [];

  @override
  Future<void> updateSortOrder(String id, int sortOrder) async {}

  @override
  Future<void> toggleArchive(String id, bool isArchived) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _categories[index] = _categories[index].copyWith(isArchived: isArchived);
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
  group('CategoriesScreen', () {
    late _FakeCategoryDao fakeCategoryDao;

    setUp(() {
      fakeCategoryDao = _FakeCategoryDao();
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryDaoProvider.overrideWithValue(fakeCategoryDao),
            expenseDaoProvider.overrideWithValue(_FakeExpenseDao()),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const CategoriesScreen(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows empty state when no categories', (tester) async {
      await pumpScreen(tester);

      expect(find.text('No expense categories yet'), findsOneWidget);
      expect(find.text('New Category'), findsOneWidget);
    });

    testWidgets('displays expense categories in list', (tester) async {
      await fakeCategoryDao.create(
        const CategoryInput(
          name: 'Food',
          iconName: 'restaurant',
          colorHex: '#EF4444',
        ),
      );

      await pumpScreen(tester);

      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('displays income categories on income tab', (tester) async {
      await fakeCategoryDao.create(
        const CategoryInput(
          name: 'Salary',
          iconName: 'work',
          colorHex: '#10B981',
          isIncome: true,
        ),
      );

      await pumpScreen(tester);

      // Switch to income tab
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      expect(find.text('Salary'), findsOneWidget);
    });

    testWidgets('FAB is present', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New Category'), findsOneWidget);
    });

    testWidgets('reorder mode toggles with drag handle button', (tester) async {
      await fakeCategoryDao.create(
        const CategoryInput(
          name: 'A',
          iconName: 'icon',
          colorHex: '#000000',
        ),
      );

      await pumpScreen(tester);

      expect(find.byIcon(Icons.drag_handle), findsOneWidget);

      await tester.tap(find.byIcon(Icons.drag_handle));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.done), findsOneWidget);
    });

    testWidgets('archive button is visible for active categories', (tester) async {
      await fakeCategoryDao.create(
        const CategoryInput(
          name: 'Food',
          iconName: 'restaurant',
          colorHex: '#EF4444',
        ),
      );

      await pumpScreen(tester);

      expect(find.byIcon(Icons.archive), findsOneWidget);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      await fakeCategoryDao.create(
        const CategoryInput(
          name: 'Food',
          iconName: 'restaurant',
          colorHex: '#EF4444',
        ),
      );

      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Category'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
