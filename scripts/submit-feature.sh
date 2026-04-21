#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

CURRENT_BRANCH=$(git branch --show-current)

if [[ ! "$CURRENT_BRANCH" =~ ^feature/ ]]; then
    echo "Error: Not on a feature branch. Current: $CURRENT_BRANCH"
    echo "Run ./scripts/start-feature.sh first"
    exit 1
fi

FEATURE_NAME="${CURRENT_BRANCH#feature/}"

echo "Submitting feature: $FEATURE_NAME"
echo "========================="

# Run pipeline
echo "Running pipeline..."
if ! ./scripts/dev-pipeline.sh full; then
    echo ""
    echo "Pipeline failed. Fix issues before submitting."
    exit 1
fi

# Stage all changes
git add -A

# Generate commit message from conventional commits
COMMIT_TYPE="feat"
if git diff --cached --name-only | grep -q "test"; then
    COMMIT_TYPE="test"
fi
if git diff --cached --name-only | grep -q "fix\|bug"; then
    COMMIT_TYPE="fix"
fi

COMMIT_MSG="${COMMIT_TYPE}(${FEATURE_NAME}): implement feature"

echo ""
echo "Commit message: $COMMIT_MSG"
read -p "Press Enter to commit, or Ctrl+C to abort..."

git commit -m "$COMMIT_MSG"

# Push
git push -u origin "$CURRENT_BRANCH"

# Create PR using gh if available
if command -v gh &> /dev/null; then
    echo ""
    echo "Creating pull request..."
    gh pr create \
        --title "feat: ${FEATURE_NAME}" \
        --body "$(cat << EOF
## Feature: ${FEATURE_NAME}

### Changes
$(git diff --name-only develop...HEAD | sed 's/^/- /')

### Testing
- [ ] Unit tests pass
- [ ] Widget tests pass
- [ ] Manual QA complete

### Pipeline
$(cat .logs/pipeline_*.log 2>/dev/null | tail -20 || echo "Pipeline logs available in .logs/")
EOF
)" \
        --base develop \
        2>/dev/null || echo "PR may already exist or gh auth required"
fi

echo ""
echo "Feature submitted: $FEATURE_NAME"
echo "Branch: $CURRENT_BRANCH"
