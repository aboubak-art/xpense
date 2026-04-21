import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:xpense/data/database/app_database.dart' as db;
import 'package:xpense/domain/entities/category.dart' as domain;

class CategoryDao {
  CategoryDao(this._db);

  final db.AppDatabase _db;
  final _uuid = const Uuid();

  // --- Mapping helpers ---

  domain.Category _toDomain(db.Category row) {
    return domain.Category(
      id: row.id,
      name: row.name,
      iconName: row.iconName,
      colorHex: row.colorHex,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isIncome: row.isIncome,
      isArchived: row.isArchived,
      sortOrder: row.sortOrder,
      parentId: row.parentId,
      deletedAt: row.deletedAt,
    );
  }

  db.CategoriesCompanion _toCompanion(
    domain.CategoryInput input, {
    String? id,
  }) {
    return db.CategoriesCompanion(
      id: Value(id ?? _uuid.v4()),
      name: Value(input.name),
      iconName: Value(input.iconName),
      colorHex: Value(input.colorHex),
      isIncome: Value(input.isIncome),
      isArchived: Value(input.isArchived),
      sortOrder: Value(input.sortOrder),
      parentId: Value(input.parentId),
    );
  }

  // --- Queries ---

  Future<List<domain.Category>> getAll({bool includeArchived = false}) async {
    final query = _db.select(_db.categories)
      ..where((c) => c.deletedAt.isNull())
      ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]);
    if (!includeArchived) {
      query.where((c) => c.isArchived.equals(false));
    }
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<domain.Category?> getById(String id) async {
    final query = _db.select(_db.categories)
      ..where((c) => c.id.equals(id) & c.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  // --- CRUD ---

  Future<domain.Category> create(domain.CategoryInput input) async {
    final companion = _toCompanion(input);
    await _db.into(_db.categories).insert(companion);
    final result = await getById(companion.id.value);
    return result!;
  }

  Future<void> updateCategory(String id, domain.CategoryInput input) async {
    await _db.update(_db.categories).replace(
          _toCompanion(input, id: id).copyWith(
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> deleteCategory(String id) async {
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      db.CategoriesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<domain.Category>> getSubcategories(String parentId) async {
    final query = _db.select(_db.categories)
      ..where(
        (c) =>
            c.parentId.equals(parentId) &
            c.deletedAt.isNull() &
            c.isArchived.equals(false),
      )
      ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<void> updateSortOrder(String id, int sortOrder) async {
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      db.CategoriesCompanion(
        sortOrder: Value(sortOrder),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> toggleArchive(String id, bool isArchived) async {
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      db.CategoriesCompanion(
        isArchived: Value(isArchived),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> count() async {
    return _db.categories.count().getSingle();
  }
}
