import 'package:planact/features/classification/domain/tag.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

class CommitmentFilter {
  const CommitmentFilter({
    this.kind,
    this.status,
    this.tag,
    this.from,
    this.to,
  });

  final CommitmentKind? kind;
  final CommitmentStatus? status;
  final Tag? tag;
  final DateTime? from;
  final DateTime? to;
}

class CommitmentReport {
  const CommitmentReport({required this.items, required this.byStatus});

  final List<Commitment> items;
  final Map<CommitmentStatus, int> byStatus;

  int get total => items.length;
}

CommitmentReport buildCommitmentReport(
  Iterable<Commitment> commitments,
  CommitmentFilter filter, {
  Map<String, Set<Tag>> tagsByCommitment = const {},
}) {
  final items = commitments
      .where((item) {
        if (filter.kind != null && item.kind != filter.kind) {
          return false;
        }
        if (filter.status != null && item.status != filter.status) {
          return false;
        }
        if (filter.from != null && item.createdAt.isBefore(filter.from!)) {
          return false;
        }
        if (filter.to != null && item.createdAt.isAfter(filter.to!)) {
          return false;
        }
        if (filter.tag != null &&
            !(tagsByCommitment[item.id.value] ?? const {}).any(
              (tag) => tag.normalizedLabel == filter.tag!.normalizedLabel,
            )) {
          return false;
        }
        return true;
      })
      .toList(growable: false);
  final byStatus = <CommitmentStatus, int>{};
  for (final item in items) {
    byStatus.update(item.status, (count) => count + 1, ifAbsent: () => 1);
  }
  return CommitmentReport(items: items, byStatus: Map.unmodifiable(byStatus));
}
