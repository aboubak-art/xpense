import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/data/datasources/recurring_expense_dao.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/domain/entities/recurring_expense.dart';

/// Engine that generates expense occurrences from recurring expense definitions.
///
/// For each active recurring expense, the engine:
/// 1. Counts already-generated expenses
/// 2. Computes the next due date based on frequency
/// 3. Creates an expense record if the next date is in the past/present
///    and end conditions are not met.
class RecurringExpenseEngine {
  RecurringExpenseEngine(this._recurringDao, this._expenseDao);

  final RecurringExpenseDao _recurringDao;
  final ExpenseDao _expenseDao;

  /// Generate all due occurrences as of [asOf].
  /// Returns the number of expenses created.
  Future<int> generateOccurrences({DateTime? asOf}) async {
    final now = asOf ?? DateTime.now();
    final recurringList = await _recurringDao.getActive(now);

    var createdCount = 0;
    for (final recurring in recurringList) {
      createdCount += await _generateForRecurring(recurring, now);
    }
    return createdCount;
  }

  Future<int> _generateForRecurring(
    RecurringExpense recurring,
    DateTime asOf,
  ) async {
    var createdCount = 0;

    while (true) {
      // Get all already-generated expenses for this recurring series
      final seriesExpenses = await _expenseDao.getByRecurringExpenseId(
        recurring.id,
      );

      // Sort by date ascending to compute next date
      seriesExpenses.sort((a, b) => a.date.compareTo(b.date));

      final occurrenceCount = seriesExpenses.length;

      // Check max occurrences end condition
      if (recurring.maxOccurrences != null &&
          occurrenceCount >= recurring.maxOccurrences!) {
        break;
      }

      // Determine the next due date
      final nextDate = _computeNextDate(
        recurring: recurring,
        lastGeneratedDate: seriesExpenses.isNotEmpty
            ? seriesExpenses.last.date
            : null,
        occurrenceCount: occurrenceCount,
      );

      if (nextDate == null || nextDate.isAfter(asOf)) {
        break;
      }

      // Check end date condition
      if (recurring.endDate != null && nextDate.isAfter(recurring.endDate!)) {
        break;
      }

      // Create the expense
      await _expenseDao.create(
        ExpenseInput(
          amountCents: recurring.amountCents,
          categoryId: recurring.categoryId,
          date: nextDate,
          currency: recurring.currency,
          note: recurring.note,
          merchant: recurring.merchant,
          paymentMethod: recurring.paymentMethod,
          recurringExpenseId: recurring.id,
        ),
      );

      createdCount++;
    }

    return createdCount;
  }

  /// Compute the next occurrence date for a recurring expense.
  ///
  /// [lastGeneratedDate] is the date of the most recently generated expense,
  /// or null if none have been generated yet.
  /// [occurrenceCount] is how many expenses have already been generated.
  DateTime? _computeNextDate({
    required RecurringExpense recurring,
    required DateTime? lastGeneratedDate,
    required int occurrenceCount,
  }) {
    // If nothing generated yet, the first occurrence is on startDate
    if (lastGeneratedDate == null) {
      return DateTime(
        recurring.startDate.year,
        recurring.startDate.month,
        recurring.startDate.day,
      );
    }

    // Compute based on frequency
    final base = DateTime(
      lastGeneratedDate.year,
      lastGeneratedDate.month,
      lastGeneratedDate.day,
    );

    return switch (recurring.frequency) {
      RecurringFrequency.daily => base.add(const Duration(days: 1)),
      RecurringFrequency.weekly => base.add(const Duration(days: 7)),
      RecurringFrequency.biWeekly => base.add(const Duration(days: 14)),
      RecurringFrequency.monthly => _addMonths(base, 1),
      RecurringFrequency.quarterly => _addMonths(base, 3),
      RecurringFrequency.yearly => _addMonths(base, 12),
      RecurringFrequency.custom => _parseCustomRule(recurring.frequencyRule, base),
    };
  }

  DateTime _addMonths(DateTime date, int months) {
    var newMonth = date.month + months;
    var newYear = date.year;
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    // Handle month-end overflow (e.g., Jan 31 + 1 month = Feb 28)
    final lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    final newDay = date.day > lastDayOfNewMonth ? lastDayOfNewMonth : date.day;
    return DateTime(newYear, newMonth, newDay);
  }

  DateTime? _parseCustomRule(String? rule, DateTime base) {
    if (rule == null) return null;
    // Custom rules are not fully implemented;
    // fallback to monthly for now.
    return _addMonths(base, 1);
  }
}
