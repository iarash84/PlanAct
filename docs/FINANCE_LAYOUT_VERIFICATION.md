# Finance last-row accessibility

## Acceptance contract — 2026-10-11

Entry: root navigation → مالی, with locally recorded transactions; no permission or connectivity prerequisite. Short and long filtered lists must allow scrolling the entire final transaction row and its standard ≥48dp operations target into an unobscured viewport and opening that menu by an actual pointer tap. Narrow widths, increased text scale, RTL, Light/Dark and simulated system insets are required widget evidence.

Trace: navigation selects Finance → Finance refresh reads repository entries → existing domain filtering/sorting → list renders → operations menu invokes existing confirmation/relationship/tag commands → existing durable writes and refresh callbacks. Quick Add continues to invoke the existing shell quick-add sheet. No application command, domain rule, persistence, cancellation, retry, Undo, filter or loading semantics change.

Implementation plan: remove the Finance-only overlap structurally. Compose its existing Quick Add button in a content-sized trailing action row above the existing NavigationBar, so Scaffold excludes the actual combined navigation/action geometry from the body. Keep the floating placement on other tabs. Keep safe-area ownership in NavigationBar/root SafeArea; do not duplicate a fixed system inset or estimate FAB height. No dragging, saved position, new theme values, dependencies, schema/migration or backup impact.

Coverage: Finance viewport and root Finance action/navigation composition **Migrated**. Transaction cards now give amount/details the full text width below the direction/menu header; filters use bounded full-width dropdowns with content-driven menu heights, and the accounts heading wraps within its remaining width. These are scoped large-text prerequisites, not smaller fonts or targets. Other tabs' action placement, forms, menu commands, Finance data and shared theme **Intentionally Unchanged** because this is a Finance layout defect, not a global design-system change.

## Defect and evidence

The shell's floating Quick Add button overlays the nested Finance Scaffold; its list's fixed 16dp padding does not reserve the floating control. Existing isolated Finance tests omit this shell geometry, and finding a menu does not prove that it receives a tap. Regression tests must exercise the actual HomeShell, scroll to the end, assert full row/menu bounds clear of the add/navigation regions, tap the menu and cancel its confirmation without writing. Also exercise Quick Add and filter behavior.

Validation results — 2026-10-11:

- Formatting of the two production files and regression test: passed.
- Static analysis: no issues.
- Focused widget suite: **51 passed**, including 24 shell-level layout cases and existing Finance transaction-form, tagged-creation and contextual-reconciliation coverage.
- Layout matrix: widths 320/360/430dp, height 900dp, text scales 1/2, Light/Dark, RTL, simulated 24dp top / 34dp bottom system insets, and 1/40 transactions. Each case selects the expense filter by pointer, reaches the actual list end after layout stabilizes, checks the whole fixture card and ≥48×48dp menu target, opens the menu by pointer, opens/cancels safe-delete confirmation, opens/dismisses Quick Add, and verifies unchanged entry count. No render exceptions are accepted.
- No domain decisions, persisted defaults, schema/migrations, dependencies, history changes or backup impact. Existing commands and refresh callbacks remain unchanged; no PRD/AGENTS semantic update is required.

Evidence is bounded: this does not prove all note lengths fit simultaneously in a viewport, every phone height, platform delivery, cold-restart durability, native screen readers or app-wide large-text readiness. Initial large-text startup with unresolved financial review cards exposed an existing [Today relationship-review card trailing-width assertion](../lib/features/today/presentation/today_page.dart:243); the matrix applies increased scale after navigating to Finance and does not fix or waive that separate defect. Owner: Today presentation maintainer; next action: a separately scoped startup large-text regression/fix. Exposure: no app-wide accessibility readiness claim; review this gap before release.

## Remaining acceptance gates

Native device review and independent acceptance are unexecuted. Owner: release maintainer / accessibility reviewer. Next action: verify narrow-phone RTL scrolling and menu activation with gesture and three-button navigation, large system fonts, Light/Dark and TalkBack on the release candidate. Exposure: existing Finance remains available with a layout-only fix; this task does not authorize release or waive other financial/native gates. Automated inset simulation is not native system-bar or screen-reader evidence.
