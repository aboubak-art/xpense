import 'package:flutter_test/flutter_test.dart';
import 'package:xpense/domain/entities/budget.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/features/analytics/domain/entities/insight.dart';
import 'package:xpense/features/analytics/presentation/providers/insights_provider.dart';

void main() {
  group('computeInsights', () {
    test('returns empty list when no expenses', () {
      final insights = computeInsights([], []);
      expect(insights, isEmpty);
    });

    test('returns at most 5 insights', () {
      final expenses = List.generate(
        100,
        (i) => Expense(
          id: 'exp_$i',
          amountCents: 1000,
          categoryId: 'cat_food',
          date: DateTime.now().subtract(Duration(days: i)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final budget = Budget(
        id: 'budget_1',
        name: 'Monthly',
        amountCents: 300000,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final insights = computeInsights(expenses, [budget]);
      expect(insights.length, lessThanOrEqualTo(5));
    });

    test('sorts insights by priority high to low', () {
      final insights = computeInsights(
        _generateManyExpenses(),
        [_generateBudget()],
      );

      for (var i = 0; i < insights.length - 1; i++) {
        final currentPriority = insights[i].priority;
        final nextPriority = insights[i + 1].priority;
        expect(
          _priorityValue(currentPriority) <= _priorityValue(nextPriority),
          isTrue,
        );
      }
    });
  });

  group('dayOfWeekInsights', () {
    test('returns empty when fewer than 14 expenses', () {
      final expenses = List.generate(
        10,
        (i) => _expense(
          amountCents: 1000,
          date: DateTime.now().subtract(Duration(days: i)),
        ),
      );
      expect(dayOfWeekInsights(expenses), isEmpty);
    });

    test('returns peak and lowest spending day insights', () {
      final expenses = List.generate(
        14,
        (i) {
          // All on Monday (weekday 1)
          final date = DateTime(2024, 1, 1 + i * 7); // Mondays
          return _expense(amountCents: 5000, date: date);
        },
      );

      final insights = dayOfWeekInsights(expenses);
      expect(insights.length, 1);
      expect(insights.first.type, InsightType.dayOfWeekPattern);
      expect(insights.first.title, 'Peak Spending Day');
    });
  });

  group('monthOverMonthInsight', () {
    test('returns empty when no last month data', () {
      final now = DateTime.now();
      final expenses = [
        _expense(
          amountCents: 1000,
          date: DateTime(now.year, now.month, 5),
        ),
      ];
      expect(monthOverMonthInsight(expenses), isEmpty);
    });

    test('returns increase insight when spending up >20%', () {
      final now = DateTime.now();
      final expenses = [
        // Last month: $100
        _expense(
          amountCents: 10000,
          date: DateTime(now.year, now.month - 1, 5),
        ),
        // This month: $150 (50% increase)
        _expense(
          amountCents: 15000,
          date: DateTime(now.year, now.month, 5),
        ),
      ];

      final insights = monthOverMonthInsight(expenses);
      expect(insights.length, 1);
      expect(insights.first.type, InsightType.monthOverMonth);
      expect(insights.first.title, contains('Spending Up'));
      expect(insights.first.priority, InsightPriority.high);
    });

    test('returns decrease insight when spending down >20%', () {
      final now = DateTime.now();
      final expenses = [
        // Last month: $100
        _expense(
          amountCents: 10000,
          date: DateTime(now.year, now.month - 1, 5),
        ),
        // This month: $50 (50% decrease)
        _expense(
          amountCents: 5000,
          date: DateTime(now.year, now.month, 5),
        ),
      ];

      final insights = monthOverMonthInsight(expenses);
      expect(insights.length, 1);
      expect(insights.first.type, InsightType.monthOverMonth);
      expect(insights.first.title, contains('Spending Down'));
      expect(insights.first.priority, InsightPriority.low);
    });

    test('returns empty when change is within 20%', () {
      final now = DateTime.now();
      final expenses = [
        _expense(
          amountCents: 10000,
          date: DateTime(now.year, now.month - 1, 5),
        ),
        _expense(
          amountCents: 11000,
          date: DateTime(now.year, now.month, 5),
        ),
      ];

      expect(monthOverMonthInsight(expenses), isEmpty);
    });
  });

  group('anomalyInsights', () {
    test('returns empty when fewer than 10 expenses', () {
      final expenses = List.generate(9, (i) => _expense(amountCents: 1000));
      expect(anomalyInsights(expenses), isEmpty);
    });

    test('detects unusually high expense', () {
      final expenses = [
        ...List.generate(9, (i) => _expense(amountCents: 1000)),
        _expense(amountCents: 50000), // $500 - way above average
      ];

      final insights = anomalyInsights(expenses);
      expect(insights.length, 1);
      expect(insights.first.type, InsightType.anomaly);
      expect(insights.first.title, 'Unusual Charge Detected');
      expect(insights.first.priority, InsightPriority.high);
    });

    test('returns empty when no anomalies', () {
      final expenses = List.generate(15, (i) => _expense(amountCents: 1000 + i * 100));
      expect(anomalyInsights(expenses), isEmpty);
    });
  });

  group('budgetStreakInsight', () {
    test('returns empty when no budgets', () {
      final expenses = [_expense(amountCents: 1000)];
      expect(budgetStreakInsight(expenses, []), isEmpty);
    });

    test('returns empty when streak < 3 days', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expenses = [
        _expense(amountCents: 50000, date: today), // Over budget
      ];
      final budget = _generateBudget(amountCents: 10000); // $100 / 30 days

      expect(budgetStreakInsight(expenses, [budget]), isEmpty);
    });

    test('returns streak insight for 3+ days', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expenses = [
        _expense(amountCents: 100, date: today),
        _expense(amountCents: 100, date: today.subtract(const Duration(days: 1))),
        _expense(amountCents: 100, date: today.subtract(const Duration(days: 2))),
      ];
      final budget = _generateBudget(amountCents: 300000); // $3000 / 30 = $100/day

      final insights = budgetStreakInsight(expenses, [budget]);
      expect(insights.length, 1);
      expect(insights.first.type, InsightType.budgetStreak);
      expect(insights.first.title, contains('Streak'));
    });
  });

  group('milestoneInsights', () {
    test('returns expense count milestone at multiples of 100', () {
      final expenses = List.generate(100, (i) => _expense(amountCents: 100));
      final insights = milestoneInsights(expenses);

      final countMilestone = insights.where(
        (i) => i.title.contains('Expenses Tracked'),
      );
      expect(countMilestone.length, 1);
      expect(countMilestone.first.type, InsightType.milestone);
    });

    test('returns spending milestone when threshold reached', () {
      final expenses = [
        _expense(amountCents: 1000001), // > $10,000
      ];
      final insights = milestoneInsights(expenses);

      final spendMilestones = insights.where(
        (i) => i.title.contains('Tracked'),
      );
      expect(spendMilestones.isNotEmpty, isTrue);
      expect(spendMilestones.first.type, InsightType.milestone);
    });

    test('returns empty when no milestones reached', () {
      final expenses = List.generate(50, (i) => _expense(amountCents: 100));
      expect(milestoneInsights(expenses), isEmpty);
    });
  });
}

int _priorityValue(InsightPriority priority) {
  return switch (priority) {
    InsightPriority.high => 0,
    InsightPriority.medium => 1,
    InsightPriority.low => 2,
  };
}

Expense _expense({
  required int amountCents,
  DateTime? date,
  String? note,
}) {
  final d = date ?? DateTime.now();
  return Expense(
    id: 'exp_${d.millisecondsSinceEpoch}_$amountCents',
    amountCents: amountCents,
    categoryId: 'cat_food',
    date: d,
    createdAt: d,
    updatedAt: d,
    note: note,
  );
}

Budget _generateBudget({int amountCents = 300000}) {
  return Budget(
    id: 'budget_1',
    name: 'Monthly Budget',
    amountCents: amountCents,
    startDate: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

List<Expense> _generateManyExpenses() {
  return List.generate(
    100,
    (i) => _expense(
      amountCents: 1000 + (i % 10) * 100,
      date: DateTime.now().subtract(Duration(days: i)),
    ),
  );
}
