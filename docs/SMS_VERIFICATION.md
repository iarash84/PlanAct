# Priority 3 — SMS ingestion checkpoint

Status: **Partial implementation, not release complete**.

## Independent Inbox review repair acceptance contract (2026-10-11)

Entry: Inbox review queue after explicit import; reviewing persisted suggestions
requires neither SMS permission nor a new scan. Unconfirmed suggestions offer
Persian rejection with explicit recovery via Undo and the rejected-items filter.
Confirmed suggestions remain historical and guide users to existing Finance
correction, never deletion or Inbox rollback. Rejection removes only the committed
item from the pending queue; failed writes retain it and offer retry. Each item has
its own pending state; other rows and scrolling remain usable. Refresh retains
scroll, bank/status filters, ordering and open form state. Duplicate row commands
are suppressed; stale reads/commands must not overwrite newer review revisions.
Receipt date and extracted transaction date are separately labelled; absent bank
or date provenance remains unknown, including legacy records. Equal-date ordering
uses stable IDs. No parser expansion, native ingestion change or dependencies.

Trace: row action → Inbox command → fresh transactional review/revision guard →
suggestion/import + versioned metadata write → keyed lazy-list refresh → Finance
and explicit rescan. Recovery appends review history and reopens the same draft;
it does not reverse a confirmed entry or restore expired raw SMS. Versioned
metadata uses the existing schema table: legacy absence maps to unknown/revision
zero, without rewriting saved dates. Personal backup must preserve this metadata
while retaining existing raw-text redaction. Evidence required: reject/recover,
failed-save retry, different-row concurrency, duplicates/stale work, rescan,
file-backed cold reopen, legacy compatibility and production snapshot preservation;
route-level equal-time/unknown-bank/filter/scroll/large-list responsiveness checks.
Native frame-time budgets and independent acceptance remain separate release gates.

## Independent Inbox review repair implementation and evidence

Implemented scope:

- Inbox rejection and explicit recovery compare fresh status and monotonic revision
  inside one SQLite transaction, update suggestion/import together, and append
  rejected/reopened decisions. Edits and confirmation append decisions too. A
  confirmed suggestion has no Inbox rejection/recovery control and directs the
  user to Finance correction. Review never removes or reverses financial entries.
- Per-ID admission/pending feedback replaces the global row lock. Failed rejection
  retains the item and offers Persian retry; committed rejection offers Undo.
  Rejected-items browsing can recover after the transient Undo feedback expires.
- Keyed lazy rows, a retained scroll controller, bank/status filters and stable
  receipt/import-time plus ID ordering preserve browsing context. Refresh epochs
  discard pre-commit results. Open edit/confirmation routes are not replaced by
  refresh. The new cancellation journey caught premature edit-controller disposal;
  disposal now waits for the sheet's closing route to finish.
- Parser evidence, bank/direction/quality, receipt timestamp, extracted-versus-
  receipt date origin, revision and review history persist in per-item version-1
  metadata. Undated parsing returns absence, not a parser-generated current time;
  an explicit provider receipt fallback is visibly proposed before confirmation.

Compatibility and backup:

- SQLite schema remains version 18; no table, column, dependency or native change.
  This is a versioned metadata evolution using the existing schema_metadata table,
  not a destructive schema migration. Missing legacy metadata reads as revision
  zero with unknown evidence/bank/date origin. First explicit write creates metadata
  without inferring old provenance or rewriting saved dates. Unsupported metadata
  versions fail rather than being silently reinterpreted.
- File-backed tests remove metadata to exercise legacy compatibility, cold reopen
  rejection/recovery revisions, and replay the same source after restart. Production
  redacted snapshot/export is opened in an isolated database: bank, review revision
  and append-only history survive; raw SMS stays redacted, and recovery still works.
  Existing migration and backup/schema compatibility suites passed in the full run.

Automated verification (2026-10-11):

- `dart format lib/features/inbox test/widget/inbox_review_repair_test.dart test/widget/inbox_account_selection_test.dart test/repository/inbox_review_repair_test.dart test/unit/inbox_test.dart` passed.
- `flutter analyze` passed with no issues; rerun after final presentation copy passed.
- `flutter test test/widget/inbox_review_repair_test.dart test/widget/inbox_account_selection_test.dart test/repository/inbox_review_repair_test.dart`: **10 passed**.
- `flutter test`: **545 passed** (full suite). Final heading/number-format copy then
  passed `flutter test test/widget/inbox_review_repair_test.dart test/widget/inbox_account_selection_test.dart`: **7 passed**.
- Final `dart format --output=none --set-exit-if-changed` for the affected Dart paths
  and `git diff --check` passed; temporary full-suite output was removed.
- New repository evidence covers mistaken rejection/recovery, stale duplicate
  commands, injected transactional write failure/retry, different-item concurrency,
  rescan, cold restart, metadata absence, equal-time stable ID ordering and unknown
  bank filtering, plus production redacted backup preservation.
- New route evidence covers concurrent pending rows, delayed stale refresh after
  commit, duplicate taps, failure/retry/Undo, bank/status retention, Dark RTL at 1.5x
  text scale, lifecycle refresh with an edited form open, and a 1,000-row lazy queue
  with scrolling while a rejection waits. Existing account journeys protect explicit
  financial admission, failure/cancellation and cold reopen in Light/Dark.

Readiness and unexecuted gates:

- Bounded review repair is implemented and automated checks pass. This is not
  independent acceptance sign-off or native responsiveness evidence. The 1,000-row
  fixture proves lazy rendering/interaction, not a device frame-time budget.
- Owner: release QA/product reviewer. Next: independently review Inbox rejection,
  recovery, confirmed-item correction guidance and filter/form retention on an
  isolated reference Android device; record device/specification, frame-time budget,
  narrow-screen/large-text usability and real provider date behavior. Exposure:
  development checkpoint only; do not claim SMS/review capability release-ready
  until these checks and the existing SMS/backup native gates are accepted.
- No native build/install/provider access or fresh-install native restore was run
  for this repair. Existing ingestion identity limitations and native permission,
  provider compatibility, restore and performance gates remain unchanged. Edit-save
  failure reports visibly but does not retain a closed edit draft for automatic retry;
  the requested rejection retry and open-form refresh guarantees are covered.

## Bounded consent/resume acceptance contract (2026-10-11)

Entry: Inbox with Android permission independently granted. Permission, navigation,
refresh and lifecycle resume do not authorize history. Users explicitly select a
visible bounded recent range or new-only from consent time. Native source queries
use date bounds and ascending timestamp + row ID paging, inspecting at most 100
rows per page (irrelevant rows also advance the cursor), off the main thread.
Consent, fixed upper bound, cursor and progress survive restart in a versioned
existing metadata entry. Interrupted, cancelled and failed scans offer explicit
Resume/Retry. Checkpoints follow safe staging; replay preserves confirmed/rejected
history. Cancellation stops between rows without erasing committed work. No service,
parser redesign or financial automation. Restore preserves state but cannot start a
scan without explicit Resume. Existing global fingerprint suppression remains an
identity limitation, not proof of lossless identical-body transaction ingestion.

Trace: Inbox choice → application scan → source page → staging command → durable
checkpoint → progress/Inbox refresh → explicit financial confirmation.
Evidence: bounded source contract, equal-time paging/resume, permission-only UI,
cancel/retry, file-backed reopen, backup preservation, volume and regression checks.
Native provider compatibility, process kill, permissions and frame-time performance
require isolated device evidence and independent review before release.

## 2026-10-11 implementation and evidence

This section supersedes the older provider-rescan implementation below.

- Permission checks, Inbox reload, broadcasts and lifecycle transitions now only
  refresh state; none reads provider history. Explicit choices are 7 days, 30 days
  or new-only from consent time. No choice is preselected.
- Android queries use date bounds, ascending timestamp/row ID and LIMIT 100 on a
  dedicated executor. Irrelevant rows advance the cursor without crossing the
  channel with their bodies. Null cursors and provider/permission failures fail
  visibly rather than claiming an empty successful scan.
- Versioned consent/checkpoint/progress resides in existing schema metadata.
  Compare-and-write runs transactionally. A scan holds the application command
  admission lease; cancellation/background/disposal stop between rows. Page-end
  checkpoints follow safe processing; crashes replay bounded pages. Source/content
  conflicts fail retryably rather than being misclassified as unsupported formats.
- Explicit new-only scans replay the consented window, recovering delayed rows
  behind the old cursor. This trades longer-term scan cost for safety. Historical
  completed windows can be explicitly selected again for delayed provider rows.
- No schema migration or dependency added. Old databases/backups without scan
  metadata start without consent. Production redacted backup snapshots preserve
  the checkpoint without including a new raw-message store.
- Automated evidence includes 10,000 equal-time provider rows (100 relevant),
  cancellation after 137 rows, cold reopen, source failure/retry, rejection
  preservation, stale checkpoint rejection, delayed insertion, channel argument
  bounds, malformed payload failure, permission-only Inbox and cancelled selection.
  Existing confirmation/reopen tests cover financial admission. The production
  snapshot test checks checkpoint preservation with raw-text redaction.
- Initial per-row checkpointing exceeded the 30-second volume test timeout;
  page/cancel checkpointing removed that bottleneck. The volume fixture is a
  correctness/workload regression, NOT a reference-device performance benchmark.
- Validation: focused suite 11 passed; full Flutter suite 539 passed; analysis no
  issues; Android debug APK build succeeded. Final post-safeguard rerun also passed
  all 539 tests with no analyzer issues (including delayed-insertion recovery and
  retryable source-conflict handling). Formatting and whitespace checks passed.
  No installation or real SMS read occurred.

### Remaining gates and exposure decision

**Not release-ready; no independent acceptance sign-off.** Owner: Android integration
maintainer, next action: isolated synthetic-provider/device runs for LIMIT support,
permission denial/revocation, process death, multipart/delayed insertion and large
provider responsiveness. Proposed reference device for acceptance: Pixel 4a, Android 13,
6 GB RAM, isolated synthetic SMS provider dataset; device availability and independent
run are not yet confirmed. Target budget: no native main-thread query; progress/cancel
interaction response within 100ms and ordinary frames within 16.7ms. Measure a 10,000-row
provider with both sparse-relevant and all-relevant workloads in a profile build.
Neither budget has measured device evidence. All-relevant large-volume parser/database
cost remains unmeasured; staging still reads existing imports for deduplication.

Owner: product/domain maintainer, next action: approve provider identity and compatibility
policy before claiming lossless identical-body transactions. Global content fingerprints
still suppress distinct identical-body messages, including equal-time messages. Timestamp
plus ID paging prevents cursor omission but does not remove that independent limitation.
Restored checkpoints/source row IDs remain provider-local; restore across devices needs
explicit range re-selection and native acceptance. Full logical backup replacement/rebind
and reference-device Light/Dark, narrow/large-text review remain existing release gates.
No permanent service or background automation is exposed by this change.

## Earlier checkpoint (historical evidence)

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
- Persisted parser metadata (direction, confidence, bank/account hint) remains incomplete. Explicit durable financial-account selection, account creation/return and confirmation regressions are recorded in [financial account selection verification](FINANCIAL_ACCOUNT_SELECTION_VERIFICATION.md); this does not close the native ingestion gates.
- Full Jalali SMS date parsing, ambiguous transfer classification, manual unsupported-message recovery and atomic stale-edit conflict handling remain open. Confirmation-to-ledger widget journeys now have local automated coverage; the broader ingestion/device journeys remain open.
- Do not describe this checkpoint as complete SMS automation or release-ready Priority 3.
