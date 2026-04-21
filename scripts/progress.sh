#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "Xpense Development Progress"
echo "==========================="
echo ""

# Count stories from EPICS_STORIES.md
if [ -f "docs/EPICS_STORIES.md" ]; then
    TOTAL_STORIES=$(grep -c "^### Story" docs/EPICS_STORIES.md 2>/dev/null || echo "0")
    echo "Total Stories Defined: $TOTAL_STORIES"
fi

# Git stats
if [ -d .git ]; then
    TOTAL_COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    BRANCHES=$(git branch -r 2>/dev/null | wc -l | tr -d ' ')
    FEATURE_BRANCHES=$(git branch -r 2>/dev/null | grep "feature/" | wc -l | tr -d ' ')

    echo "Total Commits: $TOTAL_COMMITS"
    echo "Remote Branches: $BRANCHES"
    echo "Feature Branches: $FEATURE_BRANCHES"

    # Last commit
    LAST_COMMIT=$(git log -1 --format="%h %s (%cr)" 2>/dev/null || echo "No commits yet")
    echo "Last Commit: $LAST_COMMIT"
fi

# Test coverage
if [ -f "coverage/lcov.info" ]; then
    COVERAGE=$(grep -o 'LF:[0-9]*' coverage/lcov.info 2>/dev/null | awk -F: '{sum+=$2} END {print sum}')
    HIT=$(grep -o 'LH:[0-9]*' coverage/lcov.info 2>/dev/null | awk -F: '{sum+=$2} END {print sum}')
    if [ -n "$COVERAGE" ] && [ "$COVERAGE" -gt 0 ]; then
        PERCENTAGE=$((HIT * 100 / COVERAGE))
        echo "Test Coverage: ${PERCENTAGE}%"
    fi
else
    echo "Test Coverage: No report found (run: make coverage)"
fi

# Pipeline status
LATEST_LOG=$(ls -t .logs/pipeline_*.log 2>/dev/null | head -1)
if [ -n "$LATEST_LOG" ]; then
    LOG_DATE=$(basename "$LATEST_LOG" | sed 's/pipeline_//;s/\.log//;s/_/ /')
    if grep -q "PIPELINE COMPLETE" "$LATEST_LOG" 2>/dev/null; then
        echo "Last Pipeline: PASS ($LOG_DATE)"
    else
        echo "Last Pipeline: FAIL ($LOG_DATE)"
    fi
else
    echo "Last Pipeline: No runs yet"
fi

# Source stats
if command -v cloc >/dev/null 2>&1; then
    echo ""
    cloc lib/ --quiet 2>/dev/null | tail -4 || true
elif command -v wc >/dev/null 2>&1; then
    DART_FILES=$(find lib -name "*.dart" 2>/dev/null | wc -l | tr -d ' ')
    DART_LINES=$(find lib -name "*.dart" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')
    echo "Dart Files: $DART_FILES"
    echo "Lines of Code: $DART_LINES"
fi

echo ""
echo "Next Steps:"
echo "  - Run 'make pipeline' to execute full pipeline"
echo "  - Run './scripts/start-feature.sh <name>' to start a new feature"
