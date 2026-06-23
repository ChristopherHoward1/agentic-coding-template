# AI Engineering Operating Plan

## Project Vision

Build an AI-native engineering operating system that enables a solo builder to work with AI agents as if managing a disciplined, high-performing software engineering team.

The focus is on improving engineering process, maintainability, review quality, and learning—not maximizing automation.

This document is jointly maintained by the Product Owner and the Staff Engineer and should evolve throughout the project.

---

## Current Objective

The read-only review-preparation helper shipped (`scripts/review-context.sh`, Issue #41, PR #43, reviewed APPROVE) and Milestone 7 opened to validate it through real use. The Product Owner has now decided to open the agent-triggering milestone (Milestone 8) immediately, deliberately overriding the forward gate that would otherwise require Milestone 7's validation to complete first. The override is bounded and does not skip validation: (a) the triggering slice is scoped to the smallest mechanical step — a single command that starts exactly one external agent run against an existing handoff — so the at-risk investment is small; and (b) Milestone 8 runs through the normal lifecycle, so its PR is reviewed with `scripts/review-context.sh`, producing Milestone 7's real-use validation as a byproduct rather than deferring it.

The Product Owner is accelerating toward automation and eventual productization of this framework. Each step is still justified by a demonstrated pattern and scoped to the narrowest mechanical increment; the forward gate remains the default, and this override is a deliberate, bounded exception — not its removal. See Staff Engineer Recommendations below.

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

### Milestone 6: Read-Only Review-Preparation Helper — Complete

`scripts/review-context.sh` shipped (Issue #41, PR #43): a read-only helper that assembles PR review context in one command — PR metadata/body, the linked issue and its acceptance criteria (resolved from a Closes/Fixes/Resolves reference), the changed-file list, the diff (or a stat summary above a size threshold), and the results of the repository's lint and test checks — without making or recording any review decision. The read-only boundary is enforced by a test that fails on any write-capable `gh` subcommand. The cycle dogfooded both Milestone 5 scripts (Issue #41 via `new-issue.sh`'s flags, the branch and handoff via `new-handoff.sh`'s flags) with no friction. Review was APPROVE: all acceptance criteria met, all four verification commands green under bash 3.2. Non-blocking observations were carried forward to the validation phase below.

---

## Active Milestone

### Milestone 8: Manually Trigger the External Agent (Narrowest Slice)

Objective: a single local invocation that takes an **existing** handoff (the artifact `scripts/new-handoff.sh` already produces) and starts **exactly one** external Software Engineer agent run against it. Nothing else.

This opens the triggering layer ahead of Milestone 7's validation completing — a deliberate, bounded gate-override by the Product Owner. It does not skip validation: the slice is the smallest mechanical step (small at-risk investment), and it runs through the normal lifecycle so its PR is reviewed with `scripts/review-context.sh`, producing Milestone 7's real-use validation as a byproduct. A local manual trigger is the first step; event-wiring (GitHub Actions) is deferred until the manual trigger demonstrates value, keeping this milestone on the same internal gate discipline every prior milestone followed.

Explicitly out of scope until separately justified: orchestration, multi-agent coordination, retries, status polling, parsing or acting on agent output, looping over issues, and event-driven/GitHub Actions triggers.

### Milestone 7: Validate the Review-Preparation Helper Through Use (satisfied via Milestone 8's review)

Objective unchanged: run `scripts/review-context.sh` against at least one real PR review and evaluate whether it materially reduces review-prep effort. Under the override above, this validation is now produced by reviewing Milestone 8's PR with the helper rather than by a standalone cycle. The next retrospective records whether it meaningfully reduced the manual review-prep sequence.

Observations carried forward (recorded only; none yet justifies a cleanup increment): unused `contains()` helper; untested zero-arg path; above-threshold diffs still fetch the full diff before `--stat`, with `gh pr diff` running up to three times; write-capable `gh` detection is a denylist.

Deferred until separately justified: productization, and unifying `new-issue.sh`/`new-handoff.sh`. Explicitly out of scope until justified: agent orchestration, multi-agent communication infrastructure, and skills or GitHub integrations beyond demonstrated need.

---

## Staff Engineer Recommendations

### Current Recommendation

The Product Owner has decided to accelerate toward automation and, eventually, productizing this framework for other projects. This replaces the prior blanket "no automation" stance — but the gating logic stays: automate only what has been demonstrated through repeated manual use, starting with the narrowest, most mechanical step first. The gate now also runs forward: shipped automation must demonstrate value in real use before the next layer (triggering, productization) is opened.

Milestone 6 is complete and Milestone 7's validation is underway. The Product Owner has chosen to open Milestone 8 (manual agent triggering) now under a bounded override of the forward gate. The Staff Engineer supports this: the slice is the narrowest mechanical step, the at-risk investment is small, and the override produces — rather than skips — the review-helper validation, because Milestone 8's PR is reviewed with `review-context.sh`.

Recommended next step: implement the narrowest manual trigger (one command → one agent run against an existing handoff), then let real use of it decide whether event-wiring or any further triggering layer is justified. Productization remains gated until separately justified.

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

- How far to automate triggering the external agent **beyond the narrowest manual slice** (e.g., GitHub Actions firing on issue creation, status polling, looping over issues) — the manual one-shot trigger is now active as Milestone 8; everything past it stays deferred until the manual trigger demonstrates value.
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