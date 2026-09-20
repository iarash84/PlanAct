# Test structure

Tests are organized by the lowest effective layer:

- `unit/`: pure domain and core behavior.
- `repository/`: persistence constraints and transactions.
- `scenario/`: end-to-end domain scenarios.
- `integration/`: platform and application integration.
- `fixtures/`: versioned test data.
