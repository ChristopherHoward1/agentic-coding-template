# AI Engineering Operating Plan

## Project Vision

Build an AI-native engineering operating system that enables a solo builder to work with AI agents as if managing a disciplined, high-performing software engineering team.

The focus is on improving engineering process, maintainability, review quality, and learning—not maximizing automation.

This document is jointly maintained by the Product Owner and the Staff Engineer and should evolve throughout the project.

---

## Current Objective

Milestone 8 shipped (`scripts/trigger-agent.sh`, Issue #46, PR #48, reviewed REQUEST CHANGES then APPROVE): a single local command that starts exactly one headless Codex run against an existing handoff. Reviewing PR #48 with `scripts/review-context.sh` produced Milestone 7's real-use validation as planned — the helper materially reduced review-prep effort, while the same review exposed a recurring defect: the hardcoded shellcheck list in `lint.sh` and the hardcoded test list in `review-context.sh` both silently exclude newly added files. The Product Owner has promoted that root cause to the next increment (Milestone 9: replace the hardcoded lists with discovery). Two items remain owed: firing one live Codex run to validate the trigger end-to-end (Milestone 8's own real-use validation), and the Milestone 9 maintainability fix.

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

### Milestone 7: Validate the Review-Preparation Helper Through Use — Complete

`scripts/review-context.sh` was exercised on a real review — PR #48's initial review and re-review. It materially reduced review-prep effort: one command assembled the PR metadata/body, the linked issue and its acceptance criteria, the changed-file list, the diff, and lint/test results, replacing the manual multi-step gather. The same cycle exposed a real limitation: the helper's test runner uses a hardcoded script list, so it silently never ran the PR's new `tests/test-trigger-agent.sh` while still reporting "All tests passed" — false confidence on exactly the new code under review. The reviewer caught it only by running the test manually. The identical hardcoded-list pattern in `lint.sh` had already forced PR #48 to be hand-patched to honor AC #6. Both are the same root cause, now promoted to Milestone 9.

### Milestone 8: Manually Trigger the External Agent (Narrowest Slice) — Implementation Complete; live validation owed

`scripts/trigger-agent.sh` shipped (Issue #46, PR #48): it takes an existing handoff path plus a `--dry-run` flag, runs preflight (path given, file non-empty, run from repo root, codex installed, clean working tree), and invokes `codex exec --sandbox workspace-write - < "$handoff"` exactly once, exiting with Codex's status without parsing its output. Hermetic tests (stubbed codex, bash 3.2) cover stdin delivery, dry-run, each preflight failure, and status propagation. Review was REQUEST CHANGES then APPROVE: the first pass found AC #6 hollow because `lint.sh` excluded the new script and test; the revision wired both in via a commit scoped to `lint.sh` only. One validation remains **owed**: the script has only ever run against a stubbed codex — a single live Codex run against a real handoff is still required to confirm end-to-end behavior before any further triggering layer is justified.

Observations carried forward from Milestone 6 (recorded only; folded into Milestone 9 where relevant): unused `contains()` helper; untested zero-arg path; above-threshold diffs still fetch the full diff before `--stat`, with `gh pr diff` running up to three times; write-capable `gh` detection is a denylist.

---

## Active Milestone

### Milestone 9: Replace Hardcoded File Lists with Discovery

Objective: replace the hand-maintained shellcheck list in `scripts/lint.sh` and the hand-maintained test list in `scripts/review-context.sh` with discovery (e.g., globbing `scripts/*.sh` and `tests/test-*.sh`), so newly added scripts and tests are linted and run automatically. This is the promoted root cause behind two observed failures in the Milestone 8 cycle: AC #6 was hollow until `lint.sh` was hand-patched, and `review-context.sh` silently skipped the new test while still reporting success. It is a maintainability fix to existing automation rather than a new automation layer, so it is **not** gated behind Milestone 8's live-run validation.

Out of scope: changing what lint or the test runner do beyond which files they cover; any new triggering, orchestration, or productization capability.

Carried forward (owed, independent of Milestone 9): one live Codex run via `scripts/trigger-agent.sh` against a real handoff, to validate Milestone 8 end-to-end and to decide whether event-wiring is justified.

Deferred until separately justified: productization, and unifying `new-issue.sh`/`new-handoff.sh`. Explicitly out of scope until justified: agent orchestration, multi-agent communication infrastructure, retries/status polling, event-driven/GitHub Actions triggers, and skills or GitHub integrations beyond demonstrated need.

---

## Staff Engineer Recommendations

### Current Recommendation

The Product Owner has decided to accelerate toward automation and, eventually, productizing this framework for other projects. This replaces the prior blanket "no automation" stance — but the gating logic stays: automate only what has been demonstrated through repeated manual use, starting with the narrowest, most mechanical step first. The gate now also runs forward: shipped automation must demonstrate value in real use before the next layer (triggering, productization) is opened.

Milestones 6, 7, and 8 are complete. The bounded gate-override worked as intended: Milestone 8's narrowest-slice trigger shipped, and reviewing its PR with `review-context.sh` produced Milestone 7's validation rather than skipping it. That review also did what real use is supposed to do — it found a concrete defect (hardcoded file lists in `lint.sh` and `review-context.sh` that silently exclude new files), which is now Milestone 9.

Recommended next steps, in order:

1. **Milestone 9** — replace the hardcoded shellcheck and test lists with discovery. Small, mechanical, and directly motivated by two observed failures; it is a fix to existing automation, not a new layer, so it proceeds now.
2. **Fire the owed live Codex run** through `scripts/trigger-agent.sh` against a real handoff. Until this happens, Milestone 8 is validated only against a stub. This run is the forward gate for any further triggering layer (event-wiring, status polling, looping), all of which stay deferred until the live trigger demonstrates value.

Productization remains gated until separately justified.

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

- How far to automate triggering the external agent **beyond the narrowest manual slice** (e.g., GitHub Actions firing on issue creation, status polling, looping over issues) — the manual one-shot trigger shipped in Milestone 8; everything past it stays deferred until a live Codex run demonstrates the trigger's value.
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