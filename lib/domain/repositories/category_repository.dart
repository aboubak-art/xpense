import 'package:xpense/domain/entities/category.dart';

/// Repository interface for category operations.
abstract class CategoryRepository {
  /// Get all active categories, ordered by sortOrder.
  Future<List<Category>> getAll({bool includeArchived = false});

  /// Get a single category by id.
  Future<Category?> getById(String id);

  /// Get subcategories for a given parent id.
  Future<List<Category>> getSubcategories(String parentId);

  /// Create a new category.
  Future<Category> create(CategoryInput input);

  /// Update an existing category.
  Future<void> update(String id, CategoryInput input);

  /// Soft-delete a category.
  Future<void> delete(String id);

  /// Toggle archive status.
  Future<void> toggleArchive(String id, bool isArchived);

  /// Update sort order for multiple categories.
  Future<void> updateSortOrders(Map<String, int> idToOrder);

  /// Get spending stats for a category in a date range.
  Future<CategoryStats> getStats(String categoryId, DateTime start, DateTime end);

  /// Get total count of categories.
  Future<int> count();
}

/// Spending statistics for a category.
class CategoryStats {
  const CategoryStats({
    required this.totalSpentCents,
    required this.transactionCount,
    required this.averageCents,
    required this.periodStart,
    required this.periodEnd,
  });

  final int totalSpentCents;
  final int transactionCount;
  final int averageCents;
  final DateTime periodStart;
  final DateTime periodEnd;
}
