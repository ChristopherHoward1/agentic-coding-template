# AI Engineering Operating Plan

## Project Vision

Build an AI-native engineering operating system that enables a solo builder to work with AI agents as if managing a disciplined, high-performing software engineering team.

The focus is on improving engineering process, maintainability, review quality, and learning—not maximizing automation.

This document is jointly maintained by the Product Owner and the Staff Engineer and should evolve throughout the project.

---

## Current Objective

Establish the minimum viable version of the engineering operating system.

Success is defined by successfully completing one end-to-end development cycle using the workflow defined in CLAUDE.md.

The objective is to validate the process before adding automation or complexity.

---

## Active Milestone

### Milestone 1: Foundation

Deliverables:

- CLAUDE.md
- PLAN.md

Near-term goals:

- Define repository philosophy.
- Validate Staff Engineer / Product Owner collaboration.
- Establish a repeatable planning process.
- Avoid unnecessary persistent documentation.

Completion criteria:

- Claude can onboard into the repository from CLAUDE.md.
- Product Owner and Staff Engineer share a clear understanding of priorities.
- Planning can continue without relying on prior chat history.

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

## Next Recommended Actions

1. Finalize CLAUDE.md.
2. Create the repository foundation.
3. Execute a small planning exercise using the documented workflow.
4. Complete one feature through branch → PR → review → merge.
5. Conduct a retrospective and update this document with lessons learned.

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