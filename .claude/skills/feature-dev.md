---
description: Feature development skill for Xpense - implements a user story end-to-end following clean architecture
---

# Feature Development Agent

Implement a user story for the Xpense app following clean architecture and project conventions.

## Workflow

### 1. Understand the Story
Read the relevant documentation:
- `docs/EPICS_STORIES.md` — Find the story details and acceptance criteria
- `docs/PRD.md` — Understand feature requirements
- `docs/ARCHITECTURE.md` — Follow architectural patterns
- `docs/UI_UX_GUIDE.md` — Implement design and haptics correctly

### 2. Plan Implementation
Before coding, outline:
- Files to create/modify
- Data model changes (if any)
- UI components needed
- Tests to write

### 3. Implement Layer by Layer

**Domain Layer (Pure Dart, no Flutter)**
- Define/update entity in `lib/domain/entities/`
- Define repository interface in `lib/domain/repositories/`
- Implement use case in `lib/domain/usecases/`

**Data Layer**
- Add/update drift table in `lib/data/local/database.dart`
- Create/update DAO in `lib/data/local/dao/`
- Implement repository in `lib/data/repositories/`
- Create data model with freezed in `lib/data/models/`
- Run code generation

**Presentation Layer**
- Create Riverpod provider in `lib/features/<feature>/presentation/providers/`
- Create StateNotifier if needed
- Build pages in `lib/features/<feature>/presentation/pages/`
- Build reusable widgets in `lib/features/<feature>/presentation/widgets/`

**Haptics**
- Add appropriate haptic feedback per `docs/UI_UX_GUIDE.md`
- Use `HapticsService` from `lib/core/haptics/`

### 4. Write Tests
- Unit tests for use cases and repositories
- Widget tests for pages and components
- Update golden tests if UI changed

### 5. Run Pipeline
```bash
./scripts/dev-pipeline.sh full
```

## Rules
- Never access repositories directly from widgets
- Always use `AsyncValue` for async state
- Store amounts as integer cents
- Use UUIDv4 for all IDs
- Add `const` constructors where possible
- Minimum 44x44pt touch targets
- Respect `MediaQuery.disableAnimations`

## Acceptance Criteria Verification
Before finishing, verify all acceptance criteria from the story are met:
```bash
# Check the story
grep -A 50 "Story X.X" docs/EPICS_STORIES.md
```
