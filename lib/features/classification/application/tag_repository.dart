import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/classification/domain/tag.dart';

abstract interface class TagRepository {
  Future<Tag> getOrCreate(String label);
  Future<List<Tag>> autocomplete(String query);
  Future<List<Tag>> list();

  /// Renames the label without changing identity or memberships.
  Future<Tag> rename(StableId id, String label);

  /// Removes this classification and its links, never the classified records.
  Future<void> remove(StableId id);
  Future<Set<String>> recordsWithTag(StableId id, TaggableType type);
  Future<Set<StableId>> tagsFor(String recordId, TaggableType type);
  Future<void> attach({
    required String recordId,
    required Tag tag,
    required TaggableType type,
  });
  Future<void> detach({
    required String recordId,
    required Tag tag,
    required TaggableType type,
  });
}

enum TaggableType { commitment, accountEntry }

class InMemoryTagRepository implements TagRepository, CommandGateProvider {
  @override
  CommandGate? get commandGate => CommandGate.forOwner(this);
  final Map<String, Tag> _tags = {};
  final Map<(TaggableType, String), Set<StableId>> _links = {};

  @override
  Future<Tag> getOrCreate(String label) => CommandGate.runFor(this, () async {
    final key = normalizeTagKey(label);
    final existing = _tags[key];
    if (existing != null) return existing;
    final tag = Tag(
      id: StableId.generate(),
      label: label,
      createdAt: DateTime.now().toUtc(),
    );
    _tags[key] = tag;
    return tag;
  });

  @override
  Future<Tag> rename(StableId id, String label) => CommandGate.runFor(
    this,
    () async {
      final existing = _requireTag(id);
      final renamed = Tag(id: id, label: label, createdAt: existing.createdAt);
      final duplicate = _tags[renamed.normalizedLabel];
      if (duplicate != null && duplicate.id != id) {
        throw const ValidationError('Tag label already exists');
      }
      _tags.remove(existing.normalizedLabel);
      _tags[renamed.normalizedLabel] = renamed;
      return renamed;
    },
  );

  @override
  Future<void> remove(StableId id) => CommandGate.runFor(this, () async {
    _tags.removeWhere((_, tag) => tag.id == id);
    for (final links in _links.values) {
      links.remove(id);
    }
  });

  @override
  Future<Set<String>> recordsWithTag(StableId id, TaggableType type) =>
      CommandGate.runFor(
        this,
        () async => Set.unmodifiable({
          for (final entry in _links.entries)
            if (entry.key.$1 == type && entry.value.contains(id)) entry.key.$2,
        }),
      );

  Tag _requireTag(StableId id) => _tags.values.firstWhere(
    (tag) => tag.id == id,
    orElse: () => throw const ValidationError('Tag does not exist'),
  );

  @override
  Future<List<Tag>> autocomplete(String query) =>
      CommandGate.runFor(this, () async {
        final key = normalizeTagKey(query);
        return _tags.values
            .where((tag) => key.isEmpty || tag.normalizedLabel.contains(key))
            .toList(growable: false);
      });

  @override
  Future<List<Tag>> list() =>
      CommandGate.runFor(this, () async => List.unmodifiable(_tags.values));

  @override
  Future<Set<StableId>> tagsFor(String recordId, TaggableType type) =>
      CommandGate.runFor(
        this,
        () async => Set.unmodifiable(_links[(type, recordId)] ?? const {}),
      );

  @override
  Future<void> attach({
    required String recordId,
    required Tag tag,
    required TaggableType type,
  }) => CommandGate.runFor(this, () async {
    _requireTag(tag.id);
    _links.putIfAbsent((type, recordId), () => <StableId>{}).add(tag.id);
  });

  @override
  Future<void> detach({
    required String recordId,
    required Tag tag,
    required TaggableType type,
  }) => CommandGate.runFor(this, () async {
    _links[(type, recordId)]?.remove(tag.id);
  });
}
