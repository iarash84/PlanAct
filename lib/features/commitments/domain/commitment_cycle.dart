import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';

enum CommitmentCycleType {
  openEnded,
  fixedDateRange,
  fixedCount,
  manualPackage,
  hybrid,
}

enum CompletionRule { byDate, byUnits, whicheverFirst, whicheverLast, manual }

enum CommitmentCycleStatus { draft, active, completed, cancelled, archived }

class CommitmentCycle {
  CommitmentCycle({
    required this.id,
    required this.commitmentId,
    required this.cycleType,
    required this.startDate,
    required this.completionRule,
    this.plannedEndDate,
    this.actualEndDate,
    this.targetUnits,
    this.consumedUnits = 0,
    this.status = CommitmentCycleStatus.draft,
  }) {
    _validate();
  }

  factory CommitmentCycle.create({
    required StableId commitmentId,
    required CommitmentCycleType cycleType,
    required DateTime startDate,
    required CompletionRule completionRule,
    DateTime? plannedEndDate,
    int? targetUnits,
  }) {
    return CommitmentCycle(
      id: StableId.generate(),
      commitmentId: commitmentId,
      cycleType: cycleType,
      startDate: _utcDate(startDate),
      completionRule: completionRule,
      plannedEndDate: plannedEndDate == null ? null : _utcDate(plannedEndDate),
      targetUnits: targetUnits,
    );
  }

  final StableId id;
  final StableId commitmentId;
  final CommitmentCycleType cycleType;
  final DateTime startDate;
  final DateTime? plannedEndDate;
  final DateTime? actualEndDate;
  final int? targetUnits;
  final int consumedUnits;
  final CompletionRule completionRule;
  final CommitmentCycleStatus status;

  bool get isCompleted => status == CommitmentCycleStatus.completed;

  bool shouldComplete({required DateTime onDate, int? unitsConsumed}) {
    final dateReached =
        plannedEndDate != null && !onDate.isBefore(plannedEndDate!);
    final unitsReached =
        targetUnits != null && (unitsConsumed ?? consumedUnits) >= targetUnits!;
    return switch (completionRule) {
      CompletionRule.byDate => dateReached,
      CompletionRule.byUnits => unitsReached,
      CompletionRule.whicheverFirst => dateReached || unitsReached,
      CompletionRule.whicheverLast => dateReached && unitsReached,
      CompletionRule.manual => false,
    };
  }

  CommitmentCycle activate() {
    if (status != CommitmentCycleStatus.draft) {
      throw const ValidationError('Only a draft cycle can be activated');
    }
    return _copyWith(status: CommitmentCycleStatus.active);
  }

  CommitmentCycle complete({DateTime? completedAt, int? unitsConsumed}) {
    if (status != CommitmentCycleStatus.active) {
      throw const ValidationError('Only an active cycle can be completed');
    }
    return _copyWith(
      status: CommitmentCycleStatus.completed,
      actualEndDate: _utcDate(completedAt ?? DateTime.now()),
      consumedUnits: unitsConsumed ?? consumedUnits,
    );
  }

  CommitmentCycle cancel() {
    if (status != CommitmentCycleStatus.draft &&
        status != CommitmentCycleStatus.active) {
      throw const ValidationError(
        'Only a draft or active cycle can be cancelled',
      );
    }
    return _copyWith(status: CommitmentCycleStatus.cancelled);
  }

  CommitmentCycle _copyWith({
    CommitmentCycleStatus? status,
    DateTime? actualEndDate,
    int? consumedUnits,
  }) {
    return CommitmentCycle(
      id: id,
      commitmentId: commitmentId,
      cycleType: cycleType,
      startDate: startDate,
      plannedEndDate: plannedEndDate,
      actualEndDate: actualEndDate ?? this.actualEndDate,
      targetUnits: targetUnits,
      consumedUnits: consumedUnits ?? this.consumedUnits,
      completionRule: completionRule,
      status: status ?? this.status,
    );
  }

  void _validate() {
    if (plannedEndDate != null && plannedEndDate!.isBefore(startDate)) {
      throw const ValidationError('Planned end date cannot precede start date');
    }
    if (targetUnits != null && targetUnits! <= 0) {
      throw const ValidationError('Target units must be positive');
    }
    if (consumedUnits < 0) {
      throw const ValidationError('Consumed units cannot be negative');
    }
    if (targetUnits == null &&
        (completionRule == CompletionRule.byUnits ||
            completionRule == CompletionRule.whicheverFirst ||
            completionRule == CompletionRule.whicheverLast)) {
      throw const ValidationError('This completion rule requires target units');
    }
    if (plannedEndDate == null &&
        (completionRule == CompletionRule.byDate ||
            completionRule == CompletionRule.whicheverFirst ||
            completionRule == CompletionRule.whicheverLast)) {
      throw const ValidationError(
        'This completion rule requires planned end date',
      );
    }
  }

  static DateTime _utcDate(DateTime value) => value.toUtc();
}
