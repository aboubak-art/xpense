import 'package:freezed_annotation/freezed_annotation.dart';

part 'insight.freezed.dart';

enum InsightType {
  dayOfWeekPattern,
  monthOverMonth,
  anomaly,
  budgetStreak,
  milestone,
}

enum InsightPriority { low, medium, high }

/// A computed insight about the user's spending behavior.
@freezed
class Insight with _$Insight {
  const factory Insight({
    required String id,
    required InsightType type,
    required String title,
    required String message,
    required InsightPriority priority,
    DateTime? createdAt,
  }) = _Insight;
}
