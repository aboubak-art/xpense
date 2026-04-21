import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/domain/services/recurring_expense_engine.dart';

final recurringExpenseEngineProvider = Provider<RecurringExpenseEngine>((ref) {
  final recurringDao = ref.watch(recurringExpenseDaoProvider);
  final expenseDao = ref.watch(expenseDaoProvider);
  return RecurringExpenseEngine(recurringDao, expenseDao);
});
