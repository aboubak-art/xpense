import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/features/expenses/presentation/widgets/expense_card.dart';

void main() {
  group('ExpenseCard', () {
    final testCategory = Category(
      id: 'cat_food',
      name: 'Food',
      iconName: 'restaurant',
      colorHex: '#EF4444',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    final testExpense = Expense(
      id: 'exp_1',
      amountCents: 1250,
      categoryId: 'cat_food',
      date: DateTime(2024, 6, 15, 10, 30),
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      note: 'Lunch',
      merchant: 'Chipotle',
    );

    Widget pumpCard({
      required Expense expense,
      Category? category,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
      bool? isSelected,
      VoidCallback? onToggleSelect,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: ExpenseCard(
              expense: expense,
              category: category,
              onEdit: onEdit ?? () {},
              onDelete: onDelete ?? () {},
              isSelected: isSelected,
              onToggleSelect: onToggleSelect,
            ),
          ),
        ),
      );
    }

    testWidgets('renders expense title, amount and category', (tester) async {
      await tester.pumpWidget(
        pumpCard(expense: testExpense, category: testCategory),
      );

      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text(r'$12.50'), findsOneWidget);
      expect(find.textContaining('Food'), findsOneWidget);
    });

    testWidgets('renders merchant when note is empty', (tester) async {
      final expense = testExpense.copyWith(note: null);
      await tester.pumpWidget(
        pumpCard(expense: expense, category: testCategory),
      );

      expect(find.text('Chipotle'), findsOneWidget);
    });

    testWidgets('renders "Expense" when both note and merchant are empty',
        (tester) async {
      final expense = testExpense.copyWith(note: null, merchant: null);
      await tester.pumpWidget(
        pumpCard(expense: expense, category: testCategory),
      );

      expect(find.text('Expense'), findsOneWidget);
    });

    testWidgets('slidable reveals Edit and Delete actions', (tester) async {
      await tester.pumpWidget(
        pumpCard(expense: testExpense, category: testCategory),
      );

      // Slidable should be present
      expect(find.byType(Slidable), findsOneWidget);

      // Fling to reveal actions
      await tester.fling(
        find.byType(Slidable),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SlidableAction), findsNWidgets(2));
    });

    testWidgets('tapping Edit action triggers onEdit callback', (tester) async {
      var editCalled = false;
      await tester.pumpWidget(
        pumpCard(
          expense: testExpense,
          category: testCategory,
          onEdit: () => editCalled = true,
        ),
      );

      await tester.fling(
        find.byType(Slidable),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // Find the primary-colored action (Edit)
      final actions = tester.widgetList<SlidableAction>(
        find.byType(SlidableAction),
      );
      final editAction = actions.firstWhere(
        (a) => a.backgroundColor == const Color(0xFF000000) || a.icon == Icons.edit,
        orElse: () => actions.first,
      );

      // Tap the first SlidableAction widget (Edit)
      await tester.tap(find.byWidget(editAction));
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
    });

    testWidgets('tapping Delete action triggers onDelete callback',
        (tester) async {
      var deleteCalled = false;
      await tester.pumpWidget(
        pumpCard(
          expense: testExpense,
          category: testCategory,
          onDelete: () => deleteCalled = true,
        ),
      );

      await tester.fling(
        find.byType(Slidable),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      final actions = tester.widgetList<SlidableAction>(
        find.byType(SlidableAction),
      ).toList();

      // Tap the second action (Delete)
      await tester.tap(find.byWidget(actions[1]));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });

    testWidgets('long press triggers onToggleSelect callback', (tester) async {
      var toggleCalled = false;
      await tester.pumpWidget(
        pumpCard(
          expense: testExpense,
          category: testCategory,
          onToggleSelect: () => toggleCalled = true,
        ),
      );

      await tester.longPress(find.byType(Slidable));
      await tester.pumpAndSettle();

      expect(toggleCalled, isTrue);
    });

    testWidgets('shows checkbox when isSelected is true', (tester) async {
      await tester.pumpWidget(
        pumpCard(
          expense: testExpense,
          category: testCategory,
          isSelected: true,
          onToggleSelect: () {},
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('shows unchecked checkbox when isSelected is false',
        (tester) async {
      await tester.pumpWidget(
        pumpCard(
          expense: testExpense,
          category: testCategory,
          isSelected: false,
          onToggleSelect: () {},
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('tapping card in selection mode toggles selection',
        (tester) async {
      var toggleCalled = false;
      await tester.pumpWidget(
        pumpCard(
          expense: testExpense,
          category: testCategory,
          isSelected: false,
          onToggleSelect: () => toggleCalled = true,
        ),
      );

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(toggleCalled, isTrue);
    });

    testWidgets('no slidable when in selection mode', (tester) async {
      await tester.pumpWidget(
        pumpCard(
          expense: testExpense,
          category: testCategory,
          isSelected: true,
          onToggleSelect: () {},
        ),
      );

      expect(find.byType(Slidable), findsNothing);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('uses fallback color when category is null', (tester) async {
      await tester.pumpWidget(
        pumpCard(expense: testExpense),
      );

      expect(find.textContaining('Uncategorized'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
    });
  });
}
