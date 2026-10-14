# PlanAct localization resources

`app_fa.arb` is the single editable catalog of application-owned Persian copy.
Persian remains the only enabled/default language. Resource extraction does not
add a language setting or change RTL, Jalali recurrence/display, currency or
persisted user data.

## Editing copy

- Use stable, semantic camelCase keys. Shared actions use `common…`; settings,
  occurrence states and calendar names have their own prefixes. Existing migrated
  feature keys also retain the originating helper/field in their names.
- Keep each `@key.description`. It records the original source location so a
  translator can find the context. Locations describe the migration baseline,
  not current line numbers. Do not rename keys just because a widget moved.
- Translate a complete sentence/template, rather than concatenating translated
  fragments. Keep placeholders and their metadata. Existing `value1`, `value2`,
  etc. are positional arguments; their descriptions identify the original
  expressions and the order is part of the generated method contract. Prefer
  descriptive names for new placeholders.
- Existing numeric/date/money placeholders are **preformatted String values**.
  Do not reinterpret stored integer money, convert units or replace the existing
  Persian formatter with floating-point formatting. A new plural message should
  receive a separate integer count for ICU selection and a formatted display
  value where needed; do not infer a count from Persian text.
- Do not edit generated Dart files. Run from the repository root:

```sh
flutter gen-l10n
dart run tool/generate_persian_copy.dart
dart run tool/generate_persian_copy.dart --check
```

`pub get`/Flutter builds generate the standard `generated/app_localizations…`
files. CI separately verifies that the pure-Dart companion is current. A catalog
baseline test deliberately freezes the pre-migration Persian templates; an
intentional copy change needs a reviewed baseline update.

## Consumers and safe boundaries

Widgets use `planActL10n(context)` and the root registers `AppLocalizations` beside
the existing Material/Cupertino delegates. The helper has an immutable Persian
fallback for isolated existing widget tests/embeddings; it does not maintain a
global mutable locale.

Messages marked `x-planact-default` generate `PersianCopy` in
`core/localization/persian_copy.g.dart`. That companion contains only Dart
constants/template functions: no Flutter, database, platform dependencies or
second editable source. It preserves existing domain validation, application
projections, context-free presentation helpers, calendar-name tables and native
adapter messages without changing their signatures/const semantics. It remains
Persian regardless of the widget locale. This is an explicit compatibility seam,
not a complete multilingual application.

Before enabling another language, add its ARB, localize context-free helpers and
projection/error/platform boundaries through explicit inputs or typed
presentation mappings, and verify the real routes. A translated ARB alone is not
the acceptance gate. Keep language, calendar/recurrence, numeric formatting and
money unit as separate decisions; changing UI language must never rewrite saved
dates, notes, categories, ledger values, matches or entitlement.

## Strings that are data

These intentionally remain outside translation substitution:

| Source | Reason |
| --- | --- |
| `real_bank_sms_parser.dart`, `GenericBankSmsParser`, SMS unit regexes | Exact source recognition/evidence; translating tokens would change parsing. |
| `iranian_holiday_data.dart` | Versioned source dataset, not UI copy; source titles are retained. |
| `IranianBank` names/detection | Entity/recognition data; translation must use a separate display mapping. |
| `MerchantNormalizer` suffixes | Deterministic matching input vocabulary. |
| Financial creation/correction notes and default categories | Existing persisted defaults/history semantics. |
| Currency identity, digits, numeric separators and normalization | Currency/storage and exact presentation/parser contracts; retain dedicated formatting policy. |
| User titles, descriptions, tags, notes, imported messages and evidence | User/source data must never be translated or overwritten automatically. |

See [verification](../../docs/LOCALIZATION_VERIFICATION.md) for evidence and the
separate product/native/independent acceptance status.
