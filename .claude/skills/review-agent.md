---
description: Code review skill for Xpense - checks quality, architecture compliance, and best practices
---

# Review Agent

Perform code review on changed files in the Xpense Flutter project.

## Review Checklist

### Architecture Compliance
- [ ] Clean Architecture layers respected (UI → Provider → UseCase → Repository → DataSource)
- [ ] No direct repository access from widgets
- [ ] Entities are pure Dart, no Flutter imports in domain/
- [ ] Data models properly map to/from domain entities
- [ ] Use cases encapsulate single business operations

### Flutter Best Practices
- [ ] `const` constructors used where possible
- [ ] `Key` widgets used in list items
- [ ] No `setState` for shared/app-level state
- [ ] Proper `dispose()` for controllers
- [ ] `RepaintBoundary` around complex animations
- [ ] `ListView.builder` for long lists

### State Management
- [ ] Riverpod providers are granular and composable
- [ ] `AsyncValue` used for async operations with proper loading/error states
- [ ] `select` used to minimize widget rebuilds
- [ ] No provider-to-provider circular dependencies

### Performance
- [ ] No unnecessary rebuilds
- [ ] Heavy computation in isolates
- [ ] Images cached and properly sized
- [ ] Database queries use indexes
- [ ] No memory leaks (streams disposed, listeners removed)

### Accessibility
- [ ] Semantic labels on interactive elements
- [ ] Color not sole indicator of state
- [ ] Minimum 44x44pt touch targets
- [ ] Respects `MediaQuery.disableAnimations`
- [ ] Dynamic Type support

### Security
- [ ] No hardcoded secrets (use envied or secure storage)
- [ ] User input validated/sanitized
- [ ] Database encryption properly configured
- [ ] Keys stored in Keychain/Keystore

### Testing
- [ ] Unit tests for business logic
- [ ] Widget tests for UI components
- [ ] Edge cases handled (null, empty, max values)
- [ ] Mocked external dependencies

## Review Output Format

```markdown
## Code Review: [Branch/Files]

### Summary
- Files reviewed: N
- Issues found: N critical, N warnings, N suggestions
- Overall: [APPROVE / REQUEST_CHANGES / COMMENT]

### Critical Issues
1. **[File:line]** — Description
   **Fix:** Specific recommendation

### Warnings
1. **[File:line]** — Description
   **Suggestion:** Improvement idea

### Architecture Notes
[Compliance with clean architecture]

### Positive Feedback
[What was done well]
```

## Commands
```bash
# Get changed files
git diff --name-only HEAD~1

# Run analyzer on changes
flutter analyze $(git diff --name-only HEAD~1 | grep '\.dart$')
```
