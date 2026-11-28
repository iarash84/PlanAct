part of 'drift_reconciliation_repository.dart';

/// Shares the existing reviewed-match admission path and its nested transaction.
final class _OccurrenceAllocationBackend {
  _OccurrenceAllocationBackend(this.repository);
  final DriftReconciliationRepository repository;
  db.AppDatabase get database => repository.database;

  Never fail(OccurrenceAllocationErrorCode code) =>
      throw OccurrenceAllocationException(code);

  Future<T> guarded<T>(Future<T> Function() action) async {
    try {
      return await CommandGate.runFor(repository, action);
    } on OccurrenceAllocationException {
      rethrow;
    } catch (_) {
      // Do not expose storage errors, SQL, or private financial data to UI/logs.
      throw const OccurrenceAllocationException(
        OccurrenceAllocationErrorCode.storage,
      );
    }
  }

  Future<OccurrenceAllocationSnapshot> load(
    StableId transactionId,
    StableId occurrenceId,
  ) => guarded(
    () => database.transaction(() => read(transactionId, occurrenceId)),
  );

  Future<List<Map<String, Object?>>> rows(String sql, String id) async => [
    for (final row
        in await database.customSelect(sql, variables: [Variable(id)]).get())
      row.data,
  ];

  Future<OccurrenceAllocationSnapshot> read(
    StableId transactionId,
    StableId occurrenceId,
  ) async {
    final transactions = await rows(
      'SELECT * FROM account_entries WHERE id = ?',
      transactionId.value,
    );
    final occurrences = await rows(
      'SELECT * FROM occurrences WHERE id = ?',
      occurrenceId.value,
    );
    if (transactions.isEmpty || occurrences.isEmpty) {
      fail(OccurrenceAllocationErrorCode.missing);
    }
    final t = transactions.single;
    final o = occurrences.single;
    final accounts = await rows(
      'SELECT * FROM financial_accounts WHERE id = ?',
      t['account_id']! as String,
    );
    final cycles = await rows(
      'SELECT * FROM commitment_cycles WHERE id = ?',
      o['cycle_id']! as String,
    );
    if (accounts.isEmpty || cycles.isEmpty) {
      fail(OccurrenceAllocationErrorCode.missing);
    }
    final owners = await rows(
      'SELECT * FROM commitments WHERE id = ?',
      cycles.single['commitment_id']! as String,
    );
    if (owners.isEmpty) fail(OccurrenceAllocationErrorCode.missing);
    // Persisted enum indices are the existing active values, not new semantics.
    if (accounts.single['status'] != FinancialAccountStatus.active.index ||
        owners.single['status'] != CommitmentStatus.active.index ||
        cycles.single['status'] != CommitmentCycleStatus.active.index) {
      fail(OccurrenceAllocationErrorCode.historicalInactive);
    }
    final reversals = await rows(
      'SELECT * FROM account_entries WHERE type = ${AccountEntryType.reversal.index} AND reference_id = ? ORDER BY id',
      transactionId.value,
    );
    if (reversals.isNotEmpty ||
        (t['type'] != AccountEntryType.income.index &&
            t['type'] != AccountEntryType.expense.index) ||
        (t['minor_units']! as int) <= 0) {
      fail(OccurrenceAllocationErrorCode.historicalInactive);
    }
    if (accounts.single['currency'] != t['currency']) {
      fail(OccurrenceAllocationErrorCode.currency);
    }
    final review = await repository._loadReview(transactionId);
    if (review.isIndependent) fail(OccurrenceAllocationErrorCode.stale);
    final settlement = await DriftFinancialExpectationRepository(database)
        .readSettlementSnapshot();
    final expectations = settlement.expectations
        .where((e) => e.occurrenceId == occurrenceId)
        .toList();
    final active = expectations
        .where((e) => e.status == FinancialExpectationStatus.active)
        .toList();
    final state = expectations.isEmpty
        ? OccurrenceExpectationState.missing
        : active.length == 1
        ? OccurrenceExpectationState.existing
        : OccurrenceExpectationState.ambiguous;
    final expectation = state == OccurrenceExpectationState.existing
        ? active.single
        : null;
    final reversedIds = settlement.entries
        .where((e) => e.type == AccountEntryType.reversal)
        .map((e) => e.referenceId)
        .toSet();
    final capacity = OutstandingExpectationCapacity(
      expectations: settlement.expectations,
      matches: settlement.matches,
      reversedTransactionIds: settlement.entries
          .where((e) => reversedIds.contains(e.id.value))
          .map((e) => e.id)
          .toSet(),
    );
    final expectationRows = await rows(
      'SELECT * FROM financial_expectations WHERE occurrence_id = ? ORDER BY id',
      occurrenceId.value,
    );
    final reviews = await rows(
      'SELECT * FROM relationship_reviews WHERE transaction_id = ? ORDER BY revision',
      transactionId.value,
    );
    final relevantMatches = settlement.matches.where(
      (m) =>
          m.transactionId == transactionId ||
          m.allocations.any((a) => a.occurrenceId == occurrenceId),
    );
    final currency = t['currency']! as String;
    final fingerprint = jsonEncode([
      transactions,
      accounts,
      owners,
      cycles,
      occurrences,
      expectationRows,
      reviews,
      allocationFingerprintFor(relevantMatches),
      // Include reversal history: changing validity of another payment changes capacity.
      (settlement.entries
          .where((e) => e.type == AccountEntryType.reversal)
          .map((e) => [e.id.value, e.referenceId])
          .toList()
        ..sort((a, b) => a.first!.compareTo(b.first!))),
    ]);
    return OccurrenceAllocationSnapshot(
      transaction: AccountEntry(
        id: transactionId,
        accountId: StableId.parse(t['account_id']! as String),
        type: AccountEntryType.values[t['type']! as int],
        amount: Money(minorUnits: t['minor_units']! as int, currency: currency),
        occurredAt: DateTime.fromMillisecondsSinceEpoch(
          (t['occurred_at']! as int) * 1000,
          isUtc: true,
        ),
        note: t['note'] as String?,
        category: t['category'] as String?,
        referenceId: t['reference_id'] as String?,
        source: AccountEntrySource.values[t['source']! as int],
      ),
      occurrenceId: occurrenceId,
      expectationState: state,
      suggestedDirection: t['type'] == AccountEntryType.income.index
          ? FinancialExpectationDirection.incoming
          : FinancialExpectationDirection.outgoing,
      expectedTotal: expectation?.currency == null
          ? null
          : Money(
              minorUnits: expectation!.amount,
              currency: expectation.currency!,
            ),
      expectationCapacity: expectation == null
          ? null
          : Money(
              minorUnits: capacity.remaining(occurrenceId, currency),
              currency: currency,
            ),
      transactionCapacity: Money(
        minorUnits: review.remainderMinorUnits,
        currency: currency,
      ),
      fingerprint: fingerprint,
    );
  }

  Future<TransactionMatch> confirm(
    OccurrenceAllocationSnapshot expected, {
    Money? total,
    required Money allocation,
  }) => guarded(
    () => database.transaction(() async {
      // First SQL operation inside the transaction is writer admission, before read().
      await UndoJournal(database).admitWriter();
      final current = await read(
        expected.transaction.id,
        expected.occurrenceId,
      );
      if (current.fingerprint != expected.fingerprint) {
        fail(OccurrenceAllocationErrorCode.stale);
      }
      await requireWritableOccurrence(database, current.occurrenceId.value);
      if (current.expectationState == OccurrenceExpectationState.ambiguous) {
        fail(OccurrenceAllocationErrorCode.ambiguous);
      }
      final currency = current.transaction.amount.currency;
      if (allocation.currency != currency ||
          (total != null && total.currency != currency) ||
          (current.expectationState == OccurrenceExpectationState.existing &&
              current.expectedTotal?.currency != currency)) {
        fail(OccurrenceAllocationErrorCode.currency);
      }
      final missing =
          current.expectationState == OccurrenceExpectationState.missing;
      if (missing && total == null) fail(OccurrenceAllocationErrorCode.missing);
      if (!missing && total != null) fail(OccurrenceAllocationErrorCode.stale);
      if (allocation.minorUnits <= 0 ||
          (total != null && total.minorUnits <= 0) ||
          allocation.minorUnits > current.transactionCapacity.minorUnits) {
        fail(OccurrenceAllocationErrorCode.capacity);
      }
      // Even a missing expectation can retain legacy allocations. Never grant its
      // full new total as fresh capacity without subtracting those payments.
      if (missing) {
        final now = DateTime.now().toUtc();
        await DriftFinancialExpectationRepository(database).saveExpectation(
          FinancialExpectation(
            id: StableId.generate(),
            occurrenceId: current.occurrenceId,
            direction: current.suggestedDirection,
            amount: total!.minorUnits,
            currency: currency,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      final admitted = await read(current.transaction.id, current.occurrenceId);
      if (allocation.minorUnits > admitted.expectationCapacity!.minorUnits) {
        fail(OccurrenceAllocationErrorCode.capacity);
      }
      final id = StableId.generate();
      final match = TransactionMatch(
        id: id,
        transactionId: current.transaction.id,
        transactionAmount: current.transaction.amount,
        createdAt: DateTime.now().toUtc(),
        allocations: [
          MatchAllocation(
            id: StableId.generate(),
            matchId: id,
            occurrenceId: current.occurrenceId,
            amount: allocation,
          ),
        ],
      );
      await repository.saveReviewedMatch(
        match,
        await repository._loadReview(current.transaction.id),
      );
      return match;
    }),
  );
}
