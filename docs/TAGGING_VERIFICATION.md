# Tagging integration verification

Checkpoint: 2026-10-06. Bounded local tagging flow; not native release sign-off.

## Scope and product path

Reusable optional tags classify commitments and account entries independently of status and transaction category. Production wiring uses the shared SQLite database; in-memory repositories are test/preview seams, not production authority.

- Commitment Details supports creating/reusing, assigning and detaching tags. Assignment persists immediately, with explicit Persian disclosure; metadata Save is independent.
- Today and commitment timeline rows display shared tag labels.
- Finance transaction actions open the record editor. Finance displays labels and supports one optional tag filter alongside existing filters. Clearing means all records, not just untagged records.
- Shared management supports global rename and explicitly confirmed global deletion. Detach affects one membership; global deletion removes the tag and both types of membership, never the classified records.
- Busy, empty, loading, retry, failure and success feedback are Persian. A committed mutation followed by failed refresh is reported as saved-but-not-refreshed, rather than inviting a duplicate mutation.

Not claimed: multi-tag filters, broad commitment search/filter UI, tag-specific report UI, automatic copying of memberships to corrected/new ledger entries, or native/device acceptance.

## Persistence, legacy and identity decisions

The existing tag table and typed commitment/account-entry link tables remain the durable source of truth. Rename retains the stable ID and creation time, so memberships and active filters are not keyed by mutable display text. Labels trim surrounding whitespace and a leading hash; normalized uniqueness folds Latin case. Creation reuses a normalized existing label; rename to another existing key fails rather than merging silently. Autocomplete treats SQL wildcard characters literally.

Existing commitment metadata/lifecycle saves preserve canonical memberships rather than writing stale label snapshots back into links. New commitments may seed memberships from their initial labels. The legacy commitment label column is a rebuildable projection updated transactionally with attach/detach/rename/remove; it is not a second authority and cannot resurrect deleted labels on later saves or restart. Existing migration behavior is retained, not replaced by a new read-time legacy backfill.

Global tag deletion is deliberately not deletion of commitment, occurrence, actual, financial or entitlement history. Recreating a deleted label creates a new identity. Projection failures roll back the whole mutation. CommandGate admission/retirement is reused; it is not a claim of general command serialization.

**No schema version, migration, dependency, backup format or stable-ID algorithm change.** No new sensitive logging. The PRD now records the product contract and bounded checkpoint. The repository contract needs no change: existing persistence, identity, transaction, history and confirmation safeguards already apply.

## Test evidence

- [Repository lifecycle tests](../test/repository/tag_lifecycle_test.dart): file-backed close/reopen; typed memberships; stable rename identity/time; archived commitment and completed occurrence history; stale metadata/status saves; detach/delete without resurrection; exact ledger/actual/occurrence preservation; injected projection failure rollback.
- [Repository contract tests](../test/unit/tag_repository_test.dart): normalization, duplicate rejection, literal autocomplete, typed/idempotent membership and retired-gate rejection for the supported adapters.
- [Shared control tests](../test/widget/tag_controls_test.dart): assign/detach isolation, global deletion confirmation/cancel, rename/editor refresh, busy duplicate prevention, failure recovery, load retry and Finance filter clearing.
- [Commitment integration](../test/widget/commitment_tags_test.dart): persisted detach followed by metadata Save preserves the edited title without resurrecting membership.
- [Details journey](../test/commitment_details_test.dart): independent details route, persisted metadata and unsaved-change protection.
- [Finance critical journeys](../test/widget/finance_tags_test.dart): Light and Dark RTL transaction menu → create/assign → management rename → detach → empty tag filter → clear. SQLite memberships, stable ID/time and exact unchanged ledger rows are asserted.

The two original integration failures were viewport/focus assumptions, not missing persistence: the tag region pushed Save outside the lazy viewport and scrolling to tags disposed the title field. Tests now scroll the outer page, select semantic fields/buttons, finish text input and settle scroll/snackbar transitions. No persistence, title, membership or refresh-count assertion was removed and no oversized test viewport was used.

## Backup impact

Existing [full-state backup tests](../test/repository/backup_full_state_test.dart) explicitly seed tags, commitment memberships and account-entry memberships and compare every persisted table after encrypted restore/rollback and cold restart. These tests are reused, not replaced by an in-memory backup claim. Existing backup application-scope tests cover command draining and repository/UI generation rebinding. Tagging adds no portable platform state or backup-format change.

This does not close the installation-bound key recovery, migrated-schema compatibility or isolated native picker/Keystore/crash gates documented in [ADR 0013](adr/0013-production-backup-restore.md) and the PRD.

## Proportional visual coverage

| Surface | Review status | Evidence / scope |
| --- | --- | --- |
| Shared record editor and management sheets/dialogs | Compliant | Shared Material themes, spacing and semantic typography; Persian disclosure, selected chip state, labeled icon actions, confirmation and retry; Light/Dark widget coverage |
| Commitment Details | Compliant | Existing scrollable metadata flow plus shared editor; persisted detach/save integration |
| Today and timeline rows | Compliant | Shared read-only labels, no feature-local palette or new status meaning |
| Finance | Compliant | Shared labels/filter/editor; critical journey in both themes with RTL and unchanged ledger |
| Quick Capture, quick financial entry, full income/expense form | Migrated | Shared draft-only tag picker; Persian save/cancel disclosure, normalized selected chips, review/retry coverage in Light/Dark RTL |
| Calendar, Settings, root navigation | Intentionally Unchanged | No shared theme change; creation callbacks are wired without changing unrelated navigation/settings work |

No palette, font, motion or component-theme redesign. Automated Light/Dark journey success is not measured contrast, narrow-device text scaling, keyboard or screen-reader acceptance.

## Validation and remaining gates

Original editing-flow validation (before the creation-time extension below):

- Dart formatting: all 14 changed Dart files formatted; follow-up check reports 0 changed.
- Flutter analysis: no issues found.
- Full Flutter suite: **328 passed, 0 failed** (final run 1 minute 19 seconds), including existing full-state backup tests. The initial targeted reproduction had 2 passing and 2 failing tests; both failures are fixed without removing assertions. Two new Finance theme journeys raise the full-suite total from 326 to 328.
- Git whitespace check: passed. Final working tree contains 9 modified and 7 new files for the combined tagging change; no schema/dependency files changed.

Real-device Persian shaping/text scaling, touch/contrast and accessibility, keyboard/IME and sheet behavior remain independent acceptance checks. Native backup, reminder, app-lock and SMS gates are unchanged; no Android build or device exercise is claimed for this checkpoint.

## Creation-time extension — 2026-10-06

The shared draft picker reads reusable labels and retains selected/new labels only in the creation draft. It does not call tag creation or attachment commands. Cancellation therefore leaves no new label or membership. Editing existing records keeps its immediate-save semantics. Normalization and typed stable identities reuse the existing tagging model; no hidden default tag is introduced.

Quick Capture exposes the picker in the basic step and labels in review; all commitment creation entry points use this same flow. Quick income/expense and the full Finance form also use it. More Options carries draft tag selections into the full form. Quick creation now waits for persistence before dismissing; failed writes retain the draft for retry. Committed creation followed by a refresh failure is distinguished from failure to save.

Commitment creation reuses the existing transaction encompassing commitment tags and the plan. Finance uses an explicit atomic-creation capability: the Drift adapter writes the ledger entry, normalized tags and typed memberships in one transaction. Unsupported adapters reject tagged creation before writing an entry, rather than attempting best-effort links. Account choices are snapshotted for the form so background refresh does not invalidate the selected account during sheet dismissal.

Creation scope is commitments and expense/income entries; transfer creation and automatic tag propagation to financial corrections remain unchanged. No schema, migration, package dependency, backup format or architecture policy change is needed. Existing full-state backup coverage remains applicable to the same tables.

Additional evidence:

- [Creation repository tests](../test/repository/tagged_creation_test.dart): file-backed restart with shared normalized identities and typed links; injected attachment failure rolls back commitment/plan or expense, labels and links; retry creates exactly one record; unsupported adapter fails before writing.
- [Creation widget tests](../test/widget/tagged_creation_test.dart): Light/Dark RTL draft reuse, normalization/deduplication, removal and cancellation without writes; commitment review and retry preserve tags; quick income/expense retry preserves tags; full income/expense atomically persists initial and new selections.
- Full local suite after this extension: **363 passed, 0 failed**, including existing editing, migration, backup/restore, quick creation and concurrent Today/settings/Finance regression tests. Flutter analysis reports no issues; changed Dart files are formatted.

This checkpoint is local automated evidence, not Android/device acceptance. Unrelated concurrent Today/settings/navigation/transaction-direction changes are preserved.
