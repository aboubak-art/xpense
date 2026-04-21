# Xpense - Technical Architecture

## Stack Overview

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Framework | Flutter 3.19+ | Single codebase for iOS/Android, excellent performance, rich ecosystem |
| Language | Dart 3.3+ | Null safety, pattern matching, records, excellent async support |
| State Management | Riverpod 2.x + StateNotifier | Compile-safe dependency injection, testable, granular rebuilds |
| Local DB | Drift ( moor ) | Type-safe SQL, migrations, reactive queries, encrypted support |
| Cloud Backend | Supabase | Open source, real-time sync, auth, storage, generous free tier |
| Local Storage | flutter_secure_storage + path_provider | Keychain/Keystore for keys, standard FS for backups |
| Networking | Dio + retrofit | Interceptors, retry logic, type-safe API clients |
| Analytics | PostHog (self-hostable) or Mixpanel | Event tracking, funnel analysis |
| Charts | fl_chart | Highly customizable, performant Flutter charts |
| DI | Riverpod (built-in) | No additional DI package needed |
| Routing | go_router | Deep linking, declarative, type-safe routes |
| Code Gen | build_runner + freezed + drift_dev | Immutable data classes, JSON serialization, type-safe SQL |

## Project Structure (Clean Architecture)

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # MaterialApp/CupertinoApp config
├── config/                            # App configuration
│   ├── constants.dart                 # App-wide constants
│   ├── routes.dart                    # go_router configuration
│   ├── theme.dart                     # ThemeData definitions
│   └── env.dart                       # Environment variables (envied)
├── core/                              # Shared core utilities
│   ├── errors/                        # Failure classes, exceptions
│   ├── usecases/                      # Base UseCase class
│   ├── utils/                         # Extensions, helpers, formatters
│   ├── widgets/                       # Reusable UI components
│   └── haptics/                       # Haptic feedback service
├── features/                          # Feature modules
│   ├── onboarding/                    # Onboarding flow
│   ├── dashboard/                     # Home dashboard
│   ├── expenses/                      # CRUD operations
│   ├── categories/                    # Category management
│   ├── budgets/                       # Budget tracking
│   ├── analytics/                     # Stats and reports
│   ├── backup_sync/                   # Cloud/local backup
│   └── settings/                      # App settings
├── data/                              # Global data layer
│   ├── local/                         # Local database
│   │   ├── database.dart              # Drift database definition
│   │   ├── dao/                       # Data access objects
│   │   └── migrations/                # Schema migrations
│   ├── remote/                        # API clients
│   │   ├── supabase_client.dart
│   │   └── sync_service.dart
│   ├── models/                        # Data models (freezed)
│   └── repositories/                  # Repository implementations
├── domain/                            # Business logic
│   ├── entities/                      # Pure business entities
│   ├── repositories/                  # Repository interfaces
│   └── usecases/                      # Business use cases
└── presentation/                      # Shared presentation
    ├── providers/                     # Global Riverpod providers
    └── state/                         # Shared state classes
```

Each feature module follows the same pattern:
```
features/expenses/
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── pages/
    ├── widgets/
    ├── providers/
    └── state/
```

## Data Flow Architecture

```
UI Layer (Pages/Widgets)
    ↑↓
Presentation Layer (Riverpod Providers/StateNotifier)
    ↑↓
Domain Layer (UseCases + Entities)
    ↑↓
Data Layer (Repositories)
    ↑↓
Data Sources (Local DB / Remote API / Local Files)
```

### Layer Rules
- **UI**: Only talks to Providers. No direct repository access.
- **Presentation**: Manages widget state, calls UseCases, handles UI logic
- **Domain**: Pure Dart, no Flutter dependencies. Contains business rules.
- **Data**: Implements repository interfaces. Handles mapping between models and entities.
- **Data Sources**: Lowest level. Drift DB, Supabase client, file system.

## Database Architecture

### Why Drift?
- Type-safe SQL with compile-time verification
- Reactive streams: Queries auto-update when data changes
- Migration system for schema evolution
- Encryption support via `encrypted_moor` / `sqlcipher_flutter_libs`
- Works seamlessly with Riverpod through StreamProviders

### Schema Design
```sql
-- expenses table
CREATE TABLE expenses (
  id TEXT PRIMARY KEY,
  amount INTEGER NOT NULL, -- stored in smallest currency unit (cents)
  currency_code TEXT NOT NULL DEFAULT 'USD',
  category_id TEXT NOT NULL REFERENCES categories(id),
  subcategory_id TEXT REFERENCES categories(id),
  date INTEGER NOT NULL, -- unix timestamp
  merchant TEXT,
  payment_method INTEGER NOT NULL DEFAULT 0,
  note TEXT,
  tags TEXT, -- JSON array
  latitude REAL,
  longitude REAL,
  receipt_image_path TEXT,
  is_recurring INTEGER NOT NULL DEFAULT 0,
  recurring_group_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  sync_status INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_expenses_date ON expenses(date);
CREATE INDEX idx_expenses_category ON expenses(category_id);
CREATE INDEX idx_expenses_sync ON expenses(sync_status);

-- categories table
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  color_hex TEXT NOT NULL,
  is_default INTEGER NOT NULL DEFAULT 0,
  is_income INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL,
  parent_id TEXT REFERENCES categories(id),
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- budgets table
CREATE TABLE budgets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type INTEGER NOT NULL,
  category_id TEXT REFERENCES categories(id),
  amount INTEGER NOT NULL,
  period INTEGER NOT NULL,
  start_date INTEGER NOT NULL,
  rollover_enabled INTEGER NOT NULL DEFAULT 0,
  rollover_amount INTEGER NOT NULL DEFAULT 0,
  alert_thresholds TEXT, -- JSON array of integers
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- recurring_groups table
CREATE TABLE recurring_groups (
  id TEXT PRIMARY KEY,
  base_expense_id TEXT NOT NULL,
  frequency INTEGER NOT NULL,
  interval INTEGER NOT NULL DEFAULT 1,
  end_date INTEGER,
  max_occurrences INTEGER,
  next_occurrence_date INTEGER NOT NULL
);

-- user_settings table (singleton)
CREATE TABLE user_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  default_currency TEXT NOT NULL DEFAULT 'USD',
  theme_mode INTEGER NOT NULL DEFAULT 0,
  accent_color TEXT DEFAULT '#FF6B6B',
  haptic_intensity INTEGER NOT NULL DEFAULT 2,
  biometric_enabled INTEGER NOT NULL DEFAULT 0,
  auto_lock_timeout INTEGER,
  daily_reminder_time INTEGER,
  number_format INTEGER NOT NULL DEFAULT 0,
  week_starts_on INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- sync_state table (singleton)
CREATE TABLE sync_state (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  last_sync_at INTEGER,
  device_id TEXT NOT NULL,
  user_id TEXT,
  encryption_key_hash TEXT
);
```

## State Management Strategy

### Global State (Riverpod)
- `userSettingsProvider`: App settings, accessed everywhere
- `currencyProvider`: Current currency + exchange rates
- `syncStatusProvider`: Online/offline/syncing indicator
- `authProvider`: Authentication state (Premium)

### Feature State (StateNotifier + AsyncValue)
```dart
// Example: Expenses list
@riverpod
class ExpensesNotifier extends _$ExpensesNotifier {
  @override
  FutureOr<List<Expense>> build() async {
    final repository = ref.watch(expensesRepositoryProvider);
    return repository.watchAll().first;
  }

  Future<void> addExpense(Expense expense) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(addExpenseUseCaseProvider)(expense);
      return ref.read(expensesRepositoryProvider).getAll();
    });
  }
}
```

### Local UI State (flutter_hooks or StatefulWidget)
- Form field values
- Animation controllers
- Scroll positions
- Page controller state

## Sync Architecture

### Sync Engine
```dart
class SyncEngine {
  // Priority queue: expenses first, then categories, then budgets
  final _queue = PriorityQueue<SyncOperation>();
  
  Future<void> sync() async {
    if (!await _hasConnectivity()) return;
    
    // 1. Upload pending changes
    final pending = await _localDb.getPendingSyncRecords();
    for (final batch in pending.chunks(50)) {
      await _uploadBatch(batch);
    }
    
    // 2. Download server changes
    final lastSync = await _localDb.getLastSyncAt();
    final serverChanges = await _supabase.getChangesSince(lastSync);
    
    // 3. Apply changes with conflict resolution
    for (final change in serverChanges) {
      await _applyChange(change);
    }
    
    // 4. Update sync timestamp
    await _localDb.setLastSyncAt(DateTime.now());
  }
}
```

### Background Sync
- iOS: `background_fetch` plugin, minimum interval 15 minutes
- Android: `WorkManager` periodic task, minimum interval 15 minutes
- Trigger on: app foreground, expense save, manual pull-to-refresh

## Analytics Computation

### Stats Engine
Runs computations in isolate to avoid UI jank:

```dart
class StatsEngine {
  Future<SpendingStats> computeMonthlyStats(DateTime month) async {
    return await Isolate.run(() async {
      final expenses = await _db.getExpensesForMonth(month);
      
      return SpendingStats(
        total: expenses.fold(0, (sum, e) => sum + e.amount),
        byCategory: _groupByCategory(expenses),
        dailyAverage: _computeDailyAverage(expenses, month),
        trends: _computeTrends(expenses),
        insights: _generateInsights(expenses),
      );
    });
  }
}
```

### Caching Strategy
- Pre-compute current month stats on app start
- Cache results in memory (Riverpod provider)
- Invalidate cache on expense CRUD operations
- Historical months computed on-demand with disk cache

## Security Implementation

### Encryption Layers
1. **Database**: SQLCipher with AES-256, key in Keychain/Keystore
2. **Cloud Backup**: Client-side encryption before upload
   - Key derivation: PBKDF2(password, salt) → AES key
   - Each backup encrypted with unique IV
3. **In-Transit**: TLS 1.3 enforced, certificate pinning (optional)

### Key Management
```dart
class EncryptionService {
  Future<String> getOrCreateDbKey() async {
    final storage = FlutterSecureStorage();
    var key = await storage.read(key: 'db_encryption_key');
    if (key == null) {
      key = base64Encode(secureRandom(32));
      await storage.write(key: 'db_encryption_key', value: key);
    }
    return key;
  }
}
```

## Build Flavors

```
Development:
  - Debug symbols enabled
  - Test Supabase project
  - Verbose logging
  - Fake data seeded on first launch

Staging:
  - Release mode optimizations
  - Staging Supabase project
  - Analytics disabled
  - Crash reporting enabled

Production:
  - Release mode, obfuscated
  - Production Supabase project
  - Full analytics
  - Crash reporting + performance monitoring
```

## Dependency Injection

All dependencies wired through Riverpod providers:

```dart
// Core
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Repositories
final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepositoryImpl(
    localDataSource: ref.watch(expensesLocalDataSourceProvider),
    remoteDataSource: ref.watch(expensesRemoteDataSourceProvider),
  );
});

// UseCases
final addExpenseUseCaseProvider = Provider<AddExpenseUseCase>((ref) {
  return AddExpenseUseCase(ref.watch(expensesRepositoryProvider));
});
```

## Testing Strategy

### Unit Tests
- UseCases: Mock repositories, test business logic
- Repositories: Mock data sources, test mapping
- Utils/Helpers: Pure function testing

### Widget Tests
- Golden tests for critical screens
- Interaction testing for user flows
- Accessibility testing with `AccessibilityGuideline`

### Integration Tests
- Full expense CRUD flow
- Sync end-to-end with local Supabase
- Backup/restore cycle

### Coverage Targets
- Domain layer: 90%+
- Data layer: 80%+
- Presentation: 70%+
- Overall: 80%+

## Performance Optimizations

1. **Database**: Indexed queries, pagination (50 items/page), lazy loading for history
2. **Images**: Cached network images, receipt thumbnails (200x200), full image on demand
3. **Charts**: Debounced updates, computed in isolate for large datasets
4. **Lists**: `ListView.builder` with `findChildIndexCallback`, recycling
5. **Animations**: `RepaintBoundary` around animated widgets, `AnimatedBuilder` over `setState`
6. **Memory**: Image cache limits, database connection pooling, periodic cache eviction
7. **Startup**: Deferred loading for non-critical features, splash screen until first frame

## CI/CD Pipeline

### GitHub Actions
1. **PR Checks**: Format, analyze, unit tests, widget tests
2. **Build**: Android APK/AAB, iOS IPA on tagged releases
3. **Deploy**: Firebase App Distribution (beta), Play Store/App Store (production)
4. **Code Quality**: Dart Code Metrics, custom lint rules

### Versioning
- Semantic versioning: MAJOR.MINOR.PATCH
- Version in `pubspec.yaml` + fastlane match
- Changelog maintained in `CHANGELOG.md`
