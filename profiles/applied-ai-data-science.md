# Applied AI & Data Science Profile

## STATUS: PROVISIONAL / UNVALIDATED

This profile is a hypothesis for the first real hand-pass on the posing-coach project. Any section below may be cut, merged, or rewritten by that pass; this is not settled guidance.

It composes with the base operating model and the primitives merged in #79. Use the base model for lifecycle discipline, handoff boundaries, behavioral-vs-mechanical acceptance criteria, evidence-named evaluation, the limit of self-evaluation, and the rule that profiles compose rather than override.

## Required Project Slots

Every project using this profile declares these seams before implementation scope is treated as ready:

- [DATA_SOURCES]
- [DATA_LICENSE_CONSENT]
- [EVAL_METRIC] (or NONE, when evaluation is criterion/command-based rather than a metric over a dataset)
- [GROUND_TRUTH_SOURCE]
- [EVAL_CRITERION]
- [EVAL_COMMAND]
- [DATA_REGIME]
- [NOTEBOOK_STRATEGY]

## Lifecycle Menu

Use these as four selectable states, not a numbered sequence and not a stage-gate. A project may move between states as evidence changes.

### Frame

Entry condition: the project goal, data reality, or evaluation standard is unclear enough that implementation scope would be guesswork.

Work: frame the problem, identify [DATA_SOURCES], classify online-vs-offline up front, declare [DATA_REGIME], and route the work as implementation-ready, investigation-first, or hybrid.

Exit condition: the next state is explicit:

- Implementation-ready → move to Implement.
- Investigation-first → move to Investigate.
- Hybrid → Investigate → decision gate → Implement. Hybrid is a routing choice, not a fifth state.

### Investigate

Entry condition: feasibility, data quality, metric choice, model behavior, or evaluation evidence is uncertain.

Work: run the smallest useful investigation that can answer the declared question. Name the evidence needed before starting.

Exit condition: stop when the declared evidence bar is met or further work is not worth its cost. This stopping rule is the exit condition.

### Implement

Entry condition: the work has enough framing and evidence to satisfy the base implementation handoff standard.

Work: use the base lifecycle and single Software Engineer handoff. This profile adds DS-specific evidence and review inputs; it does not create a parallel implementation path.

Exit condition: implementation is complete, checks pass, and the PR gives the reviewer the agreed evaluation artifacts.

### Operate

Entry condition: the system, model, workflow, or analysis is in real use or ready for release.

Work: monitor drift, failures, data changes, user feedback, cost, latency where applicable, and evaluation regression against [EVAL_METRIC] when one exists, otherwise [EVAL_CRITERION].

Exit condition: continue operating, return to Investigate for new uncertainty, or return to Frame when the problem definition or data regime changes.

## Analysis Lenses

These are ANALYSIS LENSES the Staff Engineer may adopt while analyzing the work. They are not delegated agents and not a code-producing channel. Any work that produces code crosses the single blessed handoff to the external Software Engineer.

- Research — prior art, uncertainty reduction, external retrieval, benchmark awareness.
- Applied ML — data splits, labels, feature/model fit, baselines, error analysis, or pretrained model selection, contract/version pinning, and failure modes.
- LLM Systems — prompting, retrieval, context construction, evaluation correlation, hallucination risk.
- Computer Vision — data capture, annotation quality, augmentation, model failure modes, visual inspection.
- Data Engineering — ingestion, schemas, lineage, reproducibility, data contracts.
- MLOps — deployment shape, monitoring, rollback, drift, reproducible artifacts.

Research is the least-correlated lens because it can bring in external retrieval. If delegation is ever justified, Research is the first lens to revisit; delegation remains out of scope here.

## Architecture Concerns Menu

First classify online-vs-offline:

- Offline — batch analysis, deterministic CLI/tool runs over static inputs, notebook-backed exploration, training, evaluation, or post-processing. Do not assume real-time inference.
- Online — request-time inference, interactive user flows, or production serving with latency and availability constraints.
- Hybrid — offline preparation plus online serving. Name which parts are offline and which are online.

Then include only triggered sections; each item below is include-if-triggered:

- Data source and consent — triggered when [DATA_SOURCES] or [DATA_LICENSE_CONSENT] affects collection, use, retention, or sharing.
- Ground truth — triggered when [GROUND_TRUTH_SOURCE] requires labeling, human judgment, synthetic data, benchmark data, proxy labels, or is NONE by design; answer with the source, or with why no ground truth is legitimate for this project.
- Evaluation — triggered for every DS project; bind [EVAL_CRITERION] and [EVAL_COMMAND] to reviewable evidence, bind [EVAL_METRIC] only when the evaluation actually uses a metric, and distinguish product outputs from eval metrics.
- Leakage and holdout discipline — triggered when training, tuning, retrieval construction, prompt selection, or manual inspection can contaminate evaluation.
- Runtime and serving — triggered only for online or hybrid systems; cover latency, cost, failure behavior, and fallback.
- Data operations — triggered when ingestion, versioning, lineage, refresh cadence, or schema drift can change behavior.
- Model operations — triggered when deployed artifacts require monitoring, rollback, reproducibility, or drift handling.
- Notebook strategy — conditional on [NOTEBOOK_STRATEGY]; include only when notebooks are used.

For general software concerns such as databases, APIs, frontend/backend boundaries, security, and deployment, use the base operating model rather than duplicating guidance here.

## Evaluation Guidance

Point at the base primitives for behavioral-vs-mechanical criteria, evidence-named evaluation, and the rule that self-evaluation is not independent validation.

DS-specific evaluation should name:

- Leakage and holdout discipline — what data is excluded from tuning, prompt iteration, retrieval construction, and manual exploration.
- Evaluator correlation — whether the same model, prompt family, author, dataset source, or labeling process appears on both sides of the evaluation.
- Non-determinism handling — require exact repeatability when the project can provide it; where exact repeatability is not realistic, use seeds, repeated runs, confidence intervals, thresholds, or qualitative review rules.
- Evaluation artifacts as review inputs — metrics when they are true eval metrics, property checks, deterministic thresholds, confusion/error slices, sample outputs, labeled examples, notebooks, logs, or reports needed to review the claim.

## Notebook Strategy

Include this section only when [NOTEBOOK_STRATEGY] declares notebooks part of the work.

Declare whether notebooks are exploratory scratch, review artifacts, reproducible reports, or source-of-truth analysis. If a notebook supports a PR claim, it must have a clear rerun path, named inputs, and outputs that map to [EVAL_METRIC] when one exists, [EVAL_CRITERION], or [EVAL_COMMAND].

## Domain Declaration

This profile has no default employer, industry, or regulatory regime. [DATA_REGIME] is declared per project and may name privacy, licensing, consent, retention, safety, or compliance constraints when they actually apply.
