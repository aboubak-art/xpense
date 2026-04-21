import 'package:xpense/domain/entities/budget.dart';

/// Repository interface for budget operations.
abstract class BudgetRepository {
  /// Get all non-deleted budgets.
  Future<List<Budget>> getAll();

  /// Get a single budget by id.
  Future<Budget?> getById(String id);

  /// Create a new budget.
  Future<Budget> create(BudgetInput input);

  /// Update an existing budget.
  Future<void> update(String id, BudgetInput input);

  /// Soft-delete a budget.
  Future<void> delete(String id);

  /// Get spent amount (in cents) for a budget in its current active period.
  Future<int> getSpentCents(String budgetId);

  /// Get remaining amount (in cents) for a budget in its current period.
  Future<int> getRemainingCents(String budgetId);
}
