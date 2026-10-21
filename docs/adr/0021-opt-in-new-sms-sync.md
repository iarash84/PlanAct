# 0021 — Opt-in foreground synchronization of new SMS

Date: 2026-10-14. Product authorization: the user's request to synchronize new
messages automatically, on app opening and on pull to refresh.

Permission alone remains insufficient consent. Inbox exposes a separate, initially
off, persistent choice for automatic new-message ingestion starting at activation.
Existing range/new-only import consent does not enable it. Turning it off preserves
staged suggestions; enabling it again starts a fresh boundary.

The application scope owns foreground broadcast listening and startup/resume
synchronization, including when Inbox is closed. Today and Inbox pull to refresh
await the same command. Broadcasts trigger delayed bounded provider scans rather
than staging broadcast payloads with a second identity. No permanent background
service is added. Missing/revoked permission prevents reading and is actionable in
Inbox; permission prompts require explicit user action.

Automatic and historical scans have separate versioned metadata and share serial
admission within a repository. Each run fixes its upper bound, pages by timestamp
and row ID, and checkpoints only handled rows. New-message retries replay the
consented window to recover delayed provider insertion. The stable provider row ID
is the SMS source key: replay of that key returns the existing suggestion and
preserves its decision, while different SMS row IDs remain distinct even when body
and receipt time are identical. Exact-fingerprint deduplication against non-SMS
imports remains in force. This avoids silently losing separate provider messages
without changing schema or automatically creating financial entries.

Automatic consent/progress survives cold restart and logical backup/restore in
schema_metadata. An enabled automatic new-only scan may resume on app opening
after restart/restore; historical interrupted scans still require explicit Resume.
This replaces the earlier lifecycle prohibition only for this separate opt-in.
Old versions ignore this new key; semantic downgrade safety is not established.
No schema migration or dependency is needed.

Native provider compatibility, permission lifecycle, delayed delivery and device
performance require separate device acceptance. Replaying a growing consent window
is a known performance limitation, not a claim of constant-cost synchronization.
