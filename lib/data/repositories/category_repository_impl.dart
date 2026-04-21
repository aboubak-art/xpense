import 'package:xpense/data/datasources/category_dao.dart';
import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._categoryDao, this._expenseDao);

  final CategoryDao _categoryDao;
  final ExpenseDao _expenseDao;

  @override
  Future<List<Category>> getAll({bool includeArchived = false}) async {
    return _categoryDao.getAll(includeArchived: includeArchived);
  }

  @override
  Future<Category?> getById(String id) async {
    return _categoryDao.getById(id);
  }

  @override
  Future<List<Category>> getSubcategories(String parentId) async {
    return _categoryDao.getSubcategories(parentId);
  }

  @override
  Future<Category> create(CategoryInput input) async {
    return _categoryDao.create(input);
  }

  @override
  Future<void> update(String id, CategoryInput input) async {
    return _categoryDao.updateCategory(id, input);
  }

  @override
  Future<void> delete(String id) async {
    return _categoryDao.deleteCategory(id);
  }

  @override
  Future<void> toggleArchive(String id, bool isArchived) async {
    await _categoryDao.toggleArchive(id, isArchived);
  }

  @override
  Future<void> updateSortOrders(Map<String, int> idToOrder) async {
    for (final entry in idToOrder.entries) {
      await _categoryDao.updateSortOrder(entry.key, entry.value);
    }
  }

  @override
  Future<CategoryStats> getStats(
    String categoryId,
    DateTime start,
    DateTime end,
  ) async {
    final expenses = await _expenseDao.getByCategoryAndDateRange(
      categoryId,
      start,
      end,
    );

    final totalCents = expenses.fold<int>(
      0,
      (sum, e) => sum + e.amountCents,
    );
    final count = expenses.length;
    final average = count > 0 ? totalCents ~/ count : 0;

    return CategoryStats(
      totalSpentCents: totalCents,
      transactionCount: count,
      averageCents: average,
      periodStart: start,
      periodEnd: end,
    );
  }

  @override
  Future<int> count() async {
    return _categoryDao.count();
  }
}
