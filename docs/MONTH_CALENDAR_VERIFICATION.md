# Calendar Month bounded improvement

## Acceptance contract — recorded before presentation changes

Entry is root Calendar → Month. Existing persisted commitments/occurrences are prerequisites; no permission or account is required. Day cells show readable short title markers, not identity dots alone; dense days show a remaining count and an explicit day-list action. Seven RTL columns fit narrow screens at large text without horizontal scrolling, with non-overlapping day targets at least 48dp high. Full Persian date, holiday reasons and day-list semantics remain available. Full titles and actual recorded statuses remain in the selected-day list, with identity independent of status and historical/archived records retained.

Previous/next buttons and today remain. Horizontal swipes use the existing RTL navigation convention (rightward next, leftward previous), crossing Jalali year boundaries. Vertical scrolling and ordinary day taps must not navigate months. Month navigation selects a day in the displayed month, so the selected-day heading never silently describes another month. Empty month/day, loading, visible failure/retry, stale-result rejection, holiday overlap and incomplete-coverage warning are required.

Trace: navigation/day tap → read-only presentation selection → bounded production repository Month range → recorded occurrences grouped by local display date → cell markers and full selected-day cards → existing commitment details/reminder route. Reads never generate or mutate occurrences, financial data, duration, entitlement or reminders. Persistence source remains existing SQLite records; there is no new durable state, migration, dependency or backup format. Cold reopen and range/status preservation require repository evidence. Existing root Today eager reads remain outside scope.

Minimum plan: reuse Week repository encoding-aware bounded query for 1–31 local dates; add Month loader with stale-result protection; pre-group recorded month data once rather than rescan every cell; use paired shared identity palette and themed typography for bounded title markers; gesture only the Month grid; retain selected-day cards and Week composition. Add narrow/dense/scaled Light/Dark, navigation/tap/semantics/retry and realistic-volume checks.

Scope: Month only. Week layout, shared theme/picker, Today eager loading, occurrence-specific details selection, recurrence, domain statuses and platform delivery are intentionally unchanged. Evidence required: format/analyze, relevant widget/repository/Week regressions, desktop realistic-volume timing with stated budget; device screenshots, native screen-reader and reference-device profiling remain separate acceptance gates, not implied by passing tests.

## Verification status

Implementation of the bounded Month slice is complete; automated Calendar evidence passes. Overall release acceptance remains Partial, not ready: independent visual/native acceptance is not performed and the broader workspace suite is not clean. Owner: maintainer/release reviewer. Next action: inspect Light/Dark dense Month at narrow width and 2x text on reference Android device, exercise swipe/tap/TalkBack, and profile recorded monthly volume. Exposure decision: no claim of device-verified visual or performance release readiness until those checks pass.

## Changed files and decisions

- [Calendar presentation](../lib/features/calendar/presentation/calendar_page.dart): optional bounded Month loader, pregrouped local display dates, stale-result protection, loading/retry, two identity title markers and remaining count, explicit day-list access, grid-only RTL swipe, selection clamping and Today reload.
- [Production wiring](../lib/app/planact_app.dart:1077) and [range repository](../lib/features/commitments/data/drift_commitment_plan_repository.dart:439): 1–31-date half-open Month query using existing date/local/instant encodings. Week shares the private query without changing seven-day semantics.
- [Month widgets](../test/widget/calendar_month_test.dart) and [range repository tests](../test/repository/calendar_range_test.dart): density, scaled Light/Dark, accessibility semantics, history/status, navigation, loading/retry/staleness, cold reopen, no-write and volume regression evidence.
- [Product contract](product/PRD.md:430) and [design contract](DESIGN_SYSTEM.md): scoped Month behavior and limitations aligned.

No schema, migration, dependency, durable default, duration, generation, ledger/reminder write, holiday source change or backup format change. Selection and swipe state are intentionally transient. Full existing day cards preserve real status independently of identity. No new domain status rule was invented.

Coverage inventory: Month grid/title markers/day access/navigation/content/empty/loading/error **Migrated**. Selected-day cards/holiday reasons/incomplete coverage/existing details callbacks **Compliant** through existing regressions. Week, shared theme/marker palette, picker, Today and other feature surfaces **Intentionally Unchanged**; no shared visual rule or domain action was modified.

## Final automated evidence — 2026-10-12

- Analyzer: no issues found after the final boundary fix.
- Format verification: 288 files, zero changes; diff whitespace check passed.
- Final expanded Calendar/Week/unit/repository run: **60 tests passed**, including Month responsiveness, holiday/package behavior, reminder/details, return-today and mode-toggle consumers.
- Additional focused post-fix run: **22 tests passed**.
- File-backed desktop volume: **12,020 stored rows, 310 returned**; final cold-reopen/warm timings **34 / 32 / 34 / 31 ms**, below the explicit **5,000 ms/query desktop regression guard**. This guard detects gross regressions, not a reference-device responsiveness certification; OR/prefix queries may scan history.
- Widget volume smoke: 3,000 recorded Month rows. This proves grouping/layout does not throw in the test environment, not frame-budget performance.
- Full workspace suite completed: **678 passed, 5 failed**. Failures: signed correction backup restore; contextual SMS imported-entry routing; ambiguous SMS explicit toman editing in Light and Dark; bank/account reviewed edit failed-save persistence. None of these failing tests exercises the Calendar range or Month UI. They were not repaired in this bounded change, and pre-existing status was not independently proven. Maintainer/test owners must reproduce and repair or formally triage before a clean workspace/release claim. Temporary console-output files were removed during cleanup; results and failure categories are preserved here.

### Integration review correction

Integrated review found that presentation initially supplied the last date to an end-exclusive repository contract, dropping the final day in production. The original fake-loader expectation repeated that mistake rather than checking durable range semantics. Fixed by passing the following day; added regression coverage for 31-day, 30-day, non-leap Esfand and leap Esfand boundaries, alongside repository range/reopen tests. Future range acceptance checks must compare the actual UI loader bounds with the production half-open contract, not merely mirror implementation parameters.

## Unexecuted evidence and release blockers

No screenshots/goldens, physical-device visual review, native screen-reader journey, reference-device profile or independent acceptance review were collected. Widget text/geometry/contrast checks are automated evidence only; they do not certify the readability of abbreviated Persian titles on-device. The maintainer/release reviewer owns those gates and must collect device evidence before claiming visual/accessibility/performance readiness. Existing backup/native reminder/holiday source gates remain unchanged. Existing root Today eager plan reads and occurrence-specific details selection remain out of scope.
