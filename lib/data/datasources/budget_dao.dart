import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:xpense/data/database/app_database.dart' as db;
import 'package:xpense/domain/entities/budget.dart' as domain;

class BudgetDao {
  BudgetDao(this._db);

  final db.AppDatabase _db;
  final _uuid = const Uuid();

  // --- Mapping helpers ---

  domain.Budget _toDomain(db.Budget row) {
    return domain.Budget(
      id: row.id,
      name: row.name,
      amountCents: row.amountCents,
      currency: row.currency,
      period: domain.BudgetPeriod.values.firstWhere(
        (p) => p.name == row.period,
        orElse: () => domain.BudgetPeriod.monthly,
      ),
      categoryId: row.categoryId,
      startDate: row.startDate,
      endDate: row.endDate,
      rolloverUnused: row.rolloverUnused,
      alertThresholdPercent: row.alertThresholdPercent,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  db.BudgetsCompanion _toCompanion(domain.BudgetInput input, {String? id}) {
    return db.BudgetsCompanion(
      id: Value(id ?? _uuid.v4()),
      name: Value(input.name),
      amountCents: Value(input.amountCents),
      currency: Value(input.currency),
      period: Value(input.period.name),
      categoryId: Value(input.categoryId),
      startDate: Value(input.startDate),
      endDate: Value(input.endDate),
      rolloverUnused: Value(input.rolloverUnused),
      alertThresholdPercent: Value(input.alertThresholdPercent),
    );
  }

  // --- Queries ---

  Future<List<domain.Budget>> getAll() async {
    final query = _db.select(_db.budgets)
      ..where((b) => b.deletedAt.isNull())
      ..orderBy([(b) => OrderingTerm(expression: b.createdAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<domain.Budget?> getById(String id) async {
    final query = _db.select(_db.budgets)
      ..where((b) => b.id.equals(id) & b.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  // --- CRUD ---

  Future<domain.Budget> create(domain.BudgetInput input) async {
    final companion = _toCompanion(input);
    await _db.into(_db.budgets).insert(companion);
    final result = await getById(companion.id.value);
    return result!;
  }

  Future<void> updateBudget(String id, domain.BudgetInput input) async {
    await _db.update(_db.budgets).replace(
          _toCompanion(input, id: id).copyWith(
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> deleteBudget(String id) async {
    await (_db.update(_db.budgets)..where((b) => b.id.equals(id))).write(
      db.BudgetsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
