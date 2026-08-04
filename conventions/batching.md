# Batching a Large or Risky Issue

Most issues are delivered and reviewed in a single end-of-work pass; batching those is pure overhead. For an issue large or risky enough that a single review could not be done well, the Staff Engineer may instead scope the implementation into **batches**. Whether to batch is a per-issue judgment call the Staff Engineer makes when scoping the handoff — not a blanket rule.

When batching:

- A batch is the smallest set of the issue's acceptance-criteria items that leaves the tree green (lint and tests pass). Never split an interface from its wiring. Target a reviewable diff.
- Size by risk: novel or architecturally significant work takes smaller batches, down to a single item; mechanical or repetitive work takes larger ones.
- Batching is adaptive: a clean batch grows the next; a batch that needed heavy correction shrinks the next, and the correction pattern is stated explicitly in the next handoff.
- Each reviewed batch is a commit on the feature branch; review the delta against the last reviewed commit, applying the Review Gate Briefing at each gate. The pull request remains the final gate; squash-merge and linear history are unchanged.

The real cost of batching is that it multiplies handoff round-trips: the Staff Engineer does not implement, so every batch and every correction round-trips through the handoff to the external Software Engineer. Accept that cost deliberately, or do not batch.

Three mechanisms from the prior art this convention adapts are deliberately **not** adopted:

1. **Index-as-checkpoint** (`git add -A` staging, delta review via worktree-vs-index, no commits until release). It stores review state in the working tree's single index, so it is single-threaded by construction and does not compose with parallel decomposition; it would also compound the known worktree-incompatibility of the repo's scripts. We use commits on the branch instead.
2. **Staff Engineer fixes problems directly.** This violates the handoff boundary; corrections round-trip to the Software Engineer instead.
3. **Agent-reviews-agent as the formal gate.** The review gate stays Staff-Engineer-then-human; the same model does not both implement and formally approve.

This convention is adopted prospectively — from expected future work larger than this repo has yet produced, not from demonstrated local friction — and does nothing when not invoked.
