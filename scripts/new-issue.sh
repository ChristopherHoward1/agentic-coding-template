#!/usr/bin/env bash
# Usage: bash scripts/new-issue.sh (run from repository root)
set -euo pipefail

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

SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-' | sed 's/^-//;s/-$//')
OUTFILE="${SLUG}.md"

if [[ -f "$OUTFILE" ]]; then
  echo "Error: $OUTFILE already exists. Remove it or choose a different title." >&2
  exit 1
fi

{
  echo "## Goal"
  echo
  echo "$GOAL"
  echo

  if [[ -n "$BACKGROUND" ]]; then
    echo "## Background"
    echo
    echo "$BACKGROUND"
    echo
  fi

  echo "## Scope"
  echo
  echo "**In scope:**"
  echo
  for item in "${IN_SCOPE[@]}"; do
    echo "- $item"
  done
  echo
  echo "**Out of scope:**"
  echo
  for item in "${OUT_SCOPE[@]}"; do
    echo "- $item"
  done
  echo

  echo "## Acceptance Criteria"
  echo
  for item in "${AC[@]}"; do
    echo "- [ ] $item"
  done
  echo

  echo "## Decomposition"
  echo
  echo "_Add sub-tasks or recommended sequencing, if non-trivial. Remove this section if straightforward._"
  echo

  echo "## Risks"
  echo
  echo "_Known risks or dependencies worth flagging before implementation. Remove this section if none._"
} > "$OUTFILE"

echo
echo "Written: $OUTFILE"
echo
echo "Next steps:"
echo "  1. Edit $OUTFILE to add decomposition, risks, or any other details."
echo "  2. Open your GitHub repository's Issues tab and create a new issue."
echo "  3. Set the title to: $TITLE"
echo "  4. Paste the contents of $OUTFILE as the issue body."
echo "  5. Delete $OUTFILE once the issue is created."
