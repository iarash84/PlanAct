# ADR 0003: Dependency and privacy baseline

- Status: Accepted
- Date: 2026-09-20

## Decisions

- Reuse Flutter's existing test and lint tooling.
- Use Drift/SQLite for local persistence; generated code is produced by `build_runner` and `drift_dev`.
- Do not introduce state management, notification, encryption, or logging packages before their relevant milestone and an explicit decision.
- Core logs use a small local logger with field-level redaction. Raw SMS text, private notes, account identifiers, financial amounts, tokens, and secrets are never written by default.
- Core flows remain offline and no telemetry dependency is introduced.

## Consequences

Dependency additions stay tied to a concrete architectural need. Privacy-sensitive data is protected at the logging seam, while future platform adapters can provide controlled sinks without changing domain code.
