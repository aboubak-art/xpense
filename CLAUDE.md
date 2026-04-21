# Xpense - Claude Code Project Context

## Project Overview
Xpense is a premium offline-first expense tracker built with Flutter. It emphasizes speed (expense entry in under 3 seconds), meaningful analytics, delightful haptic feedback, and privacy-first design.

## Technology Stack
- **Framework**: Flutter 3.19+ / Dart 3.3+
- **State Management**: Riverpod 2.x
- **Local Database**: Drift (SQLite) with SQLCipher encryption
- **Cloud**: Supabase (sync, auth, storage)
- **Charts**: fl_chart
- **Routing**: go_router
- **Code Gen**: freezed, drift_dev, retrofit

## Architecture
Clean Architecture with feature modules:
- `lib/features/` — Feature-based modules (expenses, budgets, analytics, etc.)
- `lib/core/` — Shared utilities, haptics, widgets
- `lib/data/` — Database, API clients, repository implementations
- `lib/domain/` — Entities, repository interfaces, use cases

## Key Design Principles
1. **Offline-first**: All operations write to local DB immediately. Sync is background and invisible.
2. **Haptic-rich**: Every meaningful action has tactile feedback. Refer to `docs/UI_UX_GUIDE.md` for haptic mapping.
3. **Privacy-first**: End-to-end encrypted cloud backup. Local-only mode available.
4. **Performance**: Cold start <1.5s, 60fps scroll, charts <100ms render.

## Critical Patterns
- Use Riverpod `AsyncValue` for all async state
- Database operations through DAOs, never raw SQL in UI
- All amounts stored as integer cents (never floating point)
- Soft delete with `deleted_at` for sync compatibility
- UUIDv4 for all entity IDs

## Documentation
- `docs/PRODUCT_BRIEF.md` — Vision and differentiators
- `docs/PRD.md` — Full product requirements
- `docs/ARCHITECTURE.md` — Technical architecture and data flow
- `docs/UI_UX_GUIDE.md` — Design system, animations, haptics
- `docs/EPICS_STORIES.md` — Agile breakdown with estimations
- `docs/TESTING_STRATEGY.md` — Testing approach
- `docs/DEVELOPMENT_GUIDE.md` — Developer onboarding

## Build Commands
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run --flavor dev
flutter test
flutter build appbundle --flavor prod
flutter build ipa --flavor prod
```

## Testing
- Unit tests: `test/unit/`
- Widget tests: `test/widget/`
- Integration tests: `test/integration/`
- Golden tests: `test/golden/`
- Target coverage: 80%+ overall, 90%+ domain layer

## Flavors
- `dev` — Debug, test Supabase, verbose logging
- `staging` — Release mode, staging Supabase, crash reporting
- `prod` — Release, production Supabase, full analytics

## Important Notes
- Respect `MediaQuery.disableAnimations` for accessibility
- All colors must meet WCAG AA contrast
- Minimum touch target: 44x44pt
- Support iOS 15+, Android 10+
- RTL layout support required
