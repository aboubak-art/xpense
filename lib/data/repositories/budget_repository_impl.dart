import 'package:xpense/data/datasources/budget_dao.dart';
import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/domain/entities/budget.dart';
import 'package:xpense/domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._budgetDao, this._expenseDao);

  final BudgetDao _budgetDao;
  final ExpenseDao _expenseDao;

  @override
  Future<List<Budget>> getAll() => _budgetDao.getAll();

  @override
  Future<Budget?> getById(String id) => _budgetDao.getById(id);

  @override
  Future<Budget> create(BudgetInput input) => _budgetDao.create(input);

  @override
  Future<void> update(String id, BudgetInput input) =>
      _budgetDao.updateBudget(id, input);

  @override
  Future<void> delete(String id) => _budgetDao.deleteBudget(id);

  @override
  Future<int> getSpentCents(String budgetId) async {
    final budget = await _budgetDao.getById(budgetId);
    if (budget == null) return 0;

    final (start, end) = _periodBounds(budget);
    if (budget.categoryId != null) {
      final expenses = await _expenseDao.getByCategoryAndDateRange(
        budget.categoryId!,
        start,
        end,
      );
      return expenses.fold<int>(0, (sum, e) => sum + e.amountCents);
    } else {
      final expenses = await _expenseDao.getByDateRange(start, end);
      return expenses.fold<int>(0, (sum, e) => sum + e.amountCents);
    }
  }

  @override
  Future<int> getRemainingCents(String budgetId) async {
    final budget = await _budgetDao.getById(budgetId);
    if (budget == null) return 0;
    final spent = await getSpentCents(budgetId);
    return budget.amountCents - spent;
  }

  (DateTime, DateTime) _periodBounds(Budget budget) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (budget.period) {
      case BudgetPeriod.daily:
        final start = today;
        final end = today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        return (start, end);
      case BudgetPeriod.weekly:
        // Start from the budget's startDate, find the current week
        final daysSinceStart = today.difference(budget.startDate).inDays;
        final weekStart = today.subtract(Duration(days: daysSinceStart % 7));
        final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
        final end = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
        return (start, end);
      case BudgetPeriod.monthly:
        final daysSinceStart = today.difference(budget.startDate).inDays;
        final monthsSinceStart = (daysSinceStart ~/ 30);
        final startMonth = DateTime(
          budget.startDate.year,
          budget.startDate.month + monthsSinceStart,
          budget.startDate.day,
        );
        final start = DateTime(startMonth.year, startMonth.month, startMonth.day);
        final endMonth = DateTime(startMonth.year, startMonth.month + 1, startMonth.day);
        final end = endMonth.subtract(const Duration(seconds: 1));
        return (start, end);
      case BudgetPeriod.custom:
        final end = budget.endDate ?? today;
        return (budget.startDate, end);
    }
  }
}
