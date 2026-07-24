# AI Engineering Operating Plan

## Project Vision

Build an AI-native engineering operating system that enables a solo builder to work with AI agents as if managing a disciplined, high-performing software engineering team.

The focus is on improving engineering process, maintainability, review quality, and learning—not maximizing automation.

This document is jointly maintained by the Product Owner and the Staff Engineer and should evolve throughout the project.

---

## Current Objective

Milestones 1–12 are complete: the planning/handoff/review tooling is shipped and validated, and **parallel dependency-graph decomposition** is adopted and validated under real parallelism (Milestone 12). **Milestone 13 is now active** — authoring the first project-type profile (Applied AI & Data Science) as the first productization step: surgical, permanent base primitives plus a provisional profile skeleton, validated by a real hand-pass (see Active Milestone). The separate **Acceleration Roadmap** track (autonomous-implementation increments) remains at rest.

Increment 1 (auto-open the PR after the agent pushes) has been **dropped** — its premise failed empirically (full reasoning in the Acceleration Roadmap). Dropping it does not re-open the friction gate, which still governs everything outside any named acceleration roadmap; the gate was always a bounded Product Owner override, not removed.

---

## Completed Milestones

Milestones 1–12 built and validated the planning/handoff/review toolchain, each surfacing its own next increment from real use rather than speculation. The table is orientation, not a changelog; the How for any entry lives in the linked issues/PRs and git history. Reasoning that outlived its milestone is carried in the Active Milestone, Acceleration Roadmap, or Open Decisions sections and pointed to below.

| # | What shipped | What it discovered / why it mattered |
|---|---|---|
| 1 | Core repo artifacts (CLAUDE.md, PLAN.md, AGENTS.md, README, issue/PR templates, `new-issue.sh`) and the Staff Engineer / Product Owner model. | Planning process made repeatable across sessions. |
| 2 | Validated the manual handoff across two external-agent cycles. | Handoff emerged as a first-class workflow artifact; scope and git-ownership boundaries held. |
| 3 | `new-handoff.sh` — creates/pushes the branch and renders the canonical handoff (Issues #21/#25, PRs #22/#24/#26). | Review caught a non-hermetic test before merge. |
| 4 | Validated the automation across two cycles (ShellCheck #28/#29; dirty-tree fix #31/#32). | Surfaced that git-tracked `.claude/settings.local.json` dirtied the tree on every permission grant (now gitignored); left the piped-stdin friction as the next increment. |
| 5 | Non-interactive flag mode on both scripts (#34/#35, #36/#37). | Real use exposed a `set -u`/empty-array crash on bash 3.2, fixed narrowly (#39/#40). |
| 6 | `review-context.sh` — read-only PR-review context assembler (#41/#43). | Read-only boundary enforced by test; dogfooded the M5 scripts with no friction. |
| 7 | Validated `review-context.sh` on a real review (PR #48). | Exposed a hardcoded test-list that reported "all passed" while silently skipping the new test — false confidence on the code under review; root cause promoted to M9. |
| 8 | `trigger-agent.sh` — one-shot `codex exec` from a handoff path (#46/#48). | First live run drove the M9 implementation; surfaced that Codex's sandbox can't reach api.github.com, so the agent can't open its own PR. Three non-blocking observations remain recorded-only (untested zero-arg path; repeated `gh pr diff` on above-threshold diffs; denylist-based write detection). |
| 9 | Replaced hardcoded file lists with filesystem discovery in `lint.sh`/`review-context.sh` (#50/#51). | Closed the false-"all passed" defect M7 found; validated itself in review by running the previously-skipped tests. |
| 10 | `new-handoff.sh` writes git chatter to stderr; stdout carries only the handoff (#54/#55). | Made the handoff cleanly pipeable into the trigger; confirmed the PR-ownership gap a second time → codified manual fallback in CLAUDE.md (PR #56). |
| 11 | Parallel dependency-graph decomposition convention in CLAUDE.md (#65/#66). | A convention, not infrastructure — no new script; issue template gained `## Dependencies`. |
| 12 | Validated decomposition on the first real parallel batch — two file-disjoint agents in isolated clones, both merged clean (tracking issue #70, PRs #71/#72). | Measured per-PR filing as trivial (~seconds each), collapsing Increment 1's premise (see Acceleration Roadmap); surfaced two gated infra findings — `trigger-agent.sh` worktree-incompatibility and the `new-issue.sh` `## Dependencies` omission (see Open Decisions). |

---

## Active Milestone

**Milestone 13: Applied AI & Data Science profile (first productization step) — active; first validation specimen complete.**

The base primitives (permanent CLAUDE.md additions inherited by every future profile: investigation-as-work-type; behavioral acceptance criteria; investigation stopping condition; domain-agnostic standards; profiles-compose; self-evaluation-is-not-independent-validation) and the **provisional** `profiles/applied-ai-data-science.md` skeleton shipped (#79, #81). The skeleton is a set of hypotheses — a 4-state lifecycle-as-menu (Frame / Investigate / Implement / Operate), an analysis-only lens menu, the stopping rule as Investigate's exit, notebook strategy, and an ARCHI conditional-section menu with **online-vs-offline forced as a classification input** — that a real hand-pass may cut, not merely fill. The two issues were **serialized** (file-disjoint but interface-dependent: the profile composes with the base primitives). Lenses are analysis-only; anything producing code crosses the single blessed Software Engineer handoff.

**Hand-pass #1 (posing coach) — complete.** The Product Owner ran the read-only fit assessment (#82) deliberately, to break the profile co-author's validator correlation (per the self-evaluation-is-not-independent-validation primitive). The profile routed the project correctly on its defining fork (offline) and the Computer Vision lens fired hard, but five load-bearing mismatches surfaced and were applied as REVISEs: ground-truth and eval-metric declarations made explicit (#85/#87), and the offline-shape enumeration, non-determinism default, and Applied ML pretrained-consumer case fixed (#86/#89). No sections were ADDed (n=1 forbids it); five GAPs are parked for the remaining specimens. Two proposed CUTs were **not** taken, and why is load-bearing: **C1** (a "video" assumption) was a no-op — the specimen refuted an assumption in the *protocol*, not any profile line, and the posing coach is in fact offline **single-image**, not video; **C2** (Research / Data-Engineering lenses) was *correct silence*, not overfit — both are menu items a dataset-bearing project will fire. That distinction drove a **protocol amendment** (#82): the n=1 asymmetry rule now separates **universal content the specimen falsified** (cut-safe) from **conditional/menu content that merely stayed silent** (near-zero content evidence; essentially un-cuttable at n=1). The 4-state lifecycle is **UNTESTED, not validated** — the posing coach predates the profile, so its history structurally could not route episodes; the states get their real test prospectively, not on this specimen.

**Validation criterion (unchanged).** The profile stays `STATUS: PROVISIONAL` until it is also checked against **at least one conventional supervised-learning project and one LLM/RAG project** — hand-pass #1 is n=1, and the portfolio-overfit risk it guards against is not resolved by a single specimen. Those two hand-passes are the remaining owed work of this milestone; they are also where the parked GAPs (G1–G5) and the still-silent lenses get adjudicated.

**Deferred (c), each with a named flip condition:** Research-lens delegation advances when the Staff Engineer demonstrably cannot hold the research mode itself — a context-polluting prior-art survey, or review throughput past one human's serial capacity (first in line); `review-context.sh` eval-artifact gathering advances at ≥2 DS reviews where the reviewer manually assembles the same eval artifacts because the diff alone was insufficient; a profile-declaration mechanism advances when a second profile exists and manual "which profile applies" routing recurs. Until each fires, none is built.

---

## Acceleration Roadmap (Dogfooded as a Dependency Graph)

The Product Owner chose to accelerate toward autonomous implementation ahead of pure friction-evidence. The path was decomposed using the Milestone 11 technique. Each increment is an isolated roadmap node; the increments below are **gated** acceleration overrides — none is friction-justified, and sequence order is not a justification tier.

- **Foundation — Parallel decomposition (Milestone 11).** Complete and validated under real parallelism (Milestone 12). Depended on nothing new.
- **Increment 1 — Auto-open the PR after the agent pushes. DROPPED.** Its premise failed empirically: Milestone 12 measured the friction it targeted — manual PR filing — as below the automation bar at current scale, so the prospective justification (parallel batches multiplying that cost) did not materialize. This is a drop, not a deferral, and it leaves **no "revisit Increment 1" hook**: if unattended/looped runs ever make PR-filing cost real (no human present to file at all), that is a **new** decision under a **new** rationale, not a resumption of Increment 1. Increment 1 was an isolated node, so its removal triggers no downstream re-derivation.
- **Increment 2 — Label-triggered agent runs.** Depends only on the existing `trigger-agent.sh` (never on Increment 1); applying a GitHub label would fire `trigger-agent.sh` in place of a manual command. Gated acceleration override; **not auto-promoted** into the active slot — taking it up is a fresh Product Owner decision. **Precondition attached to this edge:** the `[[ -d .git ]]` repo-root check is worktree-incompatible — inside a git worktree `.git` is a file, not a directory, so the check fails. This same check exists identically in **two** scripts: `trigger-agent.sh` (line 36) and `lint.sh` (line 10); the incompatibility is therefore not confined to the trigger (n=1 observation, found in Milestone 12, which therefore needed separate full clones for isolation). Because Increment 2 fires `trigger-agent.sh` via label and is the increment most likely to drive concurrent runs, this incompatibility is a precondition to confront if and when Increment 2 is taken up; the narrow fix — accept a `.git` file as well as a directory — must be applied to **both** scripts, not just the trigger.
- **Increment 3 — Agent-to-agent review/revise loop.** With Increment 1 dropped, its precondition reduces from "Increments 1 **and** 2 plus validated throughput" to **"Increment 2 plus validated throughput"** — the largest leap. Carries the correlated-validator risk (see Risks), so **the final merge stays human or independent** even if the loop is autonomous. Gated acceleration override.

The roadmap is at a rest state. No increment is active; opening any of the above is an open Product Owner decision.

---

## Staff Engineer Recommendations

### Current Recommendation

The Product Owner has decided to accelerate toward automation and, eventually, productization. This replaces the prior blanket "no automation" stance, but the gate stays and now runs forward: automate only what repeated manual use has demonstrated, narrowest mechanical step first, and each shipped layer must prove value in real use before the next (triggering, productization) opens.

Recommended next step:

1. **Hold at the rest state; take up no new build by default.** Milestones 1–12 are complete and validated, and Increment 1 has been dropped (premise failed empirically — see Acceleration Roadmap). With the active slot deliberately empty, the disciplined default is to let the next build be a fresh Product Owner decision rather than auto-promoting Increment 2. Increments 2 and 3 remain gated acceleration overrides; do not build them absent a Product Owner decision.

The friction gate governs everything outside a named Acceleration Roadmap; dropping Increment 1 does not loosen it, and productization stays gated until separately justified.

Do not build, until each is separately justified by its own repeated manual pattern: agent orchestration; multi-agent communication infrastructure; automatic triggering of the external agent; skills or GitHub integrations beyond the Milestone 3 target.

### Reasoning

The operating model should emerge from experience rather than speculation, even on an accelerated timeline. Compressing the validation phase is acceptable; skipping it is not — automation targets must be chosen from patterns that have actually repeated, not from what seems generically useful. Premature infrastructure increases maintenance burden without validating that it solves a real problem.

---

## Open Decisions

Items requiring future discussion:

- **What the next build should be, if any — OPEN.** With Milestones 1–12 complete and Increment 1 dropped, the roadmap is at a rest state and the active slot is deliberately empty. Holding at rest is a legitimate outcome; Increment 2 is sequenced-but-gated, not auto-promoted. Choosing to take up Increment 2 (or anything else) is a fresh Product Owner decision.
- How far to automate triggering the external agent **beyond the narrowest manual slice** — partially mapped into the Acceleration Roadmap: **Increment 2 (label-triggered runs)** is the sequenced-but-gated option in this space, **not** an active or auto-promoted choice. Taking it up is a fresh Product Owner decision; anything past it (status polling, looping over issues) stays deferred until demonstrated repeated need justifies it, except where the Roadmap names it as a prerequisite for a sequenced increment.
- Whether to automate **trigger-side PR creation** — **closed: dropped with Increment 1.** Milestone 12 measured the targeted friction (manual PR filing) as below the automation bar at current scale, so the premise failed empirically. This is closed, not deferred: if unattended/looped runs ever make PR-filing cost real (no human present to file), that is a new decision under a new rationale, not a resumption of Increment 1.
- **Decomposition validated under real parallelism — Resolved (Milestone 12).** The Product Owner chose validate-first; the first genuinely parallel batch ran (tracking issue #70, PRs #71/#72): two file-disjoint agents ran concurrently in isolated clones, each stayed within its declared footprint, and both branches merged with no conflict — discharging Milestone 11's owed validation and confirming the convention's core claim. The same measurement — per-PR filing proved trivial — collapsed Increment 1's premise and led to dropping it (see Acceleration Roadmap).
- What productization requires structurally (e.g., parameterizing CLAUDE.md/AGENTS.md, removing solo-builder-specific framing) — **in progress: Milestone 13 is the first productization step** (the first project-type profile). The base-primitive vs. profile-content boundary and the profile-declaration mechanism are being established through that work; broader parameterization remains deferred until a reusability need is demonstrated rather than anticipated.
- Whether to unify `new-issue.sh` and `new-handoff.sh` into a single flow — open only if the metadata/file-list seam between them recurs as friction; not yet observed to repeat.
- **Wrapped-title papercut when hand-filing a PR** — filing via `gh pr create` with a multi-line title produced a malformed PR title (n=1, surfaced in the Milestone 11 cycle and fixed post-hoc). This is an **independent** human-filing friction sample, distinct from the PR-ownership gap. If it recurs on the next hand-filed PR, it earns its own narrow fix — set the PR title from the issue at filing time. It stands on its own and is not evidence for any broader trigger-side PR automation (the now-dropped Increment 1 space).
- **The `[[ -d .git ]]` repo-root check is worktree-incompatible — in two scripts** — inside a git worktree `.git` is a file, not a directory, so the check fails. The identical check lives in **both** `trigger-agent.sh` (line 36) and `lint.sh` (line 10), so the eventual narrow fix (accept a `.git` file as well as a directory) must touch both, not just the trigger. Recorded as a precondition attached to **Increment 2's dependency edge** in the Acceleration Roadmap (Increment 2 fires `trigger-agent.sh`), not as a free-standing item. n=1, gated, not yet justified.
- **Reproducing the working environment on a second machine — OPEN, pre-friction, un-justified.** The Product Owner is migrating personal projects from a MacBook to a self-built PC, driven by a real constraint unrelated to this repo: model training is impractical on the Mac. This gives a concrete, named machine to reproduce the environment on where before there was none — but **nothing has broken yet**, so this is pre-friction, not friction-justified. It is a live open question, **not** a build: no environment-reproduction work is justified by this entry on its own. The observe-first move is to run the existing script suite on the PC and **log toolchain drift** — which tools are present, their versions, what breaks, and the effort to fix each — before deciding anything. That log is the evidence any future decision would rest on.
- **Docker-based reproducible environment — ACCELERATION OVERRIDE (learning-motivated), not earned work.** Separately from the pre-friction question above, the Product Owner has elected to build a Docker-based reproducible environment as a future item, motivated by **learning / skill-building** — explicitly **not** by demonstrated friction. It is labeled an **acceleration override** — a deliberate build-ahead-of-evidence choice for a named reason — by the same mechanism the Acceleration Roadmap uses; this label is load-bearing and fences the item so it cannot become false precedent for any other un-earned build. It is **not on the PC-migration critical path**: getting working on the PC uses the quickest sufficient means (likely a short install step), and this Docker build is a separate deliberate exercise that must not block day-one PC work. The toolchain-drift log from the entry above still feeds it — but as an override its role shifts from *gating whether* to build to *specifying what* the Dockerfile must pin.
- **Review-granularity conventions (gate briefing + issue batching) — ADOPTED as fenced prospective conventions, not earned work.** Landed in CLAUDE.md (PR #92): a standard review-gate briefing (Review section) and an optional issue-batching convention (Implementation Handoff), adapted from prior art. **Batching is not friction-justified** — no issue in this repo's history has been too large to review well in one end-of-work pass; it is adopted *prospectively* against expected larger DS product work, and its cost is bounded because it is **conditional** (it does nothing when not invoked). This label is load-bearing and **fences** the convention so it cannot become false precedent for any other un-earned build — the same mechanism as the Docker override above. **One field is earned:** the briefing's verification field (whether lint/tests actually ran against the changed files) traces to the M7/M8 hollow-green defect and guards the residual semantic gap M9's filesystem discovery did not close. The convention text and its full justification live in CLAUDE.md and PR #92 and are not restated here. **Seam note:** batching multiplies handoff round-trips — the cost surface Increment 3 would automate — so future batched work may generate evidence relevant to it; that is not a dependency, is not scheduled, and is not pre-counted as justification.
- **`new-issue.sh` renderer omits the template's `## Dependencies` section** — Milestone 11 added the section to the issue template but not to `new-issue.sh`'s `render_body`, so flag-mode issues (e.g. #68/#69) lack it. n=1 template/script divergence — but with a standing mitigation that may make it moot: the parallel-decomposition convention already homes the dependency graph in the milestone **tracking** issue, not the individual issue, so the per-issue section is partly redundant. The narrow fix is to add the section (and a `--depends-on` flag) to the renderer. **Flip condition:** justified when the divergence recurs *and* the tracking-issue graph proves insufficient in practice — a concrete case where an implementing agent or reviewer needed the dependency edge on the individual issue and its absence caused a real miss or extra step. Recurrence alone does not flip it; the tracking-issue home must be shown inadequate. Until then, unbuilt.
- When a triggered agent cannot open its own PR — **Resolved (manual fallback codified).** The sandbox-cannot-reach-`api.github.com` gap recurred on the next triggered run, clearing the two-occurrence proven-need bar, so the fallback is now procedure in CLAUDE.md (Implementation Handoff): the Product Owner files the PR from the agent's pushed branch using the agent's PR body, and the Staff Engineer reviews the diff on its merits. The filer is the Product Owner, not the Staff Engineer, preserving the author/reviewer separation. **Still open and gated:** whether this justifies building trigger-side PR automation is tracked as its own decision above; two occurrences justify codifying the manual fallback, not automating it.
- Repository template structure beyond MVP.
- **Introduction of reusable skills** — evaluated 2026-07-01, **verdict: hold, no skill justified yet.** Candidates reviewed against the friction gate: the planning-PR flow (most-repeated, ≥3×, but its mechanical part is ~seconds/PR — below the bar by the same standard that dropped Increment 1, and its content is bespoke judgment a skill can't write); issue-based review (already a tested script + CLAUDE.md procedure, and overlaps Claude Code's built-in `/review`); cold-start orientation (already covered by CLAUDE.md's always-loaded Session Startup); the dispatch pipeline (scripts already compose, and a run-the-whole-thing skill would blur the handoff boundary). The repo's earned-automation mechanism is a *tested shell script*, not a `SKILL.md`; that stays the default even when something clears the gate. What would flip it: a judgment-heavy, multi-step, on-demand workflow that recurs and is awkward as a single script — most likely in the label-triggered/unattended direction (a fresh decision under its own rationale, not pre-built now).
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

This document captures strategic direction, current priorities, engineering recommendations, active risks, and major open questions. It is not a changelog, task list, or duplicate of Issues, PR descriptions, or implementation detail. The maintenance and compaction contract lives in CLAUDE.md's `## PLAN.md` section. When priorities change, update this document rather than creating a new planning artifact.