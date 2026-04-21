import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpense/data/database/app_database.dart';
import 'package:xpense/data/datasources/budget_dao.dart';
import 'package:xpense/data/datasources/category_dao.dart';
import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/data/repositories/budget_repository_impl.dart';
import 'package:xpense/domain/entities/budget.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/domain/repositories/budget_repository.dart';

void main() {
  late AppDatabase db;
  late BudgetDao budgetDao;
  late ExpenseDao expenseDao;
  late CategoryDao categoryDao;
  late BudgetRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    budgetDao = BudgetDao(db);
    expenseDao = ExpenseDao(db);
    categoryDao = CategoryDao(db);
    repository = BudgetRepositoryImpl(budgetDao, expenseDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('BudgetRepositoryImpl', () {
    test('getAll returns empty list initially', () async {
      final budgets = await repository.getAll();
      expect(budgets, isEmpty);
    });

    test('create and getById', () async {
      final budget = await repository.create(
        BudgetInput(
          name: 'Groceries',
          amountCents: 50000,
          startDate: DateTime.now(),
        ),
      );

      expect(budget.name, 'Groceries');
      expect(budget.amountCents, 50000);
      expect(budget.period, BudgetPeriod.monthly);

      final fetched = await repository.getById(budget.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Groceries');
    });

    test('update changes budget', () async {
      final created = await repository.create(
        BudgetInput(
          name: 'Old',
          amountCents: 1000,
          startDate: DateTime.now(),
        ),
      );

      await repository.update(
        created.id,
        BudgetInput(
          name: 'New',
          amountCents: 2000,
          startDate: DateTime(2024, 1, 1),
          period: BudgetPeriod.weekly,
        ),
      );

      final updated = await repository.getById(created.id);
      expect(updated!.name, 'New');
      expect(updated.amountCents, 2000);
      expect(updated.period, BudgetPeriod.weekly);
    });

    test('delete performs soft delete', () async {
      final budget = await repository.create(
        BudgetInput(
          name: 'ToDelete',
          amountCents: 1000,
          startDate: DateTime.now(),
        ),
      );

      await repository.delete(budget.id);

      final fetched = await repository.getById(budget.id);
      expect(fetched, isNull);

      final all = await repository.getAll();
      expect(all, isEmpty);
    });

    group('getSpentCents', () {
      test('returns 0 when budget not found', () async {
        final spent = await repository.getSpentCents('non-existent');
        expect(spent, 0);
      });

      test('returns 0 when no expenses in period', () async {
        final budget = await repository.create(
          BudgetInput(
            name: 'Monthly',
            amountCents: 100000,
            startDate: DateTime.now(),
            period: BudgetPeriod.monthly,
          ),
        );

        final spent = await repository.getSpentCents(budget.id);
        expect(spent, 0);
      });

      test('sums all expenses in period for overall budget', () async {
        final now = DateTime.now();
        // Anchor to 1st of month so period covers the whole month
        final startDate = DateTime(now.year, now.month, 1);

        final budget = await repository.create(
          BudgetInput(
            name: 'Monthly',
            amountCents: 100000,
            startDate: startDate,
            period: BudgetPeriod.monthly,
          ),
        );

        await expenseDao.create(
          ExpenseInput(
            amountCents: 1000,
            categoryId: 'cat-test',
            date: startDate.add(const Duration(days: 1)),
          ),
        );
        await expenseDao.create(
          ExpenseInput(
            amountCents: 2500,
            categoryId: 'cat-test',
            date: startDate.add(const Duration(days: 5)),
          ),
        );

        final spent = await repository.getSpentCents(budget.id);
        expect(spent, 3500);
      });

      test('sums only category expenses for category budget', () async {
        final category = await categoryDao.create(
          const CategoryInput(
            name: 'Food',
            iconName: 'restaurant',
            colorHex: '#EF4444',
          ),
        );

        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, 1);

        final budget = await repository.create(
          BudgetInput(
            name: 'Food Budget',
            amountCents: 50000,
            startDate: startDate,
            period: BudgetPeriod.monthly,
            categoryId: category.id,
          ),
        );

        await expenseDao.create(
          ExpenseInput(
            amountCents: 1000,
            categoryId: category.id,
            date: startDate.add(const Duration(days: 1)),
          ),
        );
        await expenseDao.create(
          ExpenseInput(
            amountCents: 2000,
            categoryId: 'cat-test',
            date: startDate.add(const Duration(days: 2)),
          ),
        );

        final spent = await repository.getSpentCents(budget.id);
        expect(spent, 1000);
      });

      test('excludes expenses outside period', () async {
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, 1);

        final budget = await repository.create(
          BudgetInput(
            name: 'Monthly',
            amountCents: 100000,
            startDate: startDate,
            period: BudgetPeriod.monthly,
          ),
        );

        await expenseDao.create(
          ExpenseInput(
            amountCents: 5000,
            categoryId: 'cat-test',
            date: startDate.subtract(const Duration(days: 5)),
          ),
        );

        final spent = await repository.getSpentCents(budget.id);
        expect(spent, 0);
      });
    });

    group('getRemainingCents', () {
      test('returns full amount when no spending', () async {
        final budget = await repository.create(
          BudgetInput(
            name: 'Monthly',
            amountCents: 100000,
            startDate: DateTime.now(),
            period: BudgetPeriod.monthly,
          ),
        );

        final remaining = await repository.getRemainingCents(budget.id);
        expect(remaining, 100000);
      });

      test('returns remaining after spending', () async {
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, 1);

        final budget = await repository.create(
          BudgetInput(
            name: 'Monthly',
            amountCents: 100000,
            startDate: startDate,
            period: BudgetPeriod.monthly,
          ),
        );

        await expenseDao.create(
          ExpenseInput(
            amountCents: 35000,
            categoryId: 'cat-test',
            date: startDate.add(const Duration(days: 1)),
          ),
        );

        final remaining = await repository.getRemainingCents(budget.id);
        expect(remaining, 65000);
      });

      test('returns negative when over budget', () async {
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, 1);

        final budget = await repository.create(
          BudgetInput(
            name: 'Monthly',
            amountCents: 10000,
            startDate: startDate,
            period: BudgetPeriod.monthly,
          ),
        );

        await expenseDao.create(
          ExpenseInput(
            amountCents: 15000,
            categoryId: 'cat-test',
            date: startDate.add(const Duration(days: 1)),
          ),
        );

        final remaining = await repository.getRemainingCents(budget.id);
        expect(remaining, -5000);
      });
    });

    group('period bounds', () {
      test('daily period uses today', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final budget = await repository.create(
          BudgetInput(
            name: 'Daily',
            amountCents: 10000,
            startDate: today,
            period: BudgetPeriod.daily,
          ),
        );

        await expenseDao.create(
          ExpenseInput(
            amountCents: 1000,
            categoryId: 'cat-test',
            date: today.add(const Duration(hours: 10)),
          ),
        );
        await expenseDao.create(
          ExpenseInput(
            amountCents: 2000,
            categoryId: 'cat-test',
            date: today.subtract(const Duration(days: 1)),
          ),
        );

        final spent = await repository.getSpentCents(budget.id);
        expect(spent, 1000);
      });

      test('weekly period respects start date alignment', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        // Align start to beginning of current week
        final startDate = today.subtract(Duration(days: today.weekday % 7));

        final budget = await repository.create(
          BudgetInput(
            name: 'Weekly',
            amountCents: 50000,
            startDate: startDate,
            period: BudgetPeriod.weekly,
          ),
        );

        await expenseDao.create(
          ExpenseInput(
            amountCents: 3000,
            categoryId: 'cat-test',
            date: startDate.add(const Duration(days: 2)),
          ),
        );
        await expenseDao.create(
          ExpenseInput(
            amountCents: 5000,
            categoryId: 'cat-test',
            date: startDate.subtract(const Duration(days: 3)),
          ),
        );

        final spent = await repository.getSpentCents(budget.id);
        expect(spent, 3000);
      });

      test('custom period uses start and end dates', () async {
        final startDate = DateTime(2024, 6, 1);
        final endDate = DateTime(2024, 6, 15);

        final budget = await repository.create(
          BudgetInput(
            name: 'Custom',
            amountCents: 50000,
            startDate: startDate,
            period: BudgetPeriod.custom,
            endDate: endDate,
          ),
        );

        await expenseDao.create(
          ExpenseInput(
            amountCents: 2000,
            categoryId: 'cat-test',
            date: DateTime(2024, 6, 10),
          ),
        );
        await expenseDao.create(
          ExpenseInput(
            amountCents: 1000,
            categoryId: 'cat-test',
            date: DateTime(2024, 6, 20),
          ),
        );

        final spent = await repository.getSpentCents(budget.id);
        expect(spent, 2000);
      });
    });
  });
}
