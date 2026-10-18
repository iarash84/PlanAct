# 0024 — Commitment-owned checklists

User request: 2026-10-14, a commitment may contain tasks such as a shopping list.

Use a separate commitment-owned checklist with stable item IDs, checked and removed
states, monotonic revisions and retained snapshots. It is shared across occurrences,
not a recurrence template. Checking all items never completes the owner or records
an occurrence, payment or entitlement consumption. Explicit existing lifecycle
commands remain authoritative. Resolved/archived lists remain readable.

Reuse the versioned metadata extension store, as with calendar notes, instead of
adding fields to every existing commitment reader/writer. A transactional writer
checks fresh owner status and expected revision before appending a snapshot and
advancing its head. No physical schema migration or persisted enum changes.
SQLite personal backups include this store. Legacy databases read as empty;
schema compatibility does not approve older writers that ignore these semantics.

Removal is reversible tombstoning, never history deletion. Editing is explicit and
stale writes require refresh. This scope excludes nested tasks, item reminders,
quantities/prices, automatic parent completion and per-occurrence reset.

Acceptance/evidence: [checklist verification](../CHECKLIST_VERIFICATION.md).
