import 'package:planact/core/ids/stable_id.dart';

final class ChecklistItem {
  ChecklistItem({
    required this.id,
    required String title,
    this.checked = false,
    this.removed = false,
  }) : title = title.trim() {
    if (this.title.isEmpty) throw ArgumentError('Empty checklist item');
  }

  final StableId id;
  final String title;
  final bool checked;
  final bool removed;
}

/// Commitment-wide tasks, independent from occurrence and financial outcomes.
final class CommitmentChecklist {
  CommitmentChecklist({
    required this.commitmentId,
    this.revision = 0,
    List<ChecklistItem> items = const [],
  }) : items = List.unmodifiable(items) {
    if (revision < 0 || items.map((i) => i.id).toSet().length != items.length) {
      throw ArgumentError('Invalid checklist revision or duplicate item ID');
    }
  }

  final StableId commitmentId;
  final int revision;
  final List<ChecklistItem> items;

  CommitmentChecklist add(String title, {StableId? id}) => CommitmentChecklist(
    commitmentId: commitmentId,
    revision: revision + 1,
    items: [
      ...items,
      ChecklistItem(id: id ?? StableId.generate(), title: title),
    ],
  );

  CommitmentChecklist change(
    StableId id, {
    String? title,
    bool? checked,
    bool? removed,
  }) {
    if (!items.any((i) => i.id == id)) {
      throw ArgumentError('Missing checklist item');
    }
    return CommitmentChecklist(
      commitmentId: commitmentId,
      revision: revision + 1,
      items: [
        for (final item in items)
          if (item.id != id)
            item
          else
            ChecklistItem(
              id: id,
              title: title ?? item.title,
              checked: checked ?? item.checked,
              removed: removed ?? item.removed,
            ),
      ],
    );
  }
}
