import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense.freezed.dart';

@freezed
class Expense with _$Expense {
  const factory Expense({
    required String id,
    required int amountCents,
    required String categoryId,
    required DateTime date,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default('USD') String currency,
    String? note,
    String? merchant,
    String? paymentMethod,
    List<String>? tags,
    String? location,
    String? recurringExpenseId,
    DateTime? deletedAt,
  }) = _Expense;
}

@freezed
class ExpenseInput with _$ExpenseInput {
  const factory ExpenseInput({
    required int amountCents,
    required String categoryId,
    required DateTime date,
    @Default('USD') String currency,
    String? note,
    String? merchant,
    String? paymentMethod,
    List<String>? tags,
    String? location,
    String? recurringExpenseId,
  }) = _ExpenseInput;
}
