# ADR 0004: Persian-first, Jalali, and RTL experience

- Status: Accepted
- Date: 2026-09-20

## Context

The application is intended for Persian-speaking users. A Persian interface, right-to-left layout, and Jalali calendar are product requirements rather than optional presentation polish.

## Decision

- Persian is the default user-facing locale.
- All user-visible copy, validation messages, statuses, empty states, accessibility labels, onboarding, and notifications are Persian unless an explicit product decision documents an exception.
- The UI uses RTL directionality by locale and Flutter's start/end layout APIs. Manual list reversal and left/right-specific layout hacks are prohibited.
- User-facing date selection and display use the Jalali calendar with Persian month and weekday names and locale-aware Persian digits.
- Domain and persistence layers retain unambiguous date/time semantics. Calendar conversion remains at presentation/adapter boundaries; all-day local dates are not stored as midnight UTC.
- Calendar, date conversion, formatting, and RTL behavior require unit/widget tests for Persian locale, DST/timezone boundaries, leap years, month-end behavior, and directional layout.

## Consequences

- A Jalali-capable date adapter/package may be introduced when the calendar UI milestone requires it; that dependency must be recorded and tested.
- Existing domain time abstractions remain Gregorian/instant-neutral internally where appropriate and expose localized representations through presentation services.
- Screens delivered before the full Persian UI milestone must not introduce English-only user-facing strings as permanent product copy.
