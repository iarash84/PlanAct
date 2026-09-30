import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/classification/domain/tag.dart';

abstract interface class TagRepository {
  Future<Tag> getOrCreate(String label);
  Future<List<Tag>> autocomplete(String query);
  Future<List<Tag>> list();
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

class InMemoryTagRepository implements TagRepository {
  final Map<String, Tag> _tags = {};
  final Map<(TaggableType, String), Set<StableId>> _links = {};

  @override
  Future<Tag> getOrCreate(String label) async {
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
  }

  @override
  Future<List<Tag>> autocomplete(String query) async {
    final key = normalizeTagKey(query);
    return _tags.values
        .where((tag) => key.isEmpty || tag.normalizedLabel.contains(key))
        .toList(growable: false);
  }

  @override
  Future<List<Tag>> list() async => List.unmodifiable(_tags.values);

  @override
  Future<Set<StableId>> tagsFor(String recordId, TaggableType type) async =>
      Set.unmodifiable(_links[(type, recordId)] ?? const {});

  @override
  Future<void> attach({
    required String recordId,
    required Tag tag,
    required TaggableType type,
  }) async {
    _links.putIfAbsent((type, recordId), () => <StableId>{}).add(tag.id);
  }

  @override
  Future<void> detach({
    required String recordId,
    required Tag tag,
    required TaggableType type,
  }) async {
    _links[(type, recordId)]?.remove(tag.id);
  }
}
