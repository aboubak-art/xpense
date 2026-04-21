# Xpense - Testing Strategy

## Testing Pyramid

```
       /\
      /  \     E2E Tests (10%)  — Critical user journeys
     /    \
    /------\   Integration (20%) — Feature flows, repository + DB
   /        \
  /----------\ Unit Tests (70%)  — Use cases, models, utilities
```

## Test Organization

```
test/
├── unit/
│   ├── domain/
│   │   ├── usecases/
│   │   └── entities/
│   ├── data/
│   │   ├── repositories/
│   │   └── models/
│   └── core/
│       └── utils/
├── widget/
│   ├── pages/
│   └── components/
├── integration/
│   ├── flows/
│   └── database/
└── golden/
    ├── android/
    └── ios/
```

## Unit Testing

### Domain Layer Tests
Test business logic in isolation with mocked repositories.

```dart
// Example: AddExpenseUseCase test
group('AddExpenseUseCase', () {
  late MockExpensesRepository repository;
  late AddExpenseUseCase useCase;

  setUp(() {
    repository = MockExpensesRepository();
    useCase = AddExpenseUseCase(repository);
  });

  test('should add expense and update budget spent amount', () async {
    final expense = Expense.mock();
    when(() => repository.add(expense)).thenAnswer((_) async {});

    await useCase(expense);

    verify(() => repository.add(expense)).called(1);
  });

  test('should throw ValidationFailure when amount is zero', () async {
    final expense = Expense.mock(amount: Decimal.zero);

    expect(() => useCase(expense), throwsA(isA<ValidationFailure>()));
  });
});
```

### Data Layer Tests
Test repository mapping and data source coordination.

```dart
group('ExpensesRepositoryImpl', () {
  test('should map local model to domain entity', () async {
    final localModel = ExpenseModel.mock();
    when(() => localDataSource.getById(any())).thenAnswer((_) async => localModel);

    final result = await repository.getById('123');

    expect(result.amount, equals(localModel.amount));
    expect(result.categoryId, equals(localModel.categoryId));
  });
});
```

### Model Tests
Test serialization, equality, and validation.

```dart
group('ExpenseModel', () {
  test('should serialize to and from JSON', () {
    final model = ExpenseModel.mock();
    final json = model.toJson();
    final fromJson = ExpenseModel.fromJson(json);

    expect(fromJson, equals(model));
  });
});
```

## Widget Testing

### Page Tests
Test full page rendering and interaction.

```dart
testWidgets('DashboardPage shows today\'s spending', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expensesNotifierProvider.overrideWith((ref) => mockNotifier),
      ],
      child: const MaterialApp(home: DashboardPage()),
    ),
  );

  await tester.pumpAndSettle();

  expect(find.text('\$45.20'), findsOneWidget);
  expect(find.text('Today'), findsOneWidget);
});
```

### Component Tests
Test reusable widgets in isolation.

```dart
testWidgets('BudgetRing shows correct percentage', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BudgetRing(spent: 75, total: 100),
    ),
  );

  expect(find.text('75%'), findsOneWidget);
});
```

### Accessibility Tests

```dart
testWidgets('AddExpensePage is accessible', (tester) async {
  final SemanticsHandle handle = tester.ensureSemantics();

  await tester.pumpWidget(MaterialApp(home: AddExpensePage()));

  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

  handle.dispose();
});
```

## Golden Tests

Capture pixel-perfect screenshots for regression detection.

```dart
testWidgets('Dashboard golden', (tester) async {
  await tester.pumpWidget(ProviderScope(child: MaterialApp(home: DashboardPage())));
  await tester.pumpAndSettle();

  await expectLater(
    find.byType(DashboardPage),
    matchesGoldenFile('goldens/dashboard.png'),
  );
});
```

**Golden file management:**
- Store in `test/golden/` with platform subdirectories
- Update via CI: `flutter test --update-goldens`
- Fail CI on golden diffs

## Integration Testing

### Database Integration
Test Drift operations with in-memory database.

```dart
group('AppDatabase Integration', () {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('should insert and retrieve expense', () async {
    final expense = ExpensesCompanion.insert(/* ... */);
    await database.into(database.expenses).insert(expense);

    final results = await database.select(database.expenses).get();
    expect(results.length, 1);
  });
});
```

### End-to-End Flows
Test complete user journeys.

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete expense flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Onboarding
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Add first expense
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('amount_input')), '45.50');
    await tester.tap(find.text('Food'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify on dashboard
    expect(find.text('\$45.50'), findsOneWidget);
  });
}
```

## Mocking Strategy

### Repository Mocks
```dart
class MockExpensesRepository extends Mock implements ExpensesRepository {}
```

### Drift DAO Mocks
Use `MockDatabase` or inject DAO interfaces.

```dart
class MockExpensesDao extends Mock implements ExpensesDao {}
```

### External Service Mocks
```dart
class MockHapticsService extends Mock implements HapticsService {}
class MockSyncEngine extends Mock implements SyncEngine {}
```

## Test Data

Centralized test data factories:

```dart
class TestData {
  static Expense expense({Decimal? amount, String? categoryId}) {
    return Expense(
      id: 'test-${_counter++}',
      amount: amount ?? Decimal.parse('45.50'),
      categoryId: categoryId ?? 'cat-food',
      date: DateTime(2024, 1, 15),
    );
  }

  static Category category() { /* ... */ }
  static Budget budget() { /* ... */ }
}
```

## CI/CD Integration

### GitHub Actions Workflow
```yaml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: dart format --set-exit-if-changed lib test
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info
```

### Coverage Gates
- PR cannot merge if coverage drops by >2%
- Minimum 80% overall coverage
- Domain layer: 90% minimum

## Testing Checklist

### Before Commit
- [ ] All unit tests pass
- [ ] Widget tests pass
- [ ] No analyzer warnings
- [ ] Code formatted with `dart format`

### Before PR Merge
- [ ] Integration tests pass
- [ ] Golden tests pass (or updated intentionally)
- [ ] Coverage report reviewed
- [ ] Accessibility tests pass
- [ ] Tested on iOS simulator
- [ ] Tested on Android emulator

### Before Release
- [ ] Full E2E suite on physical devices
- [ ] Performance tests: startup <1.5s, scroll 60fps
- [ ] Memory leak detection (DevTools)
- [ ] Battery impact assessment
- [ ] Offline mode fully tested
- [ ] Sync conflict scenarios tested
- [ ] Backup/restore cycle verified
- [ ] Security audit: encryption, key storage

## Performance Testing

```dart
testWidgets('Expense list performance', (tester) async {
  final stopwatch = Stopwatch()..start();

  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();

  expect(stopwatch.elapsedMilliseconds, lessThan(1500));
});
```

Use DevTools for:
- Frame rate analysis (target 60fps)
- Memory profiling (target <150MB)
- Network request inspection
- Database query performance

## Manual QA Checklist

### Exploratory Testing Areas
1. **Rapid input**: Add 20 expenses as fast as possible
2. **Low battery**: Test at 5% battery (iOS/Android throttling)
3. **Poor network**: Airplane mode during sync
4. **Backgrounding**: App killed mid-expense-entry
5. **Date boundaries**: Expenses at month/year boundaries
6. **Large dataset**: 10,000+ expenses performance
7. **Locale changes**: Switch device language/currency mid-session
8. **Accessibility**: Navigate entire app with VoiceOver/TalkBack
9. **Rotation**: All screens in landscape on phone
10. **Tablet**: All layouts on iPad/Android tablet
