#!/usr/bin/env bash
# Usage: bash scripts/new-handoff.sh [--dry-run] (run from repository root)
set -euo pipefail

DRY_RUN=false

if [[ $# -gt 1 ]]; then
  echo "Error: unrecognized arguments: $*" >&2
  exit 1
fi

if [[ $# -eq 1 ]]; then
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      echo "Error: unrecognized argument: $1" >&2
      exit 1
      ;;
  esac
fi

if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI is not installed. Install it from https://cli.github.com and authenticate with 'gh auth login'." >&2
  exit 1
fi

if [[ ! -f "CLAUDE.md" || ! -f "AGENTS.md" || ! -d ".git" ]]; then
  echo "Error: run this script from the repository root." >&2
  exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
CURRENT_DIR=$(pwd -P)
if [[ "$REPO_ROOT" != "$CURRENT_DIR" ]]; then
  echo "Error: run this script from the repository root." >&2
  exit 1
fi

if [[ "$DRY_RUN" == false ]] && [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: working tree is dirty. Commit, stash, or discard changes before creating a handoff branch." >&2
  exit 1
fi

echo "New Implementation Handoff"
echo "--------------------------"
echo

read -r -p "Issue number: " ISSUE_NUMBER
[[ -z "$ISSUE_NUMBER" ]] && { echo "Error: issue number is required." >&2; exit 1; }

read -r -p "Branch: " BRANCH
[[ -z "$BRANCH" ]] && { echo "Error: branch is required." >&2; exit 1; }

if [[ "$DRY_RUN" == false ]] && git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "Error: branch already exists: $BRANCH" >&2
  exit 1
fi

echo "Files to modify (one path per line, blank line to finish):"
FILES_TO_MODIFY=()
while true; do
  read -r -p "  - " item
  [[ -z "$item" ]] && break
  FILES_TO_MODIFY+=("$item")
done
[[ ${#FILES_TO_MODIFY[@]} -eq 0 ]] && { echo "Error: at least one file to modify is required." >&2; exit 1; }

echo "Files not to modify (one path per line, blank line to finish):"
FILES_NOT_TO_MODIFY=()
while true; do
  read -r -p "  - " item
  [[ -z "$item" ]] && break
  FILES_NOT_TO_MODIFY+=("$item")
done
[[ ${#FILES_NOT_TO_MODIFY[@]} -eq 0 ]] && { echo "Error: at least one file not to modify is required." >&2; exit 1; }

echo "Key constraints (one item per line, blank line to finish):"
KEY_CONSTRAINTS=()
while true; do
  read -r -p "  - " item
  [[ -z "$item" ]] && break
  KEY_CONSTRAINTS+=("$item")
done
[[ ${#KEY_CONSTRAINTS[@]} -eq 0 ]] && { echo "Error: at least one key constraint is required." >&2; exit 1; }

echo "Verification commands (one command per line, blank line to finish):"
VERIFICATION=()
while true; do
  read -r -p "  - " item
  [[ -z "$item" ]] && break
  VERIFICATION+=("$item")
done
[[ ${#VERIFICATION[@]} -eq 0 ]] && { echo "Error: at least one verification command is required." >&2; exit 1; }

echo "PR expectations (one item per line, blank line to finish):"
PR_EXPECTATIONS=()
while true; do
  read -r -p "  - " item
  [[ -z "$item" ]] && break
  PR_EXPECTATIONS+=("$item")
done
[[ ${#PR_EXPECTATIONS[@]} -eq 0 ]] && { echo "Error: at least one PR expectation is required." >&2; exit 1; }

ISSUE_METADATA=$(gh issue view "$ISSUE_NUMBER" --json number,title,url --template '{{.number}}{{"\n"}}{{.title}}{{"\n"}}{{.url}}{{"\n"}}')
ISSUE_NUMBER=$(printf "%s" "$ISSUE_METADATA" | sed -n '1p')
ISSUE_TITLE=$(printf "%s" "$ISSUE_METADATA" | sed -n '2p')
ISSUE_URL=$(printf "%s" "$ISSUE_METADATA" | sed -n '3p')

[[ -z "$ISSUE_TITLE" ]] && { echo "Error: could not retrieve issue title from gh issue view." >&2; exit 1; }
[[ -z "$ISSUE_URL" ]] && { echo "Error: could not retrieve issue URL from gh issue view." >&2; exit 1; }

if [[ "$DRY_RUN" == false ]]; then
  git fetch origin main
  git checkout main
  git pull --ff-only origin main
  git checkout -b "$BRANCH"

  read -r -p "Push branch to origin? [y/N]: " PUSH_BRANCH
  case "$PUSH_BRANCH" in
    y|Y|yes|YES)
      git push -u origin "$BRANCH"
      ;;
  esac
fi

CHECKED_OUT_BRANCH=$(git branch --show-current)
if [[ "$DRY_RUN" == false && "$CHECKED_OUT_BRANCH" != "$BRANCH" ]]; then
  echo "Error: expected to be checked out on $BRANCH, but current branch is $CHECKED_OUT_BRANCH." >&2
  exit 1
fi

CHECKOUT_BRANCH="$BRANCH"
if [[ "$DRY_RUN" == false ]]; then
  CHECKOUT_BRANCH="$CHECKED_OUT_BRANCH"
fi

echo
if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run: branch was not created and no GitHub writes were made."
  echo
fi

echo "## Implementation Handoff"
echo
echo "Issue: #$ISSUE_NUMBER - $ISSUE_TITLE"
echo "Issue URL: $ISSUE_URL"
echo "Branch: $BRANCH"
echo 'Checkout confirmation: The repository is currently checked out on `'"$CHECKOUT_BRANCH"'`.'
echo "Files to Modify:"
for item in "${FILES_TO_MODIFY[@]}"; do
  echo "- $item"
done
echo "Files Not to Modify:"
for item in "${FILES_NOT_TO_MODIFY[@]}"; do
  echo "- $item"
done
echo "Key Constraints:"
for item in "${KEY_CONSTRAINTS[@]}"; do
  echo "- $item"
done
echo "Acceptance Criteria:"
echo "- See Issue #$ISSUE_NUMBER: $ISSUE_URL"
echo "Verification:"
for item in "${VERIFICATION[@]}"; do
  echo "- $item"
done
echo "PR Expectations:"
for item in "${PR_EXPECTATIONS[@]}"; do
  echo "- $item"
done
