# M0 baseline

M0 establishes a testable engineering foundation without product features.

## Included

- Feature-first layered project skeleton.
- Drift/SQLite database lifecycle with schema metadata and migration seam.
- UUIDv7 stable IDs independent from SQLite row IDs.
- Injectable UTC clock abstractions.
- Integer minor-unit money primitive.
- Explicit application error types.
- Privacy-preserving logger with sensitive field redaction.
- Persian-first, Jalali-calendar, and RTL requirements documented as product constraints.
- Repository and unit smoke tests.

## Verification gate

Run:

```text
flutter pub get
 dart run build_runner build
flutter analyze
flutter test
```

The M0 gate passes when analysis is clean, tests pass, and the database smoke test can create an in-memory database and read its schema version.
