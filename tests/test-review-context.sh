#!/usr/bin/env bash
set -uo pipefail

FAILURES=0
LAST_OUTPUT=""
LAST_STATUS=0
LAST_GH_LOG=""
BASH_BIN=${BASH:-/bin/bash}
SCRIPT_PATH="$(pwd -P)/scripts/review-context.sh"

make_gh_stub() {
  local dir="$1"
  local log_file="$2"

  mkdir -p "$dir"
  cat > "$dir/gh" <<'STUB'
#!/usr/bin/env bash
printf "%s\n" "$*" >> "$GH_STUB_LOG"

case "$1 $2" in
  "pr view")
    if [[ "$3" != "12" || "$4" != "--json" ]]; then
      echo "unexpected gh pr view arguments: $*" >&2
      exit 1
    fi
    printf "12\nAdd review helper\nhttps://github.com/example/repo/pull/12\nOPEN\nengineer\nfeature/review-context-helper\nmain\nCloses #41\n\nReady for review.\n"
    ;;
  "pr diff")
    if [[ "$3" != "12" ]]; then
      echo "unexpected gh pr diff PR: $*" >&2
      exit 1
    fi
    case "${4:-}" in
      --name-only)
        printf "scripts/review-context.sh\ntests/test-review-context.sh\n"
        ;;
      --stat)
        printf " scripts/review-context.sh      | 120 +++++++++++++++++++++++++\n tests/test-review-context.sh   | 150 +++++++++++++++++++++++++++++++\n"
        ;;
      "")
        printf "diff --git a/scripts/review-context.sh b/scripts/review-context.sh\n"
        printf "+new helper content\n"
        ;;
      *)
        echo "unexpected gh pr diff arguments: $*" >&2
        exit 1
        ;;
    esac
    ;;
  "issue view")
    if [[ "$3" != "41" || "$4" != "--json" ]]; then
      echo "unexpected gh issue view arguments: $*" >&2
      exit 1
    fi
    printf "41\nAdd read-only review-context helper script\nhttps://github.com/example/repo/issues/41\n## Goal\nGather review context.\n\n## Acceptance Criteria\n\n- [ ] prints PR metadata\n- [ ] stays read-only\n## Risks\n\nNone.\n"
    ;;
  *)
    echo "unexpected gh command: $*" >&2
    exit 1
    ;;
esac
STUB
  chmod +x "$dir/gh"
  : > "$log_file"
}

make_check_stub() {
  local dir="$1"
  local script_path="$2"
  local status="$3"
  local message="$4"

  mkdir -p "$dir"
  cat > "$dir/$script_path" <<EOF
#!/usr/bin/env bash
echo "$message"
exit $status
EOF
  chmod +x "$dir/$script_path"
}

run_script() {
  local stub_dir
  local log_file

  stub_dir=$(mktemp -d)
  log_file="$stub_dir/gh.log"
  make_gh_stub "$stub_dir/bin" "$log_file"
  make_check_stub "$stub_dir/scripts" "lint.sh" 0 "lint ok"
  make_check_stub "$stub_dir/tests" "helper.sh" 1 "helper should not run"
  make_check_stub "$stub_dir/tests" "test-new-issue.sh" 2 "new issue failed"
  make_check_stub "$stub_dir/tests" "test-new-handoff.sh" 0 "new handoff ok"
  make_check_stub "$stub_dir/tests" "test-zz.sh" 0 "zz discovered ok"

  LAST_OUTPUT=$(cd "$stub_dir" && mkdir -p .git && touch CLAUDE.md AGENTS.md && GH_STUB_LOG="$log_file" PATH="$stub_dir/bin:$PATH" "$BASH_BIN" "$SCRIPT_PATH" "$@" 2>&1)
  LAST_STATUS=$?
  LAST_GH_LOG=$(cat "$log_file")
  rm -rf "$stub_dir"
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

assert_log_contains() {
  local name="$1"
  local expected="$2"

  if contains "$LAST_GH_LOG" "$expected"; then
    return 0
  fi

  fail "$name" "expected gh log to contain: $expected"
  return 1
}

assert_no_write_capable_gh_commands_in_script() {
  local name="$1"

  if grep -E 'gh[[:space:]]+(pr[[:space:]]+(review|comment|merge|close|reopen|edit|ready|lock|unlock)|issue[[:space:]]+(create|edit|close|reopen|comment|develop|delete|lock|unlock|transfer)|label[[:space:]]|api[[:space:]])' scripts/review-context.sh >/dev/null; then
    fail "$name" "script contains a write-capable gh command"
    return 1
  fi

  pass "$name"
}

test_prints_context_and_captures_check_statuses() {
  local name="prints context and captures check exit statuses"

  run_script 12

  assert_status "$name" 0 || return
  assert_output_contains "$name" "PR: #12 - Add review helper" || return
  assert_output_contains "$name" "Closes #41" || return
  assert_output_contains "$name" "Issue: #41 - Add read-only review-context helper script" || return
  assert_output_contains "$name" "## Acceptance Criteria" || return
  assert_output_contains "$name" "scripts/review-context.sh" || return
  assert_output_contains "$name" "diff --git a/scripts/review-context.sh b/scripts/review-context.sh" || return
  assert_output_contains "$name" "Exit status: 0" || return
  assert_output_contains "$name" "Exit status: 2" || return
  assert_output_contains "$name" "Command: bash tests/test-new-handoff.sh" || return
  assert_output_contains "$name" "Command: bash tests/test-new-issue.sh" || return
  assert_output_contains "$name" "Command: bash tests/test-zz.sh" || return
  assert_output_contains "$name" "new issue failed" || return
  assert_output_contains "$name" "zz discovered ok" || return
  assert_output_not_contains "$name" "helper should not run" || return
  assert_output_not_contains "$name" "Command: bash tests/helper.sh" || return
  assert_output_not_contains "$name" "approval" || return
  assert_output_not_contains "$name" "verdict" || return
  assert_log_contains "$name" "pr view 12 --json" || return
  assert_log_contains "$name" "pr diff 12 --name-only" || return
  assert_log_contains "$name" "pr diff 12" || return
  assert_log_contains "$name" "issue view 41 --json" || return

  pass "$name"
}

test_large_diff_uses_stat_summary() {
  local name="large diff uses stat summary"

  export REVIEW_CONTEXT_DIFF_SIZE_THRESHOLD=1
  run_script 12
  unset REVIEW_CONTEXT_DIFF_SIZE_THRESHOLD

  assert_status "$name" 0 || return
  assert_output_contains "$name" "above threshold 1. Showing stat summary instead." || return
  assert_output_contains "$name" "tests/test-review-context.sh   | 150" || return

  pass "$name"
}

test_no_linked_issue_is_non_fatal() {
  local name="no linked issue is non-fatal"
  local stub_dir
  local log_file

  stub_dir=$(mktemp -d)
  log_file="$stub_dir/gh.log"
  mkdir -p "$stub_dir/bin" "$stub_dir/scripts" "$stub_dir/tests" "$stub_dir/.git"
  touch "$stub_dir/CLAUDE.md" "$stub_dir/AGENTS.md"
  cat > "$stub_dir/bin/gh" <<'STUB'
#!/usr/bin/env bash
printf "%s\n" "$*" >> "$GH_STUB_LOG"
if [[ "$1 $2" == "pr view" ]]; then
  printf "13\nNo issue PR\nhttps://github.com/example/repo/pull/13\nOPEN\nengineer\nfeature/no-issue\nmain\nNo linked issue here.\n"
elif [[ "$1 $2" == "pr diff" && "${4:-}" == "--name-only" ]]; then
  printf "scripts/review-context.sh\n"
elif [[ "$1 $2" == "pr diff" ]]; then
  printf "small diff\n"
else
  echo "unexpected gh command: $*" >&2
  exit 1
fi
STUB
  chmod +x "$stub_dir/bin/gh"
  make_check_stub "$stub_dir/scripts" "lint.sh" 0 "lint ok"
  make_check_stub "$stub_dir/tests" "test-new-issue.sh" 0 "new issue ok"
  make_check_stub "$stub_dir/tests" "test-new-handoff.sh" 0 "new handoff ok"
  : > "$log_file"

  LAST_OUTPUT=$(cd "$stub_dir" && GH_STUB_LOG="$log_file" PATH="$stub_dir/bin:$PATH" "$BASH_BIN" "$SCRIPT_PATH" 13 2>&1)
  LAST_STATUS=$?
  LAST_GH_LOG=$(cat "$log_file")
  rm -rf "$stub_dir"

  assert_status "$name" 0 || return
  assert_output_contains "$name" "Notice: no linked issue found" || return
  assert_output_contains "$name" "PR: #13 - No issue PR" || return
  if contains "$LAST_GH_LOG" "issue view"; then
    fail "$name" "gh issue view should not run when no linked issue exists"
    return
  fi

  pass "$name"
}

assert_no_write_capable_gh_commands_in_script "script contains no write-capable gh subcommands"
test_prints_context_and_captures_check_statuses
test_large_diff_uses_stat_summary
test_no_linked_issue_is_non_fatal

if [[ "$FAILURES" -ne 0 ]]; then
  echo
  echo "$FAILURES test(s) failed."
  exit 1
fi

echo
echo "All tests passed."
