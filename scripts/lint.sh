#!/usr/bin/env bash
# Usage: bash scripts/lint.sh (run from repository root)
set -euo pipefail

if ! command -v shellcheck &>/dev/null; then
  echo "Error: shellcheck is not installed. Install it from https://www.shellcheck.net or your system package manager." >&2
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

shellcheck \
  scripts/lint.sh \
  scripts/new-issue.sh \
  scripts/new-handoff.sh \
  scripts/review-context.sh \
  tests/test-new-issue.sh \
  tests/test-new-handoff.sh \
  tests/test-review-context.sh
