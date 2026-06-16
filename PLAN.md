# AI Engineering Operating Plan

## Project Vision

Build an AI-native engineering operating system that enables a solo builder to work with AI agents as if managing a disciplined, high-performing software engineering team.

The focus is on improving engineering process, maintainability, review quality, and learning—not maximizing automation.

This document is jointly maintained by the Product Owner and the Staff Engineer and should evolve throughout the project.

---

## Current Objective

Confirm the external-agent handoff process holds across a second cycle, then begin targeted automation of the one step already proven repetitive: issue, branch, and handoff creation.

The Product Owner has decided to accelerate toward automation and eventual productization of this framework, but each step must still be justified by a pattern demonstrated through repeated manual use — see Staff Engineer Recommendations below.

---

## Completed Milestones

### Milestone 1: Foundation — Complete

Deliverables shipped:

- CLAUDE.md
- PLAN.md
- AGENTS.md
- README.md
- `.github/ISSUE_TEMPLATE/implementation.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `scripts/new-issue.sh` (with `gh issue create` integration)

The Staff Engineer / Product Owner collaboration model is established and the planning process is repeatable across sessions. Role boundaries have been clarified through retrospective: implementation belongs to an external agent, not a Claude sub-agent.

---

## Active Milestone

### Milestone 2: External Agent Validation

Goal: validate that the manual handoff process is sufficient for an external agent to implement scoped work without Staff Engineer clarification.

Progress:

- Cycle 1 complete: issue #14 implemented by an external agent, opened as PR #15, reviewed, and merged without scope or acceptance-criteria issues.
- One handoff-quality gap was found (Staff Engineer left the working tree on `main` after branch creation) and resolved via PR #16, which added explicit branch-handoff and git-ownership rules to CLAUDE.md and AGENTS.md.

Closing criterion:

- A second cycle, run after the PR #16 fix, completes cleanly — no clarification requests, no revision requests related to scope discipline or handoff quality. This confirms the fix held on an independently chosen issue.

Once met, Milestone 2 is complete and Milestone 3 (below) becomes active.

---

## Upcoming Milestone

### Milestone 3: Targeted Automation of Issue/Branch/Handoff Creation

Scope: automate the one step that has already been repeated identically, by hand, across both cycles so far — creating the GitHub Issue, creating and pushing the feature branch, and assembling the handoff message.

Explicitly out of scope for this milestone:

- Triggering the external agent automatically (e.g., via GitHub Actions or webhooks).
- Any multi-agent orchestration.
- Automating review, verification, or merge decisions.

Rationale: this is the first automation candidate that meets the project's own bar — a pattern demonstrated through repeated manual use, not a speculative convenience. Automating review or triggering would remove human judgment from exactly the parts of the workflow this project exists to protect.

This milestone activates only after Milestone 2 closes.

---

## Staff Engineer Recommendations

### Current Recommendation

The Product Owner has decided to accelerate toward automation and, eventually, productizing this framework for other projects. This replaces the prior blanket "no automation" stance — but the gating logic stays: automate only what has been demonstrated through repeated manual use, starting with the narrowest, most mechanical step first.

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

- When to automate triggering the external agent (e.g., GitHub Actions firing on issue creation) — deferred until Milestone 3's automation is itself validated through repeated use.
- What productization requires structurally (e.g., parameterizing CLAUDE.md/AGENTS.md, removing solo-builder-specific framing) — deferred until Milestone 3 closes.
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