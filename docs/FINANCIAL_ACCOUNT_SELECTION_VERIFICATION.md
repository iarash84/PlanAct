# Financial account selection defect — 2026-10-11

## Acceptance contract (recorded before implementation)

Entry paths: Inbox → bank SMS suggestion → تأیید و ثبت → explicit financial account selection → final confirmation; Finance → manual income/expense. SMS permission is needed only for provider ingestion, not reviewing already staged suggestions. An active durable account in the transaction currency is required. Account creation uses the existing Finance account form on a pushed route; returning reloads accounts without dismissing the transaction form. Relationship review selects commitments/occurrences for an already persisted transaction, not financial accounts.

Success: display compatible active accounts, require explicit selection even for one account, and commit exactly one ledger entry. SMS import/suggestion resolution and ledger entry commit atomically. A visible account suggestion is not consent. Loading, empty, read failure/retry and save failure have Persian feedback. Cancellation writes no transaction; failed saves preserve selection and input; repeated confirmation is guarded. Revalidate fresh durable account status/currency at write admission. Historical archived accounts/entries remain readable. Refresh Inbox, Today and Finance after success; relationship action carries the saved transaction ID.

Persistence: existing account, ledger and suggestion tables remain authoritative after cold reopen. No schema/dependency or backup format change is planned; existing logical backup preservation applies. No balance calculations in UI. SMS/manual forms support income/expense only; do not introduce SMS transfer classification. Existing separate transfer journey is outside this account-display defect.

Evidence required: real staged SMS route with several accounts, no hidden single-account selection, empty/archived/loading/read-error/retry, create-and-return, failed save preservation, cancellation, double confirmation, and file-backed cold reopen/transaction rollback. Static analysis, formatting and relevant regression suites. Native SMS permission/provider and independent acceptance remain separate release gates.

## Trace and cause

Inbox confirmation previously chose a sole account silently, or displayed a message asking users to select an account in Edit. Edit had no account selector. Manual Finance used a cached account snapshot (including archived accounts) and selected the first item. Relationship review correctly consumes an existing transaction ID and must not be replaced with an account picker.

Trace: Inbox action → InboxUseCases.confirm → DriftInboxRepository.confirmAtomically (fresh account validation, stable entry ID, suggestion/ledger transaction) → Inbox reload → root refresh/Finance refresh → relationship action. Manual action → FinanceUseCases.record → DriftFinanceRepository write → Finance/root refresh.

## Verification status

Implemented scope: a shared durable account picker for Inbox confirmation and full Finance manual income/expense; explicit selection, active/currency filtering, Persian loading/empty/read retry, account refresh, existing account creation with draft-preserving return, save retry and synchronous duplicate-tap guards. Manual ledger admission now checks fresh account state inside the write transaction. Inbox success refreshes root Today and Finance and preserves the saved ID for relationship navigation. A post-commit downstream refresh failure is reported separately from recording failure. No schema, migration, dependency, backup format or balance rule changed.

Local automated evidence:

- `test/widget/inbox_account_selection_test.dart`: real SMS parser/staging → explicit second-account selection → final confirmation → durable ledger, both income/expense; archived exclusion; double tap; refresh notification; saved relationship ID; file-backed cold reopen of entry and resolved suggestion. Includes Light/Dark, RTL and enlarged text coverage, plus empty/create-return/cancel, injected account read retry, SQL-trigger transaction rollback, retained selection and stale archive rejection.
- `test/widget/finance_transaction_form_test.dart`: sole-account explicit selection, failure/draft retention/retry, post-commit refresh failure and manual empty/create-return/draft preservation/double-tap regression.
- `test/repository/financial_account_admission_test.dart`: stale account rejection against durable state and archived historical entry/idempotent retry preservation.
- Existing SMS concurrency/restart/rejection/rollback, tagged creation and contextual relationship route regressions remain applicable; the latter routes now explicitly select an account rather than assuming consent from a sole compatible account.
- Final validation: targeted changed files formatted with `dart format`; `flutter analyze` reported no issues; `flutter test` passed all 525 tests after the final manual create-return regression and route-lifetime fix; `git diff --check` passed. These local results do not substitute for independent/native acceptance.

Escape check: previous SMS confirmation tests covered repository atomicity or a sole-account shortcut, not the multiple-account user journey. Finance tests also encoded first-account selection. New route checks require explicit choice and challenge archived snapshots. Create-return testing additionally exposed disposal of account-form controllers before the modal exit transition completed; the focused fix awaits route completion before disposal.

Acceptance limitations: reproduction was established from the existing user path/code contradiction and regression expectations, not an isolated native pre-fix recording. Android SMS permission/provider delivery and independent acceptance are unexecuted. Root refresh wiring is exercised by the existing root regressions and the confirmation callback assertion, not a new end-to-end Today/Finance/Inbox device journey. No dedicated narrow-screen contrast/touch-target audit was performed; existing shared Material/form design is reused. Separate Quick Add and transfer presentation are intentionally unchanged; fresh repository admission also protects their writes. Persisted parser metadata, unsupported SMS/transfer classification and other SMS checkpoint gaps remain open.

Release decision: this is bounded local account-selection evidence, not full SMS automation/device readiness or independent sign-off. Owner: maintainer/release reviewer; next action: review the evidence, execute native SMS gates and a root multi-surface device journey before release. Keep exposure subject to the partial SMS checkpoint.
