import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';

/// A reusable user-defined classification label.
class Tag {
  Tag({required this.id, required String label, required this.createdAt})
    : label = normalizeTagLabel(label),
      normalizedLabel = normalizeTagKey(label) {
    if (this.label.isEmpty) {
      throw const ValidationError('Tag label cannot be empty');
    }
  }

  final StableId id;
  final String label;
  final String normalizedLabel;
  final DateTime createdAt;

  String get displayLabel => '#$label';
}

String normalizeTagLabel(String value) =>
    value.trim().replaceFirst(RegExp(r'^#\s*'), '').trim();

String normalizeTagKey(String value) => normalizeTagLabel(value).toLowerCase();
