---
description: Test automation skill for Xpense - runs test suites and reports coverage
---

# Test Agent

Execute the complete test suite for the Xpense Flutter app and report results.

## Test Execution Steps

1. **Unit Tests**
   ```bash
   flutter test test/unit/
   ```

2. **Widget Tests**
   ```bash
   flutter test test/widget/
   ```

3. **Integration Tests**
   ```bash
   flutter test integration_test/
   ```

4. **Coverage Report**
   ```bash
   flutter test --coverage
   genhtml coverage/lcov.info -o coverage/html
   ```

5. **Golden Tests**
   ```bash
   flutter test test/golden/
   ```

## Coverage Thresholds
- Overall: 80%+
- Domain layer: 90%+
- Data layer: 80%+
- Presentation: 70%+

## Test Categories

### Must Pass (Blocking)
- Domain layer unit tests
- Critical user flow widget tests
- Database integration tests
- Repository tests

### Should Pass (Non-blocking)
- Full widget test suite
- Golden tests
- Accessibility tests

### Nice to Pass
- Performance benchmarks
- Full integration test suite

## Output Format
```markdown
## Test Report

### Summary
- Total tests: N
- Passed: N / Failed: N / Skipped: N
- Duration: Xm Ys
- Coverage: X.X%

### Results by Category
| Category | Tests | Passed | Failed | Coverage |
|----------|-------|--------|--------|----------|
| Unit     | N     | N      | N      | X%       |
| Widget   | N     | N      | N      | X%       |
| Integration | N  | N      | N      | X%       |

### Failed Tests
1. **[test/file.dart:line]** — Test name
   **Error:** [error message]
   **Fix:** [suggestion]

### Coverage Gaps
1. **[file.dart]** — X% covered
   **Missing:** [lines/functions not tested]

### Recommendations
[Suggestions for improving test quality/coverage]
```

## Regression Testing
When reviewing PRs, run tests for affected areas:
```bash
# Run tests related to changed files
flutter test $(git diff --name-only HEAD~1 | grep '_test\.dart$')
```
