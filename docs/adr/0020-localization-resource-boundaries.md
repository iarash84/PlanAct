# ADR 0020: Localization resources and compatibility boundaries

Date: 2026-10-14
Status: Accepted for Persian-only localization foundation requested by the user.

## Decision

Use Flutter's built-in `gen-l10n`, a Persian ARB template in `lib/l10n`, generated
typed `AppLocalizations`, and the existing framework delegates. Keep Persian as
the only enabled locale and preserve RTL/Jalali/integer money behavior. Declare
`intl` directly at the already resolved `0.20.3` version; no new package version
or state-management dependency is introduced.

Domain code cannot import Flutter localization APIs. Existing labels, validation
and explanations have legacy string/const APIs, some consumed by durable history
or native adapters. A small Dart-only generator derives `PersianCopy` from ARB
entries marked `x-planact-default`, preserving those APIs and exact default text.
This output is generated, never a second manually maintained catalog. CI checks
its reproducibility. Context-free presentation helpers retain the same explicit
default seam; future language activation must pass localization inputs through
these boundaries or add typed presentation mappings.

Parser vocabularies, bank/holiday source datasets, persisted notes/categories,
currency identity and numeric normalization are not translation resources. Keep
them stable and do not rewrite existing user/source data. Language activation
does not authorize changing recurrence calendars, anchors, storage units or
historical decisions.

## Consequences

Application copy is centralized and translators have template metadata and
placeholder contracts. Existing Persian routes and non-widget APIs retain their
behavior without a database migration or new preference. The compatibility
companion remains Persian: this change is foundation, not multilingual readiness.
Do not enable another language until route/direction/formatting, context-free
projection/error/helper and native notification/authentication copy are reviewed
and verified. See [verification](../LOCALIZATION_VERIFICATION.md).
