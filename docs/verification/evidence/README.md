# Retained historical verification evidence

This directory contains selected historical raw reports explicitly linked by feature verification documents. These are exceptions to the default policy: new local output belongs under the ignored `build/verification/` directory, while CI output belongs to its run's logs/artifacts. See the [development workflow](../../development-workflow.md).

## Inventory

| Retained report | Owning verification record | Recorded result |
| --- | --- | --- |
| [Picker responsive tests](date-picker-responsive-results.txt) | [Date picker](../../DATE_PICKER_VERIFICATION.md) | 68 tests passed |
| [Picker analysis](date-picker-responsive-analyze.txt) | [Date picker](../../DATE_PICKER_VERIFICATION.md) | No issues found |
| [Hybrid full suite](hybrid-final-suite-results.txt) | [Monthly/yearly recurrence](../../MONTHLY_YEARLY_RECURRENCE_VERIFICATION.md) | 783 tests passed |
| [Hybrid analysis](hybrid-final-analyze-results.txt) | [Monthly/yearly recurrence](../../MONTHLY_YEARLY_RECURRENCE_VERIFICATION.md) | No issues found |
| [Earlier recurrence full suite](recurrence-final-suite-results.txt) | [Monthly/yearly recurrence](../../MONTHLY_YEARLY_RECURRENCE_VERIFICATION.md) | 519 tests passed |

## Cleanup and provenance limitations — 2026-10-13

The five linked reports were relocated from the repository root without changing their bytes; SHA-256 equality was checked during relocation. Twenty unreferenced root reports and two empty diagnostic artifacts were removed from the working tree. Their previously committed versions remain recoverable from Git history; history was not rewritten. Feature verification summaries and acceptance gaps remain unchanged.

These logs are historical records, not new test executions or proof that the current revision is release-ready. They lack self-contained source/build identity; consult their owning records and Git history rather than inventing a run date or tested commit. Native/device evidence and independent acceptance remain separate requirements.

Do not overwrite these reports with later runs. Retain a new raw report in Git only when a verification record explicitly needs durable evidence, after checking for sensitive content and documenting the command, environment, date, source commit, result and limitations. Prefer existing verification summaries and traceable CI artifacts for routine runs; artifact retention/expiry must be considered when those artifacts are used as durable evidence.
