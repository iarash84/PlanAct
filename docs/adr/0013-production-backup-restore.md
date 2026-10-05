# ADR 0013 — Production encrypted backup and restore

Status: Implemented adapter design; release verification remains partial.

## Decision

Use the existing format-1 AES-256-GCM orchestration with production SQLite,
secure-storage, and user-selected file adapters. No database migration or backup
format change is introduced. sqlite3 is now a production dependency;
flutter_secure_storage 9.2.4 supplies platform key storage (encrypted Android
shared preferences backed by platform security).

Export alone provisions a random 256-bit installation key. Import never creates
or substitutes a key. The key is not included in the package. Consequently this
implementation supports recovery only while the original installation key
remains available. Uninstall, device loss, or transfer to another device may make
a package unrecoverable. Persian export/import confirmation states this
limitation. Portable key recovery requires a separate approved product/security
decision; this implementation must not be described as complete device-loss
protection.

## Snapshot and privacy

VACUUM INTO creates a consistent snapshot containing every SQLite table, not a
hand-maintained selection of entities. Export redacts staged_imports.raw_text and
removes platform notification IDs only in the isolated snapshot. Secure deletion
and VACUUM remove raw SMS from free pages. Other durable records and settings
remain present. Private rollback snapshots preserve raw SMS because rollback
must preserve the user's original logical state. Files remain in application
private storage; no sensitive values or SMS are logged.

The serialized encrypted export is decoded, validated, decrypted and validated
as an isolated SQLite file before the file picker receives it. Restore verifies
format, ciphertext checksum, authentication, size, schema version, canonical
sqlite_master declarations, schema metadata, integrity_check and
foreign_key_check before live replacement. Read-only validation never migrates
the live database.

## Ownership and recovery

The application scope suspends and disposes its feature/widget scope before
restore. It owns database close/reopen and recreates repository/UI references.
Before activation it writes and flushes a validated private safety snapshot,
validated candidate and recovery marker containing the safety SHA-256 digest.
Replacement uses same-directory rename after closing the Drift owner and removing
SQLite sidecars. Any restore failure attempts safety replacement and rebind;
failed recovery retains the marker and prevents displaying the candidate.
Startup checks the marker before opening the live database and conservatively
restores the original snapshot. Commit removes the marker only after reopen and
reminder rebuild. Dart file flushing and rename are used; full directory-fsync
power-loss durability has not been demonstrated on Android.

Notification queues are cleared during restore and crash recovery, then rebuilt
from persisted rules/instances. Resolved occurrences cannot regain active
notifications. Delivered notification history is preserved.

## Known limitations / release evidence

- Version-16 compatibility accepts only the fresh schema or complete trusted
  schema signatures produced by real committed historical migrations. Twelve
  historical fixtures cover fresh v10–v15 and sequential migration chains.
  Legacy rows are also copied into an isolated current schema to enforce current
  constraints, including previously undeclared foreign keys. Unknown signatures,
  mixed declarations and schema tampering remain rejected; this is not general
  acceptance of arbitrary version-16 databases.
- A file-backed host widget test proves full-command drainage through a delayed
  platform effect, disposal of the old application state, stale repository
  rejection and a fresh database/repository generation after cancellation. Gate
  unit tests also cover nested and unawaited work. Platform effects in this host
  test are controlled, not native Android evidence; restore/recovery integration
  with production platform listeners still requires device verification.
- Real file-backed tests cover encrypted repeated restore/reopen, corruption,
  incompatible/incomplete schema, FK violations, rebuild rollback, crash marker
  recovery, damaged safety, snapshot SMS privacy and write-stage failures.
  Secure-key tests mock platform storage; Settings tests mock file actions.
- The full-state file-backed fixture populates all 23 persisted tables and
  compares every logical row after encrypted restore and cold reopen, as well as
  after an injected rebuild failure and rollback. It includes archived records,
  entitlement grant/consume/restore, replacement chains, financial transfer and
  reversal, corrected matches/allocations, actual/evidence, tags, inbox and
  settings. The only expected export differences are raw SMS redaction and
  removal of platform notification IDs. Fixture coverage fails when a new table
  is introduced without corresponding populated data. This proves persistence,
  not every possible domain scenario or native notification outcome.
- Native picker, Keystore, notification permission failures, process killing,
  and Android filesystem power-loss behavior require an isolated test install.
  The connected personal-data installation must not be used for this testing.

This ADR records the implemented seam and limitations; it does not waive the
PRD backup release gate or claim Priority 1 is fully verified.
