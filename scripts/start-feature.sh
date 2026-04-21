#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ $# -eq 0 ]; then
    echo "Usage: $(basename "$0") <feature-name>"
    echo "Example: $(basename "$0") expense-recurring"
    exit 1
fi

FEATURE_NAME="$1"
BRANCH_NAME="feature/${FEATURE_NAME}"

cd "$PROJECT_ROOT"

echo "Starting feature: $FEATURE_NAME"
echo "========================="

# Ensure we're on develop and it's up to date
git checkout develop 2>/dev/null || git checkout -b develop
git pull origin develop 2>/dev/null || true

# Create feature branch
git checkout -b "$BRANCH_NAME"

echo ""
echo "Feature branch created: $BRANCH_NAME"
echo ""
echo "Next steps:"
echo "  1. Implement the feature"
echo "  2. Run: ./scripts/dev-pipeline.sh full"
echo "  3. Run: ./scripts/submit-feature.sh"
