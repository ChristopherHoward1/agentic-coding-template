# AI Engineering Operating Plan

## Project Vision

Build an AI-native engineering operating system that enables a solo builder to work with AI agents as if managing a disciplined, high-performing software engineering team.

The focus is on improving engineering process, maintainability, review quality, and learning—not maximizing automation.

This document is jointly maintained by the Product Owner and the Staff Engineer and should evolve throughout the project.

---

## Current Objective

Milestone 9 shipped (Issue #50, PR #51, reviewed APPROVE): `lint.sh` and `review-context.sh` now derive their script/test lists from the filesystem, closing the hardcoded-list root cause behind both PR #48 failures. The fix validated itself during its own review — running `review-context.sh` on PR #51 executed all four test files, including the two the old hardcoded list silently skipped. The same cycle also discharged Milestone 8's owed live-run validation: the `trigger-agent.sh` invocation that drove this implementation was a real `codex exec` run (Codex v0.139.0, clean stdin delivery, correct preflight, exit 0), so the trigger is no longer stub-only and the forward gate on any further triggering layer is now eligible to open. The leading candidate at the time has since shipped: the `new-handoff.sh` output fix (Issue #54, PR #55) moved git operations and diagnostics to stderr so stdout carries only the rendered handoff, making it cleanly pipeable into `trigger-agent.sh`. No milestone is currently active (see Active Milestone and Recommendations).

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

### Milestone 8: Manually Trigger the External Agent (Narrowest Slice) — Complete

`scripts/trigger-agent.sh` shipped (Issue #46, PR #48): it takes an existing handoff path plus a `--dry-run` flag, runs preflight (path given, file non-empty, run from repo root, codex installed, clean working tree), and invokes `codex exec --sandbox workspace-write - < "$handoff"` exactly once, exiting with Codex's status without parsing its output. Hermetic tests (stubbed codex, bash 3.2) cover stdin delivery, dry-run, each preflight failure, and status propagation. Review was REQUEST CHANGES then APPROVE: the first pass found AC #6 hollow because `lint.sh` excluded the new script and test; the revision wired both in via a commit scoped to `lint.sh` only. The previously-owed live validation is now discharged: the trigger drove the Milestone 9 implementation as a real `codex exec` run (Codex v0.139.0, clean stdin delivery, exit 0), confirming end-to-end behavior against a real binary rather than a stub. One known property surfaced: Codex's sandbox could not reach `api.github.com`, so the agent implemented/committed/pushed but could not open its own PR; the Staff Engineer filed it.

Observations carried forward from Milestone 6 (recorded only): unused `contains()` helper; untested zero-arg path; above-threshold diffs still fetch the full diff before `--stat`, with `gh pr diff` running up to three times; write-capable `gh` detection is a denylist.

### Milestone 9: Replace Hardcoded File Lists with Discovery — Complete

`scripts/lint.sh` and `scripts/review-context.sh` now derive their file lists from the filesystem (Issue #50, PR #51, reviewed APPROVE): `lint.sh` globs `scripts/*.sh` and `tests/test-*.sh`; `review-context.sh`'s verification keeps `run_check "lint"` and loops over discovered `tests/test-*.sh`. Both use `shopt -s nullglob` plus a guarded array-count check before expansion, avoiding the Milestone 5 `set -u`/empty-array regression on bash 3.2. The test runner matches `tests/test-*.sh` (not `tests/*.sh`), verified by a stub asserting non-test helpers are excluded; discovery is independent in each script (no shared helper). The fix validated itself in review — `review-context.sh` on PR #51 executed all four tests, including the two the old hardcoded list silently skipped — closing the root cause behind both PR #48 failures.

### Milestone 10: Clean `new-handoff.sh` Output — Complete

`scripts/new-handoff.sh` now writes its git operations (fetch/checkout/pull/push), dry-run notice, separators, and interactive prompts to stderr, so stdout carries only the rendered handoff (Issue #54, PR #55). This removes the manual-cleanup friction that recurred across the Milestone 8 and 9 trigger cycles, making the handoff cleanly pipeable into `trigger-agent.sh`; a test captures stdout and stderr separately to prove the split. The same cycle confirmed the second occurrence of the PR-ownership gap — the Codex agent implemented and pushed but its sandbox could not reach `api.github.com` — which subsequently justified codifying the manual fallback in CLAUDE.md (PR #56).

---

## Active Milestone

None active. Milestones 8, 9, and 10 are complete and Milestone 8's owed live-run validation is discharged. The next increment is under selection by the Product Owner.

With the `new-handoff.sh` output fix shipped (Milestone 10), no narrowest-mechanical increment is currently queued from observed friction. The next move is a Product Owner direction call on the gated frontier below.

Also now eligible (forward gate cleared by the live run): the open decision on how far to automate triggering beyond the one-shot — to be opened only when the Product Owner chooses, and still gated on demonstrated repeated need rather than opened automatically.

Deferred until separately justified: productization, and unifying `new-issue.sh`/`new-handoff.sh`. Explicitly out of scope until justified: agent orchestration, multi-agent communication infrastructure, retries/status polling, event-driven/GitHub Actions triggers, and skills or GitHub integrations beyond demonstrated need.

---

## Staff Engineer Recommendations

### Current Recommendation

The Product Owner has decided to accelerate toward automation and, eventually, productizing this framework for other projects. This replaces the prior blanket "no automation" stance — but the gating logic stays: automate only what has been demonstrated through repeated manual use, starting with the narrowest, most mechanical step first. The gate now also runs forward: shipped automation must demonstrate value in real use before the next layer (triggering, productization) is opened.

Milestones 6 through 10 are complete and Milestone 8's owed live-run validation is discharged. The bounded gate-override worked as intended end to end: the narrowest-slice trigger shipped, reviewing its PR with `review-context.sh` produced Milestone 7's validation, that review found the hardcoded-list defect (fixed in Milestone 9), and the Milestone 9 implementation was itself driven by the first live `trigger-agent.sh` run — discharging Milestone 8's validation as a byproduct. Each step continued to surface its own next increment from real use.

Recommended next step:

1. **No queued mechanical increment.** The `new-handoff.sh` output fix shipped (Milestone 10, Issue #54, PR #55) and the manual PR-ownership fallback is now codified (PR #56). No further narrowest-mechanical increment is currently motivated by observed repeated friction. The next move is a Product Owner direction call on the gated frontier — most immediately, whether to open the deferred triggering-automation decision below.

The forward gate on further triggering automation (event-wiring, status polling, looping) is now eligible to open, since the live run demonstrated the one-shot trigger's value — but it stays gated on demonstrated repeated need and opens only at the Product Owner's direction. Productization remains gated until separately justified.

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

- How far to automate triggering the external agent **beyond the narrowest manual slice** (e.g., GitHub Actions firing on issue creation, status polling, looping over issues) — the manual one-shot trigger shipped in Milestone 8 and is now validated by a live Codex run, so this decision is eligible to open; everything past the one-shot stays deferred until demonstrated repeated need justifies it.
- Whether to automate **trigger-side PR creation** — opening the PR automatically after a successful triggered run, in a wrapper around `trigger-agent.sh` (not inside it, to preserve the one-shot trigger's narrow contract). Feasible without touching the sandbox: the wrapper runs on the host, which already has `gh` auth and network, after `codex exec` exits and the branch is pushed. Role-safe: running under the Product Owner's host credentials keeps the PR author the Product Owner, not the Staff Engineer, so the author/reviewer separation holds — the cost is losing the human checkpoint before a PR exists. Design seam: the agent's PR body must become a readable artifact (the agent writes it to an agreed path via a handoff-format change) or be synthesized from the issue and commits. **Bar to open — gated by cost, not capability:** the manual `gh pr create` step recurs every run but is currently trivial (~10 seconds), so it is not yet justified. Open it when either (a) manual filing becomes demonstrated repeated friction (volume or error-proneness), or (b) the triggering layer moves toward looped/unattended runs, for which auto-PR is the prerequisite — a loop has no human present to file the PR. If built: hermetic tests, idempotency (no duplicate PR), success-gating (only on exit 0 with commits pushed), and loud degrade-to-manual on failure.
- What productization requires structurally (e.g., parameterizing CLAUDE.md/AGENTS.md, removing solo-builder-specific framing) — deferred until a reusability need is demonstrated rather than anticipated.
- Whether to unify `new-issue.sh` and `new-handoff.sh` into a single flow — open only if the metadata/file-list seam between them recurs as friction; not yet observed to repeat.
- When a triggered agent cannot open its own PR — **Resolved (manual fallback codified).** The sandbox-cannot-reach-`api.github.com` gap recurred on the next triggered run, clearing the two-occurrence proven-need bar, so the fallback is now procedure in CLAUDE.md (Implementation Handoff): the Product Owner files the PR from the agent's pushed branch using the agent's PR body, and the Staff Engineer reviews the diff on its merits. The filer is the Product Owner, not the Staff Engineer, preserving the author/reviewer separation. **Still open and gated:** whether this justifies building trigger-side PR automation is tracked as its own decision above; two occurrences justify codifying the manual fallback, not automating it.
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