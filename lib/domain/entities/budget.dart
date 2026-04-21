import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';

enum BudgetPeriod { daily, weekly, monthly, custom }

@freezed
class Budget with _$Budget {
  const factory Budget({
    required String id,
    required String name,
    required int amountCents,
    required DateTime startDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default('USD') String currency,
    @Default(BudgetPeriod.monthly) BudgetPeriod period,
    String? categoryId,
    DateTime? endDate,
    @Default(false) bool rolloverUnused,
    @Default(80) int alertThresholdPercent,
    DateTime? deletedAt,
  }) = _Budget;
}

@freezed
class BudgetInput with _$BudgetInput {
  const factory BudgetInput({
    required String name,
    required int amountCents,
    required DateTime startDate,
    @Default('USD') String currency,
    @Default(BudgetPeriod.monthly) BudgetPeriod period,
    String? categoryId,
    DateTime? endDate,
    @Default(false) bool rolloverUnused,
    @Default(80) int alertThresholdPercent,
  }) = _BudgetInput;
}
