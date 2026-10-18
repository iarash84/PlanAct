# Global local search — 2026-10-14

## Review fixes acceptance contract — 2026-10-17

- Search → commitment status action → snackbar Undo → existing confirmation and
  transactional command → shell revision notification → reload the current search
  snapshot. Confirmed Undo must update visible status without resetting query,
  kind filter or scroll. Cancelled/failed Undo must retain the existing command
  behavior. Read failures remain visible with Retry. Detach revision listeners on
  replacement/disposal, and retain the existing awaited reload while opening a result.
- Search → focused Finance: read no entry-tag memberships for an account and only
  the selected entry's memberships for a transaction. Preserve the full accounts
  and ledger used for balances, reversal detection and command admission; preserve
  general Finance filtering, tag editing and refresh behavior.
- Scope: presentation invalidation and membership selection only; no command,
  persistence, migration, backup format, dependency, copy or visual changes.
- Evidence required: production SQLite shell Undo confirmation/cancellation;
  query/filter/scroll retention and listener disposal; 1,000-entry focused financial
  reads with correct balance, tags and reversal controls; all repository tests,
  static analysis, formatting and generated catalogs. Native device performance
  and independent release acceptance remain separate, unexecuted gates.
- Prior coverage gap: awaited result actions did not exercise a later snackbar
  Undo, and the focused financial journey had no membership-query budget.

### Fix implementation and focused evidence

`lib/app/planact_app.dart` supplies the existing shell revision to Search.
`lib/features/search/presentation/search_page.dart` subscribes/detaches safely and
invalidates its transient snapshot. Notifications during result opening reuse the
existing awaited reload, avoiding duplicate reads; query/filter/scroll stay intact.
`lib/features/finance/presentation/finance_page.dart` limits only membership reads:
none for a focused account, the selected ID for a focused entry, all entries for
general Finance. Full account/ledger reads and all write commands are unchanged.

Focused evidence: 18 tests passed in 41 seconds on Windows with Flutter 3.47.5 /
Dart 3.13.4. The tests are `test/widget/search_actions_checklist_test.dart`,
`global_search_test.dart`, new `focused_finance_reads_test.dart`, and unchanged
`finance_tags_test.dart` / `finance_loading_test.dart` in the same directory.
They cover confirmed/cancelled snackbar Undo with production SQLite; external
read failure/Retry, listener replacement/disposal, no duplicate reads while
opening and retained scroll/filter/query; and 1,000 persisted entries split across
two accounts with a tagged reversed transaction. Account membership reads are
zero and entry reads are one per refresh; the expected full-ledger balance is
-49,900 IRR, reversal controls stay unavailable, and all 1,000 rows remain identical.
Existing general Finance tag/filter/edit/detach and failure feedback checks pass.

Self-review checks the two plausible shortcuts explicitly: truncating the ledger
would break the independently expected balance/reversal assertions; refreshing
only after the first result action would still fail the actual snackbar Undo
journey. No migration, dependency, persisted audit/backup change or new copy.

### Final verification for the fixes

- Full regression: **1,040 passed, zero failed, zero skipped**, all 201 test files
  run in 21 sequential batches of at most ten files, each with
  `flutter test --no-pub --concurrency=1 --reporter=json`. No memory crash, excluded
  test or weakened assertion; logs and machine summary are under the local ignored
  `build/verification/search-review-fixes-2026-10-17/` directory.
- `flutter analyze --no-pub`: no issues. `dart format --output=none
  --set-exit-if-changed lib test`: 402 files, zero changes. Both generated Persian
  copy and reviewed holiday catalog checks passed. `git diff --check` passed.
- Implementation and automated verification: complete for these two defects.
  This result supersedes earlier incomplete full-suite records for this working
  tree; it does not replace their independent/native acceptance gates.
- Android build/device latency, native accessibility and independent review are
  unexecuted. Owner: maintainer; next action: review the limited diff and run the
  affected device journeys with a stated reference-device budget. Exposure:
  existing local routes remain available, no release/publishing is performed and
  product release acceptance remains withheld under the existing feature gates.

## Requested action extension — 2026-10-14

The later user request supersedes direct commitment editing/read-only production
financial navigation below: selecting a commitment now opens its existing action
sheet (complete/pause/resume/cancel/archive/restore/durable Undo, according to fresh
status), Details/edit and commitment checklist. The sheet returns an awaited action;
Search reloads only after it completes. Selecting a financial entry/account opens
the existing Finance controls scoped to that exact ID, with fresh repository reads,
correction/cancellation, tags/relationship review or account edit/archive/restore.
Notes retain revision-checked explicit editing, their existing supported action.
No generic archive/status is invented for notes or financial ledger history.

Browsing remains read-only; only explicit existing commands mutate. Query, filter
and scroll survive return, and root surfaces refresh. See the before-implementation
[contract and final evidence](CHECKLIST_VERIFICATION.md) and route regressions in
`test/widget/search_actions_checklist_test.dart`. Historical evidence below describes
the original search checkpoint; it is not evidence for this extension.

## Acceptance contract (before implementation)

- Outcome/entry: the shared shell AppBar opens Persian RTL search from every root tab, without permissions, internet or account. Search current durable commitments (including archived/resolved), financial entries of every type, independent calendar notes and accounts. Search title/name, description/note, category, linked account name and classification labels. All words must match; Arabic/Persian Yeh/Kaf, diacritics, whitespace/half-space, letter case and Persian/Arabic/Latin digits are equivalent for matching only.
- Success: selectable type filters, deterministic results, lazy result rows, clear-query and empty guidance. Selecting a commitment opens existing Details; a note opens the existing revision-checked editor; financial results expose exact amounts, date, account and historical type in read-only details. Back retains query/filter/scroll. Returning from details reloads durable data and refreshes affected root surfaces.
- Failure/retry: initial/read/open failures have visible Persian feedback and retry. Superseded reads cannot replace a newer result. Navigating or searching writes no domain data; editing notes requires the existing explicit Save. No search history is persisted or logged.
- Data: production reads one SQLite snapshot behind an application reader and the backup command gate. No schema, migration, dependency, backup format or financial/calendar/entitlement semantics change. Notes search current heads, never historical revisions. Restart rebuilds search from repositories.
- Bounds/non-goals: text search over the four named record types; no raw SMS, attachments, generated future occurrence previews, semantic/cloud search, monetary-unit interpretation or persistent index. Result type/status remain explicit. The transient index is rebuilt on entry, refresh and return from details.
- Evidence: pure matching/filter/order tests; production database read-only/cold-reopen tests; real shell → search → details/edit → Back refresh journey; loading/failure/retry/stale-response and narrow/large-text light/dark widget checks. Device performance and independent acceptance are separate gates.

## Existing path and minimum implementation

Shell AppBar → SearchPage → SearchReader → repositories / transactional Drift snapshot → pure transient search projection → lazy result list → existing Details / note Save command or read-only financial details → re-read search + root refresh. Search has no durable write. Preserve existing mutation admission and note revision checks.

## Verification status

Implementation: **complete capability in the four-record-type scope**. The shell entry, read-only projection, existing edit routes, financial details and retry paths are wired. No migration or dependency was added; existing note backup/history semantics remain unchanged.

Changed files: `lib/features/search/{domain,application,data,presentation}/`, shell wiring in `lib/app/planact_app.dart`, current-head listing in the note repository contract/adapters, `lib/l10n/app_fa.arb` and its generated Flutter resources. Product/design/agent contracts are updated. Tests live in `test/{unit,repository,widget}/global_search_test.dart`; the existing note fake and localization catalog admission list were extended.

Automated evidence (Windows host, local working tree, 2026-10-14):

| Contract | Evidence | Result |
| --- | --- | --- |
| Persian matching, literal query symbols, all-word matching, ranking, kind filters, source preservation | Pure tests, including 10,000 transient documents without result truncation | Passed; this is correctness evidence, not an Android latency budget |
| Durable current state, archived records, all eight entry types, linked classifications, current note revision only, no ledger/reminder/entitlement writes | Production SQLite test with file close/reopen and before/after metadata and ledger comparison | Passed |
| Shared shell entry, Details, financial/account amounts, explicit note Save, cancelling an unsaved draft without a new revision, return refresh to Search and Calendar | Real `PlanActApp` with production repositories | Passed |
| Initial read failure/retry, open failure/recovery, empty/clear, latest query and superseded-read rejection | Controlled reader widget journeys | Passed |
| Persian RTL, 320×640 logical viewport, 2× text, light and dark themes, scroll to results | Widget layout journeys with 101 records | Passed; device shaping/screen-reader checks remain separate |
| Static analysis and generated Persian copy | `flutter analyze`; `dart run tool/generate_persian_copy.dart --check` through the installed SDK executables | Passed |
| Final focused matching/database/UI/localization run, including scroll/query/filter preservation after reload | The four focused test files above | 17 passed |
| Repository formatting | `dart format --output=none --set-exit-if-changed lib test` | Passed; 385 files, zero changes |
| Full regression suite | `flutter test --reporter compact` through the installed SDK; local report: `build/verification/search-final-all-tests.log` | 1,009 passed in 8m04s |

Self-review is separate from the implementation claim: searching all dates must not resurrect old note revisions; archive must stay visible without becoming active; reversal/transfer entries must retain their integer signs and type; query operators must not execute SQL; a late read must not replace newer state. The corresponding automated checks are recorded above. A further counterexample is joining independent fields into a fabricated query word; the projection keeps field separators and has a dedicated regression check. Search loading ends before the note editor opens, so the modal does not retain a running background progress animation.

Independent review, Android release build, device keyboard/screen-reader/shaping and performance checks are **unexecuted**. The 10,000-record test does not measure production snapshot latency; production currently reuses the commitment repository's per-owner tag reads. Owner: maintainer. Next action: review this contract against the final working-tree evidence and perform a mixed-record device run with a stated reference device and latency budget. Exposure decision: the local implementation exposes Search in the shell as requested; **release acceptance is withheld** until required device evidence and independent acceptance are recorded. No deployment/release is performed by this task.
