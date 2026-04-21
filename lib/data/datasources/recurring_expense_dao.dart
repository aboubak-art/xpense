import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:xpense/data/database/app_database.dart' as db;
import 'package:xpense/domain/entities/recurring_expense.dart' as domain;

class RecurringExpenseDao {
  RecurringExpenseDao(this._db);

  final db.AppDatabase _db;
  final _uuid = const Uuid();

  // --- Mapping helpers ---

  domain.RecurringExpense _toDomain(db.RecurringExpense row) {
    return domain.RecurringExpense(
      id: row.id,
      amountCents: row.amountCents,
      currency: row.currency,
      categoryId: row.categoryId,
      note: row.note,
      merchant: row.merchant,
      paymentMethod: row.paymentMethod,
      frequency: _parseFrequency(row.frequency),
      frequencyRule: row.frequencyRule,
      startDate: row.startDate,
      endDate: row.endDate,
      maxOccurrences: row.maxOccurrences,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  db.RecurringExpensesCompanion _toCompanion(
    domain.RecurringExpenseInput input, {
    String? id,
  }) {
    return db.RecurringExpensesCompanion(
      id: Value(id ?? _uuid.v4()),
      amountCents: Value(input.amountCents),
      currency: Value(input.currency),
      categoryId: Value(input.categoryId),
      note: Value(input.note),
      merchant: Value(input.merchant),
      paymentMethod: Value(input.paymentMethod),
      frequency: Value(_frequencyToString(input.frequency)),
      frequencyRule: Value(input.frequencyRule),
      startDate: Value(input.startDate),
      endDate: Value(input.endDate),
      maxOccurrences: Value(input.maxOccurrences),
    );
  }

  domain.RecurringFrequency _parseFrequency(String value) {
    return domain.RecurringFrequency.values.firstWhere(
      (f) => _frequencyToString(f) == value,
      orElse: () => domain.RecurringFrequency.monthly,
    );
  }

  String _frequencyToString(domain.RecurringFrequency frequency) {
    return switch (frequency) {
      domain.RecurringFrequency.daily => 'daily',
      domain.RecurringFrequency.weekly => 'weekly',
      domain.RecurringFrequency.biWeekly => 'bi-weekly',
      domain.RecurringFrequency.monthly => 'monthly',
      domain.RecurringFrequency.quarterly => 'quarterly',
      domain.RecurringFrequency.yearly => 'yearly',
      domain.RecurringFrequency.custom => 'custom',
    };
  }

  // --- Queries ---

  Future<List<domain.RecurringExpense>> getAll() async {
    final query = _db.select(_db.recurringExpenses)
      ..where((r) => r.deletedAt.isNull())
      ..orderBy(
        [(r) => OrderingTerm(expression: r.createdAt, mode: OrderingMode.desc)],
      );
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<domain.RecurringExpense?> getById(String id) async {
    final query = _db.select(_db.recurringExpenses)
      ..where((r) => r.id.equals(id) & r.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<domain.RecurringExpense>> getActive(
    DateTime asOf,
  ) async {
    final query = _db.select(_db.recurringExpenses)
      ..where(
        (r) =>
            r.deletedAt.isNull() &
            r.startDate.isSmallerOrEqualValue(asOf),
      )
      ..orderBy(
        [(r) => OrderingTerm(expression: r.startDate, mode: OrderingMode.desc)],
      );
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  // --- CRUD ---

  Future<domain.RecurringExpense> create(
    domain.RecurringExpenseInput input,
  ) async {
    final companion = _toCompanion(input);
    await _db.into(_db.recurringExpenses).insert(companion);
    final result = await getById(companion.id.value);
    return result!;
  }

  Future<void> updateRecurringExpense(
    String id,
    domain.RecurringExpenseInput input,
  ) async {
    await _db.update(_db.recurringExpenses).replace(
          _toCompanion(input, id: id).copyWith(
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> deleteRecurringExpense(String id) async {
    await (_db.update(_db.recurringExpenses)
          ..where((r) => r.id.equals(id)))
        .write(
      db.RecurringExpensesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
