# Xpense

> The most delightful expense tracker ever built. Lightning-fast entry, meaningful analytics, and privacy-first design.

[![CI](https://github.com/aboubak-art/xpense/actions/workflows/ci.yml/badge.svg)](https://github.com/aboubak-art/xpense/actions)
[![codecov](https://codecov.io/gh/aboubak-art/xpense/branch/main/graph/badge.svg)](https://codecov.io/gh/aboubak-art/xpense)

## Features

- **Expense Tracking** — Add an expense in under 3 seconds with smart defaults and intelligent categorization
- **Budget Management** — Set monthly, category, or envelope budgets with real-time tracking
- **Smart Analytics** — Meaningful insights, not just charts. "You spend 40% more on dining during stressful weeks"
- **Offline-First** — Works completely without internet. Your data is always local and instant
- **Cloud Sync** — End-to-end encrypted backup across devices (Premium)
- **Haptic Feedback** — Every meaningful action provides tactile confirmation
- **Privacy First** — Your data is yours. Local-only mode available, no ads, no tracking

## Tech Stack

- [Flutter](https://flutter.dev) 3.19+ — Cross-platform UI framework
- [Dart](https://dart.dev) 3.3+ — Programming language
- [Riverpod](https://riverpod.dev) — State management
- [Drift](https://drift.simonbinder.eu) — Type-safe SQLite
- [Supabase](https://supabase.com) — Cloud backend (sync, auth)
- [fl_chart](https://github.com/imaNNeo/fl_chart) — Chart library

## Documentation

| Document | Purpose |
|----------|---------|
| [Product Brief](docs/PRODUCT_BRIEF.md) | Vision, audience, differentiators |
| [PRD](docs/PRD.md) | Full product requirements |
| [Architecture](docs/ARCHITECTURE.md) | Technical design and data flow |
| [UI/UX Guide](docs/UI_UX_GUIDE.md) | Design system, animations, haptics |
| [Epics & Stories](docs/EPICS_STORIES.md) | Agile breakdown and estimations |
| [Testing Strategy](docs/TESTING_STRATEGY.md) | QA approach and coverage targets |
| [Development Guide](docs/DEVELOPMENT_GUIDE.md) | Developer onboarding |

## Quick Start

```bash
# Clone
git clone https://github.com/aboubak-art/xpense.git
cd xpense

# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run in development mode
flutter run --flavor dev
```

## Development Pipeline

```bash
# Build + analyze + generate code
./scripts/dev-pipeline.sh build

# Review changed files
./scripts/dev-pipeline.sh review

# Run all tests with coverage
./scripts/dev-pipeline.sh test

# Full pipeline
./scripts/dev-pipeline.sh full

# Story-specific pipeline
./scripts/dev-pipeline.sh story expenses
```

## Project Structure

```
lib/
├── main.dart              # Entry point
├── app.dart               # App configuration
├── config/                # Routes, theme, constants
├── core/                  # Shared utilities, haptics, widgets
├── features/              # Feature modules
│   ├── onboarding/
│   ├── dashboard/
│   ├── expenses/
│   ├── categories/
│   ├── budgets/
│   ├── analytics/
│   ├── backup_sync/
│   └── settings/
├── data/                  # Database, models, repositories
├── domain/                # Entities, use cases
└── presentation/          # Shared providers and state
```

## Testing

```bash
# Unit tests
flutter test test/unit/

# Widget tests
flutter test test/widget/

# Integration tests
flutter test integration_test/

# With coverage
flutter test --coverage
```

## CI/CD

GitHub Actions workflows:
- **CI** — Analyze, test, build on every PR
- **Release** — Build and publish on version tags

## License

MIT License — see [LICENSE](LICENSE) for details.

## Contributing

1. Check open issues or create a feature request
2. Fork the repo and create a feature branch
3. Follow the [Development Guide](docs/DEVELOPMENT_GUIDE.md)
4. Ensure tests pass and coverage is maintained
5. Submit a PR with clear description

---

Built with precision and care by the Xpense team.
