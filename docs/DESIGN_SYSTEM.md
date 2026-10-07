# PlanAct Design System

This document is the authoritative concrete visual specification for PlanAct. `AGENTS.md` defines how design decisions are governed; this document defines how PlanAct should feel and look. Read both before meaningful UI or shared design-system work. Product behavior remains governed by `docs/product/PRD.md`.

## Product visual character

PlanAct is a calm, trustworthy, focused, organized, modern, approachable, financially credible, action-oriented, low-noise personal commitment manager for Persian-speaking users. Its interface should make the difference between plan, actual, expectation, transaction, and reconciliation easy to understand without changing their domain meaning.

The launcher artwork at `assets/icons/app_icon.png` and `assets/icons/app_icon_foreground.png` combines deep navy with vivid blue-green/teal and green over a pale, cool field. Express that identity through a restrained blue-green foundation, clear hierarchy, and selective accent—not by copying the launcher's gradients across the app. Avoid generic framework-default appearance, excessive color, neon, decorative gradients, card-on-card layouts, and repeated logo placement. Material 3 is the component and interaction foundation, not the brand itself.

## Visual source of truth

For visual decisions, follow this order after product/domain requirements and `AGENTS.md` governance:

1. This specification.
2. Shared `ThemeData`, `ColorScheme`, `TextTheme`, component themes, and PlanAct tokens.
3. Shared PlanAct components.
4. Feature-local composition.
5. One-off local styling only when genuinely necessary, scoped, and documented.

The implementation lives in:

- [`PlanActTheme`](../lib/app/theme/planact_theme.dart)
- [`PlanActColors`](../lib/app/theme/planact_colors.dart)
- [`PlanActTypography`](../lib/app/theme/planact_typography.dart)
- [`PlanActSpacing` and `PlanActMotion`](../lib/app/theme/planact_spacing.dart)
- [`PlanActRadius`](../lib/app/theme/planact_radius.dart)

These files implement the specification; they are not permission for feature widgets to introduce further styles. When the specification and implementation disagree, identify whether implementation predates the shared contract, preserve product behavior, and record an intentional exception. A foundational visual change must update this document and the corresponding theme/tokens together, then review affected surfaces.

## Brand palette

The values below record the current token baseline after inspection of the logo and theme. Token names in code remain the implementation source for values; feature widgets must refer to those roles, not duplicate hex literals.

| Role | Current token/value | Use |
| --- | --- | --- |
| Brand primary | `PlanActColors.primary` — `#176B87` | Main product actions, focus, and selected emphasis where semantically appropriate |
| Deeper brand tone | `PlanActColors.primaryDark` — `#0D5268` | Existing deeper brand token; do not invent feature-specific variants |
| Light scaffold | `PlanActColors.lightBackground` — `#F7FAFB` | Quiet light-mode page background |
| Dark scaffold | `PlanActColors.darkBackground` — `#101A1E` | Quiet dark-mode page background |
| Light surface | `PlanActColors.lightSurface` — `#FFFFFF` | Base light-mode surface |
| Dark surface | `PlanActColors.darkSurface` — `#18262B` | Base dark-mode surface |

`ColorScheme` supplies Material roles such as `onPrimary`, containers, outlines, and additional surface levels. Use those semantic roles instead of selecting a nearby raw color. Preserve a restrained relationship to the logo's deep navy and blue-green/teal/green family; do not use the artwork's bright colors or gradients as a license for a loud interface.

Material secondary and tertiary are generated brand roles, not information or success aliases. Material error retains its own foreground/container pairing and is reserved for actual failures/destructive operations. Light primary remains #176B87 with white foreground; Dark primary is #8BD0E7 with #003544 foreground.

## Semantic palette

Business meaning is provided by the brightness-aware PlanActStatusColors theme extension in lib/app/theme/planact_status_colors.dart. Each role supplies an opaque foreground and container; foregrounds are also tested against the scaffold surface. Never use Material tertiary as success or error as a holiday/overdue shortcut.

| Role | Light foreground / container | Dark foreground / container |
| --- | --- | --- |
| Success | #17633F / #D9F3E4 | #9CDDB6 / #173B29 |
| Attention | #744900 / #FFEDC2 | #FFD58C / #493510 |
| Danger / overdue | #A32129 / #FFE3E3 | #FFB3B6 / #502329 |
| Information | #205D96 / #DFEDFF | #AACFFF / #1B354E |
| Holiday | #A32129 / #FFE3E3 | #FFB3B6 / #502329 |
| Inactive | #495B63 / #E6EDEF | #BECBD1 / #2B3B42 |

Cancellation and archival use subdued inactive styling, not destructive/error styling. Calendar holidays use the dedicated red holiday role with written reasons and accessible labels, not Material error or danger semantics. Its current red values intentionally match the danger pair, but the roles remain independent: holidays never imply failure, urgency, or destructive actions. Month day numbers/holiday labels and selected-day reasons, plus Week holiday dates/reasons, consume this role in both brightnesses. Review warnings use attention. Status must always retain a text/icon cue. Legacy static business colors have been removed.

## Typography

Persian readability is the default. Use semantic roles from `PlanActTypography`/`TextTheme`, rather than local font sizes or weights:

| Role | Preferred semantic source |
| --- | --- |
| Screen title | `headlineSmall` or the established page-title role |
| Section title | `titleLarge` |
| Card/row title | `titleMedium` |
| Body and supporting copy | `bodyLarge`, `bodyMedium`, `bodySmall` by hierarchy |
| Field labels and actions | `labelLarge`, `labelMedium` |
| Numeric and money emphasis | A semantic title/body role that preserves locale formatting and clear digit grouping |

Preserve correct Persian shaping and line height, natural mixed Persian/Latin text flow, locale-aware Persian digits where appropriate, and readable money/numeric values. Never reverse strings or replace digits with scattered string operations. Text must remain legible at increased system text scale and narrow mobile widths.

There is currently no bundled font asset or declared font dependency; the theme uses the existing `sans` family. Treat this as a documented baseline limitation, not a claim that any generic font choice is ideal. Do not introduce a new font or change the global family from a feature. A deliberate Persian font decision requires an explicit design-system change and coordinated theme/assets update; this documentation task does not add a dependency.

## Spacing and touch targets

Use the existing compact spacing scale: `xs` 4dp, `sm` 8dp, `md` 12dp, `lg` 16dp, `xl` 24dp, and `xxl` 32dp. The current page gutter token is 20dp. Use these for recurring visual rhythm; component-specific geometry may remain local when it is truly unique.

Keep interactive targets at least 48×48dp, consistent with the theme. Preserve breathing room around Persian text and controls. Do not compress spacing to make a dense form or list fit; simplify or progressively disclose content instead.

## Shape

Use the established hierarchy: chips 8dp, inputs 12dp, cards/dialogs 16dp, and sheet top corners 24dp. Reserve fully pill-shaped treatment for components whose Material semantics call for it; do not make every surface a pill. Reuse `PlanActRadius` rather than repeating radii.

## Surface hierarchy

- **Scaffold:** quiet brightness-specific background; avoid unbroken white-on-white layouts.
- **Base surface:** primary content plane, readable against the scaffold.
- **Cards and list surfaces:** group related content only when grouping improves scanning; avoid nesting cards or adding a card to every row.
- **Elevated/modal surfaces:** dialogs and sheets should be distinguishable through theme surface roles, shape, and elevation—not arbitrary shadows.
- **Selected/highlight surfaces:** use a restrained shared container/indicator plus clear text/icon state; selection must not depend on color alone.

Use `ColorScheme` surface/container and outline roles consistently. Do not add local elevation, shadow, border, or surface shades where a theme role already communicates the hierarchy.

## Component hierarchy

- **Primary action:** one visually dominant action per context; use the shared filled treatment and primary brand role.
- **Secondary action:** visible but subordinate, using outlined, tonal, or text treatment as appropriate.
- **Destructive action:** use error semantics only for an actually destructive operation; pair with the required confirmation/undo semantics.
- **Text/icon actions:** use shared theme sizing and provide accessible labels for icon-only controls.
- **Cards and rows:** prioritize readable title, useful supporting content, and a clear action; prefer a shared row pattern over similar feature-local cards.
- **Fields:** use shared filled/outlined field treatment, consistent focus/error states, and correct Persian input behavior.
- **Chips and badges:** concise secondary metadata or state; use the shared shape and do not substitute color for a label.
- **Navigation and AppBars:** keep hierarchy quiet and consistent; directional affordances must follow the app's RTL semantics.
- **Sheets and dialogs:** use shared shape/surface treatment, preserve keyboard/focus and scroll behavior, and state consequences for important actions.
- **State views:** use distinct, reusable loading, empty, error, success, stale, and disabled treatments. Error must not resemble empty; keep progress scoped to the operation/item when possible.

Use the shared Material theme for recurring component treatments. Local composition is appropriate for unique product content, not for recreating buttons, fields, cards, state views, or navigation styles.

## State presentation

Every applicable screen state must have a coherent representation:

- **Loading/refreshing:** show progress in the affected region and retain useful context where possible.
- **Saving/action in progress:** indicate which operation is busy and prevent duplicate activation where needed.
- **Success:** confirm the result in Persian; offer undo/recovery when the operation is reversible and appropriate.
- **Empty:** explain the absence and offer a relevant next step when one exists.
- **Error:** communicate failure distinctly from empty, provide a human-readable and actionable retry/recovery path where possible.
- **Stale/partial:** explain what is incomplete without implying success.
- **Disabled:** retain readable contrast and make the reason understandable where relevant.

Do not leave asynchronous failures silent and do not use color as the only state signal.

## Motion

Motion is restrained and functional: it should communicate state change, continuity, hierarchy, insertion/removal, expansion, success/failure, or navigation—not decoration. Reuse the existing `PlanActMotion` tokens: short 150ms, standard 220ms, emphasis 300ms, `easeOutCubic`. Respect reduced-motion expectations and ensure the final state is correct without animation. Prefer implicit Flutter animations for simple transitions; use explicit controllers only when necessary.

## RTL

RTL is the default. Use Flutter directionality, `AlignmentDirectional`, start/end-aware padding, and directional icons. Do not manually reverse lists, strings, or layout order to simulate RTL. Navigation and previous/next/back/forward icons must follow one consistent semantic convention. Validate mixed Persian/Latin text, numbers, forms, focus order, and date controls in context.

## Accessibility and responsive behavior

- Maintain a minimum 48×48dp interactive target, except the Calendar page's seven-column month grid on narrow screens: distribute available width equally without horizontal scrolling, retain at least 48dp height, and never overlap hit regions. This explicitly approved fit-to-screen exception does not apply to other controls or the modal date picker.
- Target WCAG 2.1 AA contrast as a baseline: 4.5:1 for normal text and 3:1 for large text and essential non-text controls; verify foregrounds against their actual Light and Dark surfaces.
- Support system text scaling without clipping, fixed-height text regions, or reducing font size to conceal overflow.
- Give icon-only actions meaningful Persian semantic labels; ensure focus and keyboard behavior where applicable.
- Communicate status through text/icon/shape in addition to color.
- Check narrow mobile widths and increased text scale. Let Persian text wrap naturally and adapt layout; do not truncate essential labels or solve overflow by shrinking text.

## Brand exceptions

Official bank/provider colors may appear only when needed to identify that external entity. Keep them scoped to the entity representation; they must not become PlanAct theme colors, general action colors, or status semantics. Logo use is similarly limited to appropriate brand moments. Any other exception must be necessary, small in scope, consistent with product behavior and accessibility, and documented with the affected surface and reason.

## Change and review policy

Implementing an existing rule or correcting drift does not require redefining the visual identity. Do not casually change the brand palette, typography family, global radius system, primary/secondary hierarchy, or visual paradigm from a feature widget.

When a task intentionally changes a foundational design rule:

1. Update this specification and the corresponding shared theme/token implementation together.
2. Review the affected Light and Dark states.
3. Review related screens and shared-component consumers; for broad work, complete the app-wide visual coverage inventory required by `AGENTS.md`.
4. Document any intentional exceptions and migration scope.

Before adding a recurring pattern, inspect the existing theme, tokens, and shared components. Extend a shared role when several surfaces need it; do not over-tokenize unique geometry or create duplicate abstractions. App-wide consistency does not authorize unrelated architectural rewrites.

## Implemented migration checkpoint (2026-10-06)

Shared body line heights are 1.6 (large/medium), 1.5 (small), and 1.4 for small labels, retaining system sans. Root single-column content is capped at 840dp; modal sheets at 640dp. Form actions wrap via an overflow bar and errors are live semantic announcements. Calendar Month now fits all seven RTL weekday columns to the viewport without horizontal scrolling. When full weekday names do not fit at the current text scale, use distinct Persian short labels with full-name semantics. Cell height grows from measured, wrapping day/holiday/count text; fonts and system scaling are not reduced. With 12dp page gutters and 3dp gaps, 320dp screens have approximately 40dp-wide day targets: the narrowly scoped width exception above is intentional, not a claim of 48dp-wide targets. The shared modal Jalali picker remains intentionally unchanged, preserving 48dp cells via horizontal scrolling when required; its explicit date-selection flow is outside this Calendar Month-page fix. Finance reuses that picker. Existing previous/next semantics are retained consistently.

PlanActMotion.duration respects platform disableAnimations; root navigation and capture transitions consume it. Startup has no decorative entrance animation, glow or custom shadow. Logos remain in launcher/startup/About, not repeated in root AppBars. Shared divider, progress, popup menu, segmented button and bottom-sheet treatments are theme-owned.

See docs/UI_MIGRATION_VERIFICATION.md for surface coverage and limitations. Automated contrast and widget checks are evidence for tested pairs/flows only, not native-device, screen-reader or profile-performance certification.

## Calendar return to today

Month and Week expose a visible Persian “بازگشت به امروز” text-and-icon action below the mode control instead of the easily missed header icon. It reads the current local Jalali date when pressed, restores the selected day and displayed month/week, and preserves the active view mode. The shared themed button retains standard targets and text scaling; its separate row avoids crowding narrow navigation headers. Calendar-only composition change; other surfaces and domain/persistence semantics remain unchanged.

## Today identity markers and Calendar mode control

Today commitment-linked action cards in Attention, Today and Upcoming reuse the shared `CommitmentIdentityMarker` also used by Calendar selected-day cards. The marker uses the same brightness-aware identity palette and deterministic stable-ID fallback, with a Persian color semantic label. Identity never replaces urgency, action, or outcome wording/icons; unrelated financial/inbox review items retain their neutral icons. Existing Today grouping and callbacks remain unchanged.

Calendar Month and Week use the same full available-width mode control with 12dp horizontal and 8dp top gutters. Switching modes must not change its bounds; height remains theme/text-scale driven rather than fixed. Regression coverage checks exact bounds at 320dp with normal and doubled text scaling in Light and Dark.

Coverage: Today action cards migrated; Calendar selected-day cards migrated to the shared marker without changing appearance; Calendar mode control corrected in both modes. Month dots and Week event cards remain compliant with the same identity palette. Legacy commitment rows, details, Finance, settings and other surfaces are intentionally unchanged because they are not consumers of this marker/control and no global token changed.

## Calendar Week and identity integration

Month retains its fit-to-screen width exception. Week does not: minimum day/lane widths and standard 48dp targets use horizontal scrolling on phones, synchronized day/all-day headers and body, and a fixed time gutter. Seven days fit when sufficient width exists; dense overlap groups expand the scrollable day widths rather than shrinking targets. Week geometry is centralized in WeekTimelineGeometry (120dp/hour). Text-scale-aware card footprints are hit geometry, not durations; production records have no ends. Titles have full Persian semantics and tooltip when visually shortened. Dense all-day content scrolls in its own header region.

CommitmentIdentityPalette owns eight brightness-specific identity pairs and deterministic stable-ID fallback. Month dots, selected-day commitment cards and Week cards consume it, independent of occurrence status. Selected-day cards use the shared Material card theme with an identity-colored icon marker (and Persian color semantics), title/tags, then separate time/status and reminder rows per recorded occurrence. Date-only records remain explicitly all-day; missing occurrence details are disclosed rather than assigned time/status. Cards wrap at narrow widths and increased text scale and preserve details navigation. Week status uses actual text/icon on the identity foreground, never inferred success/overdue recoloring. Current-time line uses the shared primary role and an isolated disposed minute timer. Shared typography, spacing and radius remain unchanged. Coverage: Calendar Month/Week migrated; picker, Today, details, Finance and other surfaces intentionally unchanged because the new holiday role and selected-day card composition do not change their styles or domain actions.
