# Application structure

This directory follows the feature-first layering defined in `AGENTS.md`.

- `core/`: shared domain primitives and infrastructure contracts.
- `features/`: feature-owned domain, application, data, and presentation code.
- `app/`: composition root and application wiring.

Dependencies must flow from presentation to application to domain. Data and infrastructure implementations depend on domain/application contracts, never the reverse.
