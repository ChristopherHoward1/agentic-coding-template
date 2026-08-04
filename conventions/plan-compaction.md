# Compaction

PLAN.md grows monotonically as milestones complete. Without discipline the completed-milestone prose drifts from orientation into a changelog — which this section already forbids — so compaction is enforcement of that rule, not new policy.

Preserve verbatim: the Active Milestone, every Open Decision, all live reasoning chains (why a decision went the way it did, why an item is gated, what a label fences off), and current state. Reasoning that survives only as a restated fact has been lost even when the fact remains — the cold-read test below is the guard against exactly that.

Compact: completed-milestone execution narrative (issue/PR numbers, what a review found, how a bug was fixed), restated acceptance criteria, and any reasoning stated in more than one place. The How is preserved by git history and the linked PR/issue; the working artifact need not carry it.

Trigger: at each milestone retrospective, write the new Completed entry at orientation density and check whether earlier entries have drifted back into narrative. Separately, when a reasoning fact appears in a second location, reduce the second to a pointer (single-source rule). Do not build a size checker or token budget; if measurement proves necessary through use, that is a later increment.

Strategies: keep What/Why, cut How; convert parallel prose to a table; collapse enumerations into summaries; give each reasoning chain one canonical home and point at it elsewhere. The density target is qualitative — a completed entry should read as orientation, not a changelog.

A compaction pass is accepted only against the cold-read test: a fresh reader given only the compacted PLAN.md must be able to reconstruct each preserved reasoning chain's Why, not merely its What. Size reduction is necessary but never sufficient, and the author of a compaction cannot be its verifier.
