#!/usr/bin/env bash
# Usage: bash scripts/new-issue.sh (run from repository root)
set -euo pipefail

if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI is not installed. Install it from https://cli.github.com and authenticate with 'gh auth login'." >&2
  exit 1
fi

TEMPLATE=".github/ISSUE_TEMPLATE/implementation.md"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Error: run this script from the repository root." >&2
  exit 1
fi

echo "New Implementation Issue"
echo "------------------------"
echo

read -r -p "Title: " TITLE
[[ -z "$TITLE" ]] && { echo "Error: title is required." >&2; exit 1; }

read -r -p "Goal (one sentence): " GOAL
[[ -z "$GOAL" ]] && { echo "Error: goal is required." >&2; exit 1; }

read -r -p "Background (optional, press Enter to skip): " BACKGROUND

echo "In scope (one item per line, blank line to finish):"
IN_SCOPE=()
while true; do
  read -r -p "  - " item
  [[ -z "$item" ]] && break
  IN_SCOPE+=("$item")
done

echo "Out of scope (one item per line, blank line to finish):"
OUT_SCOPE=()
while true; do
  read -r -p "  - " item
  [[ -z "$item" ]] && break
  OUT_SCOPE+=("$item")
done

echo "Acceptance criteria (one item per line, blank line to finish):"
AC=()
while true; do
  read -r -p "  - [ ] " item
  [[ -z "$item" ]] && break
  AC+=("$item")
done
[[ ${#AC[@]} -eq 0 ]] && { echo "Error: at least one acceptance criterion is required." >&2; exit 1; }

BODY=""
BODY+="## Goal"$'\n'
BODY+=$'\n'
BODY+="$GOAL"$'\n'
BODY+=$'\n'

if [[ -n "$BACKGROUND" ]]; then
  BODY+="## Background"$'\n'
  BODY+=$'\n'
  BODY+="$BACKGROUND"$'\n'
  BODY+=$'\n'
fi

BODY+="## Scope"$'\n'
BODY+=$'\n'
BODY+="**In scope:**"$'\n'
BODY+=$'\n'
for item in "${IN_SCOPE[@]}"; do
  BODY+="- $item"$'\n'
done
BODY+=$'\n'
BODY+="**Out of scope:**"$'\n'
BODY+=$'\n'
for item in "${OUT_SCOPE[@]}"; do
  BODY+="- $item"$'\n'
done
BODY+=$'\n'

BODY+="## Acceptance Criteria"$'\n'
BODY+=$'\n'
for item in "${AC[@]}"; do
  BODY+="- [ ] $item"$'\n'
done
BODY+=$'\n'

BODY+="## Decomposition"$'\n'
BODY+=$'\n'
BODY+="_Add sub-tasks or recommended sequencing, if non-trivial. Remove this section if straightforward._"$'\n'
BODY+=$'\n'

BODY+="## Risks"$'\n'
BODY+=$'\n'
BODY+="_Known risks or dependencies worth flagging before implementation. Remove this section if none._"$'\n'

echo
echo "Creating GitHub Issue..."
ISSUE_URL=$(gh issue create --title "$TITLE" --body "$BODY")
echo
echo "Issue created: $ISSUE_URL"
