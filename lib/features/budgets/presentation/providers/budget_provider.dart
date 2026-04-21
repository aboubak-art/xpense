import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/domain/entities/budget.dart';
import 'package:xpense/domain/repositories/budget_repository.dart';

/// Provider for the list of budgets.
final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getAll();
});

/// Provider for a single budget by id.
final budgetDetailProvider =
    FutureProvider.family<Budget?, String>((ref, id) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getById(id);
});

/// Provider for spent amount of a budget.
final budgetSpentProvider =
    FutureProvider.family<int, String>((ref, budgetId) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getSpentCents(budgetId);
});

/// Notifier for budget list operations.
class BudgetListNotifier extends StateNotifier<AsyncValue<List<Budget>>> {
  BudgetListNotifier(this._repository) : super(const AsyncValue.loading());

  final BudgetRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final budgets = await _repository.getAll();
      state = AsyncValue.data(budgets);
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

final budgetListNotifierProvider =
    StateNotifierProvider<BudgetListNotifier, AsyncValue<List<Budget>>>(
  (ref) {
    final repo = ref.watch(budgetRepositoryProvider);
    return BudgetListNotifier(repo);
  },
);

/// Notifier for budget form (create/update).
class BudgetFormNotifier extends StateNotifier<AsyncValue<Budget?>> {
  BudgetFormNotifier(this._repository) : super(const AsyncValue.data(null));

  final BudgetRepository _repository;

  Future<Budget?> create(BudgetInput input) async {
    state = const AsyncValue.loading();
    try {
      final budget = await _repository.create(input);
      state = AsyncValue.data(budget);
      return budget;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<Budget?> update(String id, BudgetInput input) async {
    state = const AsyncValue.loading();
    try {
      await _repository.update(id, input);
      final budget = await _repository.getById(id);
      state = AsyncValue.data(budget);
      return budget;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final budgetFormNotifierProvider =
    StateNotifierProvider<BudgetFormNotifier, AsyncValue<Budget?>>((ref) {
  final repo = ref.watch(budgetRepositoryProvider);
  return BudgetFormNotifier(repo);
});
