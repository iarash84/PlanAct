# 0021 — Opt-in foreground synchronization of new SMS

Date: 2026-10-14. Updated by the approved unified SMS UX decision, 2026-11-08.
The original automatic-only Inbox refresh semantics below are superseded by this
manual/automatic split; the automatic lifecycle and bounded-history safeguards remain.

## Decision

Permission alone is not import consent. Inbox offers one setup with an explicitly
unselected 7-day, 30-day or from-now choice and an independent, initially-off
automatic switch. Start captures its timestamp synchronously at the dialog action,
before dialog completion, queued work or asynchronous permission checks. Before any
provider read, one transaction compares fresh metadata and saves historical consent,
a separate manual new-message boundary and the selected automatic state. History ends
at Start; manual checking begins there, covering messages arriving during setup.
Setup feedback counts newly staged suggestions across history and manual scans once,
including a shared-boundary message, not only the final manual scan.

After setup, the always-visible manual button and Inbox pull to refresh invoke the
same manual command, even with automatic ingestion off. Manual consent/progress is
independent of historical and automatic scans. Startup/resume, foreground broadcasts
and Today pull to refresh remain automatic-only; merely opening Inbox does not grant
consent. Historical imports and interrupted-history Resume are explicit actions,
never a side effect of refresh or manual new-message checking.

Without a manual record, a valid old historical new-only window, otherwise a valid
automatic new-only window, supplies its boundary without a consent-creating read.
Range-only legacy consent requires explicit from-now activation. Existing manual
windows are not narrowed; existing enabled automatic boundaries/progress and staged
decisions are preserved. Disabling automatic ingestion preserves staged data and the
manual boundary; re-enabling starts a fresh automatic boundary only.

## Execution and persistence

The application scope owns foreground broadcast listening and startup/resume sync,
even with Inbox closed. Broadcasts trigger delayed bounded provider scans rather than
staging payloads with a second identity. No permanent background service is added.
Missing/revoked permission prevents reads; prompts require explicit action. Pending,
new-count/zero-result, permission and retryable-error feedback remain distinct.
Scanning never automatically saves financial entries.

Historical, manual and automatic scans have separate versioned metadata and share
serial repository admission. Each run fixes its upper bound, pages by timestamp and
row ID, and checkpoints only safely handled rows. New-message retries replay the
consented window for delayed insertions. Stable provider row identity preserves the
existing suggestion/decision on replay; different SMS row IDs remain distinct even
with identical body/time. Non-SMS exact-fingerprint deduplication remains in force.

The additive [manual metadata key](../../lib/features/inbox/data/drift_inbox_repository.dart:38)
uses the existing metadata extension store alongside historical and automatic keys.
No schema migration or dependency is added. Consent/progress belongs in personal
backup and survives restart; automatic continuation after restart/restore is allowed
only for enabled automatic consent, while history requires explicit Resume. Unknown
keys in older binaries do not establish semantic downgrade safety.

## Evidence and limits

See the [current acceptance/evidence record](../SMS_VERIFICATION.md). The latest
reported targeted run is 15 suites / 209 passing tests, with clean analysis, format
and diff checks. Read-only review found Start-time capture, setup-count and obsolete
cancellation-route gaps; fixes have regression coverage, not final independent sign-off.
Production repository cold reopen and a redacted SQLite snapshot prove bounded
persistence, not full encrypted export/restore, in-flight exclusion or scope/listener
rebind. Populated filter/page/selection/scroll retention is not specifically proven;
concurrent history/manual overlap remains uncertain despite shared-boundary and
manual/automatic checks. Native permission/provider/lifecycle, screen-reader and
reference-device performance evidence and final independent acceptance remain open.
Replaying a growing consent window is not constant-cost synchronization. The
capability remains Partial; local implementation evidence is not release acceptance.
