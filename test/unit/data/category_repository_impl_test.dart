import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpense/data/database/app_database.dart';
import 'package:xpense/data/datasources/category_dao.dart';
import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/data/repositories/category_repository_impl.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/domain/repositories/category_repository.dart';

void main() {
  late AppDatabase db;
  late CategoryDao categoryDao;
  late ExpenseDao expenseDao;
  late CategoryRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    categoryDao = CategoryDao(db);
    expenseDao = ExpenseDao(db);
    repository = CategoryRepositoryImpl(categoryDao, expenseDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryRepositoryImpl', () {
    test('getAll returns empty list initially', () async {
      final categories = await repository.getAll();
      expect(categories, isEmpty);
    });

    test('create and getById', () async {
      final category = await repository.create(
        const CategoryInput(
          name: 'Food',
          iconName: 'restaurant',
          colorHex: '#EF4444',
        ),
      );

      expect(category.name, 'Food');
      expect(category.iconName, 'restaurant');
      expect(category.isArchived, false);
      expect(category.isIncome, false);

      final fetched = await repository.getById(category.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Food');
    });

    test('update changes category', () async {
      final created = await repository.create(
        const CategoryInput(
          name: 'Old',
          iconName: 'icon',
          colorHex: '#000000',
        ),
      );

      await repository.update(
        created.id,
        const CategoryInput(
          name: 'New',
          iconName: 'new_icon',
          colorHex: '#FFFFFF',
        ),
      );

      final updated = await repository.getById(created.id);
      expect(updated!.name, 'New');
      expect(updated.iconName, 'new_icon');
    });

    test('delete performs soft delete', () async {
      final category = await repository.create(
        const CategoryInput(
          name: 'ToDelete',
          iconName: 'icon',
          colorHex: '#000000',
        ),
      );

      await repository.delete(category.id);

      final fetched = await repository.getById(category.id);
      expect(fetched, isNull);

      final all = await repository.getAll();
      expect(all, isEmpty);
    });

    test('toggleArchive archives and unarchives', () async {
      final category = await repository.create(
        const CategoryInput(
          name: 'Test',
          iconName: 'icon',
          colorHex: '#000000',
        ),
      );

      expect(category.isArchived, false);

      await repository.toggleArchive(category.id, true);
      var fetched = await repository.getById(category.id);
      expect(fetched!.isArchived, true);

      // getAll excludes archived by default
      final active = await repository.getAll();
      expect(active, isEmpty);

      final all = await repository.getAll(includeArchived: true);
      expect(all.length, 1);

      await repository.toggleArchive(category.id, false);
      fetched = await repository.getById(category.id);
      expect(fetched!.isArchived, false);
    });

    test('updateSortOrders reorders categories', () async {
      final cat1 = await repository.create(
        const CategoryInput(
          name: 'A',
          iconName: 'icon',
          colorHex: '#000000',
          sortOrder: 0,
        ),
      );
      final cat2 = await repository.create(
        const CategoryInput(
          name: 'B',
          iconName: 'icon',
          colorHex: '#000000',
          sortOrder: 1,
        ),
      );

      await repository.updateSortOrders({
        cat1.id: 1,
        cat2.id: 0,
      });

      final all = await repository.getAll();
      expect(all[0].name, 'B');
      expect(all[1].name, 'A');
    });

    test('getSubcategories returns children', () async {
      final parent = await repository.create(
        const CategoryInput(
          name: 'Food',
          iconName: 'restaurant',
          colorHex: '#EF4444',
        ),
      );

      await repository.create(
        CategoryInput(
          name: 'Fast Food',
          iconName: 'restaurant',
          colorHex: '#EF4444',
          parentId: parent.id,
        ),
      );

      final subs = await repository.getSubcategories(parent.id);
      expect(subs.length, 1);
      expect(subs.first.name, 'Fast Food');
    });

    test('getStats computes spending correctly', () async {
      final category = await repository.create(
        const CategoryInput(
          name: 'Food',
          iconName: 'restaurant',
          colorHex: '#EF4444',
        ),
      );

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Create expenses in this month
      await expenseDao.create(
        ExpenseInput(
          amountCents: 1000,
          categoryId: category.id,
          date: start.add(const Duration(days: 1)),
        ),
      );
      await expenseDao.create(
        ExpenseInput(
          amountCents: 2000,
          categoryId: category.id,
          date: start.add(const Duration(days: 5)),
        ),
      );

      // Create expense outside range
      await expenseDao.create(
        ExpenseInput(
          amountCents: 5000,
          categoryId: category.id,
          date: start.subtract(const Duration(days: 10)),
        ),
      );

      final stats = await repository.getStats(category.id, start, end);
      expect(stats.totalSpentCents, 3000);
      expect(stats.transactionCount, 2);
      expect(stats.averageCents, 1500);
    });

    test('count returns correct number', () async {
      expect(await repository.count(), 0);

      await repository.create(
        const CategoryInput(
          name: 'A',
          iconName: 'icon',
          colorHex: '#000000',
        ),
      );

      expect(await repository.count(), 1);
    });
  });
}
