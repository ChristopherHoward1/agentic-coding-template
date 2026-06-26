# AI Engineering Operating System

A framework for solo builders who work with AI agents using the discipline of a small, high-performing engineering team.

## Overview

This repository defines a collaboration model where one human and AI agents follow structured software engineering practices — planning, branching, code review, and retrospectives. The goal is process quality, maintainability, and learning, not maximum automation.

## How It Works

The system defines three roles:

- **Product Owner** (human) — sets priorities, makes product decisions, and owns the roadmap.
- **Staff Engineer** (AI agent) — provides technical leadership, plans work, reviews pull requests, and protects long-term maintainability.
- **Software Engineer** (AI coding agent) — implements issues, writes code, and submits pull requests for review. This role is agent-agnostic; use whichever AI coding tool fits your workflow.

Work follows a deliberate lifecycle: goal → planning → issue → feature branch → implementation → pull request → review → merge → retrospective. The workflow is intentionally designed to make engineering judgment explicit, reviewable, and repeatable.

## Getting Started

1. Clone this repository.
2. Open it in [Claude Code](https://claude.ai/claude-code).
3. Start a conversation — Claude reads `CLAUDE.md` on startup and operates as the Staff Engineer.
4. To assign implementation work, use your preferred AI coding agent scoped to a specific issue.

## Tests

Run the linter and bash test scripts from the repository root:

```bash
bash scripts/lint.sh
for t in tests/test-*.sh; do bash "$t"; done
```

The linter and this loop discover their targets from the filesystem, so they cover every script and test in the repo without a hardcoded list.

## Repository Structure

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Operating instructions for the Staff Engineer agent — role definition, workflow, principles, and standards. |
| `AGENTS.md` | Operating instructions for the Software Engineer agent — scope discipline, verification, and handoff format. |
| `PLAN.md` | Shared planning artifact — current objectives, risks, recommendations, and open decisions. |
| `scripts/new-issue.sh` | Interactive CLI to scaffold a new implementation issue from the standard template. |
| `scripts/new-handoff.sh` | Interactive CLI to create a feature branch and generate the standard implementation handoff. |
| `scripts/review-context.sh` | Read-only helper that assembles PR review context — metadata, linked issue and acceptance criteria, changed files, diff, and lint/test results — without making a review decision. |
| `scripts/trigger-agent.sh` | Hands a completed implementation handoff to the external coding agent (one-shot `codex exec` invocation). |
| `.github/ISSUE_TEMPLATE/implementation.md` | Issue template defining the standard structure for scoped implementation work. |

## Philosophy

Favor simple, reversible solutions. Prefer proven need over speculative infrastructure. Build process from experience, not speculation. See [CLAUDE.md](CLAUDE.md) for the full operating principles.

## License

TBD
