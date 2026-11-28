import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

enum RelationshipTargetSort {
  dateAscending,
  dateDescending,
  amountAscending,
  amountDescending,
}

class RelationshipTargetQuery {
  const RelationshipTargetQuery({
    this.query = '',
    this.page = 0,
    this.from,
    this.to,
    this.minimumOutstanding,
    this.maximumOutstanding,
    this.occurrenceStatus,
    this.commitmentStatus,
    this.cycleId,
    this.sort = RelationshipTargetSort.dateAscending,
  });

  final String query;
  final int page;
  final int pageSize = 20;
  final LocalDate? from;
  final LocalDate? to;
  final int? minimumOutstanding;
  final int? maximumOutstanding;
  final OccurrenceStatus? occurrenceStatus;
  final CommitmentStatus? commitmentStatus;
  final StableId? cycleId;
  final RelationshipTargetSort sort;
}

class RelationshipTargetCycleOption {
  const RelationshipTargetCycleOption({required this.id, required this.label});
  final StableId id;
  final String label;
}

class RelationshipTargetPage {
  RelationshipTargetPage({
    required Iterable<RelationshipTarget> items,
    required this.total,
    Iterable<RelationshipTargetCycleOption> cycles = const [],
  }) : items = List.unmodifiable(items),
       cycles = List.unmodifiable(cycles);

  final List<RelationshipTarget> items;
  final int total;
  final List<RelationshipTargetCycleOption> cycles;
}

abstract interface class RelationshipTargetReader {
  Future<RelationshipTargetPage> read(
    RelationshipTargetQuery query,
    String currency,
  );

  Future<List<RelationshipTarget>> byIds(
    Iterable<StableId> ids,
    String currency,
  );
}
