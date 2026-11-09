# Theme presets — acceptance and evidence

## Acceptance contract (2026-11-09, before implementation)

User-approved scope: More → Settings → Appearance offers four coordinated presets: original PlanAct (default), calm blue, soft purple and warm earth. Each has independently generated Material light/dark role pairs; light/dark/system remains a separate existing choice. No arbitrary per-component editing.

Trace: settings selection → application theme controller → AppSettings metadata write → successful root theme rebuild → retained Settings route, pushed routes, sheets and dialogs inherit the selected scheme. Failed writes retain the previous effective preset, expose Persian inline feedback and allow retry; pending writes disable duplicate selections. Loading errors must be visible/retryable, not overwrite a saved choice. Merely opening Settings performs no write.

Persist a stable versioned preset identifier in the existing SQLite metadata extension; missing/unknown identifiers select original PlanAct without rewriting them. Preserve existing theme mode and background preferences. Cold reopen and logical personal-backup metadata preservation need tests. No domain, ledger, schedule, schema migration, dependency or notification changes. Native splash/launcher and alarm activities remain intentionally branded, not dynamically recolored.

Success evidence required: all eight schemes use shared component roles; status and identity colors retain their meanings; readable foreground/background contrast; selection/loading/failure/retry widget coverage, root navigation/modal propagation, independence from display mode/background and real SQLite cold reopen. Narrow RTL/large-text controls must wrap and retain standard targets.

## Preview selector acceptance contract (2026-11-09)

Approved presentation-only follow-up: More → Settings → color theme replaces text chips with four equally structured miniature interface previews and Persian names. Use two RTL columns at ordinary phone widths, one column at narrow widths/large text. The entire tile is interactive, with a visible selection outline/check and selected/enabled accessibility semantics. Each preview uses that preset's actual current light/dark roles, showing a sample row, action and navigation marker without personal data or tiny copy. Preview geometry is local illustrative geometry, not a new shared component or design token.

Trace remains tile tap → existing controller → durable AppSettings write → root/retained route rebuild. Opening, preview rendering and failed selection must not write a different choice; pending blocks duplicate taps, failure preserves the prior theme and retry. No new Apply step, theme modes, colors, persistence, dependencies, schema or backup behavior. Required evidence: responsive RTL layout at normal and large text, eight preview schemes, selected semantics/full-tile interaction, existing failure/retry, route propagation and cold reopen regression. Device visual/TalkBack and independent review remain maintainer-owned release gates; implementation is not release sign-off.

## Coverage and verification status

Implemented: centralized stable presets, optional shared Material tonal schemes (original unchanged), persist-before-apply controller with duplicate admission, root inherited scope and wrapping Persian Settings controls. No dependency or schema migration. The additive `theme_preset_v1` metadata travels in existing personal SQLite snapshots; unknown keys are not rewritten. This does not certify older writers or the existing native restore/rebind gates.

Automated evidence (2026-11-09): 29 tests passed across theme_presets, brand_theme, design_system, background_settings, app_background_settings, localization_resource_consumers, settings_tag_management and about_page suites. `flutter analyze`: no issues. Changed Dart formatted; generated Persian copy check and `git diff --check` passed. Initial test runs exposed test-harness assumptions (retry label/offscreen target and snapshot bytes versus temporary file); corrected tests then passed. A transient Windows SQLite DLL lock cleared before successful runs.

The new tests cover eight schemes with >=4.5:1 tested foreground pairs, unchanged status extensions, shared button/card/navigation roles, four distinct primary colors, unknown-value nonmutation, actual file-backed SQLite cold reopen, reading the exported redacted SQLite snapshot, retained pushed Settings propagation, subsequent dialog inheritance, app reconstruction, 360dp RTL at 2x text, loading retry, pending disabled selection and failure/retry retention. Snapshot preservation is not full encrypted native export/restore acceptance. Golden comparisons in the pre-existing brand suite remain disabled; no new visual-golden sign-off is claimed.

### Proportional shared-role coverage inventory

These are structural/source-review statuses, not device visual acceptance. Search found no feature-local hardcoded brand palette competing with shared roles.

| Surface | Status | Basis / exception |
| --- | --- | --- |
| Root shell/navigation, quick-add host | Migrated | Root light/dark schemes and existing navigation/FAB component roles |
| Today, Calendar Month/Week, Finance, Inbox, reports, search | Migrated | Existing shared surface/text/component roles; no feature-local styling added |
| More, Settings, About | Migrated | Existing shared roles; Settings receives new wrapped selector and live scope |
| Quick Add, Quick Capture, Commitment Details, forms, date pickers, dialogs and sheets | Migrated | Inherited root theme; retained Settings and subsequent dialog verified explicitly, related shared controls regression tested |
| App Lock and loading/empty/error views | Migrated | Existing shared theme/semantic roles; no authentication or state behavior changed |
| Status, identity markers, account brands and semantic charts | Intentionally Unchanged | Domain/status/external identity is not a selectable application palette |
| Background images | Intentionally Unchanged | Existing independent preference and overlay treatment preserved; regression tested |
| Native launcher, splash/startup and alarm activity | Intentionally Unchanged | Fixed native brand assets are outside Flutter root palette scope |

### Preview selector implementation and evidence (2026-11-09)

Implemented only the Settings selector presentation: equal-width two-column RTL tiles (single column at 280dp or 360dp/2x text), Persian labels, full-tile InkWell interaction, selected outline/check and selected/enabled semantics. Decorative previews share identical geometry and use actual per-preset current-brightness surface, content, action and navigation roles. Existing controller, durable write, root inheritance, retry and duplicate admission are unchanged. No domain decision, migration, dependency, new copy or backup change.

Verification: 21 tests passed across theme_presets, brand_theme, background_settings and design_system. New tests cover both brightnesses/all four preview palettes, ordinary two-column RTL order, narrow/large-text single-column layout, whole-preview taps and selected semantics. Existing pending/failure/retry, SQLite cold reopen/snapshot preservation and real Settings/root/dialog/reconstruction tests passed. `flutter analyze` reported no issues; all three changed Dart files formatted. A pre-existing Drift multiple-database-instance debug warning is still emitted by the snapshot test; tests pass. Initial route failures exposed fixed-scroll-distance and missing scroll-settle assumptions after the selector grew; route tests now reveal targets through actual scrolling and settle before tapping, rather than weakening assertions. This is an acceptance-test robustness gap, not evidence of a production persistence defect.

Scoped coverage: Settings selector migrated; neighboring display-mode/background controls intentionally unchanged and regression tested. Other application surfaces, palettes, status colors and native assets intentionally unchanged. Device screenshots, actual TalkBack/focus quality, physical-device light/dark review, full-suite execution and Android build were not performed. Maintainer owns device/independent review before release; this bounded presentation implementation is not independent release approval.

### Remaining acceptance gates

Independent visual/device acceptance is not established by passing tests. Owner: maintainer; next action: inspect all eight palettes on representative Android devices, including background-image combinations, disabled/selected/focus states, TalkBack and large text; independently accept accessibility and visual quality before release. Full application test suite, Android build and device checks were not run for this scoped change. Capability is implemented with bounded automated verification, not independently release-approved; existing backup/native release blockers remain unchanged.
