# AI Engineering Operating Plan

## Project Vision

Build an AI-native engineering operating system that enables a solo builder to work with AI agents as if managing a disciplined, high-performing software engineering team.

The focus is on improving engineering process, maintainability, review quality, and learning—not maximizing automation.

This document is jointly maintained by the Product Owner and the Staff Engineer and should evolve throughout the project.

---

## Current Objective

Reduce the agent-driving friction in the now-validated issue/branch/handoff automation by adding a non-interactive input mode to the handoff scripts, so an agent can drive them without hand-built piped stdin.

The issue/branch/handoff automation has been validated across two real cycles (Milestone 4). The Product Owner has decided to accelerate toward automation and eventual productization of this framework, but each step must still be justified by a pattern demonstrated through repeated use. The interactive-script friction has now recurred across cycles, justifying this increment. Triggering and productization remain deferred until the validated automation's known frictions are addressed. See Staff Engineer Recommendations below.

---

## Completed Milestones

### Milestone 1: Foundation — Complete

Core repository artifacts shipped: CLAUDE.md, PLAN.md, AGENTS.md, README.md, issue and PR templates, `scripts/new-issue.sh`. The Staff Engineer / Product Owner collaboration model is established and the planning process is repeatable across sessions.

### Milestone 2: External Agent Validation — Complete

The manual handoff process was validated across two implementation cycles. External agents completed scoped issues without clarification requests. Git ownership boundaries, scope discipline, and handoff quality all held. The implementation handoff has emerged as a first-class workflow artifact.

### Milestone 3: Targeted Automation of Issue/Branch/Handoff Creation — Complete

The handoff format was formalized in CLAUDE.md (Issues #21/#25, PRs #22/#24). `scripts/new-handoff.sh` (Issue #25, PR #26) now creates and pushes the feature branch and renders the canonical handoff from issue metadata, composing with the existing `scripts/new-issue.sh`. The review cycle caught and corrected a non-hermetic test before merge.

### Milestone 4: Validate the Automation Through Use — Complete

The issue/branch/handoff automation was validated across two real cycles: ShellCheck linting (Issue #28, PR #29) and the dirty-tree fix (Issue #31, PR #32). In both, the external agent implemented the scoped issue with no clarification requests and the resulting PR matched the handoff. The cycle also surfaced and resolved a self-referential friction: `.claude/settings.local.json` was git-tracked and rewritten by the Claude Code harness on every permission grant, dirtying the tree and blocking `new-handoff.sh`; it is now untracked and gitignored (PR #32). The metadata/file-list duplication and verification-prerequisite frictions noted after cycle 1 did not recur. One friction did recur without being resolved — driving the interactive scripts requires hand-built piped stdin — and is carried forward as the next increment.

---

## Active Milestone

### Milestone 5: Non-Interactive Input for the Handoff Scripts

Scope: add a non-interactive input mode to `scripts/new-handoff.sh` (and `scripts/new-issue.sh` if the same friction applies) so an agent can supply all fields without driving sequential interactive prompts via hand-built piped stdin.

Justification: the interactive-script friction recurred across both Milestone 4 cycles (cycle 1 with #28, cycle 2 with #31), clearing the project's gating bar — an automation step is opened only by a pattern demonstrated through repeated use.

Explicitly out of scope until separately justified:

- Unifying `new-issue.sh` and `new-handoff.sh` into a single flow (the metadata/file-list duplication friction has not yet recurred).
- Triggering the external agent automatically.
- Productizing the framework.

Design note: prefer the simplest mechanism that removes the friction (e.g., flags or a structured input file) over a redesign of the scripts. Keep the interactive mode working unless evidence shows it is unused.

---

## Staff Engineer Recommendations

### Current Recommendation

The Product Owner has decided to accelerate toward automation and, eventually, productizing this framework for other projects. This replaces the prior blanket "no automation" stance — but the gating logic stays: automate only what has been demonstrated through repeated manual use, starting with the narrowest, most mechanical step first. The gate now also runs forward: shipped automation must demonstrate value in real use before the next layer (triggering, productization) is opened.

Recommended next increment: add a non-interactive input mode to the handoff scripts (Milestone 5). Driving `new-issue.sh` and `new-handoff.sh` currently requires hand-built piped stdin against sequential interactive prompts; this friction recurred across both Milestone 4 cycles, clearing the gating bar. Prefer the narrowest mechanism (flags or a structured input file) that lets an agent supply all fields at once, without unifying or redesigning the scripts.

The prior dirty-tree friction in the handoff flow has been resolved: `.claude/settings.local.json` is now untracked and gitignored (Issue #31, PR #32), so routine permission grants no longer dirty the tree or block `new-handoff.sh`.

Do not build, until each is separately justified by its own repeated manual pattern:

- Agent orchestration
- Multi-agent communication infrastructure
- Automatic triggering of the external agent
- Skills or GitHub integrations beyond the Milestone 3 target

### Reasoning

The operating model should emerge from experience rather than speculation, even on an accelerated timeline. Compressing the validation phase is acceptable; skipping it is not — automation targets must still be chosen from patterns that have actually repeated, not from what seems generically useful.

Premature infrastructure increases maintenance burden without validating that it solves a real problem.

---

## Open Decisions

Items requiring future discussion:

- When to automate triggering the external agent (e.g., GitHub Actions firing on issue creation) — deferred until the validated automation's known frictions are addressed (Milestone 5).
- What productization requires structurally (e.g., parameterizing CLAUDE.md/AGENTS.md, removing solo-builder-specific framing) — deferred while the validated automation's frictions are addressed (Milestone 5).
- Whether to unify `new-issue.sh` and `new-handoff.sh` into a single flow — open only if the metadata/file-list seam between them recurs as friction; not yet observed to repeat.
- Repository template structure beyond MVP.
- Introduction of reusable skills.
- Additional persistent documentation.
- Cross-agent orchestration.

These should remain deferred until supported by practical experience.

---

## Risks

### Over-engineering

The largest risk is building infrastructure before validating process. This risk increases under the Product Owner's decision to accelerate toward automation and productization.

Mitigation:

Gate every automation step on a pattern that has actually repeated in manual use — not on convenience or speculation. Revisit this gate explicitly at the start of each new milestone.

### Documentation Sprawl

Excess markdown files create maintenance overhead and competing sources of truth.

Mitigation:

Prefer updating existing artifacts and using GitHub Issues and Pull Requests for transient information.

### Vendor Lock-in

Avoid coupling organizational concepts to specific AI providers.

Mitigation:

Describe responsibilities in terms of roles (e.g., Staff Engineer, Software Engineer) rather than model names whenever practical.

---

## Planning Rules

This document should remain concise and actionable.

It should capture:

- Strategic direction
- Current priorities
- Engineering recommendations
- Active risks
- Major open questions

It should not duplicate:

- GitHub Issues
- Pull Request descriptions
- Implementation details
- Change logs
- Long task lists

When priorities change, update this document rather than creating a new planning artifact.