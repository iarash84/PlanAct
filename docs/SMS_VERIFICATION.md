# Priority 3 — SMS ingestion checkpoint

Status: **Partial implementation, not release complete**.

## Implemented in this checkpoint

- Inbox subscribes to native SMS events and uses them only as provider-rescan triggers. Financial staging uses Android inbox row identities, not ephemeral broadcast identities.
- Inbox rescans on return to the foreground; overlapping reloads are coalesced.
- Broadcast timestamps use the SMS timestamp rather than a fresh wall-clock timestamp.
- Undated SMS suggestions use the provider receipt timestamp when supplied. Suggestion times are normalized to the existing database's second precision before confirmation.
- Unsupported messages, database ingestion failures, and event-stream failures have distinct Persian feedback; errors no longer disappear in a catch-all per-message handler.
- Android provider access exceptions return sanitized channel errors rather than escaping the handler.
- Persisted confirmed/rejected suggestions cannot be overwritten through stale edits. The repository enforces this inside a transaction.
- Existing atomic staging and confirmation continue to require explicit user confirmation before ledger writes. Duplicate-content detection has a distinct error type.

## Automated evidence

- Formatting completed for changed Dart files.
- Flutter analysis: no issues.
- Full Flutter suite: **256 passed**.
- Isolated Android debug build: succeeded. No installation or SMS read performed during this checkpoint.
- Whitespace validation: passed.
- New file-backed tests cover cold restart, replay after raw-text expiry, rejected-history preservation, duplicate replay under a different provider key, receipt-time fallback, and no automatic financial entries.
- New safety test proves stale edits cannot reopen confirmed/rejected suggestions; existing tests cover concurrent confirmations, restart retries, source conflicts, and injected transactional rollback.

## Persistence and privacy

No schema migration or dependency was added. Existing raw-text expiry and backup redaction remain unchanged. No extra native raw-SMS store was introduced. The system SMS provider is the replay source; a broadcast alone is not a durable PlanAct receipt.

## Remaining release gates

- Ingestion currently runs while Inbox is open or reopened, not as an application-wide background worker.
- The provider query is still limited to 500 relevant rows; older history, pagination, and reliable backlog recovery are not complete.
- The two-second broadcast rescan delay is best effort. A slower provider insert requires another refresh or foreground transition.
- Native multipart delivery, process-death recovery, permission denial/revocation/settings return, and Android-version matrix require isolated synthetic-device evidence.
- Source row IDs are provider-local. Global text fingerprints currently conservatively suppress equal-content messages; distinct legitimate transactions with identical bodies need an explicitly approved identity policy and migration/compatibility tests.
- Persisted parser metadata (direction, confidence, bank/account hint) and explicit selection of an account when several are compatible are not complete.
- Full Jalali SMS date parsing, ambiguous transfer classification, manual unsupported-message recovery, atomic stale-edit conflict handling, and critical widget journey tests remain open.
- Do not describe this checkpoint as complete SMS automation or release-ready Priority 3.
