import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpense/data/database/app_database.dart';
import 'package:xpense/data/datasources/budget_dao.dart';
import 'package:xpense/domain/entities/budget.dart';

void main() {
  late AppDatabase db;
  late BudgetDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = BudgetDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BudgetDao', () {
    test('create returns created budget', () async {
      final now = DateTime.now();
      final input = BudgetInput(
        name: 'Monthly Groceries',
        amountCents: 50000,
        startDate: now,
      );

      final budget = await dao.create(input);

      expect(budget.name, 'Monthly Groceries');
      expect(budget.amountCents, 50000);
      expect(budget.currency, 'USD');
      expect(budget.period, BudgetPeriod.monthly);
      expect(budget.rolloverUnused, false);
      expect(budget.alertThresholdPercent, 80);
      expect(budget.deletedAt, isNull);
    });

    test('create with custom period and endDate', () async {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 12, 31);
      final input = BudgetInput(
        name: 'Yearly Budget',
        amountCents: 100000,
        startDate: start,
        period: BudgetPeriod.custom,
        endDate: end,
        rolloverUnused: true,
        alertThresholdPercent: 90,
      );

      final budget = await dao.create(input);

      expect(budget.period, BudgetPeriod.custom);
      expect(budget.endDate, end);
      expect(budget.rolloverUnused, true);
      expect(budget.alertThresholdPercent, 90);
    });

    test('create with category filter', () async {
      final input = BudgetInput(
        name: 'Food Budget',
        amountCents: 20000,
        startDate: DateTime.now(),
        categoryId: 'cat-food-123',
      );

      final budget = await dao.create(input);

      expect(budget.categoryId, 'cat-food-123');
    });

    test('getById returns budget after creation', () async {
      final input = BudgetInput(
        name: 'Test',
        amountCents: 1000,
        startDate: DateTime.now(),
      );
      final created = await dao.create(input);

      final fetched = await dao.getById(created.id);

      expect(fetched, isNotNull);
      expect(fetched!.id, created.id);
      expect(fetched.name, 'Test');
    });

    test('getById returns null for non-existent id', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });

    test('getById returns null for soft-deleted budget', () async {
      final created = await dao.create(
        BudgetInput(
          name: 'ToDelete',
          amountCents: 1000,
          startDate: DateTime.now(),
        ),
      );

      await dao.deleteBudget(created.id);

      final fetched = await dao.getById(created.id);
      expect(fetched, isNull);
    });

    test('getAll returns all non-deleted budgets', () async {
      await dao.create(
        BudgetInput(
          name: 'A',
          amountCents: 1000,
          startDate: DateTime.now(),
        ),
      );
      await dao.create(
        BudgetInput(
          name: 'B',
          amountCents: 2000,
          startDate: DateTime.now(),
        ),
      );

      final all = await dao.getAll();

      expect(all.length, 2);
    });

    test('getAll excludes soft-deleted budgets', () async {
      final toDelete = await dao.create(
        BudgetInput(
          name: 'ToDelete',
          amountCents: 1000,
          startDate: DateTime.now(),
        ),
      );
      await dao.create(
        BudgetInput(
          name: 'Keep',
          amountCents: 2000,
          startDate: DateTime.now(),
        ),
      );

      await dao.deleteBudget(toDelete.id);

      final all = await dao.getAll();
      expect(all.length, 1);
      expect(all.first.name, 'Keep');
    });

    test('getAll orders by createdAt', () async {
      await dao.create(
        BudgetInput(
          name: 'First',
          amountCents: 1000,
          startDate: DateTime.now(),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 10));
      await dao.create(
        BudgetInput(
          name: 'Second',
          amountCents: 2000,
          startDate: DateTime.now(),
        ),
      );

      final all = await dao.getAll();
      expect(all[0].name, 'First');
      expect(all[1].name, 'Second');
    });

    test('updateBudget modifies budget', () async {
      final created = await dao.create(
        BudgetInput(
          name: 'Old',
          amountCents: 1000,
          startDate: DateTime.now(),
        ),
      );

      await dao.updateBudget(
        created.id,
        BudgetInput(
          name: 'New',
          amountCents: 5000,
          startDate: DateTime(2024, 6, 1),
          period: BudgetPeriod.weekly,
        ),
      );

      final updated = await dao.getById(created.id);
      expect(updated!.name, 'New');
      expect(updated.amountCents, 5000);
      expect(updated.period, BudgetPeriod.weekly);
    });

    test('deleteBudget performs soft delete', () async {
      final created = await dao.create(
        BudgetInput(
          name: 'ToDelete',
          amountCents: 1000,
          startDate: DateTime.now(),
        ),
      );

      await dao.deleteBudget(created.id);

      final fetched = await dao.getById(created.id);
      expect(fetched, isNull);

      final all = await dao.getAll();
      expect(all.isEmpty, true);
    });
  });
}
