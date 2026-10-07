# Transaction relationship review — focused verification

Date: 2026-10-07. Status: implemented for the bounded local review journey; not a native release sign-off.

## Product path and decisions

- [Domain projection](../lib/features/reconciliation/domain/relationship_review.dart:38) separates independent-remainder disposition from actual financial matches, category and tags. Partial matches leave only their outstanding remainder in Today. A new amount/allocation history invalidates an old independent approval without deleting it.
- [Application contract](../lib/features/reconciliation/application/relationship_review_repository.dart) and [contextual commands](../lib/features/reconciliation/application/contextual_reconciliation.dart) carry loaded snapshot tokens. [Production admission](../lib/features/reconciliation/data/drift_reconciliation_repository.dart:133) compares fresh state transactionally. Cumulative matching is guarded even outside the contextual form.
- [Persian relationship flow](../lib/features/reconciliation/presentation/transaction_relationship_page.dart:112) explicitly confirms «به تعهدی مربوط نیست», shows reviewed disposition, supports Undo and reopening, preserves drafts on failure, and prevents duplicate busy actions. Back/cancellation without a decision writes nothing; back after a decision refreshes Today.
- [Today classification](../lib/features/today/application/attention_engine.dart:420) uses eligible unreversed income/expense remainders and durable review history loaded by the [composition root](../lib/app/planact_app.dart:364). Transfers, adjustments and reversal entries are not review obligations.
- Existing [Finance transaction relationship action](../lib/features/finance/presentation/finance_page.dart:864) remains available for independently reviewed entries; reopening there permits later real linking. No separate Finance badge/history browser is claimed.

Financial amounts, account balances, existing matches, occurrence results, expectations, category and tags are not changed by review commands. No new dependency or sensitive logging is introduced. See [ADR 0015](adr/0015-transaction-relationship-review.md).

## Persistence and backup

[Schema 17](../lib/core/database/app_database.dart) adds append-only review rows with transaction FK, constraints and unique monotonic per-transaction revisions. The forward migration preserves older financial/history data and does not infer past review decisions. Generated Drift bindings are updated.

[Trusted backup compatibility](../lib/features/backup/data/sqlite_backup_storage.dart:42) includes actual v10–v16 historical fixture migrations to v17, retaining full-schema pins and isolated current constraint validation. [Full-state encrypted round-trip](../test/repository/backup_full_state_test.dart) preserves the new history, and [review repository tests](../test/repository/relationship_review_test.dart) verify effective review reconstruction after backup. Personal snapshot redaction does not remove review history.

Old-version exports are not directly imported by the current-version gate; installed database upgrade then export is supported. Encryption remains installation-bound, not portable device-loss recovery. Other native backup release gates are not waived.

## Evidence

- [Domain tests](../test/unit/relationship_review_test.dart): remainder projection, identity/history fingerprints, invalidation, revisions and in-memory review behavior.
- [Repository tests](../test/repository/relationship_review_test.dart): cold file-backed restart, stale tokens, duplicate decisions, separate-connection races, allocation admission, correction rollback, append-only guards and backup reconstruction.
- [Historical migration fixtures](../test/repository/relationship_schema_fixture_test.dart) and [backup compatibility tests](../test/repository/sqlite_backup_schema_compatibility_test.dart): real migrations, v16 fixture, strict rejection of tampered schemas and invalid rows.
- [Attention tests](../test/unit/attention_engine_test.dart) and [critical widget journeys](../test/widget/contextual_reconciliation_test.dart): partial remainder, independence, reopening/relinking, Undo, no candidates, no review on back, stale failure/draft retention, loading, Today refresh and durable suppression after app reconstruction.
- Final Flutter analysis: **no issues found**.
- Final complete Flutter test suite: **404 passed**.
- Changed Dart file format check: **22 files, zero changes**. Diff whitespace check passed.
- Whole-repository non-writing format check also identified pre-existing formatting differences in [occurrence tests](../test/unit/occurrence_test.dart) and [series-editing tests](../test/unit/series_editing_test.dart). They were deliberately left unchanged; no claim of repository-wide formatting compliance is made.

## Proportional visual coverage

| Surface | Status | Evidence/scope |
| --- | --- | --- |
| Relationship page | Migrated | Theme-owned Material actions, Persian copy, semantic live errors, busy state, Undo/reopen; Light/Dark, RTL and 1.8× text scale widget checks |
| Today | Migrated | Domain-derived remainder/independent classification; existing row visuals retained |
| Finance | Intentionally Unchanged | Existing relationship action opens reviewed entry; no new component or local design variant |
| Shared theme/components | Intentionally Unchanged | Existing styles/tokens reused; no global visual change |

## Remaining scope and limitations

No match-correction authoring UI, bulk allocation, commitment-only target, explicit overpayment policy or review-history browser was added. Old independent decisions stay inspectable in durable history but are not presented as a new timeline UI. Pure-domain overpayment calculations do not authorize persisted over-allocation. A stale form requires explicit reload/retry; no silent approval retry is performed.

Automated checks are not native-device accessibility, screen-reader, lifecycle/crash, picker or Keystore certification. Native release evidence and broader backup recovery remain separate existing gates.
