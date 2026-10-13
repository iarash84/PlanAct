# Priority 3 — SMS ingestion checkpoint

Status: **Partial implementation, not release complete**.

## Real-format additive parser acceptance contract (2026-10-12)

Recorded before code changes. Scope: the 18 user-supplied, privacy-redacted
same-shaped messages (Sina 2, unbranded account 2, unbranded dotted 4,
Refah 2, Melli 4, Shahr 3, Gardeshgari 1), not a general bank catalogue.
Entry remains explicit consented bounded Inbox scan → LocalSmsParser → stageSms
→ atomic Drift staging → existing review refresh → explicit financial confirmation.
Permission alone never scans; parser recognition never writes the financial ledger.

Preserve GenericBankSmsParser grammar unchanged; add a separate bounded parser.
Accept Arabic/Persian digits and yeh/kaf, prefix/suffix signs and dotted/dashed
account evidence. Require one transaction amount/direction, separate balance,
validated date/time and recognized whole-message structure. Reject OTP/failure,
duplicate/contradictory fields, malformed units/dates and integer overflow.
Unbranded structures retain null bank, never infer bank from account identifiers.
Missing amount unit requires explicit selection, regardless of Settings/bank.
Unitless balance remains absent Money evidence unless the transaction explicitly
establishes the same message unit; do not infer units from sender or preference.
Short/absent years preserve sourceDate/sourceTime with absent extracted occurredAt;
never invent a century/year. Full Jalali dates allow single-digit month/day.
Transfer evidence remains true even with incoming sign; existing original-evidence
confirmation guard must prevent income/expense writes after direction edits.

Existing receipt proposal acknowledgement, cancellation/no-write, edit/retry,
rejection/recovery and Finance correction semantics remain unchanged. New parsing
only affects new staging; replay must retain stored drafts, evidence and history.
No schema, migration, dependency, consent or native adapter expansion. Necessary
presentation prerequisite discovered by route tests: guard partial-year evidence
in original-date display and editor initialization; no new screen or design variant.
Required evidence: all 18 fixtures plus independent expected amounts/directions/dates,
old labelled regressions and adversarial rejection; production staging, cold reopen,
redacted snapshot preservation and transfer admission; existing route review gates.
Native provider/timezone/device restore and independent acceptance remain open,
owned by Android integration/release QA and product reviewer. Exposure remains
Partial / development-only, not release-ready; broader corpus review remains open.

## Bounded real-format implementation and evidence (2026-10-12)

This checkpoint supersedes earlier synthetic-only coverage statements for these
18 shapes only; prior full-suite counts remain historical, not rerun evidence.

- Separate [real-format parser](../lib/features/inbox/application/real_bank_sms_parser.dart)
  is dispatched after the unchanged generic labelled grammar. Recognition uses
  seven anchored whole-message layout families, not loose number extraction.
- [18 redacted fixtures](../test/fixtures/real_bank_sms.dart) retain amount/date/sign
  structure while replacing every account identifier and personal name. Independent
  amount/direction/bank expectations and explicit Gregorian date expectations are
  tested by [38 parser tests](../test/unit/real_bank_sms_parser_test.dart), including
  Arabic normalization, unitless/explicit balances and adversarial rejection.
- Missing transaction units stay requiresSelection. An explicit transaction unit
  establishes the same-message unit for a unitless balance; an explicit balance
  unit alone does not resolve the transaction. With neither unit, balance Money
  is absent. Settings, bank and account identity never supply units.
- Two-digit, month/day and MMDD dates retain sourceDate/sourceTime with null
  extracted occurredAt. Full Jalali dates are validated, including leap-day rules.
  Receipt proposal and explicit acknowledgement remain existing review behavior.
- [Production durability test](../test/repository/real_bank_sms_test.dart) stages
  all 18, verifies replay and file-backed cold reopen, preserves original evidence
  through an isolated redacted SQLite snapshot/reopen, and proves both application
  and atomic repository transfer admission reject income after reviewer edits.
  No ledger rows are created by recognition, replay or blocked confirmation.
- [Review routes](../test/widget/sms_editable_review_test.dart) open original evidence
  and editing for all 18 shapes; real transfer remains blocked after explicit unit
  selection and direction edit in Light/Dark, RTL, 320px and 1.8 text scaling.
  The first route run exposed full-year assumptions in both original display and
  editor initialization. These are now guarded: partial dates display Persian
  evidence with year-unknown disclosure and never initialize a fabricated date.
  Missing check that allowed the defect: previous route fixtures had no compact
  or short-year source dates. The new corpus journeys protect both entry points.
- Final scoped format: seven Dart files, no further changes. Full analyzer:
  **no issues** (5.5s). Focused 17-file parser/source/application/repository/backup/
  widget regression suite: **162 passed, 0 failed** (24s). This includes existing
  bounded ingestion, review retry/recovery, currency selection, account selection,
  extracted-evidence, confirmation and full-state backup regressions. Full app suite
  was not rerun for this checkpoint. No native/provider SMS was read.

Implementation: bounded slice implemented. Verification: automated evidence above,
self-review only; independent acceptance is unexecuted. Release: still **Partial /
development-only**. Android integration/release QA owns native provider variants,
receipt timezone/device checks and fresh-install backup evidence; next action is an
isolated consented device run with these shapes and adversarial provider variants.
Product reviewer owns broader corpus/source review and independent acceptance;
next action is review of observable unit/date/transfer counterexamples. Existing
older-writer compatibility and backup/native gates remain blockers, not waived by
parser tests. Existing drafts are not reparsed or migrated; AGENTS safeguards are
unchanged. No new dependencies, schema changes or migrations were required.

## Final bounded extraction/review integration validation (2026-10-11)

This section supersedes subtask-only pending parent actions and full-suite limitations
below; earlier counts are historical evidence, not the final integrated result.
The acceptance contracts below remain the scope: explicit bounded scan → durable
original evidence → Persian edit/save → explicit classification/time/account review
→ transactional confirmation → Inbox/downstream refresh. No automatic ledger writes,
actual-bank coverage, native release approval or general free-text recovery is claimed.

### Exact final automated evidence

- Scoped formatting covered all **17 changed/new Dart files**: the initial 15 were
  already formatted; the two integration fixture files were formatted after correction.
- Full analyzer: **no issues**, final run 8.6 seconds.
- First full suite: **655 passed, 3 failed** (658 total). Failures were
  `projects source, deterministic reason, account and duplicate warning` and
  `confirmation failure does not resolve pending review` in
  [projection fixtures](../test/unit/inbox_review_projection_test.dart), and
  `SMS confirmation routes the imported entry, not another transaction` in
  [contextual route](../test/widget/contextual_reconciliation_test.dart).
  They used unsupported unlabelled/trailing-date fixture text. Only those SMS fixtures
  were changed to supported labelled input with explicit units/date/time; the route
  now scrolls to account selection and performs the required classification acknowledgement.
  Conservative parser rejection was not weakened. A first focused retry found the
  account control off-screen (**13 passed, 1 failed**); explicit scrolling fixed that
  test interaction. Final focused regression run: **14 passed, 0 failed**.
- Final **full Flutter suite: 658 passed, 0 failed**, 5m31s.
  Temporary local command-output files were removed after validation; this record
  retains the results, and the committed tests provide reproducible checks.
  This includes older schema/migration fixture suites, legacy missing metadata,
  [full logical backup/restore](../test/repository/backup_full_state_test.dart),
  [schema compatibility](../test/repository/relationship_schema_fixture_test.dart),
  and [SMS evidence cold reopen/redacted backup](../test/repository/sms_extracted_evidence_test.dart).
- Windows cmd output was redirected locally; PowerShell console decoding may render
  Persian labels incorrectly, so inspect UTF-8 logs in the editor. Tests use synthetic
  fixtures; no device/provider SMS was read, no sensitive production logging was added.
  No dependency, schema/table/column, migration or native adapter change was introduced.

### Focused code acceptance self-review (not independent sign-off)

- Reviewed amount/unit edits reconstruct reviewed source amount from exact integer
  conversion; transactional confirmation revalidates current durable evidence against
  canonical IRR before writing. Inconsistent, unresolved, zero/negative and stale
  inputs are tested, including rollback/retry. Original amount/unit remains immutable.
- Original transfer evidence survives direction edits and blocks both application
  and direct production repository income/expense admission; route tests assert no write.
- Partial source date/time remains independently absent/present. No parser-generated
  midnight or current time becomes extracted evidence. Receipt/unknown proposals are
  visibly disclosed and require route acknowledgement; explicit corrections retain
  reviewer provenance. These UI acknowledgements are route gates, not a new persisted
  acknowledgement field or proof for an alternate future command caller.
- Original extraction and complete edit/confirmation snapshots survive raw expiry,
  file-backed reopen and isolated redacted snapshot restore; legacy absence remains
  unknown and is not reconstructed by reparsing. List/details masking and retained
  failed-save input have route evidence. Existing refresh/relationship callbacks and
  contextual imported-entry navigation are included in the final full suite.
- [PRD](product/PRD.md) and [agent safeguards](../AGENTS.md) now explicitly align
  immutable evidence, exact amount/unit validation, absent-time semantics, visible
  proposals and transfer no-write. No material integrity defect was found in this
  bounded production path during this self-review; this is not an independent review.

### Supported templates, compatibility and exposure decision

Only the **labelled synthetic grammar** specified below is supported: newline/semicolon
fields, one integer amount, optional separate balance, validated partial/complete
Jalali/Gregorian date/time, bounded bank/account/reference/merchant evidence and the
listed compact amount forms. Unsupported prose, duplicate amounts, malformed units,
OTP/failure notices and unknown labels remain conservative false negatives. This is
not a verified bank catalogue, authenticated sender, ownership check or lossless import.

SQLite remains schema 18. Optional version-1 metadata fields and an appended reviewer
provenance enum require no schema migration. Older readers may ignore optional fields,
but older writers may drop new evidence or bypass unknown/transfer admission (and may
not understand reviewer provenance). **Downgrade-write safety is unproven; do not approve
older binaries to write these drafts.** Existing schema tests do not prove that safety.

| Open gate | Owner / next action | Exposure decision |
| --- | --- | --- |
| Real-bank corpus and unsupported-message product coverage | Product/domain maintainer: approve a privacy-safe representative corpus and supported-template matrix; evaluate false negatives and sender/transfer ambiguity | Synthetic templates only, development-only |
| Provider compatibility, permission revocation, process death, delayed/multipart rows and performance | Android integration maintainer + release QA: execute isolated reference-device scenarios and measure the stated budgets below | Native acceptance unexecuted; release blocker |
| Identity and downgrade semantics | Product/domain + persistence maintainer: approve identical-body identity policy and test older-reader/writer compatibility, including reviewer provenance | No lossless-import or downgrade-write claim |
| Full restore replacement/rebind and device-loss journey | Backup maintainer + release QA: run isolated native restore, rebind and command-exclusion checks | Logical snapshot tests are not native restore acceptance |
| Keyboard/accessibility, real time-zone/provider behavior and independent acceptance | Release QA/product reviewer: independently execute narrow RTL Light/Dark review journeys and counterexamples on the reference device | Widget/self-review evidence only; release blocker |

Implementation: bounded extraction/review vertical path implemented. Verification:
full automated suite/analyzer passing. Readiness: **Partial / development-only**;
all native and independent gates above remain unexecuted, with no release sign-off.

## Conservative labelled parser acceptance contract (2026-10-11)

Recorded before implementation. Parent outcome: Persian editable banking-SMS review
with durable extraction evidence, not automatic financial ingestion. Entry is Inbox
explicit bounded scan (permission is separate consent) → stage → review/edit → explicit
confirm → atomic ledger write → Inbox/Finance/Today refresh. An active compatible
financial account and explicit resolution of unknown direction/unit/date are required.
Cancel must not write a ledger entry; failed edits/confirmation retain input for retry;
confirmed corrections use Finance, not Inbox deletion. Unknown/transfer direction must
block confirmation until explicitly resolved, never default to expense or income.

Parser subtask only: deterministic offline labelled synthetic templates, integer
amount/unit evidence, separate balance, bounded bank/account/reference/merchant fields,
Persian/Arabic/Latin digits, validated Gregorian/Jalali dates and times. Multiple
transaction amounts, unsupported free prose, OTP, failed and nonfinancial notifications
are rejected. Missing time yields absent occurredAt, not midnight. No bank sender
verification or actual-bank coverage is claimed. No cloud, logging or raw account
previews are introduced. Sensitive extracted account hints are evidence, not UI copy.

Parent owns domain/editable evidence, transactional admission, UI and persistence:
extraction and explicit corrections must survive cold restart/raw expiry and personal
backup with legacy unknown compatibility; receipt fallback must be visibly proposed.
Parser changes must not rewrite old drafts/history. Evidence required: synthetic parser
counterexamples; parent production cold-reopen/backup/rollback tests; route-level
scan/edit/cancel/retry/confirm and downstream refresh; isolated provider/device and
independent acceptance. This subtask provides only parser foundation evidence.

Existing trace: explicit scan calls staging; parser result populates draft; repository
atomic staging writes import/suggestion; UI review invokes edit/confirm; atomic
confirmation writes ledger and status. Existing stage maps unknown direction to expense
and confirm does not guard unknown direction. Owner: parent domain/application agent;
next action: remove fallback and enforce fresh durable unknown admission before exposing
this capability. New optional parser evidence needs explicit parent persistence wiring.
Exposure: development-only partial checkpoint; no release approval until parent and
existing native/independent gates pass. No schema, dependency, UI or InboxUseCases change
is authorized in this parser subtask.

## Editable Persian review UI acceptance contract (2026-10-11)

Entry: persisted Inbox suggestion → edit sheet → save reviewed draft → explicit
confirmation with compatible account → atomic ledger write → Inbox refresh and
existing downstream refresh callback. Permission/scan are not prerequisites for
review. Original extraction remains immutable; bank/account hint, amount/unit,
merchant/reference, direction and Jalali transaction date/time are editable.
Missing message date/time are disclosed independently; no missing time is invented.
Receipt/import fallback requires an explicit reviewer acknowledgement before ledger
confirmation. Deposit/withdrawal evidence is not presented as automatic accounting
classification; final confirmation names income/expense. Unknown stays selectable,
and original transfer evidence blocks writes with guidance to Finance transfer.
Cancel writes nothing. Validation/write errors retain sheet values for retry.
Lists omit raw account/reference/message text; details mask sensitive evidence and
separate original extraction from review. Reuse shared form/theme/date/time APIs.
No schema/dependency/native/parser expansion. Existing durable evidence/revision and
backup safeguards apply. Required evidence: route edit/cancel/error/retry/confirm,
bank/date/time corrections, ambiguous unit independent of display preference,
transfer no-write, masking, narrow RTL Light/Dark large text. Parent owns full-suite
validation; release QA owns native/provider/restore/accessibility and independent
acceptance. Exposure remains the existing development-only Partial checkpoint.

## Editable review UI verification checkpoint (2026-10-11)

Implemented scope: the [Inbox route](../lib/features/inbox/presentation/inbox_page.dart)
opens the bounded stateful [review editor](../lib/features/inbox/presentation/sms_review_editor.dart).
Validation and asynchronous edit errors retain all inputs; successful edit alone does
not create a ledger entry. Bank/account hint, amount/unit, description/reference,
unknown/deposit/withdrawal direction and shared Jalali date/time controls are editable.
Partial original date/time remains distinct from receipt proposals; changing the
transaction timestamp requires both explicit date and time. Final confirmation requires
explicit income/expense acknowledgement and, for receipt/unknown provenance, a separate
time acknowledgement. Acknowledgement permits that proposed timestamp for this write;
it does not relabel the immutable original as extracted. Explicit date/time corrections
persist reviewer provenance. Original transfer evidence remains blocking after edits.
Lists omit account/reference/raw message text; details show masked original/current
identifiers and separate original/current evidence. Editable fields intentionally expose
the reviewer-controlled identifiers only inside the edit sheet.

Evidence: [editable review journeys](../test/widget/sms_editable_review_test.dart)
cover failed save retaining bank/account fields, retry, original preservation, Settings
toman versus SMS rial independence, absent source time, Jalali picker confirmation,
explicit time selection, incomplete timestamp rejection, unknown direction admission,
classification/receipt acknowledgement gates, cancellation and transfer no-write after
edited direction. Transfer journeys exercise 320dp RTL at 1.8 text scale in Light/Dark;
they exposed filter overflow, fixed with expanded wrapping dropdowns without shrinking
text. [Production account journeys](../test/widget/inbox_account_selection_test.dart)
exercise edit → explicit classification/account → ledger, single refresh/relationship
callback, cold reopen preserving reviewed bank versus original, cancellation,
account-read retry, atomic failure retry and archival admission. Existing
[currency review](../test/widget/sms_currency_review_test.dart) and
[queue concurrency/lifecycle journeys](../test/widget/inbox_review_repair_test.dart)
remain passing. The escaped editor defect was validation after popping; route-level
invalid-unit/save-failure assertions now require the same sheet and values to remain.

Validation: scoped formatting clean; scoped Flutter analyzer **no issues**; eight focused
parser/domain/repository/widget files **81 tests passed**. No dependency, migration,
schema or native adapter change was introduced by this UI slice. Durable evidence and
backup preservation are supplied by the foundation below, not by in-memory widget tests.
No new PRD/AGENTS semantic rule is required: this implements their existing explicit
review, immutable evidence, privacy and no-hidden-time safeguards.

Readiness remains **Partial / development-only**, not independent release sign-off.
Parent owns the next full-suite run and cross-feature acceptance. Release QA owns native
SMS/provider/permission, real-bank corpus, device keyboard/accessibility and restore
journeys plus independent acceptance. Those existing gates remain release blockers;
this scoped UI evidence does not close them. The 320dp layout evidence is not an
app-wide visual audit or native accessibility certification.

## Durable extraction / reviewed state foundation (2026-10-11)

Scope: domain/application/production Drift only; parent UI owns explicit date/unit/type
review and all route feedback. This implements the existing acceptance contract above,
not the complete user capability. Unknown direction stages as unknown, never expense.
Transfer evidence blocks income/expense confirmation even after a reviewer selects a
different type; a transfer-ledger path is deliberately outside this slice.

Original evidence is established once at staging in optional
[InboxSuggestion.extractedEvidence](../lib/features/inbox/domain/inbox.dart:237), using
[SmsExtractionEvidence](../lib/features/inbox/domain/inbox.dart:260). Its original draft
contains amount/unit, balance, bank/account hint, direction/quality/confidence,
merchant/reference and receipt/date provenance. Separate sourceDate/sourceTime retain
validated original partial calendar text. Evidence occurredAt is the original complete
parsed timestamp or absent, never the reviewed draft's receipt/import fallback. The
editable draft is distinct. Reviewer date source is appended after the three existing
[TransactionDateSource](../lib/features/inbox/domain/inbox.dart:22) values; old indices stay
stable. Parent must label receipt proposals and explicitly capture reviewer date origin;
this foundation does not claim a route-level fallback acknowledgement gate.

Production edits compare revision and stable identities transactionally, preserve the
original extractedEvidence metadata regardless of supplied replacements, and append a
complete reviewed snapshot. Confirmation validates fresh durable type, positive bounded
integer amount, exact IRR reviewed amount/unit consistency, original transfer flag,
revision, account and entry details before ledger/status/history commit. Failed edits
and confirmation roll back metadata/history with rows and ledger; retry remains possible.
Reviewed currency evidence may change with an explicit amount/unit correction; original
currency evidence remains immutable in extractedEvidence. No Settings dependency,
cloud, sensitive logs, dedup identity change or raw-text retention change was added.

Compatibility: optional extractedEvidence/reviewed/history snapshot fields extend the
existing version-1 per-item metadata. No table/column change, migration, schema-version
bump or dependency is needed. Readers lacking these fields still read the unchanged
rows and recognized v1 metadata. Missing old fields remain unknown, without reparsing
raw SMS or manufacturing original evidence on the first edit. Existing unknown keys and
history survive current writes. This is additive read compatibility, not semantic
permission to confirm new unknown/transfer drafts with older binaries; downgrade write
safety and complete parent UI acceptance are not claimed.

Evidence: [production regression tests](../test/repository/sms_extracted_evidence_test.dart)
cover date-only/time-only evidence, immutable original versus corrected review,
unknown/transfer admission, invalid amount/unit, stale edit/confirmation, transactional
failure/retry, raw expiry, file-backed cold reopen, legacy missing v1 fields and metadata,
and isolated production redacted snapshot reopen with full original/reviewed history
and ledger preservation. Existing parser/staging/replay/review/currency/scan regressions
are run as well. Only relevant legacy repository fixture grammar was adjusted; malformed
unlabelled currency tails remain rejection tests. The escaped defect was stage/confirm
assuming non-incoming meant expense; explicit unknown/transfer repository admission now
has regression coverage independent of parser direction fixtures.

Validation for this slice: final focused parser/domain/production staging, confirmation,
review, currency, replay and bounded-ingestion run **85 passed**; full Flutter analysis
reported no issues. Scoped formatting and whitespace checks passed. Full application
suite, new parent route journeys and native checks were not executed for this slice.

Status: implemented foundation, automated evidence only. Owner: parent UI/application
integration maintainer; next action: wire original-versus-reviewed presentation,
explicit unknown/unit/date review, retained input/error/retry, and test downstream refresh.
Owner: release QA; next action: independent review and isolated native provider/restore
checks already listed here. Exposure remains development-only Partial, not release-ready.
No UI/native edits, full-suite claim, device-loss restore proof or independent sign-off.

## Conservative parser implementation / exact supported synthetic grammar

- At most 4096 characters. Fields are separated by newline or semicolon (Latin or
  Persian). Every field uses colon/full-width colon; surrounding whitespace is
  ignored. Duplicate fields/aliases are rejected, including equal repeated amounts.
- Labels: amount/مبلغ; balance/مانده/موجودی; type/نوع; bank/بانک;
  account/card/حساب/کارت; reference/ref/پیگیری/شناسه;
  merchant/پذیرنده/فروشگاه; date/تاریخ; time/ساعت. English is case-insensitive.
  Unknown labels or unlabelled prose are unsupported, not heuristically interpreted.
- Compact alternative: برداشت, واریز, خرید, پرداخت, withdrawal, deposit or purchase,
  followed by مبلغ/amount, optional colon and one amount. Other fields still require
  separate labelled segments. This is synthetic compatibility, not a bank template.
- One positive integer transaction amount; optional prefix/suffix unit ریال, تومان,
  rial(s), toman(s), IRR. Ungrouped digits or three-digit comma/Arabic comma/Arabic
  thousands grouping; Persian, Arabic and Latin digits normalize exactly. Fractions,
  malformed grouping and signed/overflow amounts are rejected. Canonical IRR uses
  exact integer conversion. Missing/conflicting unit stays unknown; both potential
  interpretations must fit signed 64-bit storage. Balance is separate, zero allowed,
  and requires an unambiguous explicit unit; it never becomes transaction amount.
- Direction values: واریز/deposit/credit incoming; برداشت/خرید/پرداخت/withdrawal/
  purchase/debit outgoing; missing, unknown/نامعلوم, انتقال/کارت به کارت/transfer
  unknown. Transfers additionally set the transfer evidence flag. Unsupported type
  values and OTP/password/failure/notification markers are rejected conservatively.
- Date: four-digit year and two-digit month/day, slash or hyphen (same separator).
  1300–1499 is explicitly the synthetic Jalali range; 2000–2099 Gregorian. Impossible
  days/leap dates are rejected. Time: HH:mm or HH:mm:ss, 00–23/00–59/00–59. Missing
  date/time preserves absence; explicit 00:00 is valid. Complete timestamps are local
  wall clock, not UTC or sender-zone evidence; no timezone is inferred. Parent must
  retain/propose time semantics explicitly; timezone/DST/device behavior is not proven.
- Account evidence: 4–32 digits/asterisks or IR plus 24 digits, no trailing text;
  reference: 1–64 ASCII letters/digits/underscore/hyphen. Bank max 40 and merchant max
  80 Persian/Arabic/Latin letters/spaces (ZWNJ allowed), no colon/digits/free-line tail.
  No sender authentication, account ownership, actual-bank catalogue or unsupported
  free-prose recovery is provided. Conservative false negatives are intentional.

Changed scope: parser sections of the existing application file, synthetic unit test,
existing inbox unit fixture strings, this verification record. InboxUseCases is
unchanged. ParsedSms adds optional sourceDate/sourceTime (normalized validated original
calendar text, no generated time) and isTransfer (default false). Existing balance now
populates separately. Parent must carry these through durable editable evidence;
parser fields alone do not persist. No schema/migration/dependency/UI/native change.

Evidence: tests added first: baseline 7 passed / 30 failed, exposing first-amount,
balance, date normalization and missing-time assumptions. Final focused parser plus
Inbox unit suite: 47 passed; analyzer clean; format and whitespace checks passed.
Old Inbox unit fixtures were deliberately changed from unsupported free prose to
labelled synthetic input; merchant assertion no longer includes the remaining line.
Other repository/widget/currency fixtures with unlabelled trailing dates/free prose
need parent coordination before full-suite acceptance; they were not changed here.
No full suite, production restart/backup, native provider or independent review was
performed for this subtask. Status: parser foundation verified locally; vertical
slice and release acceptance remain Partial with parent-owned admission/evidence gates.

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
