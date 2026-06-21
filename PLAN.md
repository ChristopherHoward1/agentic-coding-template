# AI Engineering Operating Plan

## Project Vision

Build an AI-native engineering operating system that enables a solo builder to work with AI agents as if managing a disciplined, high-performing software engineering team.

The focus is on improving engineering process, maintainability, review quality, and learning—not maximizing automation.

This document is jointly maintained by the Product Owner and the Staff Engineer and should evolve throughout the project.

---

## Current Objective

Validate the issue/branch/handoff automation through repeated real use before building any further automation.

The Product Owner has decided to accelerate toward automation and eventual productization of this framework, but each step must still be justified by a pattern demonstrated through repeated use — and that bar now applies to the automation itself. Triggering and productization remain deferred until the existing scripts prove themselves in practice. See Staff Engineer Recommendations below.

---

## Completed Milestones

### Milestone 1: Foundation — Complete

Core repository artifacts shipped: CLAUDE.md, PLAN.md, AGENTS.md, README.md, issue and PR templates, `scripts/new-issue.sh`. The Staff Engineer / Product Owner collaboration model is established and the planning process is repeatable across sessions.

### Milestone 2: External Agent Validation — Complete

The manual handoff process was validated across two implementation cycles. External agents completed scoped issues without clarification requests. Git ownership boundaries, scope discipline, and handoff quality all held. The implementation handoff has emerged as a first-class workflow artifact.

### Milestone 3: Targeted Automation of Issue/Branch/Handoff Creation — Complete

The handoff format was formalized in CLAUDE.md (Issues #21/#25, PRs #22/#24). `scripts/new-handoff.sh` (Issue #25, PR #26) now creates and pushes the feature branch and renders the canonical handoff from issue metadata, composing with the existing `scripts/new-issue.sh`. The review cycle caught and corrected a non-hermetic test before merge.

---

## Active Milestone

### Milestone 4: Validate the Automation Through Use

Scope: use `scripts/new-issue.sh` and `scripts/new-handoff.sh` for real handoffs and record whether they hold up — friction, gaps, or manual steps that recur.

Explicitly out of scope until this validation produces evidence:

- Triggering the external agent automatically (e.g., via GitHub Actions or webhooks).
- Productizing the framework (parameterizing CLAUDE.md/AGENTS.md, removing solo-builder framing).
- Unifying `new-issue.sh` and `new-handoff.sh` into a single flow.

Rationale: the project's gating bar applies to the automation itself: validate through repeated use before adding the next layer. Candidate improvements (e.g., a CLAUDE.md pointer to the handoff script, unifying the two scripts) should be driven by friction observed in use, not added speculatively.

Validation status: the first full real cycle has completed and the loop held — Issue #28 (ShellCheck linting) was scoped with `new-issue.sh`, handed off via `new-handoff.sh`, implemented by the external agent with no clarification requests, reviewed, and merged (PR #29) with all acceptance criteria and verification satisfied. The milestone stays open for at least one more real handoff to test whether the single-observation frictions (interactive scripts being awkward for an agent to drive; metadata/file-list duplication across the two scripts; verification tool prerequisites not flagged in the handoff) recur or remain one-offs.

---

## Staff Engineer Recommendations

### Current Recommendation

The Product Owner has decided to accelerate toward automation and, eventually, productizing this framework for other projects. This replaces the prior blanket "no automation" stance — but the gating logic stays: automate only what has been demonstrated through repeated manual use, starting with the narrowest, most mechanical step first. The gate now also runs forward: shipped automation must demonstrate value in real use before the next layer (triggering, productization) is opened.

Recommended next increment: fix the dirty-tree friction in the handoff flow. `scripts/new-handoff.sh` aborts on a dirty working tree, but `.claude/settings.local.json` is git-tracked and is rewritten by the agent harness whenever a permission is granted — so routine operation dirties the tree and blocks the script. This was observed repeatedly across the Milestone 4 cycle (it blocked and was reverted multiple times), so it clears the gating bar as the next-narrowest mechanical step. Likely fix: untrack/gitignore `.claude/settings.local.json`, or have the scripts ignore that path. Queued for a future cycle; not yet implemented.

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

- When to automate triggering the external agent (e.g., GitHub Actions firing on issue creation) — deferred until the issue/branch/handoff automation is validated through repeated use (Milestone 4).
- What productization requires structurally (e.g., parameterizing CLAUDE.md/AGENTS.md, removing solo-builder-specific framing) — deferred until the automation is validated in use (Milestone 4).
- Whether to unify `new-issue.sh` and `new-handoff.sh` into a single flow — open only if Milestone 4 shows the manual seam between them recurs as friction.
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