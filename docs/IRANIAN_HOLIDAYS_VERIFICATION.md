# Priority 8 — Iranian holidays verification

Checkpoint: 2026-10-06. Status: **Current-year official holiday coverage implemented; future-year and special-closure gates remain**.

## Implemented

- Deterministic, fully offline Jalali lookup using bundled source facts and pinned CC0 event/month-start snapshots; no normal-operation API, cloud dependency or approximate lunar conversion.
- Separate weekly Friday, official fixed, official variable and scoped special closure kinds. Multiple reasons on one date are preserved.
- Complete published calendar-source coverage for Jalali 1400–1405. Years 1400–1404 follow calendar-center month starts, not the consolidated observed-moon table. For 1405, all twelve time.ir monthly responses were inspected: 365 enabled days, ten fixed and nineteen lunar date records. The combined birthday expands into two existing occasion titles; both Eid cycles and fixed/lunar overlaps remain visible.
- Safar-end holidays use the actual published month length, including 29-day months.
- Explicit annual coverage query. Before 1400 only weekend rules are authoritative; from 1406 fixed current rules are shown but variable holidays are omitted with a Persian warning. The warning no longer appears in 1405. Missing markers outside coverage are never advertised as proof of a working day.
- Calendar selected-day Persian reasons, accessible per-day reasons, and visible text holiday markers in addition to color.
- Special closures have explicit kind, source, version and scope validation. No invented special dates or temporary user-editing flow. Future production inputs must come from a durable versioned dataset/repository, not widget state.
- No changes to occurrences, reminders, schedules, entitlement or financial records. No database migration, package dependency or sensitive logging. Bundled source data survives cold restart and is independent of personal backup content.

## Evidence

- Repository formatter applied to changed Dart source and tests.
- Flutter analyzer: no issues.
- Initial checkpoint: **298 passed**, one worker (parallel run had allocation errors). Current-year follow-up: **10 focused tests passed**, **300 full-suite tests passed** with one worker; analyzer reports no issues. Offline generation followed by Dart formatting reproduces identical SHA-256 bytes; diff whitespace checks pass.
- Unit checks: all covered years, fixed dates, published Eid dates (2023/2024/2025), all 365 days of 1405 against monthly markers, exact Gregorian/Jalali agreement, both 1405 Eid cycles, Khordad 14 overlap, combined birthdays, 29-day Safar end, leap Esfand, invalid dates, unsupported years, special closure scope, immutable result lists and repeat/recreated-provider queries.
- Calendar widget checks in Light/Dark with Persian RTL: overlapping reasons, incomplete-year warning, no rendering exception. Existing Calendar occurrence/reminder and app flows remain covered by the full suite.
- Calendar coverage inventory: **Migrated** (holiday labels/warning/semantics); occurrence details **Intentionally Unchanged** (existing behavior retained). Shared theme/components and other screens **Intentionally Unchanged** (no shared visual contract changed). No app-wide redesign is claimed.

## Sources and refresh

Pinned revisions, license and extraction details: [source provenance](../third_party/iranian_holidays/README.md).
Regenerate from local snapshots with [the generator](../tool/generate_iranian_holidays.py), then apply Dart formatting to [generated data](../lib/features/calendar/domain/iranian_holiday_data.dart). Compare the resulting bytes before approving a refresh. Review published calendar evidence, annual completeness and representative-date tests before changing version or coverage bounds.

## Remaining gates

- 1405 coverage is verified against time.ir's secondary published monthly calendar. The official PDF endpoint returned anti-bot HTML; direct official-PDF comparison is not claimed. Source URLs, retrieval date and monthly response hashes are retained alongside minimal factual mappings, without copying website code, editorial content or claiming its license is CC0.
- Years 1406 onward require fresh annual source review; do not extrapolate lunar dates or remove their incomplete-coverage warning.
- Source refreshes may require corrections or legal rule changes. Fixed rules beyond verified annual coverage are current-rule extrapolations, not annual verification.
- No actual special closure dataset is bundled; source provenance, jurisdiction/scope and version review are required before one is shipped. User-managed closure persistence is not implemented.
- Light/Dark widget checks do not replace physical-device accessibility, large-text or screenshot review. No native installation or personal-device data mutation was performed.

## Independent annual-package checkpoint — 2026-10-06

Implemented explicit Persian Settings file import, Ed25519 integrity/signature verification, first-publisher fingerprint approval, pinned signer continuity and increasing per-year revisions. Twelve ordered Jalali months and marker/reason agreement are structurally checked. Installed official reasons replace that year while weekend/special overlays remain separate. Startup and live Calendar use durable public packages; no personal-history commands run. See [ADR 0014](adr/0014-independent-holiday-packages.md) for format, signing tool and publisher responsibilities.

Validation: formatter completed; analyzer reported no issues. Full single-worker execution hit host out-of-memory; all existing suites then passed in eleven batches of at most eight files (308 tests), plus the newly added real-file Calendar refresh/restart test (309 unique passing tests). Final focused rerun passed all nine package repository/widget tests. Tests cover approval/cancel, tampered signature, incomplete months, inconsistent markers, invalid dates/kinds/duplicates, overlap, restart, wrong signer/downgrade, transaction abort preserving old state, corrupt storage retained, and Light/Dark RTL feedback.

Presentation coverage: Settings import card/dialog Migrated using shared theme and spacing; Calendar Compliant with injected provider and refresh/restart evidence; other surfaces Intentionally Unchanged because imports do not change their state or shared visual rules.

Limitations: no real 1406+ source package is supplied or predicted. Published-source factual review and independent fingerprint publication remain publisher responsibilities. Native picker/content-provider verification on an isolated device remains a release gate. Automatic download, key rotation and corrupt-trust recovery UI are not implemented. Public packages are excluded from personal backup/restore; retain original files and reapprove on a new installation. Signature validity is not official-source verification.
