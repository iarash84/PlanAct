# ADR 0006: Commitment cycle completion semantics

- Status: Accepted
- Date: 2026-09-20

## Decision

`CommitmentCycle` represents a term, package, or active period belonging to a stable `Commitment`. It stores `plannedEndDate` and `actualEndDate` separately and supports the cycle types required by the roadmap: open-ended, fixed date range, fixed count, manual package, and hybrid.

Completion rules are explicit:

- `ByDate`: planned date is reached.
- `ByUnits`: target units are consumed.
- `WhicheverFirst`: either condition is reached.
- `WhicheverLast`: both conditions are reached.
- `Manual`: only an explicit domain command completes the cycle.

A cycle has its own status and does not infer or mutate the parent Commitment status. Invalid configurations and transitions are rejected in the domain.
