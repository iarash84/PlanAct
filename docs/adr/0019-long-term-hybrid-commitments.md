# ADR 0019 — Long-term hybrid commitments

Date: 2026-10-12. Status: user-approved product direction; implementation acceptance Partial.

## Context

Count and inclusive end-date termination already persist. Operational generation horizons (legacy 90 days; newer bounded windows) explain sparse future rows, not a row-display limit or lost termination. Infinite materialization is neither required nor safe. The acceptance contract in [verification](../MONTHLY_YEARLY_RECURRENCE_VERIFICATION.md) was recorded after the working-tree implementation, not before.

## Decision

- Keep full durable schedule rules: frequency/interval, reference calendar, immutable original day/month anchors, time semantics, start, inclusive end or logical-slot count, effective versions, reminder and financial generation templates. Entitlement is independent.
- Operational rows represent admitted occurrences and historical outcomes. Existing startup/resume rolling maintenance remains an explicit bounded command, never a read side effect.
- Details and Calendar Month/Week may read bounded future range previews alongside recorded history. Preview is calculated from durable state, has no fake occurrence ID and creates no reminder, financial, session or history effects. This supersedes the PRD's Calendar recorded-only restriction, not its read-only guarantee.
- Count measures logical slots, including occupied/resolved slots, independently of horizon and row population. Retain legacy Gregorian compatibility, original anchors, same-target-month clamp and version boundaries. Manual original/current occupancy suppresses duplicates; every historical status remains recorded.
- Only explicit preparation admits a preview: obtain transactional writer admission, reread active owner/cycle, versions, exact metadata/templates and original/current occupancy, reject stale, past, occupied or ambiguous slots, then atomically insert one real occurrence with dependent reminder/financial intent. Platform delivery is post-commit; failure there is not a failed domain commit. Reload/retry must be visible; cancellation does not write.
- No automatic past backfill, historical repair, financial posting, entitlement consumption or full recurrence editor. Recovery of missed past slots remains a separate unresolved product decision.

## Consequences / evidence

No physical schema, migration or dependency is added: existing durable recurrence JSON/templates and tables remain authoritative and portable through strict encrypted personal backup. Read projections are ephemeral, not a second source of truth. Host domain/repository/route evidence does not establish native delivery, device-loss recovery, accessibility or reference-device performance. Owners, next actions and release-blocking independent gates are recorded in the verification document. Existing shared Light/Dark tokens remain unchanged; this is not a broad redesign.
