# Xpense - Epics & User Stories

## Epic 1: Foundation & Core Experience
*Priority: Critical | Sprint: 1-2*

### Story 1.1: Project Setup
**As a** developer, **I want** a fully configured Flutter project, **so that** the team can start building features immediately.

**Acceptance Criteria:**
- [x] Flutter 3.19+ project with clean architecture structure
- [x] Riverpod, Drift, go_router dependencies configured
- [x] Build flavors (dev, staging, prod) working
- [x] CI/CD GitHub Actions for PR checks
- [x] Code analysis rules (very_good_analysis or custom)
- [x] Splash screen and app icons for iOS/Android (config ready, add branded assets to `assets/images/`)
- [x] CLAUDE.md with project context

**Estimation:** 5 points

### Story 1.2: Local Database & Models
**As a** user, **I want** my data stored reliably on my device, **so that** the app works instantly without internet.

**Acceptance Criteria:**
- [x] Drift database with all tables (expenses, categories, budgets, settings, recurring_expenses)
- [x] Freezed data models for all entities
- [x] Database encryption ready (SQLCipher dep removed due to drift_flutter conflict; native SQLite with migration support)
- [x] Migration system for schema updates
- [x] DAOs for CRUD operations on all tables
- [x] Seed default categories on first launch

**Estimation:** 8 points

### Story 1.3: Onboarding Flow
**As a** new user, **I want** a guided setup experience, **so that** I can configure the app in under 60 seconds.

**Acceptance Criteria:**
- [x] Welcome screen with animated logo
- [x] Currency selection with auto-detect (32 currencies)
- [x] Optional budget setup (skippable)
- [x] Interactive tutorial: guided first expense
- [x] Settings for notifications and biometrics (UI placeholders, logic in Story 7.x)
- [x] Can replay onboarding from settings
- [x] Onboarding state persisted via SharedPreferences

**Estimation:** 5 points

---

## Epic 2: Expense Management
*Priority: Critical | Sprint: 2-3*

### Story 2.1: Add Expense
**As a** user, **I want** to add an expense in under 3 seconds, **so that** tracking doesn't interrupt my day.

**Acceptance Criteria:**
- [x] Custom numeric keypad (not system keyboard)
- [x] Amount input with currency formatting
- [x] Category grid with recent categories first
- [x] Quick-save with smart defaults (today, default currency)
- [x] Optional fields: note, merchant, payment method, tags, location
- [x] Haptic feedback on every interaction
- [x] Success animation on save
- [x] "Add another" button for batch entry

**Estimation:** 8 points

### Story 2.2: Expense List & History
**As a** user, **I want** to browse and search my expenses, **so that** I can review my spending.

**Acceptance Criteria:**
- [x] Chronological list with date grouping (Today, Yesterday, This Week, etc.)
- [x] Pull-to-refresh with sync trigger
- [x] Search by amount, merchant, note, category
- [x] Filter by date range, category, payment method
- [x] Sort by date (default), amount, category
- [x] Infinite scroll pagination
- [x] Empty state with encouragement

**Estimation:** 5 points

### Story 2.3: Edit & Delete Expenses
**As a** user, **I want** to modify or remove expenses, **so that** I can correct mistakes.

**Acceptance Criteria:**
- [x] Swipe left to edit (with spring reveal)
- [x] Swipe right to delete (with red background)
- [x] Edit opens pre-populated add form
- [x] 5-second undo snackbar after delete
- [x] Bulk select mode (long press to enter)
- [x] Bulk delete with confirmation dialog
- [x] Haptic feedback on delete action

**Estimation:** 3 points

### Story 2.4: Recurring Expenses
**As a** user, **I want** to set up recurring expenses, **so that** I don't manually enter rent, subscriptions, etc.

**Acceptance Criteria:**
- [x] Create recurring from any expense
- [x] Frequency: daily, weekly, bi-weekly, monthly, quarterly, yearly, custom
- [x] End conditions: never, after N times, on date
- [x] Auto-generate occurrences
- [ ] Skip individual instance (deferred - requires additional schema)
- [x] Edit series or single occurrence
- [x] Visual indicator on recurring expenses in list

**Estimation:** 5 points

---

## Epic 3: Categories & Organization
*Priority: High | Sprint: 3*

### Story 3.1: Category Management
**As a** user, **I want** to organize expenses by category, **so that** I understand where my money goes.

**Acceptance Criteria:**
- [x] 11 default categories with icons and colors
- [x] Create custom categories (name, icon, color)
- [x] Subcategories (2 levels max)
- [x] Reorder categories (drag and drop)
- [x] Category detail: total spent, transaction count, trend
- [x] Archive/hide unused categories
- [x] Income categories (separate from expenses)

**Estimation:** 5 points

---

## Epic 4: Budgets & Goals
*Priority: High | Sprint: 3-4*

### Story 4.1: Budget Creation
**As a** user, **I want** to set spending limits, **so that** I can control my expenses.

**Acceptance Criteria:**
- [x] Overall monthly budget
- [x] Per-category budgets
- [x] Budget period: monthly, weekly, daily, custom
- [x] Start date selection
- [x] Rollover option for unused budget
- [x] Custom alert thresholds (default 80%, 100%)

**Estimation:** 5 points

### Story 4.2: Budget Tracking & Alerts
**As a** user, **I want** real-time budget feedback, **so that** I know when I'm overspending.

**Acceptance Criteria:**
- [x] Circular progress ring on dashboard per active budget
- [x] Color-coded: green (0-50%), blue (50-80%), orange (80-100%), red (100%+)
- [x] Warning haptic at 80% threshold
- [x] Strong alert haptic + animation at 100%
- [x] Budget remaining shown on add expense screen
- [x] End-of-period summary (under/over budget)
- [ ] Push notification for budget warnings (deferred - requires local notification infrastructure)

**Estimation:** 5 points

---

## Epic 5: Analytics & Insights
*Priority: High | Sprint: 4-5*

### Story 5.1: Dashboard Widgets
**As a** user, **I want** a quick overview of my finances, **so that** I understand my status at a glance.

**Acceptance Criteria:**
- [x] Today's spend with daily average comparison
- [x] This month progress with trend indicator
- [x] Top 3 spending categories
- [x] Biggest expense this period
- [x] Budget status summary
- [x] Income vs expense summary
- [x] Widgets are tappable for detailed view
- [x] Smooth count-up animations for numbers

**Estimation:** 5 points

### Story 5.2: Spending Reports
**As a** user, **I want** detailed spending analysis, **so that** I can identify patterns.

**Acceptance Criteria:**
- [x] Spending trend line chart (daily/weekly/monthly view)
- [x] Category breakdown donut chart
- [x] Cash flow bar chart (income vs expense)
- [x] Calendar heatmap of daily spending
- [x] Merchant analysis: top merchants, frequency
- [x] Date range selector (custom presets)
- [x] Charts animate on first appearance
- [x] All charts support tap for details

**Estimation:** 8 points

### Story 5.3: Smart Insights
**As a** user, **I want** intelligent observations about my spending, **so that** I can improve habits.

**Acceptance Criteria:**
- [x] Day-of-week spending patterns
- [x] Month-over-month comparisons
- [x] Anomaly detection (unusual charges)
- [x] Budget streak tracking
- [x] Encouraging milestone messages
- [ ] Insights computed nightly in background (deferred - no WorkManager/BGFetch yet)
- [x] Dismissible insights card on dashboard
- [ ] Push notification for noteworthy insights (deferred - no local notification infrastructure yet)

**Estimation:** 5 points

---

## Epic 6: Backup, Sync & Data
*Priority: High | Sprint: 5-6*

### Story 6.1: Local Backup & Export
**As a** user, **I want** to backup my data locally, **so that** I never lose my financial history.

**Acceptance Criteria:**
- [ ] Manual backup to device storage
- [ ] Auto-backup daily (configurable)
- [ ] Export to Files/iCloud Drive/Google Drive
- [ ] Encrypted backup with password option
- [ ] Export formats: JSON (full), CSV (readable), PDF (report)
- [ ] Backup list with date, size, device info
- [ ] Preview backup before restore

**Estimation:** 5 points

### Story 6.2: Cloud Sync (Premium)
**As a** premium user, **I want** my data synced across devices, **so that** I can access it anywhere.

**Acceptance Criteria:**
- [ ] End-to-end encrypted sync
- [ ] Incremental sync (only changes)
- [ ] Conflict resolution (auto + manual override)
- [ ] Multi-device support
- [ ] Sync status indicator in UI
- [ ] Offline queue with retry
- [ ] Background sync (iOS background fetch, Android WorkManager)
- [ ] Account management (sign in, sign out, delete account)

**Estimation:** 8 points

---

## Epic 7: Settings & Personalization
*Priority: Medium | Sprint: 4*

### Story 7.1: App Settings
**As a** user, **I want** to customize the app, **so that** it works the way I prefer.

**Acceptance Criteria:**
- [ ] Currency selection (150+ currencies)
- [ ] Theme: system/light/dark
- [ ] Accent color picker (8 presets + custom)
- [ ] Haptic intensity: off/light/medium/strong
- [ ] Number format (1,000.00 vs 1.000,00)
- [ ] Date/time format
- [ ] First day of week/month
- [ ] Language selection

**Estimation:** 3 points

### Story 7.2: Security Settings
**As a** user, **I want** to protect my financial data, **so that** my privacy is maintained.

**Acceptance Criteria:**
- [ ] Biometric lock (Face ID, Touch ID, fingerprint)
- [ ] Auto-lock timeout (1min, 5min, 15min, immediately)
- [ ] Hide amounts in app switcher
- [ ] Tap to reveal amounts in UI
- [ ] Encrypted database toggle
- [ ] App lock on backgrounding

**Estimation:** 3 points

### Story 7.3: Notifications
**As a** user, **I want** timely reminders, **so that** I stay on top of my tracking.

**Acceptance Criteria:**
- [ ] Daily reminder to log expenses (customizable time)
- [ ] Budget warning notifications
- [ ] Recurring expense due notifications
- [ ] Weekly spending summary
- [ ] Monthly report notification
- [ ] Notification settings per type
- [ ] Local notifications (no server needed)

**Estimation:** 3 points

---

## Epic 8: Polish & Performance
*Priority: Medium | Sprint: 6*

### Story 8.1: Animations & Haptics
**As a** user, **I want** delightful interactions, **so that** using the app feels premium.

**Acceptance Criteria:**
- [ ] All haptics from UI/UX guide implemented
- [ ] Page transitions: slide + fade
- [ ] Hero animations: FAB to add screen, card to detail
- [ ] Number count-up animations
- [ ] Success animations on save
- [ ] Budget milestone celebrations
- [ ] Loading skeleton screens (no spinners)
- [ ] Respect "Reduce Motion" accessibility setting

**Estimation:** 5 points

### Story 8.2: Performance Optimization
**As a** user, **I want** a fast app, **so that** I can quickly check or add expenses.

**Acceptance Criteria:**
- [ ] Cold start <1.5s
- [ ] Expense list scrolls at 60fps with 1000+ items
- [ ] Charts render in <100ms
- [ ] Database queries optimized with indexes
- [ ] Image caching for receipts
- [ ] Lazy loading for history
- [ ] Memory usage <150MB typical
- [ ] Battery efficient background sync

**Estimation:** 5 points

---

## Epic 9: Testing & Quality
*Priority: Critical | Sprint: Parallel*

### Story 9.1: Unit & Widget Tests
**As a** developer, **I want** automated tests, **so that** I can refactor with confidence.

**Acceptance Criteria:**
- [ ] Domain layer: 90%+ coverage
- [ ] Data layer: 80%+ coverage
- [ ] Widget golden tests for critical screens
- [ ] Accessibility tests (screen reader support)
- [ ] CI runs all tests on PR
- [ ] Tests run in <5 minutes

**Estimation:** 8 points

### Story 9.2: Integration & E2E Tests
**As a** developer, **I want** end-to-end tests, **so that** critical user flows are protected.

**Acceptance Criteria:**
- [ ] Full expense CRUD flow tested
- [ ] Budget creation and tracking flow
- [ ] Backup and restore cycle
- [ ] Sync flow with mocked server
- [ ] Onboarding complete flow
- [ ] Tests run on iOS and Android simulators in CI

**Estimation:** 5 points

---

## Epic 10: Launch Preparation
*Priority: Critical | Sprint: 7*

### Story 10.1: App Store Preparation
**As a** product owner, **I want** store-ready assets, **so that** we can launch successfully.

**Acceptance Criteria:**
- [ ] App store screenshots (iPhone + iPad, light + dark)
- [ ] App icon (all required sizes)
- [ ] App description and keywords (ASO optimized)
- [ ] Privacy policy page
- [ ] Terms of service
- [ ] Onboarding walkthrough video/gif
- [ ] Beta testing via TestFlight/Play Console

**Estimation:** 3 points

### Story 10.2: Analytics & Monitoring
**As a** product owner, **I want** usage analytics, **so that** I can understand user behavior.

**Acceptance Criteria:**
- [ ] Event tracking: expense_add, budget_create, export, etc.
- [ ] Funnel: onboarding completion, first expense, week-1 retention
- [ ] Crash reporting (Firebase Crashlytics)
- [ ] Performance monitoring (Firebase Performance)
- [ ] Privacy-compliant (opt-in for analytics)
- [ ] Dashboard for key metrics

**Estimation:** 3 points

---

## Story Map Summary

| Sprint | Focus | Key Deliverables |
|--------|-------|------------------|
| 1 | Foundation | Project setup, database, models, CI/CD |
| 2 | Core Experience | Onboarding, add expense, basic list |
| 3 | Organization | Categories, budgets, expense history |
| 4 | Intelligence | Dashboard widgets, settings, notifications |
| 5 | Analytics | Charts, reports, insights engine |
| 6 | Sync & Polish | Cloud sync, animations, performance |
| 7 | Launch | Tests, store assets, analytics, release |

**Total Story Points:** ~104 points
**Team Velocity Estimate:** 20-25 pts/sprint (2 Flutter devs)
**Estimated Timeline:** 7 sprints (~14 weeks with 2-week sprints)
