# Xpense - Development Guide

## Getting Started

### Prerequisites
- Flutter 3.19.0 or higher
- Dart 3.3.0 or higher
- Xcode 15+ (for iOS)
- Android Studio Hedgehog+ or Android SDK 34+
- CocoaPods (iOS dependencies)

### Setup
```bash
# Clone repository
git clone https://github.com/aboubak-art/xpense.git
cd xpense

# Install dependencies
flutter pub get

# Generate code (freezed, drift, retrofit)
flutter pub run build_runner build --delete-conflicting-outputs

# Run in development mode
flutter run --flavor dev
```

## Development Workflow

### Branch Strategy
```
main          — Production releases, protected
  ↑
develop       — Integration branch, auto-deploy to staging
  ↑
feature/xxx   — Individual features
  ↑
hotfix/xxx    — Production hotfixes
```

### Commit Convention
```
type(scope): subject

body (optional)

footer (optional)
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`

Examples:
```
feat(expenses): add recurring expense support
fix(sync): resolve conflict on simultaneous edits
test(analytics): add golden tests for dashboard
```

### Code Generation

Drift, Freezed, and Retrofit require code generation:

```bash
# One-time build
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (rebuilds on change)
flutter pub run build_runner watch --delete-conflicting-outputs
```

**Generated files (DO NOT EDIT):**
- `*.g.dart` — JSON serialization, Retrofit clients
- `*.freezed.dart` — Immutable data classes
- `*.drift.dart` — Type-safe SQL

## Architecture Patterns

### Adding a New Feature

1. **Define entity** in `domain/entities/`
2. **Define repository interface** in `domain/repositories/`
3. **Implement data sources** in `data/datasources/`
4. **Implement repository** in `data/repositories/`
5. **Create use cases** in `domain/usecases/`
6. **Create provider** in `presentation/providers/`
7. **Build UI** in `presentation/pages/`

### State Management Rules

**DO:**
- Use Riverpod for all app state
- Use `AsyncValue` for async operations
- Keep providers granular and composable
- Use `select` to minimize rebuilds

**DON'T:**
- Use `setState` for shared state
- Call repositories directly from widgets
- Create providers that depend on too many other providers
- Store controller references in providers

### Error Handling

```dart
// Domain layer: Use Either or sealed classes
Future<Either<Failure, Expense>> getExpense(String id);

// Presentation layer: Handle AsyncValue states
expensesAsync.when(
  data: (expenses) => ExpensesList(expenses),
  loading: () => const SkeletonList(),
  error: (error, stack) => ErrorWidget(message: error.toString()),
);
```

Failure types:
- `ValidationFailure` — Invalid input
- `NotFoundFailure` — Resource doesn't exist
- `NetworkFailure` — Connectivity issues
- `StorageFailure` — Local storage error
- `SyncFailure` — Synchronization error

## Database Migrations

When changing schema:

1. Update table definition in `database.dart`
2. Increment schema version
3. Write migration in `migrations/`
4. Test migration on existing database

```dart
// database.dart
@DriftDatabase(version: 2)
class AppDatabase extends _$AppDatabase {
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(expenses, expenses.merchant);
      }
    },
  );
}
```

## Localization

Add strings to `lib/l10n/app_en.arb`:
```json
{
  "addExpense": "Add Expense",
  "@addExpense": {
    "description": "Title for add expense screen"
  }
}
```

Generate:
```bash
flutter gen-l10n
```

Use in code:
```dart
Text(AppLocalizations.of(context)!.addExpense)
```

## Assets

Place in `assets/` and declare in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
    - assets/fonts/
```

Generate type-safe references:
```bash
fluttergen -c pubspec.yaml
```

## Debugging

### Flutter DevTools
```bash
flutter pub global activate devtools
devtools
```

### Database Inspection
```bash
# iOS simulator
cd ~/Library/Developer/CoreSimulator/Devices/[ID]/data/Containers/Data/Application/[ID]/Documents
sqlite3 app.db

# Android emulator
adb shell
run-as com.aboubakart.xpense
cd databases
sqlite3 app.db
```

### Logging
Use `logger` package with levels:
```dart
logger.d('Debug message');
logger.i('Info message');
logger.w('Warning');
logger.e('Error', error: e, stackTrace: st);
```

Production builds strip debug logs automatically.

## Release Builds

### Android
```bash
flutter build appbundle --flavor prod
# Upload build/app/outputs/bundle/prodRelease/app-prod-release.aab to Play Store
```

### iOS
```bash
flutter build ipa --flavor prod
# Upload build/ios/ipa/xpense.ipa via Transporter
```

### Versioning
Update in `pubspec.yaml`:
```yaml
version: 1.2.3+45  # versionName + versionCode
```

## Troubleshooting

### Common Issues

**Build runner fails:**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**iOS build fails:**
```bash
cd ios
pod deintegrate
pod install
```

**Android build fails:**
```bash
cd android
./gradlew clean
```

**Database locked:**
- Kill app completely
- Delete app and reinstall (dev only)

## Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Riverpod Documentation](https://riverpod.dev)
- [Drift Documentation](https://drift.simonbinder.eu)
- [Flutter Design Patterns](https://flutterdesignpatterns.com)
