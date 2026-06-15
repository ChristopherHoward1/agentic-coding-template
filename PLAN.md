# AI Engineering Operating Plan

## Project Vision

Build an AI-native engineering operating system that enables a solo builder to work with AI agents as if managing a disciplined, high-performing software engineering team.

The focus is on improving engineering process, maintainability, review quality, and learning—not maximizing automation.

This document is jointly maintained by the Product Owner and the Staff Engineer and should evolve throughout the project.

---

## Current Objective

Complete one end-to-end development cycle with an external implementation agent performing the Software Engineer role.

Success is defined by an external agent (e.g., Codex) receiving a handoff, implementing a scoped issue on a feature branch, opening a pull request, and having that PR reviewed and merged through the standard workflow — with the Staff Engineer not performing any implementation work.

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

Near-term goals:

- Complete one full cycle where implementation is performed by an external agent.
- Validate that AGENTS.md provides sufficient onboarding for an external agent to operate correctly without additional instruction.
- Identify any handoff artifacts or workflow steps that need refinement based on real external-agent behavior.

Completion criteria:

- An external implementation agent receives a handoff, implements a scoped issue, and opens a PR without requiring clarification from the Staff Engineer.
- The PR satisfies all acceptance criteria and passes review without revision requests related to scope discipline or handoff quality.
- Any gaps discovered are captured in updated documentation.

---

## Staff Engineer Recommendations

### Current Recommendation

Prioritize proving the engineering workflow over building tooling.

Do not build:

- Automation
- GitHub integrations
- Skills
- Agent orchestration
- Multi-agent communication infrastructure

until the manual process has been validated through repeated successful use.

### Reasoning

The operating model should emerge from experience rather than speculation.

Premature infrastructure increases maintenance burden without validating that it solves a real problem.

---

## Open Decisions

Items requiring future discussion:

- Repository template structure beyond MVP.
- Introduction of reusable skills.
- GitHub automation and Apps.
- Additional persistent documentation.
- Cross-agent orchestration.

These should remain deferred until supported by practical experience.

---

## Risks

### Over-engineering

The largest risk is building infrastructure before validating process.

Mitigation:

Continuously prefer simpler solutions and revisit assumptions only after repeated pain points emerge.

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