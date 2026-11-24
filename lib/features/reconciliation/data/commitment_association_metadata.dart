import 'dart:convert';

import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/reconciliation/domain/commitment_association.dart';

/// Shared strict logical validation for live reads and isolated backup snapshots.
abstract final class CommitmentAssociationMetadata {
  static const headPrefix = 'transaction_commitment_head_v1:';
  static const historyPrefix = 'transaction_commitment_revision_v1:';

  static Map<String, Object?> state(CommitmentAssociation value) => {
    'transactionId': value.transactionId.value,
    'revision': value.revision,
    'commitmentId': value.commitmentId?.value,
  };

  static Map<String, Object?> event(CommitmentAssociationRevision value) => {
    'version': 1,
    'before': state(value.before),
    'after': state(value.after),
    'recordedAt': value.recordedAt.toUtc().toIso8601String(),
  };

  static void _keys(Map<String, dynamic> map, Set<String> keys) {
    if (map.length != keys.length || !map.keys.every(keys.contains)) {
      throw const FormatException('Invalid association fields');
    }
  }

  static CommitmentAssociation decodeState(Object? raw) {
    final map = raw as Map<String, dynamic>;
    _keys(map, {'transactionId', 'revision', 'commitmentId'});
    final revision = map['revision'] as int;
    final commitment = map['commitmentId'];
    if (revision < 0 || (revision == 0 && commitment != null)) {
      throw const FormatException('Invalid association revision');
    }
    return CommitmentAssociation(
      transactionId: StableId.parse(map['transactionId'] as String),
      revision: revision,
      commitmentId: commitment == null
          ? null
          : StableId.parse(commitment as String),
    );
  }

  static CommitmentAssociationRevision decodeEvent(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _keys(map, {'version', 'before', 'after', 'recordedAt'});
    if (map['version'] != 1) {
      throw const FormatException('Unsupported association version');
    }
    final before = decodeState(map['before']);
    final after = decodeState(map['after']);
    final at = DateTime.parse(map['recordedAt'] as String);
    if (!at.isUtc ||
        before.transactionId != after.transactionId ||
        after.revision != before.revision + 1 ||
        before.commitmentId == after.commitmentId) {
      throw const FormatException('Invalid association transition');
    }
    return CommitmentAssociationRevision(
      before: before,
      after: after,
      recordedAt: at,
    );
  }

  static List<CommitmentAssociationRevision> validate({
    required Map<String, String> metadata,
    required Set<String> eligibleTransactionIds,
    required Set<String> commitmentIds,
  }) {
    try {
      final heads = <String, CommitmentAssociation>{};
      final histories = <String, List<CommitmentAssociationRevision>>{};
      for (final row in metadata.entries) {
        if (row.key.startsWith(headPrefix)) {
          final id = row.key.substring(headPrefix.length);
          final head = decodeState(jsonDecode(row.value));
          if (id != head.transactionId.value || head.revision < 1) {
            throw const FormatException('Invalid association head');
          }
          heads[id] = head;
        } else if (row.key.startsWith(historyPrefix)) {
          final event = decodeEvent(row.value);
          final id = event.after.transactionId.value;
          if (row.key != '$historyPrefix$id:${event.after.revision}') {
            throw const FormatException('Invalid association history key');
          }
          (histories[id] ??= []).add(event);
        }
      }
      if (heads.length != histories.length ||
          !heads.keys.every(histories.containsKey)) {
        throw const FormatException('Orphan association history');
      }
      final result = <CommitmentAssociationRevision>[];
      for (final id in heads.keys) {
        if (!eligibleTransactionIds.contains(id)) {
          throw const FormatException(
            'Invalid association transaction reference',
          );
        }
        final history = histories[id]!
          ..sort((a, b) => a.after.revision.compareTo(b.after.revision));
        var current = CommitmentAssociation(transactionId: StableId.parse(id));
        for (final event in history) {
          if (!current.sameState(event.before)) {
            throw const FormatException('Broken association history chain');
          }
          for (final value in [event.before, event.after]) {
            if (value.commitmentId != null &&
                !commitmentIds.contains(value.commitmentId!.value)) {
              throw const FormatException(
                'Invalid association commitment reference',
              );
            }
          }
          current = event.after;
          result.add(event);
        }
        if (!current.sameState(heads[id]!)) {
          throw const FormatException(
            'Association head disagrees with history',
          );
        }
      }
      return result;
    } catch (_) {
      throw const ValidationError('Invalid commitment association metadata');
    }
  }
}
