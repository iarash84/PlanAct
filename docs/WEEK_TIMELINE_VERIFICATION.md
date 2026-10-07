# Week Timeline verification

## Phase 0 — inspection map (completed before code changes)

- Calendar entry: `lib/features/calendar/presentation/calendar_page.dart`, injected commitments, scheduledDates, occurrences, reminderRules and commitment tap. Existing month grid stays fit-to-screen with its narrow-width exception. Existing details callback opens the root commitment sheet; `CommitmentDetailsPage` in `lib/app/planact_app.dart` has no occurrence-selection parameter. Reuse that flow, without a second detail screen.
- Production composition: `lib/app/planact_app.dart` `_refresh` eagerly reads every commitment plan for Today/Attention and constructs Calendar maps. Week must independently load a bounded durable range; do not claim that adding it eliminates Today’s existing eager reads or rewrite Today.
- Persistence: `DriftCommitmentPlanRepository` decodes current scheduled values with `date:year-month-day`, `local:year-month-dayThour:minute:second.millis`, or UTC `instant:ISO`. Local/date components are NOT padded, so lexicographic range filtering is unsafe. A seven-day query must match exact local dates/prefixes and UTC instant bounds, join cycles for commitment identity, and preserve every status/history. Existing private occurrence decoder is reusable. No schema change is needed.
- Domain: Occurrence has stable IDs, current/original start and nine persisted statuses; no duration/end. LocalDate is all-day, DateTime is a point start, UTC instants display locally. Never infer end/duration from a card’s visual height. Optional explicit ends belong only to a pure geometry test seam, not new persisted events.
- Dates: existing JalaliDate addDays/weekDay (Saturday=1), LocalDate and Persian formatters supply display/calculation boundaries. Week start and seven dates are centralized; navigation crosses Jalali month/year normally.
- Identity: existing uncommitted schema-18 commitment-color implementation, eight Light/Dark palette pairs, FNV stable-ID fallback, create/edit picker and backup fixtures are preserved. Month dots and Week cards consume this palette. Actual occurrence status gets text/icon, not identity recoloring; no fabricated completion or overdue status.
- Theme: PlanActTheme, spacing/radius tokens, semantic colors and Persian TextTheme already exist. Week-specific geometry is centralized, scaling-aware; standard 48dp targets apply to Week. Phone horizontal scrolling is intentionally distinct from Month’s width exception; fixed gutter, shared horizontal header/body viewport, all-day above hours, tablet all seven columns.
- Lifecycle: minute indicator owns/disposes its timer and rebuilds only itself. Initial current-week scroll is now minus two hours; other weeks use view-only 08:00, never stored as a schedule default.
- Tests inspected: calendar_responsive, calendar_holidays, calendar_reminder_details, commitment_color and file-backed repository patterns. Add pure dates/layout/midnight/lane tests, durable bounded range/reopen tests, and widget Light/Dark/RTL/scaled/loading/error/empty/navigation/tap/disposal tests.
- Governance: PRD §11 currently says all seven columns without horizontal scrolling; narrow that requirement explicitly to Month and specify Week’s scrolling/point semantics in PRD, DESIGN_SYSTEM and AGENTS together.
- Tooling: Windows cmd with Flutter/Dart; full format/analyze/test required, lower concurrency retry for VM failures. No dependency, GPL import, recurrence, schedule/history or financial mutation in scope.

## Implementation and validation

Implemented and verified on Windows, 2026-10-07.

### Files and behavior

- New `lib/features/calendar/application/week_timeline.dart`: read-only range contract, Saturday-based week/date projection, indicator/initial-scroll calculations, pure synthetic interval/midnight segmentation and half-open overlap lanes.
- New `lib/features/calendar/presentation/week_timeline_view.dart`: shared 120dp/hour geometry; fixed time gutter; synchronized RTL horizontal headers/body; measured point-card footprints; all-day header content; actual nine-status text/icons; identity palette consumption; isolated/disposed minute timers; loading, retry, empty and stale-future handling. Async navigation resets the view-only initial scroll after content reattaches.
- `lib/features/calendar/presentation/calendar_page.dart`: Month/Week toggle, previous/next/today navigation, incremental identity dots and actual status in selected-day details. Existing commitment callback is reused. No occurrence-selection API exists in the current details flow.
- `lib/features/commitments/data/drift_commitment_plan_repository.dart`: bounded seven-date read including exact all-day encodings, unpadded local prefixes and half-open UTC instant boundaries. Uses the existing occurrence decoder, keeps historical statuses and does not generate or mutate schedules.
- `lib/app/planact_app.dart`: production Week loader wiring only for this task; existing color-picker/create/edit modifications are preserved.
- New `test/unit/week_timeline_test.dart`, `test/repository/calendar_range_test.dart`, `test/widget/week_timeline_test.dart`; updated `test/widget/calendar_reminder_details_test.dart` expectations to retain time/reminder assertions and include real status.
- Governance updated together: PRD section 11, DESIGN_SYSTEM and AGENTS distinguish Month's fit-width exception from Week's standard targets/horizontal scrolling, identity from status, and point starts from durations.

### Domain and persistence decisions

No new schema, migration, dependency, persisted duration, parallel event storage, schedule default, recurrence rule, entitlement change, financial mutation or historical rewrite was introduced. The pre-existing schema-18 identity-color work and its migration/backup fixtures remain intact. Date-only records remain LocalDate in storage; display conversion does not change persistence. Synthetic explicit intervals are pure geometry inputs only. A card footprint may occupy several visible minutes but is not a recorded end or duration.

### Validation evidence

- `dart format .`: successful; 258 Dart files processed on the final implementation pass. Existing vendored file-picker example emits unresolved flutter_lints include warnings; root analysis remains clean.
- Focused command: `flutter test test/unit/week_timeline_test.dart test/repository/calendar_range_test.dart test/widget/week_timeline_test.dart test/widget/calendar_responsive_test.dart test/widget/calendar_reminder_details_test.dart --concurrency=1`: **29 passed**.
- `flutter analyze`: **no issues found** after fixing the new test's brace-style lint.
- `flutter test --concurrency=1`: **422 passed**, including existing schema migration, backup/restore, color, domain, repository and widget tests. The earlier streamed default-concurrency command did not provide a reliable completion summary, so the full single-worker result is the authoritative evidence.
- `flutter pub get --enforce-lockfile`: successful; no dependency additions.
- `dart format --output=none --set-exit-if-changed lib test`: **223 files, zero changes**, exit 0.
- `python tool/generate_iranian_holidays.py`, followed by formatting the generated Dart output and `git diff --exit-code -- lib/features/calendar/domain/iranian_holiday_data.dart`: exit 0; generator output is logically and finally byte-for-byte unchanged. The generator itself emits unformatted Dart, so the initial pre-format comparison showed formatting-only differences.
- `git diff --check`: successful (existing generated-database line-ending notice only).
- `powershell -NoProfile -Command "$env:PLANACT_SKIP_ANDROID_BUILD='true'; & ./tool/ci.ps1"`: shared CI gates passed, including locked dependency resolution, format check, clean analysis and **422 tests at default concurrency**. Signed Android appbundle generation was explicitly skipped; no release-build claim is made. Together with the full single-worker run, this supplies two complete successful suite runs.

Coverage includes Jalali leap/month/year transitions, Saturday weeks, explicit synthetic durations and midnight splitting, more than two overlap lanes, back-to-back boundaries, point footprints, current-time/initial-scroll calculations, real fixed-instant and LocalDate/local encodings in a file-backed database across reopen, range exclusions, all nine statuses, Light/Dark identity colors, narrow RTL screens at 1x/2x text scale, tablet all-day/three-lane layout, existing details tap, synchronized scrolling, previous/next/today, loading/error/retry/empty, stale async completion, navigation scroll reset and timer disposal. Existing Month responsiveness remains covered.

### Scoped coverage and limitations

Calendar Month/Week are migrated. Existing details, picker, Today, Finance and other surfaces are intentionally unchanged: no shared theme roles or their actions were changed. Today/Attention's root refresh still eagerly loads plans; this independent Week query does not eliminate those reads. Query output is bounded, but no indexed-query performance claim is made for the OR/prefix predicates. Dense overlaps expand day widths rather than shrinking touch targets; sufficient width shows all seven ordinary columns. Dense all-day headers have their own vertical scrolling. Selection of a specific occurrence within existing commitment details is not supported by that existing API.

Native Android notification verification, screen-reader/device visual review, profile performance and a signed release appbundle were not performed by this scoped desktop task. Existing backup portability, concurrency/native gates and holiday source-review limitations are unchanged and not waived. No release readiness claim is made from widget tests alone.
