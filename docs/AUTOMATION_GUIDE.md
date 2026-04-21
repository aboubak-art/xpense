# Xpense - Development Automation Guide

## Overview

This project uses a multi-agent automation system to progressively build, review, and test the Xpense app without exhausting context windows. The system combines:

1. **Local Scripts** — `scripts/dev-pipeline.sh` for immediate CI tasks
2. **Claude Skills** — `.claude/skills/*.md` for specialized agent behaviors
3. **Scheduled Remote Agents** — Recurring Claude Code sessions for sustained development
4. **GitHub Actions** — Continuous integration on every PR

## Architecture

```
Developer Request
       |
       v
+------------------+
|  Orchestrator    |  <- You, or a scheduled trigger
|  (decides what   |
|   to build next) |
+------------------+
       |
   +---+---+
   |       |
   v       v
+------+ +------+
| Build| |Review|  <- Claude skills or local scripts
|Agent | |Agent |
+------+ +------+
   |       |
   v       v
+------+ +------+
| Test | |  QA  |  <- Automated testing & validation
|Agent | |Agent |
+------+ +------+
   |       |
   v       v
+--------------+
|   GitHub     |  <- PRs, issues, releases
|   Repository |
+--------------+
```

## Quick Start

### Running the Pipeline Locally

```bash
# Full pipeline: build + review + test
./scripts/dev-pipeline.sh full

# Or use Make
make pipeline

# Individual phases
make lint          # Static analysis
make test          # All tests
make coverage      # With coverage report
make build         # Build Android APK
```

### Using Claude Skills

In Claude Code, invoke skills for specialized tasks:

```
/build-agent     -> Run build pipeline
/review-agent    -> Review changed files
/test-agent      -> Run test suite
/feature-dev     -> Implement a user story
/qa-agent        -> Quality assurance validation
```

### Progressive Development with Scheduled Agents

The most powerful automation runs on a schedule, progressively working through the backlog:

#### Story-Based Development

Each scheduled run picks the next story from the backlog and implements it end-to-end:

```
Scheduled Agent: "Xpense Feature Development"
Frequency: Every 4 hours during active development
Task:
  1. Read docs/EPICS_STORIES.md
  2. Find next unimplemented story
  3. Implement domain, data, and presentation layers
  4. Write unit and widget tests
  5. Run dev-pipeline.sh
  6. If passing, commit with conventional commit message
  7. Push to feature branch
  8. Create PR with story summary
```

#### Nightly QA Run

```
Scheduled Agent: "Xpense Nightly QA"
Frequency: Daily at 2:00 AM
Task:
  1. Pull latest changes from all branches
  2. Run full test suite with coverage
  3. Run integration tests
  4. Check for analyzer warnings
  5. Generate QA report
  6. Open issues for any regressions
```

#### Weekly Release Review

```
Scheduled Agent: "Xpense Release Review"
Frequency: Weekly on Fridays at 6:00 PM
Task:
  1. Review all merged PRs since last release
  2. Update CHANGELOG.md
  3. Bump version in pubspec.yaml
  4. Run full pipeline on release build
  5. Tag release candidate
  6. Generate release notes
```

## Setting Up Scheduled Triggers

### Using Claude Code Schedule Skill

```bash
# List existing triggers
/claude-code-schedule list

# Create a feature development trigger
/claude-code-schedule create \
  --name "xpense-feature-dev" \
  --cron "0 */4 * * 1-5" \
  --prompt "Implement the next user story from docs/EPICS_STORIES.md for the Xpense Flutter app. Follow the feature-dev skill. Run the dev pipeline. Commit and push if passing."

# Create a nightly QA trigger
/claude-code-schedule create \
  --name "xpense-nightly-qa" \
  --cron "0 2 * * *" \
  --prompt "Run full QA on the Xpense app. Execute ./scripts/dev-pipeline.sh full. Check test coverage. Open issues for regressions."
```

### Using /loop for Continuous Development

For intensive development periods, use `/loop` with dynamic pacing:

```
/loop Implement the current user story for Xpense. Check docs/EPICS_STORIES.md for the active story. Follow clean architecture. Write tests. Run pipeline. When complete, move to next story.
```

Claude will self-pace wakeups (every 20-30 minutes) to continue work across sessions.

## Git Workflow Integration

### Automated Branch Management

```bash
# Start a new feature
./scripts/start-feature.sh "expense-recurring"
# Creates: feature/expense-recurring from develop

# Submit for review
./scripts/submit-feature.sh
# Runs: pipeline -> commit -> push -> create PR -> request review

# Merge after approval
./scripts/merge-feature.sh
# Runs: rebase -> merge to develop -> delete branch
```

### Conventional Commits

All automated commits follow conventional format:

```
feat(expenses): add recurring expense support
 ^    ^            ^
 |    |            +-- Description
 |    +-- Scope (feature name)
 +-- Type: feat, fix, docs, test, refactor, perf, chore
```

## Context Window Management

To avoid exhausting the context window during long development sessions:

### 1. Story-Level Chunking
Each scheduled agent run focuses on exactly one user story (~3-8 points). This keeps the context focused and manageable.

### 2. Skill-Based Delegation
Complex tasks are delegated to skills that execute in fresh contexts:
- `/build-agent` — Fresh context for build tasks
- `/test-agent` — Fresh context for test execution
- `/review-agent` — Fresh context for code review

### 3. Session Summaries
Each agent run produces a concise summary that is stored in `.logs/session-summaries/`:

```markdown
## Session 2024-01-15 14:00
- Story: 2.1 Add Expense
- Status: COMPLETE
- Files changed: 12
- Tests added: 8
- Coverage: 87%
- Commits: 3
- Notes: Haptic feedback implemented per UI/UX guide
```

### 4. Git as State Machine
The Git repository itself becomes the state machine:
- `main` — Production
- `develop` — Integration
- `feature/*` — In-progress stories
- `hotfix/*` — Production fixes

Agents read the current state from Git and determine next actions.

## Monitoring Development Progress

### Dashboard

Run `./scripts/progress.sh` to see:

```
Xpense Development Progress
============================

Stories Completed: 8 / 25
Sprints Complete: 2 / 7
Current Sprint: 3
Active Stories: 2
Open PRs: 3
Test Coverage: 84%
Last Build: PASS (2 hours ago)

Sprint 3 Progress:
[████████░░░░░░░░░░░░] 40%

Next Up:
- Story 3.1: Category Management (5 pts)
- Story 4.1: Budget Creation (5 pts)
```

### Notification Channels

Configure the notification webhook in `.claude/settings.json`:

```json
{
  "notifications": {
    "webhook": "https://hooks.slack.com/services/...",
    "events": ["build-fail", "test-fail", "story-complete", "release-ready"]
  }
}
```

## Troubleshooting

### Build Failures

If the scheduled agent fails to build:

1. Check `.logs/pipeline_*.log` for error details
2. Run `./scripts/dev-pipeline.sh full` locally to reproduce
3. Fix the issue and push
4. The next scheduled run will pick up from there

### Context Limit Reached

If an agent hits the context limit mid-story:

1. The agent commits current progress: `git commit -m "wip(story-2.1): partial implementation"`
2. Next scheduled run reads the WIP commit message
3. Uses `git diff HEAD~1` to understand what was done
4. Continues from where it left off

### Merge Conflicts

If a scheduled agent encounters merge conflicts:

1. It aborts the merge and creates an issue: "Manual merge needed for feature/X"
2. Includes the conflict details in the issue body
3. Assigns to the human developer
4. Moves to the next story in the backlog

## Customization

### Adjusting Schedule

Edit the cron expressions in Claude Code triggers based on your development velocity:

- **Fast pace**: Every 2 hours on weekdays
- **Normal pace**: Every 4 hours on weekdays
- **Relaxed pace**: Twice daily (morning and evening)

### Adding Custom Skills

Create new skills in `.claude/skills/`:

```markdown
---
description: Custom skill description
---

# Skill Name

## Purpose
What this skill does.

## Steps
1. Step one
2. Step two

## Rules
- Rule one
- Rule two
```

Then invoke with `/skill-name`.

## Security Considerations

- Scheduled agents never push to `main` or `develop` directly
- All automated changes go through PRs
- Secrets (API keys, certificates) stored in GitHub Secrets, never in code
- Database encryption keys never logged or committed
- Supabase credentials in `.env` files (gitignored)

## Cost Optimization

- Schedule agents during off-peak hours when possible
- Use `/loop` dynamic pacing (20-30 min intervals) instead of rapid polling
- Set `run_if_changed` to skip runs when no relevant files changed
- Batch small stories together in a single session

---

## Getting Help

- Run `./scripts/dev-pipeline.sh help` for pipeline options
- Run `make help` for all available commands
- Check `.logs/` for detailed execution logs
- Open an issue on GitHub for automation problems
