# PlanAct Design System

## Direction

PlanAct uses Material 3 with a calm, Persian-first visual language. The product is RTL by default, local-first, and sensitive to personal and financial information. Visual treatment must clarify the difference between plan, actual, expectation, transaction, and reconciliation without changing domain semantics.

## Tokens

- [`PlanActColors`](../lib/app/theme/planact_colors.dart) defines semantic roles: primary, success, attention, overdue, info, background, and surface.
- [`PlanActSpacing`](../lib/app/theme/planact_spacing.dart) defines the spacing scale from `xs` through `xxl`, plus page and 48dp touch-target tokens.
- [`PlanActRadius`](../lib/app/theme/planact_radius.dart) defines chip, input, card, and bottom-sheet shapes.
- [`PlanActMotion`](../lib/app/theme/planact_spacing.dart) defines short, standard, and emphasis durations and the shared ease-out curve.

Do not introduce arbitrary colors, radii, elevations, or motion timings in feature widgets when a token or Material component theme is appropriate.

## Typography

[`PlanActTypography`](../lib/app/theme/planact_typography.dart) derives its text theme from Material 3 and applies semantic weights for display, headline, title, and action roles. Persian copy remains the default. Mixed Persian/Latin content and numbers must use normal text shaping and locale-aware formatters; do not reverse strings or perform scattered digit replacement.

## Component treatments

[`PlanActTheme`](../lib/app/theme/planact_theme.dart) is the single source for shared Material 3 treatments:

- App bars are quiet, surface-colored, and use minimal elevation.
- Navigation bars use a restrained selected indicator and a 72dp height.
- Filled, outlined, text, and icon buttons preserve a 48dp minimum touch target.
- Cards use surface hierarchy and a shared 16dp shape without heavy shadows.
- List tiles inherit consistent padding and shape.
- Text fields are filled, outlined, and use the shared input radius.
- Chips, dialogs, bottom sheets, and snackbars use shared shapes and spacing.
- FABs use primary-container contrast and are reserved for the primary action.

Financial values and statuses must remain explicit in text and not rely on color alone. Reconciliation UI must show the expected record, actual transaction, match explanation, consequence of confirmation, and undo/reversal path.

## Motion and feedback

Motion communicates insertion/removal, state changes, expansion, reconciliation, archive/undo, selection, success, and navigation continuity. Routine navigation has no haptic feedback. Prefer implicit animations and avoid animation-frame assertions in tests. Loading, disabled, success, warning, error, selected, resolved, and archived states must be visible and understandable in Persian.

## Accessibility

Use directional Flutter APIs and semantic labels. Preserve 48dp touch targets, readable contrast, text scaling, screen-reader meaning, and color-independent status communication. Avoid unnecessary shadows, blur, animation controllers, and rebuilds. Reduced-motion support should favor final-state correctness over decorative transitions.

## Journey consistency

The commitment flow keeps create, save, Today, status, archive, and undo visually coherent. Financial flows distinguish expectations from transactions and make matching consequences explicit. SMS imports remain staged until review and confirmation. Account rows, transaction history, filters, details, Inbox suggestions, and Attention cards reuse the shared Material treatments.

## Review checklist

Before adding a visual pattern, check the theme and shared tokens first. Confirm RTL, Persian copy, touch targets, text scaling, loading/error/empty states, undo or confirmation requirements, and restart-safe domain behavior. Design changes must not alter product semantics or persistence rules.
