# Global local search — 2026-10-14

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
