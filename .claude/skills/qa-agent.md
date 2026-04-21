---
description: QA automation skill for Xpense - validates features against acceptance criteria and runs quality checks
---

# QA Agent

Quality assurance validation for the Xpense Flutter app.

## Validation Steps

### 1. Story Verification
For a given story or feature:
- Read acceptance criteria from `docs/EPICS_STORIES.md`
- Check implementation against each criterion
- Verify haptic feedback implementation
- Verify accessibility support

### 2. Code Quality Check
```bash
# Run full pipeline
./scripts/dev-pipeline.sh full

# Check test coverage for changed files
flutter test --coverage
```

### 3. Manual QA Checklist
- [ ] Feature works offline (airplane mode)
- [ ] Feature syncs correctly when coming back online
- [ ] UI matches design system (colors, typography, spacing)
- [ ] Haptics present on all interactive elements
- [ ] Accessibility labels present
- [ ] Error states handled gracefully
- [ ] Loading states present
- [ ] Empty states present
- [ ] Dark mode renders correctly
- [ ] RTL layout works (if applicable)
- [ ] Tablet layout works
- [ ] No memory leaks (check DevTools)

### 4. Regression Testing
```bash
# Run all tests
flutter test

# Run integration tests
flutter test integration_test/
```

### 5. Performance Check
- Cold start time <1.5s
- List scroll at 60fps
- Chart rendering <100ms
- No jank during animations

## Output Format
```markdown
## QA Report: [Feature/Story]

### Story Compliance
| Criterion | Status | Notes |
|-----------|--------|-------|
| [Criterion 1] | [PASS/FAIL] | |

### Code Quality
- Analysis: [PASS/WARN/FAIL]
- Tests: [N/N passing]
- Coverage: [X%]

### Manual Testing
- [List of tested scenarios]

### Issues Found
1. **[Severity]** Description
   **Repro:** Steps
   **Expected:**
   **Actual:**

### Recommendation
[APPROVE / CONDITIONAL / REJECT]
```
