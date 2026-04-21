import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/repositories/category_repository.dart';

/// Provider for the list of categories.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getAll();
});

/// Provider for all categories including archived.
final allCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getAll(includeArchived: true);
});

/// Provider for a single category by id.
final categoryDetailProvider =
    FutureProvider.family<Category?, String>((ref, id) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getById(id);
});

/// Provider for subcategories of a given parent.
final subcategoriesProvider =
    FutureProvider.family<List<Category>, String>((ref, parentId) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getSubcategories(parentId);
});

/// Provider for category stats (current month by default).
final categoryStatsProvider = FutureProvider.family<CategoryStats, String>(
  (ref, categoryId) async {
    final repo = ref.watch(categoryRepositoryProvider);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return repo.getStats(categoryId, start, end);
  },
);

/// Notifier for category list operations (reorder, archive, delete).
class CategoryListNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  CategoryListNotifier(this._repository)
      : super(const AsyncValue.loading());

  final CategoryRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final categories = await _repository.getAll();
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final items = List<Category>.from(current);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    // Optimistic update
    state = AsyncValue.data(items);

    try {
      final idToOrder = <String, int>{};
      for (var i = 0; i < items.length; i++) {
        idToOrder[items[i].id] = i;
      }
      await _repository.updateSortOrders(idToOrder);
      // Reload to ensure consistency
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleArchive(String id, bool isArchived) async {
    try {
      await _repository.toggleArchive(id, isArchived);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repository.delete(id);
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final categoryListNotifierProvider =
    StateNotifierProvider<CategoryListNotifier, AsyncValue<List<Category>>>(
  (ref) {
    final repo = ref.watch(categoryRepositoryProvider);
    return CategoryListNotifier(repo);
  },
);

/// Notifier for category form (create/update).
class CategoryFormNotifier extends StateNotifier<AsyncValue<Category?>> {
  CategoryFormNotifier(this._repository)
      : super(const AsyncValue.data(null));

  final CategoryRepository _repository;

  Future<Category?> create(CategoryInput input) async {
    state = const AsyncValue.loading();
    try {
      final category = await _repository.create(input);
      state = AsyncValue.data(category);
      return category;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<Category?> update(String id, CategoryInput input) async {
    state = const AsyncValue.loading();
    try {
      await _repository.update(id, input);
      final category = await _repository.getById(id);
      state = AsyncValue.data(category);
      return category;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final categoryFormNotifierProvider =
    StateNotifierProvider<CategoryFormNotifier, AsyncValue<Category?>>(
  (ref) {
    final repo = ref.watch(categoryRepositoryProvider);
    return CategoryFormNotifier(repo);
  },
);
