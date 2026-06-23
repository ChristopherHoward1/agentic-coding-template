#!/usr/bin/env bash
set -uo pipefail

FAILURES=0
LAST_OUTPUT=""
LAST_STATUS=0
BASH_BIN=${BASH:-/bin/bash}
SCRIPT_PATH="$(pwd -P)/scripts/trigger-agent.sh"

make_codex_stub() {
  local dir="$1"
  local log_file="$2"
  local stdin_file="$3"

  mkdir -p "$dir"
  cat > "$dir/codex" <<'STUB'
#!/usr/bin/env bash
printf "%s\n" "$*" >> "$CODEX_STUB_LOG"
cat > "$CODEX_STUB_STDIN"
exit "$CODEX_STUB_STATUS"
STUB
  chmod +x "$dir/codex"
  : > "$log_file"
  : > "$stdin_file"
}

make_clean_repo() {
  local dir="$1"

  mkdir -p "$dir"
  (
    cd "$dir" || exit 1
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    printf "" > CLAUDE.md
    printf "" > AGENTS.md
    git add CLAUDE.md AGENTS.md
    git commit -q -m "Initial commit"
  )
}

write_committed_handoff() {
  local repo="$1"
  local path="$2"

  printf "Implementation handoff\nLine two\n" > "$repo/$path"
  (
    cd "$repo" || exit 1
    git add "$path"
    git commit -q -m "Add handoff"
  )
}

run_in_clean_repo() {
  local codex_status="$1"
  shift

  local temp_repo
  local stub_dir
  local log_file
  local stdin_file

  temp_repo=$(mktemp -d)
  stub_dir=$(mktemp -d)
  log_file="$stub_dir/codex.log"
  stdin_file="$stub_dir/stdin.txt"
  make_clean_repo "$temp_repo"
  make_codex_stub "$stub_dir/bin" "$log_file" "$stdin_file" "$codex_status"
  write_committed_handoff "$temp_repo" "handoff.md"
  (
    cd "$temp_repo" || exit 1
    CODEX_STUB_LOG="$log_file" \
      CODEX_STUB_STDIN="$stdin_file" \
      CODEX_STUB_STATUS="$codex_status" \
      PATH="$stub_dir/bin:$PATH" \
      "$BASH_BIN" "$SCRIPT_PATH" "$@" > "$stub_dir/output.txt" 2>&1
  )
  LAST_STATUS=$?
  LAST_OUTPUT=$(cat "$stub_dir/output.txt")
  LAST_CODEX_LOG=$(cat "$log_file")
  LAST_CODEX_STDIN=$(cat "$stdin_file")
  rm -rf "$temp_repo" "$stub_dir"
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

assert_equals() {
  local name="$1"
  local actual="$2"
  local expected="$3"

  if [[ "$actual" == "$expected" ]]; then
    return 0
  fi

  fail "$name" "expected '$expected', got '$actual'"
  return 1
}

test_invokes_codex_once_with_handoff_on_stdin() {
  local name="invokes codex once with handoff on stdin"

  run_in_clean_repo 0 handoff.md

  assert_status "$name" 0 || return
  assert_equals "$name" "$LAST_CODEX_LOG" "exec --sandbox workspace-write -" || return
  assert_equals "$name" "$LAST_CODEX_STDIN" "Implementation handoff
Line two" || return

  pass "$name"
}

test_exits_with_codex_status() {
  local name="exits with codex status"

  run_in_clean_repo 17 handoff.md

  assert_status "$name" 17 || return
  assert_equals "$name" "$LAST_CODEX_LOG" "exec --sandbox workspace-write -" || return

  pass "$name"
}

test_dry_run_prints_command_and_invokes_nothing() {
  local name="dry-run prints command and invokes nothing"

  run_in_clean_repo 0 --dry-run handoff.md

  assert_status "$name" 0 || return
  assert_equals "$name" "$LAST_OUTPUT" "codex exec --sandbox workspace-write - < \"handoff.md\"" || return
  assert_equals "$name" "$LAST_CODEX_LOG" "" || return

  pass "$name"
}

test_missing_path() {
  local name="missing path exits non-zero"

  run_in_clean_repo 0

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: handoff file path is required." || return
  assert_equals "$name" "$LAST_CODEX_LOG" "" || return

  pass "$name"
}

test_missing_or_empty_file() {
  local name="missing file exits non-zero"

  run_in_clean_repo 0 missing.md

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: handoff file does not exist or is empty: missing.md" || return
  assert_equals "$name" "$LAST_CODEX_LOG" "" || return

  pass "$name"
}

test_empty_file() {
  local name="empty file exits non-zero"
  local temp_repo
  local stub_dir
  local log_file
  local stdin_file

  temp_repo=$(mktemp -d)
  stub_dir=$(mktemp -d)
  log_file="$stub_dir/codex.log"
  stdin_file="$stub_dir/stdin.txt"
  make_clean_repo "$temp_repo"
  make_codex_stub "$stub_dir/bin" "$log_file" "$stdin_file" 0
  touch "$temp_repo/empty.md"
  (
    cd "$temp_repo" || exit 1
    git add empty.md
    git commit -q -m "Add empty handoff"
  )

  LAST_OUTPUT=$(cd "$temp_repo" && PATH="$stub_dir/bin:$PATH" "$BASH_BIN" "$SCRIPT_PATH" empty.md 2>&1)
  LAST_STATUS=$?
  LAST_CODEX_LOG=$(cat "$log_file")
  rm -rf "$temp_repo" "$stub_dir"

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: handoff file does not exist or is empty: empty.md" || return
  assert_equals "$name" "$LAST_CODEX_LOG" "" || return

  pass "$name"
}

test_missing_codex() {
  local name="missing codex exits non-zero"
  local temp_repo
  local empty_path

  temp_repo=$(mktemp -d)
  empty_path=$(mktemp -d)
  make_clean_repo "$temp_repo"
  write_committed_handoff "$temp_repo" "handoff.md"

  LAST_OUTPUT=$(cd "$temp_repo" && PATH="$empty_path:/usr/bin:/bin" "$BASH_BIN" "$SCRIPT_PATH" handoff.md 2>&1)
  LAST_STATUS=$?
  rm -rf "$temp_repo" "$empty_path"

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: codex CLI is not installed." || return

  pass "$name"
}

test_non_root_directory() {
  local name="non-root directory exits non-zero"
  local temp_repo
  local stub_dir
  local log_file
  local stdin_file

  temp_repo=$(mktemp -d)
  stub_dir=$(mktemp -d)
  log_file="$stub_dir/codex.log"
  stdin_file="$stub_dir/stdin.txt"
  make_clean_repo "$temp_repo"
  make_codex_stub "$stub_dir/bin" "$log_file" "$stdin_file" 0
  mkdir -p "$temp_repo/subdir"
  write_committed_handoff "$temp_repo" "handoff.md"

  LAST_OUTPUT=$(cd "$temp_repo/subdir" && PATH="$stub_dir/bin:$PATH" "$BASH_BIN" "$SCRIPT_PATH" ../handoff.md 2>&1)
  LAST_STATUS=$?
  LAST_CODEX_LOG=$(cat "$log_file")
  rm -rf "$temp_repo" "$stub_dir"

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: run this script from the repository root." || return
  assert_equals "$name" "$LAST_CODEX_LOG" "" || return

  pass "$name"
}

test_dirty_working_tree() {
  local name="dirty working tree exits non-zero"
  local temp_repo
  local stub_dir
  local log_file
  local stdin_file

  temp_repo=$(mktemp -d)
  stub_dir=$(mktemp -d)
  log_file="$stub_dir/codex.log"
  stdin_file="$stub_dir/stdin.txt"
  make_clean_repo "$temp_repo"
  make_codex_stub "$stub_dir/bin" "$log_file" "$stdin_file" 0
  write_committed_handoff "$temp_repo" "handoff.md"
  printf "dirty\n" > "$temp_repo/dirty-file.txt"

  LAST_OUTPUT=$(cd "$temp_repo" && PATH="$stub_dir/bin:$PATH" "$BASH_BIN" "$SCRIPT_PATH" handoff.md 2>&1)
  LAST_STATUS=$?
  LAST_CODEX_LOG=$(cat "$log_file")
  rm -rf "$temp_repo" "$stub_dir"

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: working tree is dirty." || return
  assert_equals "$name" "$LAST_CODEX_LOG" "" || return

  pass "$name"
}

test_invokes_codex_once_with_handoff_on_stdin
test_exits_with_codex_status
test_dry_run_prints_command_and_invokes_nothing
test_missing_path
test_missing_or_empty_file
test_empty_file
test_missing_codex
test_non_root_directory
test_dirty_working_tree

if [[ "$FAILURES" -ne 0 ]]; then
  echo
  echo "$FAILURES test(s) failed."
  exit 1
fi

echo
echo "All tests passed."
