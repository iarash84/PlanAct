import 'dart:convert';

import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/actuals/domain/actual.dart';

/// Shared validation for production reads and isolated logical backups.
abstract final class ActualEvidenceMetadata {
  static const orderKey = 'actual_evidence_order_v1';
  static const historyPrefix = 'actual_text_history_v1:';
  static const headPrefix = 'actual_text_head_v1:';

  static Map<String, List<String>> order(
    Map<String, String> metadata, {
    required List<String> actualIds,
    required List<String> evidenceIds,
  }) {
    final raw = metadata[orderKey];
    if (raw == null) return {'actuals': actualIds, 'evidence': evidenceIds};
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      if (value.length != 3 || value['version'] != 1) {
        throw const FormatException();
      }
      final result = <String, List<String>>{};
      for (final entry in {
        'actuals': actualIds,
        'evidence': evidenceIds,
      }.entries) {
        final ids = (value[entry.key] as List).cast<String>();
        if (ids.length != entry.value.length ||
            ids.toSet().length != ids.length ||
            !ids.toSet().containsAll(entry.value)) {
          throw const FormatException();
        }
        result[entry.key] = ids;
      }
      return result;
    } catch (_) {
      throw const ValidationError('Invalid actual/evidence ordering metadata');
    }
  }

  static Map<String, Evidence> validate({
    required Map<String, String> metadata,
    required List<String> actualIds,
    required List<Evidence> originals,
  }) {
    order(
      metadata,
      actualIds: actualIds,
      evidenceIds: originals.map((e) => e.id.value).toList(),
    );
    final result = {for (final e in originals) e.id.value: e};
    try {
      final heads = <String, int>{};
      final events = <String, List<EvidenceRevision>>{};
      for (final entry in metadata.entries) {
        if (entry.key.startsWith(headPrefix)) {
          final id = entry.key.substring(headPrefix.length);
          final revision = int.parse(entry.value);
          if (revision < 1 || entry.value != '$revision') {
            throw const FormatException();
          }
          heads[id] = revision;
        } else if (entry.key.startsWith(historyPrefix)) {
          final map = jsonDecode(entry.value) as Map<String, dynamic>;
          final id = map['evidenceId'] as String;
          final original = result[id];
          final revision = map['revision'] as int;
          final at = DateTime.parse(map['recordedAt'] as String);
          if (map.length != 7 ||
              map['version'] != 1 ||
              original == null ||
              original.type != EvidenceType.note ||
              map['actualId'] != original.actualId.value ||
              !at.isUtc ||
              entry.key != '$historyPrefix$id:$revision') {
            throw const FormatException();
          }
          (events[id] ??= []).add(
            EvidenceRevision(
              revision: revision,
              value: map['value'] as String,
              isDiscarded: map['isDiscarded'] as bool,
              recordedAt: at,
            ),
          );
        }
      }
      if (heads.length != events.length ||
          !heads.keys.every(events.containsKey) ||
          (heads.isNotEmpty && !metadata.containsKey(orderKey))) {
        throw const FormatException();
      }
      for (final id in heads.keys) {
        final original = result[id];
        if (original == null || !actualIds.contains(original.actualId.value)) {
          throw const FormatException();
        }
        final history = events[id]!
          ..sort((a, b) => a.revision.compareTo(b.revision));
        var previousValue = original.value;
        var discarded = false;
        for (var i = 0; i < history.length; i++) {
          final item = history[i];
          if (item.revision != i + 1 ||
              item.value.trim().isEmpty ||
              discarded ||
              (item.isDiscarded
                  ? item.value != previousValue
                  : item.value == previousValue)) {
            throw const FormatException();
          }
          previousValue = item.value;
          discarded = item.isDiscarded;
        }
        if (history.length != heads[id]) throw const FormatException();
        result[id] = Evidence(
          id: original.id,
          actualId: original.actualId,
          type: original.type,
          value: previousValue,
          createdAt: original.createdAt,
          originalValue: original.value,
          revision: history.length,
          isDiscarded: discarded,
          history: List.unmodifiable(history),
        );
      }
      return result;
    } catch (_) {
      throw const ValidationError('Invalid actual text evidence history');
    }
  }

  static String encodeEvent(Evidence original, EvidenceRevision item) =>
      jsonEncode({
        'version': 1,
        'evidenceId': original.id.value,
        'actualId': original.actualId.value,
        'revision': item.revision,
        'value': item.value,
        'isDiscarded': item.isDiscarded,
        'recordedAt': item.recordedAt.toUtc().toIso8601String(),
      });
}
