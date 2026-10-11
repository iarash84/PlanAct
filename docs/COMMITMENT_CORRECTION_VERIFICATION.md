# Independent commitment corrections

## Acceptance contract (2026-10-11, before implementation)

Entry: Commitment Details, persisted active cycle. Schedule count and package credit are independent actions; neither implicitly changes the other. Unsaved creation remains a draft, not a historical correction. Existing persisted plans without outcomes still use explicit confirmation and append-only records; plans with history preserve it.

Preview must show declared count, future additions/cancellations, package remaining before/after, scope and protected history before confirmation. Cancel and errors retain form input. Confirm must acquire SQLite writer admission before fresh durable reads and compare the preview fingerprint; stale previews require another preview. Decreases incompatible with protected past/resolved/manual/payment/consumption are rejected. Credit decreases may not make remaining negative. No permanent deletion, counter editing, financial reversal or consumption rewriting.

Schedule scope: count termination only, retaining original recurrence anchor/calendar/time and adding a new effective version. Only untouched scheduled future logical slots can be cancelled; cancelled rows remain historical. Materialization stays bounded. Unsupported/non-count schedules reject visibly. Package corrections append signed semantic ledger entries with reason and timestamp; original package declaration stays unchanged.

Durability: one atomic transaction for version, occurrence changes, reminder intent and correction audit; cold reopen and personal SQLite backup preserve logical state. Details and root refresh propagate to Today, Calendar and credit/reminder consumers. Platform reminder delivery is separate from domain commit and reported as pending on failure.

Evidence required: production before/after consumption increases/decreases, protected-history rejection, stale preview, rollback, cold reopen, backup/schema compatibility and actual Details cancellation/error/confirmation journey. No native-device or independent release sign-off is implied by Flutter tests.

## Status

**Implemented bounded slice; acceptance remains Partial, not release-ready.** Details exposes an explicitly experimental correction form. No permanent deletion or automatic financial/consumption reversal was added. Unsaved creation stays on its existing draft path rather than being treated as a persisted correction.

## Implementation decisions

- Count corrections support fixed-count schedules only, retain the original recurrence/calendar/time anchor, create a new version effective tomorrow, and preserve occupied historical/manual slots. A second count correction sharing that effective boundary is rejected. Limits are 1–1000 logical occurrences; preview additions are bounded materialized additions, not a claim that the entire future series is materialized.
- Count and credit are separate commands. Credit uses signed Adjustment entries; negative adjustments reduce granted credit, not consumed units. Existing enum indices, original package units and positive-entry semantics stay unchanged. No independent remaining-credit counter exists.
- SQLite writer admission precedes fresh reads and preview validation. The fingerprint conservatively covers whole affected tables; unrelated changes can require a new preview. Atomic writes include schedule version, cancellations, new occurrence/reminder/financial intent, ledger adjustment and a uniquely keyed versioned JSON correction audit. Correction materialization is restricted to the new schedule version.
- Audit records use the existing schema metadata backup surface and are append-only through this command. There are no database-level immutable guards for these metadata keys.
- Schema remains v18: no table/column migration or dependency was introduced. Current-reader cold reopen and encrypted backup restore are covered. Negative Adjustment is a semantic extension: older binaries that enforce positive units cannot safely read these entries. Downgrade/older-reader compatibility is NOT established and must not be advertised. A reviewed application compatibility/version policy remains a release gate.
- Details reads persisted correction history with reason, Jalali date and before/after values. Input is retained on preview cancellation and validation/confirmation error. Reminder platform delivery runs after domain commit; subsequent failure is pending delivery/refresh, not a rollback claim.

## Verification evidence (2026-10-11)

- Six new tests pass: independent count/credit increases and decreases before/after consumption; incompatible decrease and manual-history rejection; stale preview; atomic rollback after injected final-audit failure; file-based cold reopen including the public history reader; encrypted production SQLite backup restore; actual Details page preview cancellation, retained error input and credit confirmation/refresh callback.
- Broader unit, repository, scenario and widget regression run: **542 tests passed**. After the final schedule-version restriction and experimental subtitle change, the six correction tests passed again; static analysis reported **no issues**, formatting required no further changes and the whitespace diff check passed. The broad suite was not repeated after those final changes.
- Existing migration regressions were included in the broad repository suite; no dedicated older-version fixture containing corrections exists because older versions could not create them. This is not evidence of old-reader semantic compatibility.

## Open acceptance gates and exposure decision

Owner for software gaps: commitment-correction implementer; owner for independent acceptance and native evidence: release reviewer/device tester. Experimental development exposure only; production release blocked until these gates are resolved:

1. Add independent separate-connection writer contention evidence; stale-preview and rollback tests alone do not prove contention behavior.
2. Add explicit payment/Actual/replacement and delivered/snoozed-reminder preservation counterexamples, and correction journeys proving refreshed Today, Calendar and credit consumers through the root route (the current Details test proves the callback, not all consumers).
3. Review signed-adjustment application/backup compatibility and define a tested older-binary rejection/version contract before distribution.
4. Verify narrow RTL screens, large text, Light/Dark and correction-history browsing; add navigation-away dirty-input handling if acceptance requires retaining unsaved corrections after leaving Details.
5. Independently verify native reminder cancellation/rebuild and isolated restore. No device or independent sign-off was performed.

The full independent correction mission must not be described as complete merely because this bounded slice and regression suite pass.
