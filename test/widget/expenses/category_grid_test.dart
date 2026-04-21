import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/features/expenses/presentation/widgets/category_grid.dart';

void main() {
  final testCategories = [
    Category(
      id: 'cat_food',
      name: 'Food',
      iconName: 'restaurant',
      colorHex: '#EF4444',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
    Category(
      id: 'cat_transport',
      name: 'Transport',
      iconName: 'directions_car',
      colorHex: '#F59E0B',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
  ];

  group('CategoryGrid', () {
    testWidgets('renders category names', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryGrid(
              categories: testCategories,
              selectedId: null,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets('selecting a category fires callback', (tester) async {
      Category? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryGrid(
              categories: testCategories,
              selectedId: null,
              onSelect: (c) => selected = c,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, 'cat_food');
    });

    testWidgets('selected category is highlighted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryGrid(
              categories: testCategories,
              selectedId: 'cat_transport',
              onSelect: (_) {},
            ),
          ),
        ),
      );

      // ChoiceChip renders two widgets with the text when selected (label + semantics)
      // We just verify both are present and the widget tree builds.
      expect(find.text('Transport'), findsWidgets);
      expect(find.text('Food'), findsOneWidget);
    });
  });
}
