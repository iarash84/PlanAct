# Priorities 6 and 7 — partial implementation checkpoint

Status: **Partial**, not release acceptance. Existing priorities 1–5 keep their independent unresolved gates. Priorities 8–10 are outside this change.

## Implemented path

- Commitment Details exposes a shared Jalali date picker and explicit date/time edit scopes: only this, this and following, or future automatic occurrences of the active cycle.
- Writes reload the plan transactionally, reject stale input and resolved/past occurrences, preserve manual overrides, original values and stable occurrence identifiers, and retain older schedule definitions.
- Recurring date/time edits create a schedule version. Fixed-count/manual schedules, monthly/yearly date shifts and non-unit interval date shifts are rejected instead of inventing termination or recurrence semantics.
- Result choices include completion, attendance, cancellation, no-show and partial completion. Actual insertion and occurrence status update commit in one SQLite transaction. Reopening appends a new result and retains earlier results; it is not a financial or entitlement reversal.
- Existing actual fields cannot be overwritten through the repository; evidence addition still uses the existing evidence contract.
- Details offers result history with loading, empty and error states. Database commit and reminder delivery remain separate outcomes.
- No schema migration or dependency was introduced; the new outcome is appended to the persisted enum to retain existing indices.

## Evidence

Repository tests cover file-backed reopening, same-second append order, stale result rejection, transaction rollback, persisted schedule versions and preservation of manual/resolved rows. A widget test covers all-day date editing without inventing a time. These tests do not establish native delivery or complete product acceptance.

## Remaining acceptance gates

- Full recurrence frequency/termination editing, fixed-count remainder semantics and regeneration beyond the materialized horizon. Version boundaries and logical generation identity need explicit integration tests before claiming infinite/open-ended series editing complete.
- Append-only intermediate schedule edit audit: current storage retains original/current times and schedule definitions, not every intermediate single-occurrence change.
- Reopening restores an actionable scheduled/rescheduled state, not an exact prior status snapshot; no explicit reversal reference is stored. Partial results remain pending decision.
- Same-second ordering currently follows SQLite row insertion order. Production file backup retains it, but arbitrary logical row re-import/reordering is not yet proven. ABA/concurrent partial-result updates need a durable revision contract.
- Complete Today/Calendar outcome journeys, note/evidence capture, accessibility/large-text and both-theme acceptance, multiple-cycle history selection, and command refresh error boundaries.
- Reminder intent is synchronized after domain commit. Same-time interrupted reopening recovery and native cancellation/delivery retain the Priority 5 gates in TRANSACTIONAL_PLATFORM_VERIFICATION.md.
- No automatic policy/financial/entitlement consumption or reversal is added. Policy-confirmed consumption and correction remain separate commands.

Do not label priorities 6 or 7 fully implemented based on this checkpoint.
