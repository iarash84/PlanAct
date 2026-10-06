# Priority 8 — Iranian holidays verification

Checkpoint: 2026-10-06. Status: **Partial — current-year coverage gate remains open**.

## Implemented

- Deterministic, fully offline Jalali lookup using bundled, pinned CC0 snapshots; no normal-operation API, cloud dependency or approximate lunar conversion.
- Separate weekly Friday, official fixed, official variable and scoped special closure kinds. Multiple reasons on one date are preserved.
- Complete official calendar-source coverage for Jalali 1400–1404. Ten fixed event dates and eighteen lunar event rows; dates follow published calendar-center month starts, not the consolidated observed-moon table.
- Safar-end holidays use the actual published month length, including 29-day months.
- Explicit annual coverage query. Before 1400 only weekend rules are authoritative; from 1405 fixed current rules are shown but variable holidays are omitted with a Persian warning. Missing markers are never advertised as proof of a working day.
- Calendar selected-day Persian reasons, accessible per-day reasons, and visible text holiday markers in addition to color.
- Special closures have explicit kind, source, version and scope validation. No invented special dates or temporary user-editing flow. Future production inputs must come from a durable versioned dataset/repository, not widget state.
- No changes to occurrences, reminders, schedules, entitlement or financial records. No database migration, package dependency or sensitive logging. Bundled source data survives cold restart and is independent of personal backup content.

## Evidence

- Repository formatter applied to changed Dart source and tests.
- Flutter analyzer: no issues.
- Full Flutter test suite, one worker: **298 passed**. Initial parallel run crashed from Dart out-of-memory allocation errors; the complete single-worker rerun passed.
- Unit checks: all covered years, fixed dates, published Eid dates (2023/2024/2025), overlaps, Safar boundaries, leap Esfand, invalid dates, unsupported years, special closure scope, immutable result lists and repeat/recreated-provider queries.
- Calendar widget checks in Light/Dark with Persian RTL: overlapping reasons, incomplete-year warning, no rendering exception. Existing Calendar occurrence/reminder and app flows remain covered by the full suite.
- Calendar coverage inventory: **Migrated** (holiday labels/warning/semantics); occurrence details **Intentionally Unchanged** (existing behavior retained). Shared theme/components and other screens **Intentionally Unchanged** (no shared visual contract changed). No app-wide redesign is claimed.

## Sources and refresh

Pinned revisions, license and extraction details: [source provenance](../third_party/iranian_holidays/README.md).
Regenerate from local snapshots with [the generator](../tool/generate_iranian_holidays.py), then apply Dart formatting to [generated data](../lib/features/calendar/domain/iranian_holiday_data.dart). Compare the resulting bytes before approving a refresh. Review published calendar evidence, annual completeness and representative-date tests before changing version or coverage bounds.

## Remaining gates

- Verify and bundle complete Jalali 1405 published-calendar dates (the official PDF endpoint returned anti-bot HTML here). This is a release gate; Priority 8 must not be called fully complete.
- Source refreshes may require corrections or legal rule changes. Fixed rules beyond verified annual coverage are current-rule extrapolations, not annual verification.
- No actual special closure dataset is bundled; source provenance, jurisdiction/scope and version review are required before one is shipped. User-managed closure persistence is not implemented.
- Light/Dark widget checks do not replace physical-device accessibility, large-text or screenshot review. No native installation or personal-device data mutation was performed.
