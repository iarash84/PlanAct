# Commitment checklists and search actions — 2026-10-14

## Integrated authoring acceptance — 2026-10-18

- Add Commitment keeps checklist items in the same draft and saves them with the
  commitment plan; cancelling or failing the commitment save leaves no orphan list.
- Details and editing expose the checklist inline. The action sheet does not expose
  a separate checklist route. Add, rename, reversible removal and restore retain
  the existing revision and owner checks.
- Today commitment cards show checklist progress and up to three active items.
  Checking or unchecking an item works from the card, visibly strikes completed
  text, and never changes commitment, occurrence, financial or entitlement state.
- Existing full checklist route remains a compatibility surface for direct links;
  it shares the same checked-item presentation and durable commands.

Evidence: `test/repository/commitment_checklist_test.dart`,
`test/unit/commitment_plan_use_case_test.dart`,
`test/widget/search_actions_checklist_test.dart`,
`test/widget/checklist_page_test.dart`, and focused Today/widget checks.

## Acceptance contract (before implementation)

- Entry/outcome: offline shell Search opens the existing commitment action sheet, including lifecycle, archive, durable Undo and Details; financial results open the existing Finance controls scoped to the selected record. Notes keep their sole existing action, revision-checked editing. Search query/filter/scroll survive returning; durable results reload after completed actions. Opening/cancelling does not write.
- Checklist entry: Add Commitment → Details section, then Details/editing inline. Create an ordinary commitment (for example a shopping list), then add named items, edit names, check/uncheck, remove with confirmation and restore removed items. The list belongs to the commitment, shared across its cycles/occurrences; there is no automatic recurrence reset, parent completion, attendance, reminder, financial or entitlement effect.
- Durable behavior: stable item IDs, monotonic list revisions and append-only snapshots in the existing metadata extension store. Fresh SQLite writer admission precedes owner/status/revision checks and atomic snapshot/head writes. Active/paused owners are editable; resolved/archived owners retain readable lists/history. Stale edits fail visibly and require reloading, without losing the visible failed draft. Closing an unsaved item dialog writes nothing. Each edit is an explicit save; checking is reversible by unchecking, removal by restoration.
- Errors: loading and retry, empty guidance, explicit save error/conflict and refresh. After a committed write, a read failure must be described as refresh pending rather than failed saving. No private text is logged.
- Compatibility: no schema/persisted-enum/dependency change. Legacy databases have an empty list. Personal SQLite backup preserves heads and all revisions; cold reopen and production backup validation/restore must retain logical state. Older readers ignore the extension; older writers do not enforce checklist semantics and are not approved for downgrade use.
- Evidence: pure validation/transitions; production SQLite stale-write, owner isolation/status, rollback, cold reopen and backup round-trip; actual shell Search → actions → mutation → refreshed result and checklist journeys; narrow RTL large text/light/dark. Independent review/native accessibility remain separate release gates.

## Path and minimum implementation

Add/Details or Search row → existing commands → transactional durable write → refresh the parent surface and root consumers. The full checklist route remains a compatibility surface; keep checklist outside scheduling/accounting models.

## Status

Implementation: **complete capability in the bounded scope above**. User confirmed
the shared commitment-owned list explicitly. Creation uses the existing Add flow,
followed by the inline Details checklist editor; no new commitment kind or
automatic lifecycle effect was introduced.

Changed files: shell/Details wiring in `lib/app/planact_app.dart`, Search presentation,
focused existing Finance presentation, new commitment checklist domain/application/
Drift/presentation files, Persian ARB/generated resources and catalog admission test.
The existing counted-progress route test now follows Search → actions → Details.
The PRD, AGENTS, design system, Search record and ADR 0024 record the contract.
No schema migration, persisted enum change or dependency was added. Version/release-workflow
changes already being made concurrently in the workspace are outside this task.

## Verification evidence

Automated evidence: Windows host; Flutter 3.47.5 / Dart 3.13.4; implementation begun
2026-10-14, verification continued 2026-10-17. Commands use the installed SDK
executables directly because the batch launcher could not acquire its cache lock
inside the repository sandbox.

| Contract | Evidence | Result |
| --- | --- | --- |
| Independent task identity, trim/validation, checked/uncheck, rename/removal/restoration, immutable earlier states | `test/unit/commitment_checklist_test.dart` | Passed |
| Owner isolation, fresh status/revision, competing writers, rejection of physical item removal, atomic rollback after history insert, cold reopen and unchanged occurrence/reminder/financial/credit tables | `test/repository/commitment_checklist_test.dart` | Passed |
| Legacy v17 migration into unchanged v18, production SQLite snapshot, encrypted BackupService + strict SqliteBackupStorage validation/restore, identical metadata and task identity | Same repository test | Passed |
| Shell Search → status/pause/archive → durable Undo restoring paused state; Details inline checklist editor; add/cancel/empty validation/check/rename/confirmed removal/restore/reopen; unchanged parent status | `test/widget/search_actions_checklist_test.dart` | Passed |
| Search → exact transaction/account controls (including equal IDs in separate account/entry tables) → cancelled confirmation makes no write; confirmed reversal; repeated cancellation unavailable; confirmed account archive; return refresh | Same widget file | Passed |
| Back cannot return a focused financial result while its admitted cancellation is still pending | Same widget file, delayed writer | Passed in focused run |
| Read failure/retry, a competing edit while dialog is open, retained failed draft, post-commit read failure shown distinctly without duplicate creation | `test/widget/checklist_page_test.dart` | Passed |
| 320×640 logical viewport, 2× text, Persian RTL, light/dark, scroll to add/edit, archive read-only; checkbox and action menu have distinct semantics nodes with Persian title/tooltip | Same widget file; semantics enabled | Passed; native shaping/screen-reader behavior is separate |
| Existing Search entry/edit/note cancellation and refresh, all result kinds, scroll/filter preservation, superseded reads and narrow layouts | Updated `test/widget/global_search_test.dart` | Passed |
| Final related matching/database/UI/localization/progress checks | Nine focused test files; local `build/verification/checklist-final-related.log` | **33 passed**, 45 seconds; includes corrected semantics-handle lifecycle, updated progress navigation and typed financial targets |
| Generated Persian copy; static analysis | `generate_persian_copy.dart --check`; `flutter analyze --no-pub` | Passed on final implementation; no analyzer issues |
| Repository formatting | `dart format --output=none --set-exit-if-changed lib test` | Passed; 401 files, zero changes |
| Full regression suite | `flutter test --no-pub --reporter expanded`; local `build/verification/checklist-all-tests.log` | Host Dart/Flutter out-of-memory crash; not a passing run |
| Full regression retry with bounded test concurrency | `flutter test --no-pub --concurrency=1 --reporter expanded`; local `build/verification/checklist-all-tests-sequential.log` | Native out-of-memory loading an unrelated test while another analyzer was running; stopped, not a passing run |
| Full regression with no concurrent verification process | Same command; local `build/verification/checklist-full-final.log` | 842 passed before a further native out-of-memory crash; one old progress test still expected direct Details and was updated for the requested action sheet, then passed in the 33-test final run. Full run is not passing evidence |

## Acceptance review and exposure

Self-review checks counterexamples against the contract: checking every item must
not complete a paused owner; a stale open item dialog must not overwrite another
task; archived status must be checked after writer admission; failure between
snapshot and head writes must roll both back; restored removed items keep their
checked state and identity; searching must await the status command; Back during a
financial write must not refresh Search before commit. Regression evidence is
mapped above. Missing checks in the prior Search contract were actionable result
navigation and command completion before reloading; the added route tests cover
those gaps without replacing command-layer financial/Undo tests.
Financial navigation retains kind as well as ID: account and transaction primary
keys belong to separate tables, so equal values must not expose both records.

Retained revision snapshots are durable audit data; this slice exposes current and
removed tasks, not a full revision-browser or arbitrary snapshot rollback. Items
have names and checked state, not quantities/prices, independent schedules or
automatic per-occurrence reset. Older writers are not approved for downgrade use.

Verification status: all 33 relevant automated checks passed; **full-suite
verification is incomplete** because of repeated host memory/paging exhaustion,
including an isolated single-concurrency run. No host memory settings or unrelated
holiday tests are changed. Owner: maintainer. Next action: rerun the full suite in CI
or a host with sufficient committed memory; the local failed-run logs above retain
the distinction between native crashes and assertions.

Independent acceptance review, Android build/device journeys, native screen reader
and Persian shaping are **unexecuted**. Owner: maintainer. Next action: review this
contract against final code/evidence, then run device journeys from Search and
Details (including large text and cancelled confirmation). Exposure decision:
requested local UI is exposed; **release acceptance is withheld** pending the full
regression, independent and device gates. This task does not publish a release.
