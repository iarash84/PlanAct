import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/application/relationship_target_reader.dart';
import 'package:planact/features/search/domain/search.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

/// Compatibility projection for injected flows without a durable paged reader.
RelationshipTargetPage pageLocalRelationshipTargets(
  List<RelationshipTarget> targets,
  RelationshipTargetQuery query,
) {
  final tokens = normalizeSearchText(query.query)
      .split(' ')
      .where((s) => s.isNotEmpty);
  final filtered = targets.where((target) {
    final text = normalizeSearchText(
      '${target.commitment.title} ${target.commitment.description ?? ''} ${target.commitment.tags.join(' ')}',
    );
    final date = relationshipTargetDate(target.occurrence.currentScheduledAt);
    final outstanding = target.outstanding?.minorUnits;
    return tokens.every(text.contains) &&
        (query.from == null ||
            (date != null &&
                !date.isBefore(query.from!.toUtcDateForCalculation()))) &&
        (query.to == null ||
            (date != null &&
                !date.isAfter(query.to!.toUtcDateForCalculation()))) &&
        (query.minimumOutstanding == null ||
            (outstanding != null &&
                outstanding >= query.minimumOutstanding!)) &&
        (query.maximumOutstanding == null ||
            (outstanding != null &&
                outstanding <= query.maximumOutstanding!)) &&
        (query.occurrenceStatus == null ||
            target.occurrence.status == query.occurrenceStatus) &&
        (query.commitmentStatus == null ||
            target.commitment.status == query.commitmentStatus) &&
        (query.cycleId == null || target.occurrence.cycleId == query.cycleId);
  }).toList();
  int dateOrder(RelationshipTarget a, RelationshipTarget b) {
    final result = relationshipTargetInstant(a.occurrence.currentScheduledAt)
        .compareTo(relationshipTargetInstant(b.occurrence.currentScheduledAt));
    return result;
  }

  filtered.sort((a, b) {
    int result;
    if (query.sort == RelationshipTargetSort.dateAscending ||
        query.sort == RelationshipTargetSort.dateDescending) {
      result = dateOrder(a, b);
      if (query.sort == RelationshipTargetSort.dateDescending) result = -result;
    } else {
      final x = a.outstanding?.minorUnits;
      final y = b.outstanding?.minorUnits;
      result = x == null
          ? (y == null ? 0 : 1)
          : y == null
          ? -1
          : query.sort == RelationshipTargetSort.amountAscending
          ? x.compareTo(y)
          : y.compareTo(x);
      if (result == 0) result = dateOrder(a, b);
    }
    return result == 0
        ? a.occurrence.id.value.compareTo(b.occurrence.id.value)
        : result;
  });
  final cycles = {
    for (final t in filtered)
      t.occurrence.cycleId: t.cycleLabel ?? t.occurrence.cycleId.value,
  };
  return RelationshipTargetPage(
    items: filtered.skip(query.page * query.pageSize).take(query.pageSize),
    total: filtered.length,
    cycles: cycles.entries.map(
      (e) => RelationshipTargetCycleOption(id: e.key, label: e.value),
    ),
  );
}

DateTime relationshipTargetInstant(Object value) => value is DateTime
    ? value.toLocal()
    : value is LocalDate
    ? DateTime(value.year, value.month, value.day)
    : DateTime(1);

DateTime? relationshipTargetDate(Object value) {
  if (value is! DateTime && value is! LocalDate) return null;
  final at = relationshipTargetInstant(value);
  return DateTime.utc(at.year, at.month, at.day);
}
