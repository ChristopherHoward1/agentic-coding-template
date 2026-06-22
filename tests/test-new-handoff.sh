#!/usr/bin/env bash
set -uo pipefail

FAILURES=0
LAST_OUTPUT=""
LAST_STATUS=0
BASH_BIN=${BASH:-/bin/bash}

make_gh_stub() {
  local dir="$1"

  mkdir -p "$dir"
  cat > "$dir/gh" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" != "issue" || "$2" != "view" ]]; then
  echo "unexpected gh command: $*" >&2
  exit 1
fi

if [[ "$4" != "--json" || "$5" != "number,title,url" ]]; then
  echo "unexpected gh metadata arguments: $*" >&2
  exit 1
fi

printf "25\nAdd scripts/new-handoff.sh to generate implementation handoffs\nhttps://github.com/example/repo/issues/25\n"
STUB
  chmod +x "$dir/gh"
}

run_script() {
  local input="$1"
  shift

  local stub_dir
  stub_dir=$(mktemp -d)
  make_gh_stub "$stub_dir"

  LAST_OUTPUT=$(printf "%b" "$input" | PATH="$stub_dir:$PATH" bash scripts/new-handoff.sh "$@" 2>&1)
  LAST_STATUS=$?
  rm -rf "$stub_dir"
}

contains() {
  local haystack="$1"
  local needle="$2"

  [[ "$haystack" == *"$needle"* ]]
}

handoff_output() {
  printf "%s" "$LAST_OUTPUT" | sed -n '/^## Implementation Handoff$/,$p'
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

  fail "$name" "output did not match expected handoff"
  return 1
}

test_dry_run_output() {
  local name="dry-run renders canonical handoff"
  local branch="feature/test-handoff-$$"
  local before_branch
  local after_branch
  local expected

  before_branch=$(git branch --show-current)

  run_script "25\n$branch\nscripts/new-handoff.sh\ntests/test-new-handoff.sh\n\nscripts/new-issue.sh\nCLAUDE.md\n\nFollow repository conventions.\nPreserve existing behavior.\n\nbash scripts/new-handoff.sh --dry-run\nbash tests/test-new-handoff.sh\n\nOpen as ready for review.\nInclude Closes #25.\n\n" --dry-run

  after_branch=$(git branch --show-current)
  expected=$(cat <<EOF
## Implementation Handoff

Issue: #25 - Add scripts/new-handoff.sh to generate implementation handoffs
Issue URL: https://github.com/example/repo/issues/25
Branch: $branch
Checkout confirmation: The repository is currently checked out on \`$branch\`.
Files to Modify:
- scripts/new-handoff.sh
- tests/test-new-handoff.sh
Files Not to Modify:
- scripts/new-issue.sh
- CLAUDE.md
Key Constraints:
- Follow repository conventions.
- Preserve existing behavior.
Acceptance Criteria:
- See Issue #25: https://github.com/example/repo/issues/25
Verification:
- bash scripts/new-handoff.sh --dry-run
- bash tests/test-new-handoff.sh
PR Expectations:
- Open as ready for review.
- Include Closes #25.
EOF
)

  assert_status "$name" 0 || return
  assert_equals "$name" "$(handoff_output)" "$expected" || return

  if [[ "$before_branch" != "$after_branch" ]]; then
    fail "$name" "dry-run changed branch from $before_branch to $after_branch"
    return
  fi

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    fail "$name" "dry-run created branch $branch"
    return
  fi

  pass "$name"
}

test_noninteractive_dry_run_output_parity() {
  local name="non-interactive dry-run output matches interactive output"
  local branch="feature/test-handoff-parity-$$"
  local interactive_handoff
  local noninteractive_handoff

  run_script "25\n$branch\nscripts/new-handoff.sh\ntests/test-new-handoff.sh\n\nscripts/new-issue.sh\nCLAUDE.md\n\nFollow repository conventions.\nPreserve existing behavior.\n\nbash scripts/new-handoff.sh --dry-run\nbash tests/test-new-handoff.sh\n\nOpen as ready for review.\nInclude Closes #25.\n\n" --dry-run
  assert_status "$name" 0 || return
  interactive_handoff=$(handoff_output)

  run_script "" \
    --dry-run \
    --issue 25 \
    --branch "$branch" \
    --file-to-modify "scripts/new-handoff.sh" \
    --file-to-modify "tests/test-new-handoff.sh" \
    --file-not-to-modify "scripts/new-issue.sh" \
    --file-not-to-modify "CLAUDE.md" \
    --constraint "Follow repository conventions." \
    --constraint "Preserve existing behavior." \
    --verify "bash scripts/new-handoff.sh --dry-run" \
    --verify "bash tests/test-new-handoff.sh" \
    --pr-expectation "Open as ready for review." \
    --pr-expectation "Include Closes #25."
  assert_status "$name" 0 || return
  assert_output_not_contains "$name" "Issue number:" || return
  assert_output_not_contains "$name" "Files to modify" || return
  noninteractive_handoff=$(handoff_output)

  assert_equals "$name" "$noninteractive_handoff" "$interactive_handoff" || return

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    fail "$name" "dry-run created branch $branch"
    return
  fi

  pass "$name"
}

test_noninteractive_missing_required_field() {
  local name="non-interactive missing required field exits non-zero"

  LAST_OUTPUT=$("$BASH_BIN" scripts/new-handoff.sh \
    --dry-run \
    --issue 25 \
    --file-to-modify "scripts/new-handoff.sh" \
    --file-not-to-modify "scripts/new-issue.sh" \
    --constraint "Follow repository conventions." \
    --verify "bash tests/test-new-handoff.sh" \
    --pr-expectation "Open as ready for review." 2>&1)
  LAST_STATUS=$?

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: branch is required." || return
  assert_output_not_contains "$name" "gh CLI is not installed" || return
  assert_output_not_contains "$name" "Issue number:" || return

  pass "$name"
}

test_noninteractive_list_values_preserved() {
  local name="non-interactive list values preserve spaces and punctuation"

  run_script "" \
    --dry-run \
    --issue 25 \
    --branch "feature/test-handoff-lists-$$" \
    --file-to-modify "scripts/new-handoff.sh (flag mode)" \
    --file-not-to-modify "scripts/new-issue.sh: leave untouched" \
    --constraint "Preserve spaces, commas, semicolons; and punctuation!" \
    --verify "bash tests/test-new-handoff.sh -- value with spaces" \
    --pr-expectation "Mention --push / --no-push behavior."

  assert_status "$name" 0 || return
  assert_output_contains "$name" "- scripts/new-handoff.sh (flag mode)" || return
  assert_output_contains "$name" "- scripts/new-issue.sh: leave untouched" || return
  assert_output_contains "$name" "- Preserve spaces, commas, semicolons; and punctuation!" || return
  assert_output_contains "$name" "- bash tests/test-new-handoff.sh -- value with spaces" || return
  assert_output_contains "$name" "- Mention --push / --no-push behavior." || return

  pass "$name"
}

test_push_conflict() {
  local name="push conflict exits non-zero"

  LAST_OUTPUT=$("$BASH_BIN" scripts/new-handoff.sh --push --no-push 2>&1)
  LAST_STATUS=$?

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: --push and --no-push cannot both be supplied." || return

  pass "$name"
}

test_missing_gh() {
  local name="missing gh exits non-zero"
  local empty_path

  empty_path=$(mktemp -d)
  LAST_OUTPUT=$(PATH="$empty_path" "$BASH_BIN" scripts/new-handoff.sh --dry-run 2>&1)
  LAST_STATUS=$?
  rm -rf "$empty_path"

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: gh CLI is not installed." || return

  pass "$name"
}

test_non_root_directory() {
  local name="non-root directory exits non-zero"
  local stub_dir

  stub_dir=$(mktemp -d)
  make_gh_stub "$stub_dir"

  LAST_OUTPUT=$(cd scripts && PATH="$stub_dir:$PATH" bash ../scripts/new-handoff.sh --dry-run 2>&1)
  LAST_STATUS=$?
  rm -rf "$stub_dir"

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: run this script from the repository root." || return

  pass "$name"
}

test_dirty_working_tree() {
  local name="dirty working tree exits non-zero"
  local temp_repo
  local script_path
  local stub_dir

  temp_repo=$(mktemp -d)
  script_path="$(pwd)/scripts/new-handoff.sh"
  stub_dir=$(mktemp -d)
  make_gh_stub "$stub_dir"

  (
    cd "$temp_repo" || exit 1
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    printf "" > CLAUDE.md
    printf "" > AGENTS.md
    git add CLAUDE.md AGENTS.md
    git commit -q -m "Initial commit"
    printf "dirty\n" > dirty-file.txt
  )

  LAST_OUTPUT=$(cd "$temp_repo" && PATH="$stub_dir:$PATH" bash "$script_path" 2>&1)
  LAST_STATUS=$?

  rm -rf "$temp_repo" "$stub_dir"

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: working tree is dirty." || return

  pass "$name"
}

test_pre_existing_branch() {
  local name="pre-existing branch exits non-zero"
  local temp_repo
  local script_path
  local stub_dir

  temp_repo=$(mktemp -d)
  script_path="$(pwd)/scripts/new-handoff.sh"
  stub_dir=$(mktemp -d)
  make_gh_stub "$stub_dir"

  (
    cd "$temp_repo" || exit 1
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    printf "" > CLAUDE.md
    printf "" > AGENTS.md
    git add CLAUDE.md AGENTS.md
    git commit -q -m "Initial commit"
    git branch feature/existing
  )

  LAST_OUTPUT=$(cd "$temp_repo" && printf "25\nfeature/existing\n" | PATH="$stub_dir:$PATH" bash "$script_path" 2>&1)
  LAST_STATUS=$?

  rm -rf "$temp_repo" "$stub_dir"

  assert_nonzero_status "$name" || return
  assert_output_contains "$name" "Error: branch already exists: feature/existing" || return

  pass "$name"
}

test_dry_run_output
test_noninteractive_dry_run_output_parity
test_noninteractive_missing_required_field
test_noninteractive_list_values_preserved
test_push_conflict
test_missing_gh
test_non_root_directory
test_dirty_working_tree
test_pre_existing_branch

if [[ "$FAILURES" -ne 0 ]]; then
  echo
  echo "$FAILURES test(s) failed."
  exit 1
fi

echo
echo "All tests passed."
