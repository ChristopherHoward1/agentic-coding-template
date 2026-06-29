# AI Engineering Operating Plan

## Project Vision

Build an AI-native engineering operating system that enables a solo builder to work with AI agents as if managing a disciplined, high-performing software engineering team.

The focus is on improving engineering process, maintainability, review quality, and learning—not maximizing automation.

This document is jointly maintained by the Product Owner and the Staff Engineer and should evolve throughout the project.

---

## Current Objective

Milestone 11 is active: adopt **parallel dependency-graph decomposition** as the planning foundation — a convention, not a tool (see Active Milestone). With that foundation in place, the Product Owner has set a deliberate acceleration path toward autonomous implementation, sequenced as three increments and dogfooded as a dependency graph (see Acceleration Roadmap).

This is a direction shift. Through Milestone 10 every automation step was gated on demonstrated repeated friction. The three acceleration increments are explicitly **not** friction-justified — they are Product Owner acceleration overrides, justified prospectively by the throughput that parallel decomposition is expected to unlock. The friction gate still governs everything outside this named roadmap; the override is bounded to it, not a removal of the gate.

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

Observations carried forward from Milestone 6 (recorded only): ~~unused `contains()` helper~~ (removed in Issue #60 / PR #61 as a workflow-exercise dogfood, not an earned increment); untested zero-arg path; above-threshold diffs still fetch the full diff before `--stat`, with `gh pr diff` running up to three times; write-capable `gh` detection is a denylist. Three observations remain recorded-only.

### Milestone 9: Replace Hardcoded File Lists with Discovery — Complete

`scripts/lint.sh` and `scripts/review-context.sh` now derive their file lists from the filesystem (Issue #50, PR #51, reviewed APPROVE): `lint.sh` globs `scripts/*.sh` and `tests/test-*.sh`; `review-context.sh`'s verification keeps `run_check "lint"` and loops over discovered `tests/test-*.sh`. Both use `shopt -s nullglob` plus a guarded array-count check before expansion, avoiding the Milestone 5 `set -u`/empty-array regression on bash 3.2. The test runner matches `tests/test-*.sh` (not `tests/*.sh`), verified by a stub asserting non-test helpers are excluded; discovery is independent in each script (no shared helper). The fix validated itself in review — `review-context.sh` on PR #51 executed all four tests, including the two the old hardcoded list silently skipped — closing the root cause behind both PR #48 failures.

### Milestone 10: Clean `new-handoff.sh` Output — Complete

`scripts/new-handoff.sh` now writes its git operations (fetch/checkout/pull/push), dry-run notice, separators, and interactive prompts to stderr, so stdout carries only the rendered handoff (Issue #54, PR #55). This removes the manual-cleanup friction that recurred across the Milestone 8 and 9 trigger cycles, making the handoff cleanly pipeable into `trigger-agent.sh`; a test captures stdout and stderr separately to prove the split. The same cycle confirmed the second occurrence of the PR-ownership gap — the Codex agent implemented and pushed but its sandbox could not reach `api.github.com` — which subsequently justified codifying the manual fallback in CLAUDE.md (PR #56).

### Milestone 11: Adopt Parallel Dependency-Graph Decomposition — Complete

The parallel-decomposition convention shipped (Issue #65, PR #66, reviewed APPROVE): CLAUDE.md's Planning Expectations now documents recording dependency edges via native GitHub issue references, per-issue file-footprint declaration, a pre-dispatch pairwise disjointness check, the two-part parallel-eligibility rule (disjoint footprint AND no interface dependency, else serialize via an edge), and reading live run-state from `gh issue list`/`gh pr list` with the graph recorded in a milestone tracking issue, not PLAN.md. The issue template gained an optional `## Dependencies` section. It is a convention, not infrastructure — no new script — and the discovery-based lint/test runners stayed green. The cycle dogfooded the full lifecycle end to end (planning PR → `new-issue.sh`/`new-handoff.sh` flag modes → live `trigger-agent.sh` run → `review-context.sh` review → merge); the agent held scope exactly and the review was a clean first-pass APPROVE.

### Milestone 12: Validate Decomposition Under Real Parallelism — Complete

The decomposition convention was exercised on its first genuinely parallel batch (tracking issue #70): two file-disjoint issues — #68 (README.md, PR #71) and #69 (AGENTS.md, PR #72) — were dispatched to two `codex` agents running **concurrently in isolated clones**, then both merged to `main`. The convention's core claim held: each agent stayed within its declared footprint under true concurrency (neither touched the other's file, aided by listing the concurrent issue's file under `Files Not to Modify`), and the two disjoint branches merged with no conflict (#72 was `MERGEABLE CLEAN` against the post-#71 `main`). This discharges Milestone 11's owed validation. **Measured-N:** the manual PR filings were trivial (~seconds each), so the parallel amplification of PR-filing cost is real but small per occurrence — see the recalibrated Increment 1 rationale. Two infrastructure findings surfaced (recorded under Open Decisions): `trigger-agent.sh` is worktree-incompatible, and `new-issue.sh`'s renderer omits the issue template's `## Dependencies` section.

---

## Active Milestone

### Increment 1: Auto-Open the PR After the Agent Pushes — Active

The first Acceleration Roadmap increment and a Product Owner acceleration override (see the Acceleration Roadmap for the full rationale and build constraints): a host-side wrapper around `trigger-agent.sh` that opens the PR after a successful triggered run. Milestone 12 discharged the validation gate (decomposition works under real parallelism) but also **recalibrated the justification**: measured per-PR filing cost is trivial (~seconds), so the case for Increment 1 rests not on N×10s but on the **unattended/looped** scenario, where no human is present to file the PR at all (the Increment 3 prerequisite). Not yet started. When built: a wrapper (not inside the trigger), PR-body as a readable artifact, hermetic tests, idempotency (no duplicate PR), success-gating (exit 0 + commits pushed), and loud degrade-to-manual.

Deferred until separately justified: productization, and unifying `new-issue.sh`/`new-handoff.sh`. Explicitly out of scope until justified: agent orchestration, multi-agent communication infrastructure, retries/status polling, and skills or GitHub integrations beyond demonstrated need. Increments 2 and 3 remain sequenced but gated (see Acceleration Roadmap).

---

## Acceleration Roadmap (Dogfooded as a Dependency Graph)

The Product Owner has chosen to accelerate toward autonomous implementation ahead of pure friction-evidence. The path is decomposed below using the Milestone 11 technique. **All three increments are Product Owner acceleration overrides — none is friction-justified. Sequence order is not a justification tier.**

- **Foundation — Parallel decomposition (Milestone 11, active).** Depends on nothing new. Goes first: parallel throughput is meaningless without parallel-decomposed independent work, and the convention is cheap and validatable through use.
- **Increment 1 — Auto-open the PR after the agent pushes.** Depends only on the already-shipped `trigger-agent.sh` and `new-handoff.sh` — nothing new. **Now the active milestone (the first build after the foundation).** Acceleration override, justified *prospectively*: once decomposition enables parallel batches, the ~10s manual `gh pr create` recurs N-fold per batch (one per concurrent run), and that projected N×cost — contingent on parallel throughput actually materializing — is the rationale. It is **not** friction-justified: the prior retrospective measured the per-occurrence cost at ~10s (below the automation bar) and judged the recurrences to be pseudoreplication of a single deterministic property (one structural fact repeated on every triggered run), not accumulating independent evidence. Milestone 12 then **measured** this: per-PR filing is trivial (~seconds), so the operative justification is the unattended/looped case (no human present to file at all), not N×10s. When built: a wrapper around `trigger-agent.sh` (not inside it, preserving the one-shot contract), host-side under Product Owner credentials (preserving author/reviewer separation), hermetic tests, idempotency (no duplicate PR), success-gating (only on exit 0 with commits pushed), and loud degrade-to-manual.
- **Increment 2 — Label-triggered agent runs.** Depends on the existing trigger; applying a GitHub label fires `trigger-agent.sh` in place of a manual command. Gated acceleration override. Planned and sequenced now, **not built this session.**
- **Increment 3 — Agent-to-agent review/revise loop.** Depends on Increments 1 **and** 2 **and** on throughput being validated through use — the largest leap. Carries the correlated-validator risk (see Risks), so **the final merge stays human or independent** even if the loop is autonomous. Gated acceleration override. Planned and sequenced now, **not built this session.**

Build order: Foundation → 1 → (2, 3, gated). Increment 3 opens only once decomposition + Increments 1–2 have demonstrated the throughput is worth the orchestration cost.

---

## Staff Engineer Recommendations

### Current Recommendation

The Product Owner has decided to accelerate toward automation and, eventually, productizing this framework for other projects. This replaces the prior blanket "no automation" stance — but the gating logic stays: automate only what has been demonstrated through repeated manual use, starting with the narrowest, most mechanical step first. The gate now also runs forward: shipped automation must demonstrate value in real use before the next layer (triggering, productization) is opened.

Milestones 6 through 10 are complete and Milestone 8's owed live-run validation is discharged. The bounded gate-override worked as intended end to end: the narrowest-slice trigger shipped, reviewing its PR with `review-context.sh` produced Milestone 7's validation, that review found the hardcoded-list defect (fixed in Milestone 9), and the Milestone 9 implementation was itself driven by the first live `trigger-agent.sh` run — discharging Milestone 8's validation as a byproduct. Each step continued to surface its own next increment from real use.

Recommended next step:

1. **Ship Milestone 11 (parallel decomposition), then Increment 1.** The foundation is a convention, not infrastructure, so the over-engineering risk is low; validate it through real use before leaning on it. Increment 1 (auto-open PR) follows as the first acceleration override — see the Acceleration Roadmap for its dependency edges, override rationale, and build constraints. Increments 2 and 3 are sequenced but gated; do not build them this session.

The friction gate still governs everything outside the named Acceleration Roadmap. The roadmap is a bounded Product Owner override, not a removal of the gate; productization remains gated until separately justified.

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

- How far to automate triggering the external agent **beyond the narrowest manual slice** — partially resolved into the Acceleration Roadmap: **Increment 2 (label-triggered runs)** is the chosen next step in this space, as a gated acceleration override. Anything past it (status polling, looping over issues) stays deferred until demonstrated repeated need justifies it, except where the Roadmap names it as a prerequisite for a sequenced increment.
- Whether to automate **trigger-side PR creation** — **resolved into the Acceleration Roadmap as Increment 1, now the active milestone.** The earlier cost-gate bar (manual `gh pr create` is ~10s, below the automation bar) is deliberately overridden by Product Owner choice rather than waiting for manual filing to become demonstrated friction; the prospective justification (parallel batches multiplying the ~10s cost N-fold) and the build constraints (host-side wrapper around `trigger-agent.sh`, PR-body as a readable artifact, idempotency, success-gating, degrade-to-manual) are recorded in the Roadmap. The design seam remains: the agent's PR body must be a readable artifact (written to an agreed path via a handoff-format change) or synthesized from the issue and commits.
- **Decomposition validated under real parallelism — Resolved (Milestone 12).** The Product Owner chose validate-first; the first genuinely parallel batch ran (tracking issue #70, PRs #71/#72): two file-disjoint agents ran concurrently in isolated clones, each stayed within its declared footprint, and both branches merged with no conflict — discharging Milestone 11's owed validation and confirming the convention's core claim. Forecast-N was replaced with measured-N: per-PR filing proved trivial, which recalibrated Increment 1's rationale toward the unattended/looped case (see Acceleration Roadmap and Active Milestone) rather than per-PR seconds.
- What productization requires structurally (e.g., parameterizing CLAUDE.md/AGENTS.md, removing solo-builder-specific framing) — deferred until a reusability need is demonstrated rather than anticipated.
- Whether to unify `new-issue.sh` and `new-handoff.sh` into a single flow — open only if the metadata/file-list seam between them recurs as friction; not yet observed to repeat.
- **Wrapped-title papercut when hand-filing a PR** — filing via `gh pr create` with a multi-line title produced a malformed PR title (n=1, surfaced in the Milestone 11 cycle and fixed post-hoc). This is an **independent** human-filing friction sample, distinct from the PR-ownership gap; it is **not** folded into Increment 1's justification. If it recurs on the next hand-filed PR, it earns its own narrow fix — set the PR title from the issue at filing time — which is cheaper than, and separate from, Increment 1's auto-open-PR build. Increment 1 must not absorb the evidence for this smaller targeted fix.
- **`trigger-agent.sh` is worktree-incompatible** — its `[[ -d .git ]]` repo-root check fails inside a git worktree (there `.git` is a file), so the Milestone 12 parallel batch needed separate full clones for isolation. n=1. If parallel batches become routine and clone overhead bites, the narrow fix is to accept a `.git` file as well as a directory. Not yet justified.
- **`new-issue.sh` renderer omits the template's `## Dependencies` section** — Milestone 11 added the section to the issue template but not to `new-issue.sh`'s `render_body`, so issues created via flag mode (e.g. #68/#69) lack it; dependencies were recorded in the tracking issue instead. n=1 template/script divergence. The narrow fix is to add the section (and a `--depends-on` flag) to the renderer. Not yet justified.
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

### Correlated Validators (Increment 3)

An agent-to-agent review/revise loop pairs two LLM agents that share training blind spots, so the loop can converge on confident-but-wrong output that neither flags. Mitigation: the final merge decision stays human or independent even when the loop is autonomous, and Increment 3 is gated until decomposition and Increments 1–2 have proven the throughput justifies the orchestration cost.

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