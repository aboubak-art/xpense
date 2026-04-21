import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurring_expense.freezed.dart';

enum RecurringFrequency {
  daily,
  weekly,
  biWeekly,
  monthly,
  quarterly,
  yearly,
  custom
}

@freezed
class RecurringExpense with _$RecurringExpense {
  const factory RecurringExpense({
    required String id,
    required int amountCents,
    required String categoryId,
    required RecurringFrequency frequency,
    required DateTime startDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default('USD') String currency,
    String? note,
    String? merchant,
    String? paymentMethod,
    String? frequencyRule,
    DateTime? endDate,
    int? maxOccurrences,
    DateTime? deletedAt,
  }) = _RecurringExpense;
}

@freezed
class RecurringExpenseInput with _$RecurringExpenseInput {
  const factory RecurringExpenseInput({
    required int amountCents,
    required String categoryId,
    required RecurringFrequency frequency,
    required DateTime startDate,
    @Default('USD') String currency,
    String? note,
    String? merchant,
    String? paymentMethod,
    String? frequencyRule,
    DateTime? endDate,
    int? maxOccurrences,
  }) = _RecurringExpenseInput;
}
