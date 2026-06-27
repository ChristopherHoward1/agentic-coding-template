#!/usr/bin/env bash
# Usage: bash scripts/review-context.sh [pr-number] (run from repository root)
set -euo pipefail

DIFF_SIZE_THRESHOLD=${REVIEW_CONTEXT_DIFF_SIZE_THRESHOLD:-20000}

usage_error() {
  local message="$1"

  echo "Error: $message" >&2
  exit 1
}

require_gh() {
  if ! command -v gh &>/dev/null; then
    echo "Error: gh CLI is not installed. Install it from https://cli.github.com and authenticate with 'gh auth login'." >&2
    exit 1
  fi
}

print_section() {
  local title="$1"

  echo
  echo "## $title"
  echo
}

extract_issue_number() {
  local text="$1"
  local reference

  reference=$(printf "%s\n" "$text" | sed -nE 's/.*([Cc]loses|[Ff]ixes|[Rr]esolves)[[:space:]]+#([0-9]+).*/\2/p' | sed -n '1p')
  printf "%s" "$reference"
}

print_acceptance_criteria() {
  local body="$1"
  local criteria

  criteria=$(printf "%s\n" "$body" | sed -n '/^## Acceptance Criteria[[:space:]]*$/,/^## /p' | sed '$ { /^## /d; }')

  if [[ -n "$criteria" ]]; then
    printf "%s\n" "$criteria"
  else
    echo "Notice: no explicit Acceptance Criteria section found in the linked issue body."
  fi
}

run_check() {
  local label="$1"
  shift

  local output
  local status

  print_section "$label"
  echo "Command: $*"
  set +e
  output=$("$@" 2>&1)
  status=$?
  set -e
  echo "Exit status: $status"
  echo
  if [[ -n "$output" ]]; then
    printf "%s\n" "$output"
  else
    echo "(no output)"
  fi
}

if [[ $# -gt 1 ]]; then
  usage_error "expected zero or one PR number."
fi

require_gh

if [[ ! -f "CLAUDE.md" || ! -f "AGENTS.md" || ! -d ".git" ]]; then
  echo "Error: run this script from the repository root." >&2
  exit 1
fi

PR_REF="${1:-}"

PR_METADATA=$(gh pr view ${PR_REF:+"$PR_REF"} --json number,title,url,state,author,headRefName,baseRefName,body --template '{{.number}}{{"\n"}}{{.title}}{{"\n"}}{{.url}}{{"\n"}}{{.state}}{{"\n"}}{{.author.login}}{{"\n"}}{{.headRefName}}{{"\n"}}{{.baseRefName}}{{"\n"}}{{.body}}')
PR_NUMBER=$(printf "%s\n" "$PR_METADATA" | sed -n '1p')
PR_TITLE=$(printf "%s\n" "$PR_METADATA" | sed -n '2p')
PR_URL=$(printf "%s\n" "$PR_METADATA" | sed -n '3p')
PR_STATE=$(printf "%s\n" "$PR_METADATA" | sed -n '4p')
PR_AUTHOR=$(printf "%s\n" "$PR_METADATA" | sed -n '5p')
PR_HEAD=$(printf "%s\n" "$PR_METADATA" | sed -n '6p')
PR_BASE=$(printf "%s\n" "$PR_METADATA" | sed -n '7p')
PR_BODY=$(printf "%s\n" "$PR_METADATA" | sed '1,7d')

print_section "Pull Request"
echo "PR: #$PR_NUMBER - $PR_TITLE"
echo "URL: $PR_URL"
echo "State: $PR_STATE"
echo "Author: $PR_AUTHOR"
echo "Branch: $PR_HEAD -> $PR_BASE"
echo
echo "Body:"
if [[ -n "$PR_BODY" ]]; then
  printf "%s\n" "$PR_BODY"
else
  echo "(empty)"
fi

ISSUE_NUMBER=$(extract_issue_number "$PR_BODY")
if [[ -n "$ISSUE_NUMBER" ]]; then
  ISSUE_METADATA=$(gh issue view "$ISSUE_NUMBER" --json number,title,url,body --template '{{.number}}{{"\n"}}{{.title}}{{"\n"}}{{.url}}{{"\n"}}{{.body}}')
  ISSUE_TITLE=$(printf "%s\n" "$ISSUE_METADATA" | sed -n '2p')
  ISSUE_URL=$(printf "%s\n" "$ISSUE_METADATA" | sed -n '3p')
  ISSUE_BODY=$(printf "%s\n" "$ISSUE_METADATA" | sed '1,3d')

  print_section "Linked Issue"
  echo "Issue: #$ISSUE_NUMBER - $ISSUE_TITLE"
  echo "URL: $ISSUE_URL"
  echo
  echo "Body:"
  if [[ -n "$ISSUE_BODY" ]]; then
    printf "%s\n" "$ISSUE_BODY"
  else
    echo "(empty)"
  fi

  print_section "Linked Issue Acceptance Criteria"
  print_acceptance_criteria "$ISSUE_BODY"
else
  print_section "Linked Issue"
  echo "Notice: no linked issue found from a Closes/Fixes/Resolves #N reference in the PR body."
fi

print_section "Changed Files"
CHANGED_FILES=$(gh pr diff ${PR_REF:+"$PR_REF"} --name-only)
if [[ -n "$CHANGED_FILES" ]]; then
  printf "%s\n" "$CHANGED_FILES"
else
  echo "(none)"
fi

print_section "Diff"
DIFF_OUTPUT=$(gh pr diff ${PR_REF:+"$PR_REF"})
DIFF_SIZE=${#DIFF_OUTPUT}
if [[ "$DIFF_SIZE" -gt "$DIFF_SIZE_THRESHOLD" ]]; then
  echo "Diff is $DIFF_SIZE bytes, above threshold $DIFF_SIZE_THRESHOLD. Showing stat summary instead."
  echo
  gh pr diff ${PR_REF:+"$PR_REF"} --stat
else
  if [[ -n "$DIFF_OUTPUT" ]]; then
    printf "%s\n" "$DIFF_OUTPUT"
  else
    echo "(empty)"
  fi
fi

print_section "Verification"
run_check "lint" bash scripts/lint.sh

shopt -s nullglob
test_files=(tests/test-*.sh)

if [[ ${#test_files[@]} -gt 0 ]]; then
  for test_file in "${test_files[@]}"; do
    run_check "$(basename "$test_file" .sh)" bash "$test_file"
  done
fi
