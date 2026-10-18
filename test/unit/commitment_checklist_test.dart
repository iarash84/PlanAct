import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/domain/commitment_checklist.dart';

void main() {
  test('shopping tasks retain identity and checked state through rename/removal/restore', () {
    final empty = CommitmentChecklist(commitmentId: StableId.generate());
    final added = empty.add('  نان  ').add('شیر');
    final id = added.items.first.id;
    final checked = added.change(id, checked: true);
    final renamed = checked.change(id, title: 'نان سنگک');
    final removed = renamed.change(id, removed: true);
    final restored = removed.change(id, removed: false);
    expect(empty.items, isEmpty);
    expect(added.items.first.title, 'نان');
    expect(restored.commitmentId, empty.commitmentId);
    expect(restored.revision, 6);
    expect(restored.items.first.id, id);
    expect(restored.items.first.title, 'نان سنگک');
    expect(restored.items.first.checked, isTrue);
    expect(restored.items.first.removed, isFalse);
    expect(restored.change(id, checked: false).items.first.checked, isFalse);
    expect(restored.items.last.checked, isFalse);
    expect(() => restored.items.clear(), throwsUnsupportedError);
  });

  test(
    'reject empty titles, duplicate IDs, missing items and invalid revisions',
    () {
      final list = CommitmentChecklist(commitmentId: StableId.generate())
          .add('نان');
      expect(() => list.add('  '), throwsArgumentError);
      expect(
        () => list.change(list.items.single.id, title: ''),
        throwsArgumentError,
      );
      expect(
        () => list.change(StableId.generate(), checked: true),
        throwsArgumentError,
      );
      expect(
        () => list.add('شیر', id: list.items.single.id),
        throwsArgumentError,
      );
      expect(
        () =>
            CommitmentChecklist(commitmentId: list.commitmentId, revision: -1),
        throwsArgumentError,
      );
    },
  );
}
