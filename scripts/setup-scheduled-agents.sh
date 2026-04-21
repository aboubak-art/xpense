#!/usr/bin/env bash
set -euo pipefail

echo "Xpense Scheduled Agent Setup"
echo "============================="
echo ""
echo "This script shows you the commands to set up automated development agents."
echo "You must be logged into claude.ai first. Run: /login"
echo ""

cat << 'EOF'
## Step 1: Login to Claude.ai
Run this in Claude Code:
  /login

## Step 2: Create Scheduled Triggers

### Feature Development Agent (runs every 4 hours on weekdays)
Use the schedule skill or RemoteTrigger with this config:

Name: xpense-feature-dev
Schedule: 0 */4 * * 1-5
Prompt: You are working on the Xpense Flutter expense tracker app in /Users/sidikfaha/Desktop/Aboubak-art/xpense. Read docs/EPICS_STORIES.md to find the next unimplemented user story. Implement it end-to-end following clean architecture: domain layer first (entities, repository interface, use case), then data layer (drift table, DAO, repository impl, model), then presentation (Riverpod provider, page, widgets). Add haptic feedback per docs/UI_UX_GUIDE.md. Write unit and widget tests. Run ./scripts/dev-pipeline.sh full. If passing, commit with conventional commit message and push to the feature branch.

### Nightly QA Agent (runs daily at 2:00 AM)
Name: xpense-nightly-qa
Schedule: 0 2 * * *
Prompt: You are the QA agent for the Xpense Flutter app in /Users/sidikfaha/Desktop/Aboubak-art/xpense. Run the full quality assurance pipeline: execute ./scripts/dev-pipeline.sh full, verify test coverage meets 80% threshold, check for any analyzer warnings, review recent commits for quality issues. Generate a QA report summarizing results.

### Weekly Release Review (runs Fridays at 6:00 PM)
Name: xpense-release-review
Schedule: 0 18 * * 5
Prompt: Review all merged PRs since last release for the Xpense app. Update CHANGELOG.md, bump version in pubspec.yaml, run full pipeline on release build, generate release notes, and tag a release candidate.

## Step 3: Alternative - Use /loop for intensive development

For focused development sprints, use:
  /loop Implement the current user story for Xpense. Check docs/EPICS_STORIES.md for the active story. Follow clean architecture. Write tests. Run pipeline. When complete, move to next story.

This will self-pace across sessions without manual intervention.

## Step 4: Monitor Progress

Check development progress anytime:
  ./scripts/progress.sh

Or in Claude Code:
  Run ./scripts/progress.sh and summarize what needs attention.

EOF

echo ""
echo "Setup complete. Follow the steps above to activate scheduled agents."
