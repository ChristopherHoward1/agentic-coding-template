#!/usr/bin/env bash
set -uo pipefail

FAILURES=0
LAST_OUTPUT=""
LAST_STATUS=0

run_script() {
  local input="$1"
  shift

  LAST_OUTPUT=$(printf "%b" "$input" | bash scripts/new-issue.sh "$@" 2>&1)
  LAST_STATUS=$?
}

contains() {
  local haystack="$1"
  local needle="$2"

  [[ "$haystack" == *"$needle"* ]]
}

pass() {
  local name="$1"

  echo "PASS: $name"
}

fail() {
  local name="$1"
  local message="$2"

  echo "FAIL: $name - $message"
  FAILURES=$((FAILURES + 1))
}

assert_status() {
  local name="$1"
  local expected="$2"

  if [[ "$LAST_STATUS" -eq "$expected" ]]; then
    return 0
  fi

  fail "$name" "expected exit $expected, got $LAST_STATUS"
  return 1
}

assert_nonzero_status() {
  local name="$1"

  if [[ "$LAST_STATUS" -ne 0 ]]; then
    return 0
  fi

  fail "$name" "expected non-zero exit, got 0"
  return 1
}

assert_output_contains() {
  local name="$1"
  local expected="$2"

  if contains "$LAST_OUTPUT" "$expected"; then
    return 0
  fi

  fail "$name" "expected output to contain: $expected"
  return 1
}

test_dry_run_output() {
  local name="dry-run prints issue title and body"

  run_script "My Title\nMy Goal\n\nIn scope item\n\nOut of scope item\n\nMy AC\n\n" --dry-run

  assert_status "$name" 0 || return
  assert_output_contains "$name" "Dry run: GitHub Issue was not created." || return
  assert_output_contains "$name" "Title: My Title" || return
  assert_output_contains "$name" "## Goal" || return
  assert_output_contains "$name" "My Goal" || return
  assert_output_contains "$name" "## Scope" || return
  assert_output_contains "$name" "- In scope item" || return
  assert_output_contains "$name" "- Out of scope item" || return
  assert_output_contains "$name" "## Acceptance Criteria" || return
  assert_output_contains "$name" "- [ ] My AC" || return

  pass "$name"
}

test_unrecognized_argument() {
  local name="unrecognized argument exits non-zero"

  run_script "" --unknown

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: unrecognized argument: --unknown" || return

  pass "$name"
}

test_too_many_arguments() {
  local name="too many arguments exit non-zero"

  run_script "" --dry-run extra

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: unrecognized arguments: --dry-run extra" || return

  pass "$name"
}

test_empty_title() {
  local name="empty title exits non-zero"

  run_script "\n" --dry-run

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: title is required." || return

  pass "$name"
}

test_empty_goal() {
  local name="empty goal exits non-zero"

  run_script "My Title\n\n" --dry-run

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: goal is required." || return

  pass "$name"
}

test_no_acceptance_criteria() {
  local name="no acceptance criteria exits non-zero"

  run_script "My Title\nMy Goal\n\n\n\n\n" --dry-run

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: at least one acceptance criterion is required." || return

  pass "$name"
}

test_dry_run_output
test_unrecognized_argument
test_too_many_arguments
test_empty_title
test_empty_goal
test_no_acceptance_criteria

if [[ "$FAILURES" -ne 0 ]]; then
  echo
  echo "$FAILURES test(s) failed."
  exit 1
fi

echo
echo "All tests passed."
