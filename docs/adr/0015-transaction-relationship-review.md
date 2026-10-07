# ADR 0015 — Explicit transaction relationship review

Date: 2026-10-07

Status: Accepted for the user-approved bounded local relationship flow.

## Context

Absence of a real financial match does not distinguish an unreviewed transaction from a transaction deliberately unrelated to commitments. Suppressing any transaction with an active match also hides partially allocated remainders. Neither categories nor tags express relationship review.

## Decision

Use a separate append-only review history. The explicit Persian action «به تعهدی مربوط نیست» covers only the current unmatched remainder. It does not create a match, financial entry, occurrence result, expectation or tag/category change. Navigation and cancellation append nothing.

The domain [review projection](../../lib/features/reconciliation/domain/relationship_review.dart:38) captures transaction identity, amount/currency, active allocation fingerprint, retained allocation-history fingerprint, remainder and latest review revision. Canonical allocation fingerprints include stable identities, targets, values and resolved states, not only totals. A changed amount or allocation history invalidates an earlier independent decision without deleting it; resolved allocation history prevents an equal-total restoration from reviving old approval.

Undo and explicit reopening append a new decision. They do not remove matches or reverse money. Finance retains its relationship action for independently reviewed transactions; reopening enables later real linking. Today uses the domain projection for eligible unreversed income/expense remainders.

Production [review compare-and-append and allocation admission](../../lib/features/reconciliation/data/drift_reconciliation_repository.dart:133) reload durable state inside a database transaction. Review revisions are unique per transaction. Loaded form tokens reject stale confirmation; ordinary match writes also validate cumulative allocation against the durable amount, eligibility and effective review. Database serialization/transaction failure, not CommandGate alone, protects concurrent admission. Failed writes retain previous durable state and surface Persian retry feedback. No automatic retry can turn an old form into fresh user approval.

Schema 16 → 17 adds [review history](../../lib/core/database/app_database.dart:252), with transaction FK, value constraints, per-transaction revision index and append-only update/delete guards. Existing transactions start unreviewed; migration does not invent independent decisions. No dependency is added.

Personal snapshots preserve review history. [Backup compatibility](../../lib/features/backup/data/sqlite_backup_storage.dart:42) pins complete actual historical schema migrations to v17 and validates logical rows against the isolated current schema; it does not broadly waive constraints. Older-version exports remain incompatible with the current-version restore gate until an explicit tested restore migration policy exists; upgrading an installed database before export is supported. Encryption remains installation-bound.

## Consequences and scope

Independent remainder is review disposition, not full allocation or commitment settlement. Existing matches, balances and history are preserved. Repository admission disallows cumulative over-allocation until an explicit overpayment policy authorizes it; the pure-domain overpayment projection is not such authorization.

This does not add a review-history browser, match-correction UI, commitment-only targets, bulk allocation or overpayment authoring. Native accessibility, picker/Keystore and crash certification remain release gates. The test-only in-memory adapter is not a production durable source.

See [verification](../RELATIONSHIP_REVIEW_VERIFICATION.md) for tested scope and limitations.
