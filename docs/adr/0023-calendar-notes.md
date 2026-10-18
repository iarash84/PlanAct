# 0023 — Independent date-only calendar notes

Status: accepted for the user-requested 2026-10-14 scope.

Notes have a title, optional description, civil LocalDate and a named shared
identity color. They have no commitment lifecycle or generated side effects.
Reusing a commitment/occurrence would incorrectly add overdue, outcome, financial
or reminder semantics. Calendar composes notes alongside commitments instead.

Use the existing versioned `schema_metadata` extension seam, with separate
`calendar_note_head_v1:ID`, `calendar_note_day_v1:YYYY-MM-DD:ID` and append-only
`calendar_note_revision_v1:ID:REVISION` records. The day prefix supports bounded
range reads using the existing primary-key index. Heads and day indexes are
rebuildable from snapshots; commands take fresh SQLite writer admission and compare
the expected revision before atomically appending history and updating projections.
No schema, persisted enum, native reader or dependency changes are required.
The domain/application contract remains independent of Drift and Flutter.

SQLite personal snapshots preserve the records. Old binaries ignore these keys;
that is not semantic acceptance of downgrade writes or old-backup replacement.
No data conversion of existing commitments is authorized. General-purpose rich
notes, deletion/restore and search are outside this bounded delivery. A future
dedicated table requires a forward migration and explicit backup compatibility.
