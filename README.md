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

Not every item ends in merged code. Uncertainty-reducing work — a benchmark, a recommendation, a validated or rejected hypothesis — moves through the same issue → branch → PR → review path, but records its outcome as a decision in PLAN.md or an issue comment rather than a new artifact.

Milestones can be decomposed into a dependency graph of issues. Independent issues — those with disjoint file footprints and no interface dependency — can run in parallel, while dependent work is serialized with explicit issue references. The implementation issue template includes an optional `## Dependencies` section for recording those edges.

## Project-Type Profiles

The base operating model in `CLAUDE.md` is domain-agnostic. A **project-type profile** supplements it with guidance for a class of work without overriding it — profiles compose with the base concerns and point back at the universal workflow rather than duplicating it. This keeps the core model general while letting a specific kind of project adopt conventions that only make sense for it.

The first profile, `profiles/applied-ai-data-science.md`, is in progress (`STATUS: PROVISIONAL`). It adds a Frame → Investigate → Implement → Operate lifecycle lens and evaluation conventions for applied AI and data-science work, and is being validated against real projects before it is considered stable.

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
| `profiles/applied-ai-data-science.md` | Project-type profile (provisional) supplementing the base model with conventions for applied AI and data-science work. |
| `scripts/new-issue.sh` | Interactive CLI to scaffold a new implementation issue from the standard template. |
| `scripts/new-handoff.sh` | Interactive CLI to create a feature branch and generate the standard implementation handoff. |
| `scripts/review-context.sh` | Read-only helper that assembles PR review context — metadata, linked issue and acceptance criteria, changed files, diff, and lint/test results — without making a review decision. |
| `scripts/trigger-agent.sh` | Hands a completed implementation handoff to the external coding agent (one-shot `codex exec` invocation). |
| `.github/ISSUE_TEMPLATE/implementation.md` | Issue template defining the standard structure for scoped implementation work. |
| `.github/PULL_REQUEST_TEMPLATE.md` | Pull request template prompting for the linked issue, a summary, partially-satisfied criteria, and risks or follow-ups. |

## Philosophy

Favor simple, reversible solutions. Prefer proven need over speculative infrastructure. Build process from experience, not speculation. See [CLAUDE.md](CLAUDE.md) for the full operating principles.

## License

TBD
