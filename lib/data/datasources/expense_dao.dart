import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:xpense/data/database/app_database.dart' as db;
import 'package:xpense/domain/entities/expense.dart' as domain;

class ExpenseDao {
  ExpenseDao(this._db);

  final db.AppDatabase _db;
  final _uuid = const Uuid();

  // --- Mapping helpers ---

  domain.Expense _toDomain(db.Expense row) {
    return domain.Expense(
      id: row.id,
      amountCents: row.amountCents,
      currency: row.currency,
      categoryId: row.categoryId,
      note: row.note,
      merchant: row.merchant,
      paymentMethod: row.paymentMethod,
      tags: row.tags?.split(','),
      location: row.location,
      recurringExpenseId: row.recurringExpenseId,
      date: row.date,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  db.ExpensesCompanion _toCompanion(domain.ExpenseInput input, {String? id}) {
    return db.ExpensesCompanion(
      id: Value(id ?? _uuid.v4()),
      amountCents: Value(input.amountCents),
      currency: Value(input.currency),
      categoryId: Value(input.categoryId),
      note: Value(input.note),
      merchant: Value(input.merchant),
      paymentMethod: Value(input.paymentMethod),
      tags: Value(input.tags?.join(',')),
      location: Value(input.location),
      recurringExpenseId: Value(input.recurringExpenseId),
      date: Value(input.date),
    );
  }

  // --- Queries ---

  Future<List<domain.Expense>> getAll({int limit = 50, int offset = 0}) async {
    final query = _db.select(_db.expenses)
      ..where((e) => e.deletedAt.isNull())
      ..orderBy(
        [(e) => OrderingTerm(expression: e.date, mode: OrderingMode.desc)],
      )
      ..limit(limit, offset: offset);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<domain.Expense?> getById(String id) async {
    final query = _db.select(_db.expenses)
      ..where((e) => e.id.equals(id) & e.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<domain.Expense>> getByRecurringExpenseId(
    String recurringExpenseId,
  ) async {
    final query = _db.select(_db.expenses)
      ..where(
        (e) =>
            e.recurringExpenseId.equals(recurringExpenseId) &
            e.deletedAt.isNull(),
      )
      ..orderBy(
        [(e) => OrderingTerm(expression: e.date, mode: OrderingMode.asc)],
      );
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<List<domain.Expense>> getByCategory(String categoryId) async {
    final query = _db.select(_db.expenses)
      ..where(
        (e) => e.categoryId.equals(categoryId) & e.deletedAt.isNull(),
      )
      ..orderBy(
        [(e) => OrderingTerm(expression: e.date, mode: OrderingMode.desc)],
      );
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<List<domain.Expense>> getByCategoryAndDateRange(
    String categoryId,
    DateTime start,
    DateTime end,
  ) async {
    final query = _db.select(_db.expenses)
      ..where(
        (e) =>
            e.categoryId.equals(categoryId) &
            e.date.isBetweenValues(start, end) &
            e.deletedAt.isNull(),
      )
      ..orderBy(
        [(e) => OrderingTerm(expression: e.date, mode: OrderingMode.desc)],
      );
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<List<domain.Expense>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final query = _db.select(_db.expenses)
      ..where(
        (e) => e.date.isBetweenValues(start, end) & e.deletedAt.isNull(),
      )
      ..orderBy(
        [(e) => OrderingTerm(expression: e.date, mode: OrderingMode.desc)],
      );
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  // --- CRUD ---

  Future<domain.Expense> create(domain.ExpenseInput input) async {
    final companion = _toCompanion(input);
    await _db.into(_db.expenses).insert(companion);
    final result = await getById(companion.id.value);
    return result!;
  }

  Future<void> updateExpense(String id, domain.ExpenseInput input) async {
    await _db.update(_db.expenses).replace(
          _toCompanion(input, id: id).copyWith(
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> deleteExpense(String id) async {
    await (_db.update(_db.expenses)..where((e) => e.id.equals(id))).write(
      db.ExpensesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> totalAmountCentsByDateRange(DateTime start, DateTime end) async {
    final query = _db.selectOnly(_db.expenses)
      ..addColumns([_db.expenses.amountCents.sum()])
      ..where(
        _db.expenses.date.isBetweenValues(start, end) &
            _db.expenses.deletedAt.isNull(),
      );
    final result = await query.getSingle();
    return result.read(_db.expenses.amountCents.sum()) ?? 0;
  }

  Future<List<domain.Expense>> search(
    String query, {
    String? categoryId,
    String? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
    String sortBy = 'date',
    int limit = 50,
    int offset = 0,
  }) async {
    final dbQuery = _db.select(_db.expenses)
      ..where((e) => e.deletedAt.isNull());

    if (query.isNotEmpty) {
      final lowerQuery = '%${query.toLowerCase()}%';
      dbQuery.where(
        (e) =>
            e.note.lower().like(lowerQuery) |
            e.merchant.lower().like(lowerQuery),
      );
    }

    if (categoryId != null) {
      dbQuery.where((e) => e.categoryId.equals(categoryId));
    }

    if (paymentMethod != null) {
      dbQuery.where((e) => e.paymentMethod.equals(paymentMethod));
    }

    if (startDate != null && endDate != null) {
      dbQuery.where((e) => e.date.isBetweenValues(startDate, endDate));
    }

    switch (sortBy) {
      case 'amount':
        dbQuery.orderBy([
          (e) => OrderingTerm(expression: e.amountCents, mode: OrderingMode.desc),
        ]);
      case 'category':
        dbQuery.orderBy([
          (e) => OrderingTerm(expression: e.categoryId),
          (e) => OrderingTerm(expression: e.date, mode: OrderingMode.desc),
        ]);
      case 'date':
      default:
        dbQuery.orderBy([
          (e) => OrderingTerm(expression: e.date, mode: OrderingMode.desc),
        ]);
    }

    dbQuery.limit(limit, offset: offset);

    final rows = await dbQuery.get();
    return rows.map(_toDomain).toList();
  }
}
