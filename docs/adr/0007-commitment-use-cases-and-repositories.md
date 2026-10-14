# ADR 0007: Commitment use cases and repositories

- Status: Accepted
- Date: 2026-09-20

## Decision

Repository interfaces live in application-facing code. UI and future adapters invoke use cases rather than mutating persistence tables. Commitment lifecycle commands are separate use cases: create, pause, resume, and archive.

The repository contract is asynchronous and persistence-agnostic. The initial in-memory implementation exists for domain/application tests only; Drift persistence is added in P07. Each use case reads the current aggregate, applies a domain transition, and saves the new value, preserving the no-silent-mutation rule.

## User-approved Undo extension — 2026-10-14

Undo is a confirmed application command with durable admission, not a widget snapshot or a global in-memory stack. Domain-facing repository contracts expose opaque operation tokens. SQLite writers acquire admission before reading current state and commit the mutation with an append-only versioned audit event. `undo_event_v1` records live in the established personal `schema_metadata` extension store; per-owner `undo_head_v1` keys identify the latest operation. No table/schema version change or new package is needed. Personal SQLite backup preserves events and heads. Only the latest eligible operation can be undone; Undo itself is audited and does not imply Redo or a multi-operation stack.

Commitment lifecycle Undo restores the recorded preceding status without changing metadata, financial or entitlement history. Archive restoration uses its recorded preceding status; old archives without that history retain the explicitly disclosed active-state restoration path. Earlier missing events are not synthesized. A dedicated history entry route keeps resolved/archived commitments reachable after snackbars expire.

Financial reversal uses the existing stable `reversal` enum with integer amount equal to minus the original signed ledger effect. Admission prevents repeated reversal and checks the complete fresh transfer group; cancellation reverses both transfer legs and recorded fees in one transaction, with explicit UI disclosure. Previously misclassified legacy compensations are not silently rewritten. Known legacy compensation references prevent further cancellation pending explicit recovery. Real match removal/correction preserves original allocations and does not reverse money.

Actual reopening is explicit for resolved and partial results, retains prior results and records the referenced latest Actual in audit. Append-count revisions reject stale/ABA occurrence snapshots; every production Details/Calendar reader carries that revision. Reopening changes no consumed entitlement or money. Durable reminder reopening intent distinguishes interrupted reopening from independent explicit reminder cancellation.

Date/time schedule edits record complete intermediate before/after evidence. Undo validates the latest token and a coherent snapshot, refuses past/changed/protected effects, retains identities and creates a forward schedule version for series restoration rather than erasing definitions. Dependent reminder intent commits before platform delivery. New materialization or other relevant changes may conservatively invalidate Undo; unrestricted recovery of such history is outside this slice.

Older binaries can read the unchanged schema but do not implement these semantic safeguards. Downgrade and concurrent older writers are not supported by this decision; no older-reader/writer release acceptance is claimed. Native reminder delivery and independent acceptance remain separate gates in [verification](../SCHEDULE_ACTUAL_VERIFICATION.md).
