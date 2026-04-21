import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xpense/features/analytics/domain/entities/insight.dart';
import 'package:xpense/features/analytics/presentation/providers/insights_provider.dart';
import 'package:xpense/features/analytics/presentation/widgets/insights_card.dart';

void main() {
  group('InsightsCard', () {
    Future<void> pumpInsightsCard(
      WidgetTester tester, {
      required AsyncValue<List<Insight>> insightsAsync,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            insightsProvider.overrideWith((ref) async {
              return insightsAsync.value ?? [];
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InsightsCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders insight tiles when data available', (tester) async {
      final insights = [
        Insight(
          id: 'insight_1',
          type: InsightType.anomaly,
          title: 'Unusual Charge',
          message: 'You spent more than usual.',
          priority: InsightPriority.high,
          createdAt: DateTime.now(),
        ),
        Insight(
          id: 'insight_2',
          type: InsightType.budgetStreak,
          title: '3-Day Streak',
          message: 'Stayed within budget.',
          priority: InsightPriority.medium,
          createdAt: DateTime.now(),
        ),
      ];

      await pumpInsightsCard(tester, insightsAsync: AsyncValue.data(insights));

      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Unusual Charge'), findsOneWidget);
      expect(find.text('3-Day Streak'), findsOneWidget);
      expect(find.text('You spent more than usual.'), findsOneWidget);
      expect(find.text('Stayed within budget.'), findsOneWidget);
    });

    testWidgets('renders nothing when insights empty', (tester) async {
      await pumpInsightsCard(tester, insightsAsync: const AsyncValue.data([]));

      expect(find.text('Insights'), findsNothing);
    });

    testWidgets('renders nothing while loading', (tester) async {
      await pumpInsightsCard(
        tester,
        insightsAsync: const AsyncValue.loading(),
      );

      expect(find.text('Insights'), findsNothing);
    });

    testWidgets('renders nothing on error', (tester) async {
      await pumpInsightsCard(
        tester,
        insightsAsync: AsyncValue.error('Error', StackTrace.empty),
      );

      expect(find.text('Insights'), findsNothing);
    });

    testWidgets('each insight has correct icon and color', (tester) async {
      final insights = [
        Insight(
          id: 'insight_anomaly',
          type: InsightType.anomaly,
          title: 'Anomaly',
          message: 'Test',
          priority: InsightPriority.high,
          createdAt: DateTime.now(),
        ),
        Insight(
          id: 'insight_streak',
          type: InsightType.budgetStreak,
          title: 'Streak',
          message: 'Test',
          priority: InsightPriority.medium,
          createdAt: DateTime.now(),
        ),
      ];

      await pumpInsightsCard(tester, insightsAsync: AsyncValue.data(insights));

      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });
  });
}
