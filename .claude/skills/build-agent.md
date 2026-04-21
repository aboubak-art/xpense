---
description: Build automation skill for Xpense Flutter app - compiles, analyzes, and generates code
---

# Build Agent

Run the complete build pipeline for the Xpense Flutter app.

## Steps

1. **Pre-build checks**
   - Run `flutter doctor` to verify environment
   - Check `pubspec.yaml` exists and is valid
   - Verify all referenced assets exist

2. **Dependency resolution**
   ```bash
   flutter pub get
   ```

3. **Code generation**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Static analysis**
   ```bash
   flutter analyze
   dart format --set-exit-if-changed lib test
   ```

5. **Build verification**
   ```bash
   flutter build apk --flavor dev  # Quick Android build check
   ```

6. **Report results**
   - List any errors or warnings
   - Report build time
   - Flag critical issues for human review

## When to Use
- Before committing code
- After pulling latest changes
- After modifying generated-code dependencies (freezed, drift, retrofit)
- Before running tests

## Output Format
```
## Build Report
- Status: [PASS/WARNING/FAIL]
- Duration: Xs
- Issues: N warnings, M errors
- Generated files: [list if relevant]

## Critical Issues
[if any]

## Recommendations
[if any]
```
