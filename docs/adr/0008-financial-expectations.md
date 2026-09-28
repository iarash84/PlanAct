# ADR 0008: Financial expectations

## Decision

Financial expectations are optional, per-occurrence records. They store integer minor units, an optional currency, an optional durable account reference, direction, and archive status. They do not create a second transaction model.

A bounded recurring schedule creates one expectation only when the user explicitly assigns it; recurrence generation does not fabricate amounts or currencies. Schema 11 adds the table through an additive migration from schema 10, leaving all historical records unchanged.

Settlement is independent of activity completion. It is derived from active `MatchAllocation` records targeting the occurrence; corrected or reversed matches do not settle an expectation. Account entries and transaction matches remain the sources of financial history.

Archiving is reversible history-preserving state, not deletion. Archived expectations are excluded from active outstanding/settled queries but remain in backups and history.

## Consequences

- Missing currency remains missing and cannot be used to infer settlement.
- A later transaction correction changes settlement without mutating the expectation.
- Backup/restore must carry expectation rows and nullable fields; platform notification identifiers are unrelated and omitted.
- The UI must ask for amount explicitly and must not assign a hidden default.
