#!/usr/bin/env bash
set -uo pipefail

FAILURES=0
LAST_OUTPUT=""
LAST_STATUS=0
BASH_BIN=${BASH:-/bin/bash}
SCRIPT_PATH="$(pwd -P)/scripts/lint.sh"

make_shellcheck_stub() {
  local dir="$1"
  local status="$2"

  mkdir -p "$dir"
  cat > "$dir/shellcheck" <<EOF
#!/usr/bin/env bash
printf "%s\n" "\$@" > "\$SHELLCHECK_STUB_LOG"
exit $status
EOF
  chmod +x "$dir/shellcheck"
}

make_repo() {
  local dir="$1"

  mkdir -p "$dir/scripts" "$dir/tests"
  (
    cd "$dir" || exit 1
    git init -q
    touch CLAUDE.md AGENTS.md
    touch scripts/lint.sh scripts/new-issue.sh tests/test-lint.sh tests/test-new-issue.sh
  )
}

run_lint() {
  local shellcheck_status="$1"
  local temp_repo
  local stub_dir
  local log_file

  temp_repo=$(mktemp -d)
  stub_dir=$(mktemp -d)
  log_file="$stub_dir/shellcheck.log"
  make_repo "$temp_repo"
  make_shellcheck_stub "$stub_dir/bin" "$shellcheck_status"
  : > "$log_file"

  LAST_OUTPUT=$(cd "$temp_repo" && SHELLCHECK_STUB_LOG="$log_file" PATH="$stub_dir/bin:$PATH" "$BASH_BIN" "$SCRIPT_PATH" 2>&1)
  LAST_STATUS=$?

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

assert_output_not_contains() {
  local name="$1"
  local unexpected="$2"

  if ! contains "$LAST_OUTPUT" "$unexpected"; then
    return 0
  fi

  fail "$name" "expected output not to contain: $unexpected"
  return 1
}

test_success_output_reports_scope_and_files() {
  local name="success output reports shell-only scope and checked files"

  run_lint 0

  assert_status "$name" 0 || return
  assert_output_contains "$name" "Lint scope: shell files only (scripts/*.sh and tests/test-*.sh)." || return
  assert_output_contains "$name" "Checked files:" || return
  assert_output_contains "$name" "- scripts/lint.sh" || return
  assert_output_contains "$name" "- scripts/new-issue.sh" || return
  assert_output_contains "$name" "- tests/test-lint.sh" || return
  assert_output_contains "$name" "- tests/test-new-issue.sh" || return

  pass "$name"
}

test_shellcheck_failure_exits_nonzero() {
  local name="shellcheck failure exits non-zero"

  run_lint 12

  assert_nonzero_status "$name" || return
  assert_output_not_contains "$name" "Checked files:" || return

  pass "$name"
}

test_success_output_reports_scope_and_files
test_shellcheck_failure_exits_nonzero

if [[ "$FAILURES" -ne 0 ]]; then
  echo
  echo "$FAILURES test(s) failed."
  exit 1
fi

echo
echo "All tests passed."
