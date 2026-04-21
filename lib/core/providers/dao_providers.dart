import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xpense/core/providers/database_provider.dart';
import 'package:xpense/data/datasources/category_dao.dart';
import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/data/datasources/recurring_expense_dao.dart';

final expenseDaoProvider = Provider<ExpenseDao>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseDao(db);
});

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryDao(db);
});

final recurringExpenseDaoProvider = Provider<RecurringExpenseDao>((ref) {
  final database = ref.watch(databaseProvider);
  return RecurringExpenseDao(database);
});
