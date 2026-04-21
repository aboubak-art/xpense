import 'package:flutter_test/flutter_test.dart';

import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/data/datasources/recurring_expense_dao.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/domain/entities/recurring_expense.dart';
import 'package:xpense/domain/services/recurring_expense_engine.dart';

class _FakeRecurringExpenseDao implements RecurringExpenseDao {
  final List<RecurringExpense> _items = [];

  @override
  Future<List<RecurringExpense>> getAll() async =>
      _items.where((r) => r.deletedAt == null).toList();

  @override
  Future<RecurringExpense?> getById(String id) async =>
      _items.firstWhere((r) => r.id == id, orElse: () => throw Exception());

  @override
  Future<List<RecurringExpense>> getActive(DateTime asOf) async {
    return _items.where((r) {
      if (r.deletedAt != null) return false;
      if (r.startDate.isAfter(asOf)) return false;
      return true;
    }).toList();
  }

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
      currency: input.currency,
      note: input.note,
      merchant: input.merchant,
      paymentMethod: input.paymentMethod,
      frequencyRule: input.frequencyRule,
      endDate: input.endDate,
      maxOccurrences: input.maxOccurrences,
    );
    _items.add(item);
    return item;
  }

  @override
  Future<void> updateRecurringExpense(
    String id,
    RecurringExpenseInput input,
  ) async {}

  @override
  Future<void> deleteRecurringExpense(String id) async {
    final index = _items.indexWhere((r) => r.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(deletedAt: DateTime.now());
    }
  }
}

class _FakeExpenseDao implements ExpenseDao {
  final List<Expense> _expenses = [];
  int _nextId = 1;

  @override
  Future<Expense> create(ExpenseInput input) async {
    final expense = Expense(
      id: 'exp_${_nextId++}',
      amountCents: input.amountCents,
      categoryId: input.categoryId,
      date: input.date,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      currency: input.currency,
      note: input.note,
      merchant: input.merchant,
      paymentMethod: input.paymentMethod,
      tags: input.tags,
      location: input.location,
      recurringExpenseId: input.recurringExpenseId,
    );
    _expenses.add(expense);
    return expense;
  }

  @override
  Future<void> deleteExpense(String id) async {}

  @override
  Future<List<Expense>> getAll({int limit = 50, int offset = 0}) async =>
      _expenses;

  @override
  Future<Expense?> getById(String id) async => null;

  @override
  Future<List<Expense>> getByCategory(String categoryId) async => [];

  @override
  Future<List<Expense>> getByDateRange(DateTime start, DateTime end) async =>
      [];

  @override
  Future<List<Expense>> getByRecurringExpenseId(
    String recurringExpenseId,
  ) async {
    return _expenses
        .where((e) => e.recurringExpenseId == recurringExpenseId)
        .toList();
  }

  @override
  Future<void> updateExpense(String id, ExpenseInput input) async {}

  @override
  Future<int> totalAmountCentsByDateRange(DateTime start, DateTime end) async =>
      0;

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
  }) async =>
      _expenses;

  List<Expense> get expenses => List.unmodifiable(_expenses);
}

void main() {
  group('RecurringExpenseEngine', () {
    late _FakeRecurringExpenseDao fakeRecurringDao;
    late _FakeExpenseDao fakeExpenseDao;
    late RecurringExpenseEngine engine;

    setUp(() {
      fakeRecurringDao = _FakeRecurringExpenseDao();
      fakeExpenseDao = _FakeExpenseDao();
      engine = RecurringExpenseEngine(fakeRecurringDao, fakeExpenseDao);
    });

    test('generates first occurrence on start date', () async {
      final today = DateTime(2024, 6, 15);
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1000,
          categoryId: 'cat_1',
          frequency: RecurringFrequency.daily,
          startDate: today,
        ),
      );

      final count = await engine.generateOccurrences(asOf: today);

      expect(count, 1);
      expect(fakeExpenseDao.expenses.length, 1);
      expect(fakeExpenseDao.expenses.first.date, today);
      expect(fakeExpenseDao.expenses.first.amountCents, 1000);
    });

    test('does not generate before start date', () async {
      final today = DateTime(2024, 6, 15);
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1000,
          categoryId: 'cat_1',
          frequency: RecurringFrequency.daily,
          startDate: today.add(const Duration(days: 1)),
        ),
      );

      final count = await engine.generateOccurrences(asOf: today);

      expect(count, 0);
      expect(fakeExpenseDao.expenses, isEmpty);
    });

    test('generates daily occurrences up to asOf', () async {
      final start = DateTime(2024, 6, 10);
      final today = DateTime(2024, 6, 15);
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1000,
          categoryId: 'cat_1',
          frequency: RecurringFrequency.daily,
          startDate: start,
        ),
      );

      final count = await engine.generateOccurrences(asOf: today);

      // Should generate: 10, 11, 12, 13, 14, 15 = 6 days
      expect(count, 6);
      expect(fakeExpenseDao.expenses.length, 6);
    });

    test('generates weekly occurrences', () async {
      final start = DateTime(2024, 6, 3); // Monday
      final today = DateTime(2024, 6, 24); // 3 weeks later
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 5000,
          categoryId: 'cat_1',
          frequency: RecurringFrequency.weekly,
          startDate: start,
        ),
      );

      final count = await engine.generateOccurrences(asOf: today);

      // Should generate: Jun 3, 10, 17, 24 = 4 weeks
      expect(count, 4);
    });

    test('generates monthly occurrences', () async {
      final start = DateTime(2024, 1, 15);
      final today = DateTime(2024, 6, 15);
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 10000,
          categoryId: 'cat_1',
          frequency: RecurringFrequency.monthly,
          startDate: start,
        ),
      );

      final count = await engine.generateOccurrences(asOf: today);

      // Should generate: Jan 15, Feb 15, Mar 15, Apr 15, May 15, Jun 15 = 6
      expect(count, 6);
    });

    test('respects end date condition', () async {
      final start = DateTime(2024, 6, 10);
      final end = DateTime(2024, 6, 12);
      final today = DateTime(2024, 6, 15);
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1000,
          categoryId: 'cat_1',
          frequency: RecurringFrequency.daily,
          startDate: start,
          endDate: end,
        ),
      );

      final count = await engine.generateOccurrences(asOf: today);

      // Should generate: 10, 11, 12 = 3 days (end date inclusive)
      expect(count, 3);
    });

    test('respects max occurrences condition', () async {
      final start = DateTime(2024, 6, 10);
      final today = DateTime(2024, 6, 20);
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1000,
          categoryId: 'cat_1',
          frequency: RecurringFrequency.daily,
          startDate: start,
          maxOccurrences: 3,
        ),
      );

      final count = await engine.generateOccurrences(asOf: today);

      expect(count, 3);
    });

    test('does not generate duplicate expenses', () async {
      final today = DateTime(2024, 6, 15);
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1000,
          categoryId: 'cat_1',
          frequency: RecurringFrequency.daily,
          startDate: today,
        ),
      );

      // Run twice
      await engine.generateOccurrences(asOf: today);
      final count = await engine.generateOccurrences(asOf: today);

      expect(count, 0);
      expect(fakeExpenseDao.expenses.length, 1);
    });

    test('generated expenses link to recurring expense', () async {
      final today = DateTime(2024, 6, 15);
      final recurring = await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1000,
          categoryId: 'cat_1',
          frequency: RecurringFrequency.daily,
          startDate: today,
        ),
      );

      await engine.generateOccurrences(asOf: today);

      expect(fakeExpenseDao.expenses.first.recurringExpenseId, recurring.id);
    });

    test('does not generate for deleted recurring expenses', () async {
      final today = DateTime(2024, 6, 15);
      final recurring = await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1000,
          categoryId: 'cat_1',
          frequency: RecurringFrequency.daily,
          startDate: today,
        ),
      );
      await fakeRecurringDao.deleteRecurringExpense(recurring.id);

      final count = await engine.generateOccurrences(asOf: today);

      expect(count, 0);
    });

    test('generates bi-weekly occurrences', () async {
      final start = DateTime(2024, 6, 3);
      final today = DateTime(2024, 7, 15);
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1000,
          categoryId: 'cat_1',
          frequency: RecurringFrequency.biWeekly,
          startDate: start,
        ),
      );

      final count = await engine.generateOccurrences(asOf: today);

      // Jun 3, 17 | Jul 1, 15 = 4 occurrences
      expect(count, 4);
    });

    test('generates quarterly occurrences', () async {
      final start = DateTime(2024, 1, 15);
      final today = DateTime(2024, 12, 15);
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1000,
          categoryId: 'cat_1',
          frequency: RecurringFrequency.quarterly,
          startDate: start,
        ),
      );

      final count = await engine.generateOccurrences(asOf: today);

      // Jan 15, Apr 15, Jul 15, Oct 15 = 4 occurrences
      expect(count, 4);
    });

    test('generates yearly occurrences', () async {
      final start = DateTime(2020, 6, 15);
      final today = DateTime(2024, 6, 15);
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1000,
          categoryId: 'cat_1',
          frequency: RecurringFrequency.yearly,
          startDate: start,
        ),
      );

      final count = await engine.generateOccurrences(asOf: today);

      // 2020, 2021, 2022, 2023, 2024 = 5 occurrences
      expect(count, 5);
    });

    test('handles month-end overflow for monthly frequency', () async {
      final start = DateTime(2024, 1, 31);
      final today = DateTime(2024, 4, 30);
      await fakeRecurringDao.create(
        RecurringExpenseInput(
          amountCents: 1000,
          categoryId: 'cat_1',
          frequency: RecurringFrequency.monthly,
          startDate: start,
        ),
      );

      await engine.generateOccurrences(asOf: today);

      // Jan 31, Feb 29 (leap year), Mar 29, Apr 29
      // Day is preserved month-to-month; overflow only when target month is shorter
      final dates = fakeExpenseDao.expenses.map((e) => e.date.day).toList();
      expect(dates, [31, 29, 29, 29]);
    });
  });
}
