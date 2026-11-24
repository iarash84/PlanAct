import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reconciliation/data/commitment_association_metadata.dart';
import 'package:planact/features/reconciliation/domain/commitment_association.dart';

void main() {
  final transaction = StableId.generate();
  final owner = StableId.generate();
  final missing = StableId.generate();
  final before = CommitmentAssociation(transactionId: transaction);
  final after = CommitmentAssociation(
    transactionId: transaction,
    revision: 1,
    commitmentId: owner,
  );
  final event = CommitmentAssociationRevision(
    before: before,
    after: after,
    recordedAt: DateTime.utc(2026),
  );
  final headKey =
      '${CommitmentAssociationMetadata.headPrefix}${transaction.value}';
  final eventKey =
      '${CommitmentAssociationMetadata.historyPrefix}${transaction.value}:1';

  Map<String, String> valid() => {
    headKey: jsonEncode(CommitmentAssociationMetadata.state(after)),
    eventKey: jsonEncode(CommitmentAssociationMetadata.event(event)),
  };
  void validate(Map<String, String> metadata) =>
      CommitmentAssociationMetadata.validate(
        metadata: metadata,
        eligibleTransactionIds: {transaction.value},
        commitmentIds: {owner.value},
      );

  test('strict validator accepts empty legacy metadata and complete chain', () {
    validate({});
    validate(valid());
  });

  final mutations = <String, void Function(Map<String, dynamic>)>{
    'unknown version': (map) => map['version'] = 2,
    'missing before': (map) => map.remove('before'),
    'unknown event field': (map) => map['settlement'] = true,
    'non-UTC time': (map) => map['recordedAt'] = '2026-01-01T00:00:00',
    'invalid time': (map) => map['recordedAt'] = 'invalid',
    'gap revision': (map) => (map['after'] as Map)['revision'] = 3,
    'fractional revision': (map) => (map['after'] as Map)['revision'] = 1.5,
    'different transaction': (map) =>
        (map['after'] as Map)['transactionId'] = missing.value,
    'missing commitment': (map) =>
        (map['after'] as Map)['commitmentId'] = missing.value,
    'no-op event': (map) => (map['after'] as Map)['commitmentId'] = null,
    'broken before': (map) => (map['before'] as Map)['revision'] = 1,
    'unknown state field': (map) => (map['after'] as Map)['amount'] = 1000,
  };
  for (final mutation in mutations.entries) {
    test('strict validator rejects ${mutation.key}', () {
      final metadata = valid();
      final map = jsonDecode(metadata[eventKey]!) as Map<String, dynamic>;
      mutation.value(map);
      metadata[eventKey] = jsonEncode(map);
      expect(() => validate(metadata), throwsA(isA<ValidationError>()));
    });
  }

  test('strict validator rejects orphan and mismatched keys', () {
    for (final metadata in [
      {headKey: valid()[headKey]!},
      {eventKey: valid()[eventKey]!},
      {...valid(), '$eventKey:extra': valid()[eventKey]!},
      {
        ...valid(),
        '${CommitmentAssociationMetadata.headPrefix}${missing.value}':
            valid()[headKey]!,
      },
    ]) {
      expect(() => validate(metadata), throwsA(isA<ValidationError>()));
    }
  });
}
