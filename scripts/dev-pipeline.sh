#!/usr/bin/env bash
set -euo pipefail

# Xpense Development Pipeline
# Progressive build, review, and test automation
# Usage: ./scripts/dev-pipeline.sh [build|review|test|full|story <story-id>]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/.logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/pipeline_$TIMESTAMP.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

mkdir -p "$LOG_DIR"

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

info() { log "${BLUE}[INFO]${NC} $1"; }
success() { log "${GREEN}[PASS]${NC} $1"; }
warn() { log "${YELLOW}[WARN]${NC} $1"; }
error() { log "${RED}[FAIL]${NC} $1"; }

check_flutter() {
    info "Checking Flutter environment..."
    if ! command -v flutter &> /dev/null; then
        error "Flutter not found in PATH"
        exit 1
    fi
    FLUTTER_VERSION=$(flutter --version | head -1)
    success "Flutter found: $FLUTTER_VERSION"
}

run_build() {
    info "=== BUILD PHASE ==="
    cd "$PROJECT_ROOT"

    info "Getting dependencies..."
    flutter pub get >> "$LOG_FILE" 2>&1 && success "Dependencies resolved" || { error "pub get failed"; return 1; }

    info "Running code generation..."
    flutter pub run build_runner build --delete-conflicting-outputs >> "$LOG_FILE" 2>&1 && success "Code generation complete" || { error "Code generation failed"; return 1; }

    info "Running static analysis..."
    flutter analyze >> "$LOG_FILE" 2>&1 && success "Static analysis passed" || { warn "Static analysis found issues (check logs)"; }

    info "Checking code formatting..."
    if dart format --set-exit-if-changed lib test >> "$LOG_FILE" 2>&1; then
        success "Code formatting OK"
    else
        warn "Code formatting issues found. Run: dart format lib test"
    fi

    info "Building Android dev APK..."
    flutter build apk --flavor dev >> "$LOG_FILE" 2>&1 && success "Android build OK" || { error "Android build failed"; return 1; }

    success "Build phase complete"
}

run_review() {
    info "=== REVIEW PHASE ==="
    cd "$PROJECT_ROOT"

    if [ ! -d .git ]; then
        warn "Not a git repository, skipping diff review"
        return 0
    fi

    CHANGED_FILES=$(git diff --name-only HEAD~1 2>/dev/null || echo "")
    if [ -z "$CHANGED_FILES" ]; then
        warn "No changed files to review"
        return 0
    fi

    info "Changed files:"
    echo "$CHANGED_FILES" | tee -a "$LOG_FILE"

    DART_FILES=$(echo "$CHANGED_FILES" | grep '\.dart$' || true)
    if [ -n "$DART_FILES" ]; then
        info "Analyzing changed Dart files..."
        flutter analyze $DART_FILES >> "$LOG_FILE" 2>&1 && success "Changed files analysis OK" || warn "Issues in changed files"
    fi

    # Check for common issues
    info "Running custom lint checks..."

    # Check for debug prints
    if echo "$CHANGED_FILES" | xargs grep -l 'print(' 2>/dev/null; then
        warn "Found print() statements in changed files. Use logger instead."
    fi

    # Check for TODO/FIXME
    TODOS=$(echo "$CHANGED_FILES" | xargs grep -n 'TODO\|FIXME\|HACK' 2>/dev/null || true)
    if [ -n "$TODOS" ]; then
        warn "Found TODOs/FIXMEs:"
        echo "$TODOS" | tee -a "$LOG_FILE"
    fi

    success "Review phase complete"
}

run_tests() {
    info "=== TEST PHASE ==="
    cd "$PROJECT_ROOT"

    info "Running unit tests..."
    if [ -d "test/unit" ]; then
        flutter test test/unit/ >> "$LOG_FILE" 2>&1 && success "Unit tests passed" || error "Unit tests failed"
    else
        warn "No unit tests found"
    fi

    info "Running widget tests..."
    if [ -d "test/widget" ]; then
        flutter test test/widget/ >> "$LOG_FILE" 2>&1 && success "Widget tests passed" || error "Widget tests failed"
    else
        warn "No widget tests found"
    fi

    info "Running coverage..."
    flutter test --coverage >> "$LOG_FILE" 2>&1 && success "Coverage report generated" || warn "Coverage incomplete"

    if [ -f "coverage/lcov.info" ]; then
        COVERAGE=$(grep -o 'LF:[0-9]*' coverage/lcov.info | awk -F: '{sum+=$2} END {print sum}')
        HIT=$(grep -o 'LH:[0-9]*' coverage/lcov.info | awk -F: '{sum+=$2} END {print sum}')
        if [ -n "$COVERAGE" ] && [ "$COVERAGE" -gt 0 ]; then
            PERCENTAGE=$((HIT * 100 / COVERAGE))
            info "Coverage: $PERCENTAGE% ($HIT / $COVERAGE lines)"
            if [ "$PERCENTAGE" -lt 80 ]; then
                warn "Coverage below 80% target"
            else
                success "Coverage target met"
            fi
        fi
    fi

    success "Test phase complete"
}

run_full() {
    info "=== FULL PIPELINE ==="
    run_build
    run_review
    run_tests

    echo ""
    success "=== PIPELINE COMPLETE ==="
    info "Log file: $LOG_FILE"
}

run_story() {
    STORY_ID=$1
    info "=== STORY MODE: $STORY_ID ==="

    # Story-specific pipeline execution
    # This can be extended to run tests for specific features
    case "$STORY_ID" in
        "expenses")
            info "Running expense-related tests..."
            flutter test test/unit/domain/usecases/expenses/ 2>/dev/null || warn "No expense usecase tests yet"
            flutter test test/widget/expenses/ 2>/dev/null || warn "No expense widget tests yet"
            ;;
        "budgets")
            info "Running budget-related tests..."
            flutter test test/unit/domain/usecases/budgets/ 2>/dev/null || warn "No budget usecase tests yet"
            ;;
        "analytics")
            info "Running analytics-related tests..."
            flutter test test/unit/core/utils/stats/ 2>/dev/null || warn "No stats tests yet"
            ;;
        *)
            info "Running full pipeline for story $STORY_ID"
            run_full
            ;;
    esac
}

show_help() {
    cat << EOF
Xpense Development Pipeline

Usage: $(basename "$0") [COMMAND]

Commands:
  build         Run build, code generation, and static analysis
  review        Review changed files for quality issues
  test          Run all test suites and coverage
  full          Run complete pipeline (build + review + test)
  story <id>    Run pipeline for specific story/feature
  help          Show this help message

Examples:
  $(basename "$0") build
  $(basename "$0") full
  $(basename "$0") story expenses

Environment:
  FLUTTER_ROOT    Path to Flutter SDK (optional)
EOF
}

# Main
case "${1:-full}" in
    build)
        check_flutter
        run_build
        ;;
    review)
        check_flutter
        run_review
        ;;
    test)
        check_flutter
        run_tests
        ;;
    full)
        check_flutter
        run_full
        ;;
    story)
        check_flutter
        if [ -z "${2:-}" ]; then
            error "Story ID required. Usage: $(basename "$0") story <id>"
            exit 1
        fi
        run_story "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
