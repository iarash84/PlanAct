# Calendar notes — 2026-10-14

## Acceptance contract (before implementation)

User outcome: Global Add → «یادداشت» opens a Persian RTL form with a required
title and explicitly chosen Jalali date, optional description and identity color.
No account, permission or network is required. Notes are independent local-date
records, never commitments, occurrences, actuals or reminders. Past dates are valid.

Save validates input, blocks duplicate submission and editing while pending, and
preserves input on failure for retry. Cancel writes nothing. Selecting a note in
Calendar opens the same form for explicit editing. Concurrent stale edits fail
without overwriting newer data. Month markers/day list and Week agenda/wide all-day
region show the chosen color, note identity and full accessible title. Reading and
changing notes never creates notifications, alarms, money, entitlement, overdue or
completion effects. Existing commitment behavior remains intact.

Trace: Add sheet → note editor → SaveCalendarNote → CalendarNote validation →
transactional repository revision append + current head/date index → Calendar
bounded range reload → month/week and editor. Note storage participates in the
existing database command gate and personal SQLite backup, surviving cold reopen.
Date changes retain earlier snapshots; date-only values never become UTC instants.

Scope: create, read and edit one-date notes, shared identity palette, month/week,
local durability and backup preservation. No recurrence, time, reminder delivery,
completion, financial/report/Today attention integration, attachments or deletion.
Evidence: domain validation; production persistence, stale writers, date moves,
cold reopen, snapshot preservation and legacy database coexistence; actual global
Add → save → calendar → edit widget journey; month/week color and RTL layout.

## Status / acceptance review

Implementation: complete within the create/read/edit scope above. Storage uses the
existing schema-18 metadata extension; no schema migration, native adapter or
dependency was added. No existing commitment/holiday/financial data is converted.

Automated evidence (Windows host, 2026-10-14):

- `test/repository/calendar_note_test.dart`: 3 passing tests cover domain title
  validation, same-database competing repository revisions, atomic rollback after
  injected head-write failure, date-index movement, original snapshot retention,
  cold reopen, command-gate retirement and absence of occurrence/reminder/financial/
  entitlement effects. A committed v17 fixture migrates normally; production
  redacted SQLite snapshot + encrypted restore preserves every metadata row and
  legacy data. This is host evidence, not fresh-install native backup acceptance.
- `test/widget/calendar_notes_test.dart`: 7 passing tests cover actual production
  global Add → title/date validation → Jalali confirmation → color → save → Month
  marker → Week → edit → durable revision/UI refresh; dark/light at 320dp with 2×
  text and 1100dp with 1× text; canceled/failed/stale saves and pending input lock;
  stale Month results and Month/Week read failure/retry. The bounded layout fixture
  has one long-title/description note; no large-volume performance claim is made.
- Updated `test/widget/quick_add_sheet_test.dart` expects the new supported action.
- `test/unit/localization_resources_test.dart`: 4 passing tests after marking new
  messages `calendar-note-2026-10-14`. They are excluded from the frozen historic
  translation hash, following the existing introduction-marker convention; all
  descriptions and placeholder contracts still undergo the same validation. The
  historic hash and pre-existing messages were preserved.
- `flutter analyze`: no issues. Scoped `dart format --output=none
  --set-exit-if-changed ...` and `dart run tool/generate_persian_copy.dart --check`:
  pass. The full `flutter test --reporter compact` run completed with 995 passed
  and one failed: the frozen translation baseline initially included the new note
  messages. The introduction-marker fix above preserves the historic hash; the
  localization file then passed all 4 tests. Final focused acceptance rerun:
  `flutter test test/repository/calendar_note_test.dart
  test/widget/calendar_notes_test.dart test/widget/quick_add_sheet_test.dart
  test/unit/localization_resources_test.dart`: **17 passed**. The entire 996-test suite was not rerun after that metadata/test
  classification fix; the original full run is not recorded as green.

Self-review against the contract: date stays civil through editing/reopen/restore;
note heads never enter commitment consumers; old edits cannot overwrite the fresh
revision; delivery permissions and APIs are absent from the note command. A first
large-text/wide-calendar test found the initial horizontal tile could put the tap
center outside its visible region. The tile now gives the title the full width,
bounds description previews and retains the full editor text. Both layout and
tap checks pass. The missing check was reachability inside the Week all-day area,
not just widget existence.

Independent acceptance, native device Persian shaping/screen-reader/large-text
and fresh-install backup journeys remain unexecuted. Owner: product maintainer;
next action: run the above journey on the release device and review the contract
independently. Exposure: available through Add in this development change; do not
approve release until those checks pass. Existing backup native release gates
remain applicable. Cross-connection contention and downgrade writer acceptance
are not established by the same-database revision test. No release-ready claim.

## Changed surfaces

- `lib/features/notes/`: pure model, application command/repository, durable adapter,
  editor and shared calendar tile.
- `lib/features/quick_add/presentation/quick_add_sheet.dart` and
  `lib/app/planact_app.dart`: global entry, production binding and refresh revision.
- Calendar Month and Week presentation: bounded note reads, markers/day rows and
  wide all-day composition with retry and stale-result protection.
- Shared `CommitmentColorPicker`: optional semantic label/helper overrides, with
  existing commitment defaults preserved. `app_fa.arb` and generated resources hold
  all new application-owned Persian copy.
- PRD, AGENTS, design specification and ADR 0023 record independent note semantics.
  The repository/widget tests above and the quick-add expectation provide evidence.
