import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/domain/entities/budget.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/features/analytics/domain/entities/insight.dart';

/// Provider for the list of active (non-dismissed) insights.
final insightsProvider = FutureProvider<List<Insight>>((ref) async {
  final expenseDao = ref.watch(expenseDaoProvider);
  final budgetDao = ref.watch(budgetDaoProvider);

  final expenses = await expenseDao.getAll(limit: 1000);
  final budgets = await budgetDao.getAll();

  final allInsights = computeInsights(expenses, budgets);

  final dismissed = await _loadDismissedIds();
  return allInsights.where((i) => !dismissed.contains(i.id)).toList();
});

Future<Set<String>> _loadDismissedIds() async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList('dismissed_insights') ?? [];
  return list.toSet();
}

/// Dismiss an insight by ID.
Future<void> dismissInsight(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList('dismissed_insights') ?? [];
  if (!list.contains(id)) {
    list.add(id);
    await prefs.setStringList('dismissed_insights', list);
  }
}

/// Computes all insights from expenses and budgets.
List<Insight> computeInsights(List<Expense> expenses, List<Budget> budgets) {
  final insights = <Insight>[
    ...dayOfWeekInsights(expenses),
    ...monthOverMonthInsight(expenses),
    ...anomalyInsights(expenses),
    ...budgetStreakInsight(expenses, budgets),
    ...milestoneInsights(expenses),
  ]..sort((a, b) {
      const priorityOrder = {
        InsightPriority.high: 0,
        InsightPriority.medium: 1,
        InsightPriority.low: 2,
      };
      return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
    });

  return insights.take(5).toList();
}

/// Computes day-of-week spending pattern insights.
List<Insight> dayOfWeekInsights(List<Expense> expenses) {
  if (expenses.length < 14) return [];

  final dayTotals = List<double>.filled(7, 0);
  final dayCounts = List<int>.filled(7, 0);

  for (final e in expenses) {
    final weekday = e.date.weekday % 7;
    dayTotals[weekday] += e.amountCents / 100;
    dayCounts[weekday]++;
  }

  final dayAverages = List<double>.generate(7, (i) {
    return dayCounts[i] > 0 ? dayTotals[i] / dayCounts[i] : 0;
  });

  final maxDay = dayAverages.indexOf(dayAverages.reduce(max));
  final minDay = dayAverages.indexOf(dayAverages.reduce(min));

  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  return [
    Insight(
      id: 'dow_highest_${dayNames[maxDay]}',
      type: InsightType.dayOfWeekPattern,
      title: 'Peak Spending Day',
      message: 'You spend the most on ${dayNames[maxDay]}s. '
          'Average: \$${dayAverages[maxDay].toStringAsFixed(2)} per day.',
      priority: InsightPriority.medium,
      createdAt: DateTime.now(),
    ),
    if (maxDay != minDay && dayAverages[minDay] > 0)
      Insight(
        id: 'dow_lowest_${dayNames[minDay]}',
        type: InsightType.dayOfWeekPattern,
        title: 'Lowest Spending Day',
        message: '${dayNames[minDay]}s are your lightest spending days. '
            'Average: \$${dayAverages[minDay].toStringAsFixed(2)} per day.',
        priority: InsightPriority.low,
        createdAt: DateTime.now(),
      ),
  ];
}

/// Computes month-over-month spending comparison insights.
List<Insight> monthOverMonthInsight(List<Expense> expenses) {
  final now = DateTime.now();
  final thisMonthStart = DateTime(now.year, now.month);
  final lastMonthStart = DateTime(now.year, now.month - 1);
  final lastMonthEnd = DateTime(now.year, now.month, 0);

  var thisMonthTotal = 0;
  var lastMonthTotal = 0;

  for (final e in expenses) {
    if (!e.date.isBefore(thisMonthStart)) {
      thisMonthTotal += e.amountCents;
    } else if (!e.date.isBefore(lastMonthStart) && !e.date.isAfter(lastMonthEnd)) {
      lastMonthTotal += e.amountCents;
    }
  }

  if (lastMonthTotal == 0) return [];

  final change = (thisMonthTotal - lastMonthTotal) / lastMonthTotal;
  final pct = (change.abs() * 100).round();

  if (change > 0.2) {
    return [
      Insight(
        id: 'mom_increase_${now.year}_${now.month}',
        type: InsightType.monthOverMonth,
        title: 'Spending Up $pct%',
        message: 'Your spending is up $pct% compared to last month. '
            'This month: \$${(thisMonthTotal / 100).toStringAsFixed(2)}, '
            'Last month: \$${(lastMonthTotal / 100).toStringAsFixed(2)}.',
        priority: InsightPriority.high,
        createdAt: DateTime.now(),
      ),
    ];
  } else if (change < -0.2) {
    return [
      Insight(
        id: 'mom_decrease_${now.year}_${now.month}',
        type: InsightType.monthOverMonth,
        title: 'Spending Down $pct%',
        message: 'Great job! Your spending is down $pct% compared to last month.',
        priority: InsightPriority.low,
        createdAt: DateTime.now(),
      ),
    ];
  }

  return [];
}

/// Computes anomaly detection insights for unusual charges.
List<Insight> anomalyInsights(List<Expense> expenses) {
  if (expenses.length < 10) return [];

  final amounts = expenses.map((e) => e.amountCents / 100).toList();
  final mean = amounts.reduce((a, b) => a + b) / amounts.length;
  final variance = amounts.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) / amounts.length;
  final stdDev = sqrt(variance);

  final threshold = mean + (2.5 * stdDev);
  final anomalies = expenses.where((e) => e.amountCents / 100 > threshold).toList();

  if (anomalies.isEmpty) return [];

  // Show the most recent anomaly
  final anomaly = anomalies.first;
  final note = anomaly.note ?? anomaly.merchant ?? 'an expense';

  return [
    Insight(
      id: 'anomaly_${anomaly.id}',
      type: InsightType.anomaly,
      title: 'Unusual Charge Detected',
      message: 'Your \$${(anomaly.amountCents / 100).toStringAsFixed(2)} '
          'charge for "$note" is higher than usual. '
          'Your average expense is \$${mean.toStringAsFixed(2)}.',
      priority: InsightPriority.high,
      createdAt: DateTime.now(),
    ),
  ];
}

/// Computes budget streak insights.
List<Insight> budgetStreakInsight(List<Expense> expenses, List<Budget> budgets) {
  if (budgets.isEmpty || expenses.isEmpty) return [];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Simple overall daily budget streak
  final overallBudget = budgets.firstWhere(
    (b) => b.categoryId == null,
    orElse: () => budgets.first,
  );

  final dailyBudget = overallBudget.amountCents / 30;
  var streak = 0;
  var checkDate = today;

  while (true) {
    final dayTotal = expenses
        .where((e) {
          final d = DateTime(e.date.year, e.date.month, e.date.day);
          return d == checkDate;
        })
        .fold<int>(0, (sum, e) => sum + e.amountCents);

    if (dayTotal <= dailyBudget) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }

    if (streak > 365) break; // Safety limit
  }

  if (streak < 3) return [];

  return [
    Insight(
      id: 'streak_${today.year}_${today.month}_${today.day}',
      type: InsightType.budgetStreak,
      title: streak >= 7 ? '🔥 $streak-Day Streak!' : '$streak-Day Streak',
      message: streak >= 7
          ? 'Incredible! You have stayed within your daily budget for $streak days in a row.'
          : 'You have stayed within your daily budget for $streak days in a row. Keep it up!',
      priority: streak >= 7 ? InsightPriority.high : InsightPriority.medium,
      createdAt: DateTime.now(),
    ),
  ];
}

/// Computes milestone insights for tracking achievements.
List<Insight> milestoneInsights(List<Expense> expenses) {
  final insights = <Insight>[];

  if (expenses.length >= 100 && expenses.length % 100 == 0) {
    insights.add(
      Insight(
        id: 'milestone_${expenses.length}_expenses',
        type: InsightType.milestone,
        title: '🎉 ${expenses.length} Expenses Tracked!',
        message: 'You have tracked ${expenses.length} expenses in Xpense. '
            'That is a lot of financial awareness!',
        priority: InsightPriority.medium,
        createdAt: DateTime.now(),
      ),
    );
  }

  final totalTracked = expenses.fold<int>(0, (sum, e) => sum + e.amountCents);
  final milestones = [10000, 25000, 50000, 100000]; // dollars in cents

  for (final milestone in milestones) {
    if (totalTracked >= milestone * 100) {
      insights.add(
        Insight(
          id: 'milestone_spent_$milestone',
          type: InsightType.milestone,
          title: '\$${milestone.toStringAsFixed(0)}k Tracked',
          message: 'You have tracked over \$${milestone.toStringAsFixed(0)}k in spending. '
              'Your financial awareness is growing!',
          priority: InsightPriority.low,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  return insights;
}
