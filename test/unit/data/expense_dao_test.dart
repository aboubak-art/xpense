import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpense/data/database/app_database.dart';
import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/domain/entities/expense.dart';

void main() {
  late AppDatabase db;
  late ExpenseDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = ExpenseDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ExpenseDao', () {
    test('create returns expense with generated id', () async {
      final input = ExpenseInput(
        amountCents: 1000,
        categoryId: 'cat-1',
        date: DateTime(2024, 1, 15),
      );

      final expense = await dao.create(input);

      expect(expense.amountCents, 1000);
      expect(expense.currency, 'USD');
      expect(expense.categoryId, 'cat-1');
      expect(expense.date, DateTime(2024, 1, 15));
      expect(expense.id, isNotEmpty);
      expect(expense.deletedAt, isNull);
    });

    test('getById returns expense', () async {
      final created = await dao.create(
        ExpenseInput(
          amountCents: 2500,
          categoryId: 'cat-1',
          date: DateTime(2024, 2, 1),
          note: 'Lunch',
        ),
      );

      final fetched = await dao.getById(created.id);

      expect(fetched, isNotNull);
      expect(fetched!.amountCents, 2500);
      expect(fetched.note, 'Lunch');
    });

    test('getAll returns paginated results', () async {
      for (var i = 0; i < 5; i++) {
        await dao.create(
          ExpenseInput(
            amountCents: i * 100,
            categoryId: 'cat-1',
            date: DateTime(2024, 1, i + 1),
          ),
        );
      }

      final page1 = await dao.getAll(limit: 3);
      expect(page1.length, 3);

      final page2 = await dao.getAll(limit: 3, offset: 3);
      expect(page2.length, 2);
    });

    test('getAll orders by date descending', () async {
      await dao.create(
        ExpenseInput(
          amountCents: 100,
          categoryId: 'cat-1',
          date: DateTime(2024, 1, 1),
        ),
      );
      await dao.create(
        ExpenseInput(
          amountCents: 200,
          categoryId: 'cat-1',
          date: DateTime(2024, 1, 3),
        ),
      );

      final all = await dao.getAll();
      expect(all.first.amountCents, 200);
      expect(all.last.amountCents, 100);
    });

    test('getByCategory filters correctly', () async {
      await dao.create(
        ExpenseInput(
          amountCents: 100,
          categoryId: 'cat-food',
          date: DateTime(2024, 1, 1),
        ),
      );
      await dao.create(
        ExpenseInput(
          amountCents: 200,
          categoryId: 'cat-transport',
          date: DateTime(2024, 1, 2),
        ),
      );

      final food = await dao.getByCategory('cat-food');
      expect(food.length, 1);
      expect(food.first.amountCents, 100);
    });

    test('getByDateRange filters correctly', () async {
      await dao.create(
        ExpenseInput(
          amountCents: 100,
          categoryId: 'cat-1',
          date: DateTime(2024, 1, 5),
        ),
      );
      await dao.create(
        ExpenseInput(
          amountCents: 200,
          categoryId: 'cat-1',
          date: DateTime(2024, 1, 15),
        ),
      );
      await dao.create(
        ExpenseInput(
          amountCents: 300,
          categoryId: 'cat-1',
          date: DateTime(2024, 1, 25),
        ),
      );

      final midMonth = await dao.getByDateRange(
        DateTime(2024, 1, 10),
        DateTime(2024, 1, 20),
      );
      expect(midMonth.length, 1);
      expect(midMonth.first.amountCents, 200);
    });

    test('deleteExpense performs soft delete', () async {
      final created = await dao.create(
        ExpenseInput(
          amountCents: 500,
          categoryId: 'cat-1',
          date: DateTime(2024, 1, 1),
        ),
      );

      await dao.deleteExpense(created.id);

      expect(await dao.getById(created.id), isNull);
      expect((await dao.getAll()).isEmpty, true);
    });

    test('totalAmountCentsByDateRange sums correctly', () async {
      await dao.create(
        ExpenseInput(
          amountCents: 1000,
          categoryId: 'cat-1',
          date: DateTime(2024, 1, 5),
        ),
      );
      await dao.create(
        ExpenseInput(
          amountCents: 2000,
          categoryId: 'cat-1',
          date: DateTime(2024, 1, 10),
        ),
      );
      await dao.create(
        ExpenseInput(
          amountCents: 500,
          categoryId: 'cat-1',
          date: DateTime(2024, 2, 1),
        ),
      );

      final total = await dao.totalAmountCentsByDateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );
      expect(total, 3000);
    });
  });
}
