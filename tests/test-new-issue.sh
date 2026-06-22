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

assert_output_not_contains() {
  local name="$1"
  local unexpected="$2"

  if ! contains "$LAST_OUTPUT" "$unexpected"; then
    return 0
  fi

  fail "$name" "expected output not to contain: $unexpected"
  return 1
}

assert_equals() {
  local name="$1"
  local actual="$2"
  local expected="$3"

  if [[ "$actual" == "$expected" ]]; then
    return 0
  fi

  fail "$name" "output did not match expected issue body"
  return 1
}

issue_body_output() {
  printf "%s" "$LAST_OUTPUT" | sed -n '/^## Goal$/,$p'
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

test_noninteractive_dry_run_output_parity() {
  local name="non-interactive dry-run output matches interactive output"
  local interactive_body
  local noninteractive_body

  run_script "My Title\nMy Goal\nMy Background\nIn scope item\nSecond in-scope item\n\nOut of scope item\n\nMy AC\nSecond AC\n\n" --dry-run
  assert_status "$name" 0 || return
  interactive_body=$(issue_body_output)

  run_script "" \
    --dry-run \
    --title "My Title" \
    --goal "My Goal" \
    --background "My Background" \
    --in-scope "In scope item" \
    --in-scope "Second in-scope item" \
    --out-of-scope "Out of scope item" \
    --acceptance-criterion "My AC" \
    --acceptance-criterion "Second AC"
  assert_status "$name" 0 || return
  assert_output_not_contains "$name" "New Implementation Issue" || return
  assert_output_not_contains "$name" "In scope (one item per line" || return
  noninteractive_body=$(issue_body_output)

  assert_equals "$name" "$noninteractive_body" "$interactive_body" || return

  pass "$name"
}

test_unrecognized_argument() {
  local name="unrecognized argument exits non-zero"

  run_script "" --unknown

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: unrecognized argument: --unknown" || return

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

test_noninteractive_missing_title() {
  local name="non-interactive missing title exits non-zero"

  run_script "" --dry-run --goal "My Goal" --acceptance-criterion "My AC"

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: title is required." || return
  assert_output_not_contains "$name" "Title:" || return

  pass "$name"
}

test_noninteractive_missing_goal() {
  local name="non-interactive missing goal exits non-zero"

  run_script "" --dry-run --title "My Title" --acceptance-criterion "My AC"

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: goal is required." || return
  assert_output_not_contains "$name" "Goal (one sentence):" || return

  pass "$name"
}

test_noninteractive_missing_acceptance_criteria() {
  local name="non-interactive missing acceptance criteria exits non-zero"

  run_script "" --dry-run --title "My Title" --goal "My Goal"

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: at least one acceptance criterion is required." || return
  assert_output_not_contains "$name" "Acceptance criteria (one item per line" || return

  pass "$name"
}

test_noninteractive_list_values_preserved() {
  local name="non-interactive list values preserve spaces and punctuation"

  run_script "" \
    --dry-run \
    --title "Flag Mode Issue" \
    --goal "Preserve list values exactly." \
    --in-scope "First item: spaces, commas, semicolons; and punctuation!" \
    --out-of-scope "Do not change templates, prompts, or rendered markdown." \
    --acceptance-criterion "Handles values with spaces, punctuation, and --flag-like text."

  assert_status "$name" 0 || return
  assert_output_contains "$name" "- First item: spaces, commas, semicolons; and punctuation!" || return
  assert_output_contains "$name" "- Do not change templates, prompts, or rendered markdown." || return
  assert_output_contains "$name" "- [ ] Handles values with spaces, punctuation, and --flag-like text." || return

  pass "$name"
}

test_dry_run_output
test_noninteractive_dry_run_output_parity
test_unrecognized_argument
test_empty_title
test_empty_goal
test_no_acceptance_criteria
test_noninteractive_missing_title
test_noninteractive_missing_goal
test_noninteractive_missing_acceptance_criteria
test_noninteractive_list_values_preserved

if [[ "$FAILURES" -ne 0 ]]; then
  echo
  echo "$FAILURES test(s) failed."
  exit 1
fi

echo
echo "All tests passed."
