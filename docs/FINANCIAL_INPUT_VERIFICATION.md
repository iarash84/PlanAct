# Financial input and Inbox feedback acceptance (2026-10-13)

Entry: Inbox -> edit/confirm transaction -> saved transaction tags; all monetary forms.
Canonical amounts display in the durable app preference, with exact integer IRR storage.
Manual/legacy monetary forms pin that preference; SMS review keeps explicit source-unit
evidence and suggests the app default when evidence is ambiguous.
SMS source evidence remains separately visible; missing/conflicting evidence requires
explicit reviewed-unit saving, and no saved history is reinterpreted.
Confirmed Inbox transactions offer the existing durable tag editor and Reports direct-tag filters.
Cancellation of tagging does not undo the financial transaction; tag errors support retry.
Money inputs group integer digits from the right, preserve signs and fractional input,
and must not turn malformed text into a different valid amount. Existing shared money
formatting applies to display and initial form values. No schema/dependency change.
Evidence required: formatter exactness/cursor tests, Inbox tag route with durable storage,
existing unit/report/backup regression suites, analyzer. Independent acceptance and
native visual review are separate unexecuted release gates.

Implementation plan: reuse tag repository/editor, wire production Inbox dependency,
share input grouping across monetary forms and untyped SMS amount displays.
Escaped check: monetary forms lacked a common formatter; existing tests covered
formatted display but did not require grouping during editing.

## Verification result

Implemented: default-unit suggestion in ambiguous SMS review; optional immediate
post-confirmation tagging; shared grouping for all monetary form keyboards and
initial values; grouping for original/ambiguous SMS and report amount text.
No persisted schema, new dependency, ledger mutation or historical migration.

Automated evidence: money input/unit/display tests; Inbox account/review routes;
unit preference routes; report routes including tag filters and narrow large text;
tag lifecycle and preference repositories; full-state personal backup regression.
The new Inbox journey creates a tag, verifies assignment/filter membership after
cold SQLite reopen, and preserves the relationship action after tagging. Default
unit review tests cover cancellation, explicit save, canonical conversion and
unchanged original ambiguous evidence. All executed checks passed after fixing
SnackBar queue interference. Dart analyzer: no issues; git diff --check: clean.

Acceptance self-review challenged signed/fractional amounts, invalid pasted groups,
ambiguous SMS under toman preference, tagging without a second financial entry,
cold reopen, and existing tag report consumption. This is automated verification,
not independent release sign-off. Remaining owner: maintainer/product reviewer;
next action: independent acceptance and native narrow-screen/keyboard review of
post-save tags and monetary forms. Exposure decision: source changes are available
for review; release readiness remains conditional on those checks and existing
SMS/report native gates. No release or deployment was performed.

## Cross-feature regression follow-up (2026-10-14)

Five pre-existing route-test failures were investigated against the approved PRD
contract above. The formatter correctly grouped `۱۲۳۴۵` as the existing normalized
editing representation `12,345`; the old capture check expected raw keystrokes
after failed saving. The revised check verifies the grouped editing value before
saving and its full preservation after failure, alongside canonical 12345 IRR,
credit and reminders.

The ambiguous-unit tests still expected saving to reject a visibly suggested
default, contrary to the approved explicit-save contract. They now change the
suggestion and cancel first (no revision, amount, evidence or financial write),
then reopen and explicitly save toman (exact 25000 IRR, one review revision,
original unresolved evidence retained). Existing production default-save,
cold-reopen/backup and unresolved-confirmation checks remain required.

The two narrow/large-text transfer tests tapped a floating field decoration;
they now select the actual typed unit dropdown. Their source-transfer protection
assertions remain, with additional exact reviewed-unit/amount/revision checks.
No application behavior, schema, resource copy or dependency changed.

The three repaired test files passed all 32 cases. Full-suite/analyzer results
and the separate native/independent acceptance status are recorded in the
[five-test follow-up](LOCALIZATION_VERIFICATION.md#five-test-repair-follow-up--2026-10-14).
Escaped check: earlier monetary/default-review changes did not update these
cross-feature expectations. Next comparable change should update route tests in
the same task, covering formatted input, cancellation and immutable evidence,
and target the interactive control rather than floating decoration text.
