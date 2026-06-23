# AI Engineering Operating Plan

## Project Vision

Build an AI-native engineering operating system that enables a solo builder to work with AI agents as if managing a disciplined, high-performing software engineering team.

The focus is on improving engineering process, maintainability, review quality, and learning—not maximizing automation.

This document is jointly maintained by the Product Owner and the Staff Engineer and should evolve throughout the project.

---

## Current Objective

The issue/branch/handoff automation is now feature-complete. Non-interactive flag mode ships on both scripts (`new-handoff.sh`, PR #35; `new-issue.sh`, PR #37), and the one robustness bug real use exposed — the empty-list `set -u` crash — is fixed (PR #40). Both scripts' flag modes have been validated in a real cycle: Issue #39 and its handoff were created through them. Milestone 6 is now selected: a read-only review-preparation helper (Issue #41), chosen on observed workflow evidence — the Staff Engineer reassembles the same review context by hand every cycle — rather than speculative automation.

The Product Owner has decided to accelerate toward automation and eventual productization of this framework, but each step must still be justified by a pattern demonstrated through repeated use. With the automation loop's known frictions now resolved, the next increment is selected by expected value among evidence-backed candidates; triggering and productization remain gated until their cost is justified. See Staff Engineer Recommendations below.

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

### Milestone 5: Non-Interactive Input for the Handoff Scripts — Complete

Non-interactive flag mode shipped on both scripts — `new-handoff.sh` (Issue #34, PR #35) and `new-issue.sh` (Issue #36, PR #37) — removing the hand-built piped-stdin friction that recurred across both Milestone 4 cycles. Real use of the flag mode immediately exposed a latent robustness bug: rendering an issue or handoff with empty in-scope/out-of-scope lists aborted under `set -u` on bash 3.2 (`IN_SCOPE[@]: unbound variable`). It was fixed narrowly by guarding the empty-array render loops (Issue #39, PR #40); `new-handoff.sh` was confirmed already safe because validation requires its lists non-empty before the renderer is reached. Both scripts' flag modes were validated in a real cycle: Issue #39 was created through `new-issue.sh`'s flags and its handoff through `new-handoff.sh`'s flags.

---

## Active Milestone

### Milestone 6: Read-Only Review-Preparation Helper

Scope: add a read-only `scripts/review-context.sh` that assembles the context a Staff Engineer needs to review a pull request — the linked issue, the PR diff and changed-file list, and the repository's lint/test results — without making or recording any review decision (Issue #41).

Justification: reassembling review context by hand (reading the issue, fetching the PR and diff, running lint/tests) has repeated identically in every review cycle to date. It is the narrowest, most mechanical remaining step, is read-only, composes with the existing `gh`, lint, and test commands, and carries near-zero infrastructure cost — the best expected value among evidence-backed candidates. This clears the project's gate: automate only a pattern demonstrated through repeated manual use.

Scope boundary: the helper gathers and prints; it must not emit a verdict, post a comment, approve, merge, or otherwise write to GitHub or mutate git state. Keep it read-only and composing; do not let it expand into orchestration.

Candidates considered and deferred:

- Automatic triggering of the external agent — the largest raw recurring friction, but the highest infrastructure cost; remains gated until its cost is separately justified.
- Productization of the framework — deferred until a reusability need is demonstrated.

Explicitly out of scope until separately justified: agent orchestration, multi-agent communication infrastructure, and skills or GitHub integrations beyond demonstrated need.

---

## Staff Engineer Recommendations

### Current Recommendation

The Product Owner has decided to accelerate toward automation and, eventually, productizing this framework for other projects. This replaces the prior blanket "no automation" stance — but the gating logic stays: automate only what has been demonstrated through repeated manual use, starting with the narrowest, most mechanical step first. The gate now also runs forward: shipped automation must demonstrate value in real use before the next layer (triggering, productization) is opened.

Milestone 5 is complete: flag mode shipped on both scripts (PRs #35, #37), the empty-list `set -u` crash is fixed (PR #40), and both flag modes are validated in real use (Issue #39 and its handoff).

Recommended next increment: a read-only review-preparation helper. A normal feature cycle's largest remaining recurring human-orchestration steps are (a) carrying the rendered handoff to the external agent and (b) reassembling review context — reading CLAUDE.md/AGENTS.md/PLAN.md, fetching the issue and PR diff, and running lint/tests — by hand at the start of every review. Step (a) is the largest raw friction but the most expensive to automate (it is the triggering/orchestration layer the gate defers). Step (b) has repeated identically in every review to date, is read-only, composes with the existing `gh`, lint, and test commands, and carries near-zero infrastructure cost — the best expected value among evidence-backed candidates. It is the narrowest, most mechanical next step, consistent with the gating rule. Keep it read-only and composing; do not let it expand into orchestration.

Triggering the external agent and productization remain gated until their cost is separately justified by a demonstrated pattern.

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

- When to automate triggering the external agent (e.g., GitHub Actions firing on issue creation) — the automation loop's known frictions are now resolved (Milestone 5 complete), but triggering remains deferred behind lower-cost, higher-value increments until its infrastructure cost is justified.
- What productization requires structurally (e.g., parameterizing CLAUDE.md/AGENTS.md, removing solo-builder-specific framing) — deferred until a reusability need is demonstrated rather than anticipated.
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