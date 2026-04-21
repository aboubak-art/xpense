# Xpense - Product Requirements Document

## Table of Contents
1. [Core Features](#core-features)
2. [User Flows](#user-flows)
3. [Data Model](#data-model)
4. [Offline & Sync Strategy](#offline--sync-strategy)
5. [Analytics & Stats](#analytics--stats)
6. [Security & Privacy](#security--privacy)
7. [Non-Functional Requirements](#non-functional-requirements)

---

## Core Features

### 1. Expense Tracking

#### Add Expense (Critical Path)
- **Quick Add**: Tap floating action button → amount keypad → tap category icon → done
- **Smart Defaults**: Pre-selects today's date, most-used currency, suggests category based on amount/merchant
- **Voice Input**: "Coffee at Starbucks 5.50" parses to amount, merchant, category
- **Receipt Capture**: Camera capture with OCR for amount extraction (Premium)
- **Fields**: Amount, Currency, Category, Subcategory, Date/Time, Merchant/Payee, Payment Method, Note, Tags, Location (optional), Receipt Image
- **Haptics**: Light impact on category select, success haptic on save, error vibration on validation fail

#### Edit/Delete Expense
- Swipe left to edit, swipe right to delete with haptic confirmation
- Bulk select mode for mass operations
- Undo snackbar for 5 seconds after delete

#### Recurring Expenses
- Set frequency: daily, weekly, bi-weekly, monthly, quarterly, yearly, custom
- End conditions: never, after N occurrences, on specific date
- Generate next occurrence automatically
- Skip individual instances without breaking series

### 2. Budget Management

#### Budget Types
- **Overall Budget**: Monthly spending limit across all categories
- **Category Budgets**: Per-category limits (e.g., $500 for Dining)
- **Envelope Budgets**: Allocate specific amounts to virtual envelopes

#### Budget Behavior
- Resets automatically based on period (monthly default, customizable)
- Rollover unused budget (optional per budget)
- Warning at 80% spend (haptic + visual)
- Critical alert at 100% spend (strong haptic + banner)
- Progress visualization: circular progress rings, color-coded bars

### 3. Categories

#### Default Categories (with icons and colors)
| Category | Color | Icon |
|----------|-------|------|
| Food & Dining | #FF6B6B | Utensils |
| Transportation | #4ECDC4 | Car |
| Shopping | #45B7D1 | ShoppingBag |
| Entertainment | #96CEB4 | Film |
| Bills & Utilities | #FFEAA7 | Zap |
| Health | #DDA0DD | Heart |
| Travel | #98D8C8 | Plane |
| Education | #F7DC6F | BookOpen |
| Personal Care | #BB8FCE | Sparkles |
| Gifts & Donations | #85C1E9 | Gift |
| Income | #58D68D | ArrowDownLeft |

- Custom categories (Premium): User-defined with custom icons and colors
- Subcategories: 2 levels deep max
- Recent/Most-used categories surface to top

### 4. Analytics & Statistics

#### Dashboard Widgets
- **Today's Spend**: Real-time total with comparison to daily average
- **This Month**: Progress against monthly budget with trend line
- **Top Categories**: Horizontal bar chart of top 5 spending categories
- **Daily Average**: Computed over selected period
- **Biggest Expense**: Largest single transaction this period

#### Detailed Reports
- **Spending Trends**: Line chart (daily/weekly/monthly) with moving average
- **Category Breakdown**: Donut/pie chart with percentage and absolute values
- **Comparison**: Month-over-month, year-over-year spending
- **Heatmap**: Calendar heatmap showing spending intensity by day
- **Cash Flow**: Income vs Expenses over time
- **Merchant Analysis**: Where you spend most, frequency analysis
- **Insights Engine**:
  - "You spend 23% more on weekends"
  - "Your grocery spending is 15% below last month — great job!"
  - "You've exceeded your dining budget for 3 months straight"
  - Anomaly detection: "Unusual $200 charge at Electronics detected"

#### Export Options
- PDF report generation
- CSV/Excel export (all fields)
- JSON export (for backup/restore)

### 5. Backup & Sync

#### Local Backup
- Automated daily local backup to device storage
- Manual backup on demand
- Export to Files app / iCloud Drive / Google Drive
- Encrypted backup option with password

#### Cloud Sync (Premium)
- End-to-end encryption (AES-256-GCM)
- Incremental sync (only changed records)
- Conflict resolution: timestamp-based with manual override option
- Multi-device sync (phone + tablet)
- Sync status indicator in app bar

#### Restore
- Select backup from list with date, size, device info
- Preview backup contents before restore
- Merge or replace existing data

### 6. Settings & Customization

- Currency: 150+ currencies with live exchange rates (premium) or manual rates
- Date/Time format: system default or custom
- First day of week/month
- Decimal separator preference
- Number format (1,000.00 vs 1.000,00)
- Theme: System/Light/Dark with accent color picker
- Haptic feedback intensity: Off/Light/Medium/Strong
- Security: Biometric lock, app auto-lock timeout
- Notifications: Daily reminder, budget warnings, bill reminders
- Data management: Clear cache, delete all data, export everything

---

## User Flows

### Onboarding Flow
1. Welcome screen with animated logo (2s)
2. Currency selection (auto-detect from locale)
3. Set first monthly budget (optional skip)
4. Quick tutorial: "Try adding your first expense" with guided overlay
5. Optional: Enable notifications, enable biometric lock

### Core Loop (Happy Path)
1. User opens app → Dashboard loads in <500ms
2. Tap FAB → Amount keypad slides up with haptic
3. Enter amount → Category grid appears with recent first
4. Tap category → Optional fields expand (swipe up for more)
5. Tap Save → Success haptic, animated confetti for milestone expenses
6. Dashboard updates with smooth number animation

### Budget Check Flow
1. User adds expense in category
2. If category budget exists, check percentage
3. At 80%: subtle orange pulse on budget ring + light haptic
4. At 100%: red shake animation on budget + strong warning haptic
5. Show celebratory animation when under budget at month end

---

## Data Model

### Core Entities
```
Expense
- id: UUID (primary key)
- amount: Decimal (stored as integer cents)
- currencyCode: String (ISO 4217)
- categoryId: UUID
- subcategoryId: UUID?
- date: DateTime
- merchant: String?
- paymentMethod: PaymentMethod
- note: String?
- tags: List<String>
- location: GeoPoint?
- receiptImagePath: String?
- isRecurring: Bool
- recurringGroupId: UUID?
- createdAt: DateTime
- updatedAt: DateTime
- deletedAt: DateTime? (soft delete for sync)
- syncStatus: SyncStatus (pending/uploaded/conflict)

Category
- id: UUID
- name: String
- iconName: String
- colorHex: String
- isDefault: Bool
- isIncome: Bool
- sortOrder: Int
- parentId: UUID?

Budget
- id: UUID
- name: String
- type: BudgetType (overall/category/envelope)
- categoryId: UUID?
- amount: Decimal
- period: BudgetPeriod (daily/weekly/monthly/yearly/custom)
- startDate: DateTime
- rolloverEnabled: Bool
- rolloverAmount: Decimal
- alertThresholds: List<Int> (percentages)

RecurringGroup
- id: UUID
- baseExpenseId: UUID
- frequency: Frequency
- interval: Int
- endDate: DateTime?
- maxOccurrences: Int?
- nextOccurrenceDate: DateTime

UserSettings
- id: UUID (singleton)
- defaultCurrency: String
- theme: ThemeMode
- accentColor: String
- hapticIntensity: HapticIntensity
- biometricEnabled: Bool
- autoLockTimeout: Int?
- dailyReminderTime: TimeOfDay?
- numberFormat: NumberFormat
- weekStartsOn: DayOfWeek

SyncState
- lastSyncAt: DateTime?
- deviceId: String
- encryptionKey: String? (stored in Keychain/Keystore)
```

---

## Offline & Sync Strategy

### Offline-First Architecture
- All CRUD operations write to local SQLite database immediately
- UI updates from local database only (never wait for server)
- Background sync queue processes uploads when online
- Optimistic UI updates with rollback on sync failure

### Sync Protocol
1. Local change → Mark record with `syncStatus = pending`
2. Sync worker (periodic + on app foreground) processes queue
3. Upload batch of changed records with `lastModifiedAt` timestamps
4. Server resolves conflicts: last-write-wins with client override option
5. Download server changes since `lastSyncAt`
6. Apply server changes locally, update `lastSyncAt`
7. Emit sync completion event

### Conflict Resolution
- Automatic: Timestamp-based (later wins)
- Manual: When both client and server modified same field, present diff UI
- Always preserve both versions in conflict log

---

## Analytics & Stats

### Computed Metrics
- Daily/Weekly/Monthly/Yearly totals
- Category percentages and trends
- Day-of-week analysis ("You spend most on Saturdays")
- Time-of-day patterns
- Spending velocity (rate vs budget period)
- Projected month-end total based on current velocity
- Savings rate (income - expenses) / income

### Insight Generation
- Run nightly background job to compute insights
- Store pre-computed insights for instant display
- Threshold-based: Only show insights with statistical significance
- Tone: Encouraging, never shaming

---

## Security & Privacy

### Data at Rest
- SQLite database encrypted with SQLCipher on supported platforms
- Key stored in iOS Keychain / Android Keystore
- Biometric authentication required for app unlock (if enabled)

### Data in Transit
- TLS 1.3 for all cloud communication
- End-to-end encryption: Client encrypts with key derived from user password + device key
- Server stores only encrypted blobs, cannot read content

### Privacy
- No third-party analytics without explicit opt-in
- No advertising identifiers collected
- GDPR/CCPA compliant data export/deletion
- All processing possible entirely on-device

---

## Non-Functional Requirements

### Performance
- App cold start: <1.5s
- Expense list load (1000 items): <300ms
- Chart rendering: <100ms
- Add expense operation: <50ms local write
- Sync operation: <5s for typical daily changes

### Reliability
- 99.9% crash-free sessions
- Zero data loss guarantee: Write-ahead logging, backup on every significant operation
- Graceful degradation when sync unavailable

### Accessibility
- Full VoiceOver/TalkBack support
- Dynamic type support (up to AX5)
- High contrast mode support
- Minimum touch target: 44x44pt
- Color-blind friendly chart palettes

### Localization
- Phase 1: English, French, Spanish, German
- Phase 2: Portuguese, Italian, Dutch, Arabic, Japanese, Korean
- RTL layout support for Arabic
- Currency formatting per locale

### Battery & Resources
- Background sync: max once per hour when app closed
- Location: Only when explicitly adding location to expense
- Image compression: Max 1MB per receipt
- Database maintenance: Weekly auto-vacuum
