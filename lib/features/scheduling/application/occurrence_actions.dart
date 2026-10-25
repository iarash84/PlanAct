import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/features/actuals/application/actual_use_cases.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/sessions/data/drift_session_repositories.dart';
import 'package:planact/features/sessions/domain/replacement.dart';
import 'package:planact/features/sessions/domain/session_policy.dart';

/// User-facing lifecycle actions available for one occurrence.
enum OccurrenceActionType {
  complete,
  cancel,
  providerCancelled,
  userCancelled,
  noShow,
  reschedule,
  restore,
  makeup,
}

class OccurrenceAction {
  const OccurrenceAction({
    required this.type,
    required this.label,
    required this.consequence,
    this.requiresReason = false,
  });

  final OccurrenceActionType type;
  final String label;
  final String consequence;
  final bool requiresReason;
}

/// Pure availability policy shared by Today, Calendar, and detail screens.
List<OccurrenceAction> availableOccurrenceActions(
  Occurrence occurrence, {
  SessionPolicy? policy,
}) {
  final sessionPolicy = policy ?? const SessionPolicy();
  final actions = <OccurrenceAction>[];
  switch (occurrence.status) {
    case OccurrenceStatus.scheduled:
    case OccurrenceStatus.due:
    case OccurrenceStatus.overdue:
    case OccurrenceStatus.rescheduled:
    case OccurrenceStatus.deferred:
    case OccurrenceStatus.pendingDecision:
      actions.add(
        const OccurrenceAction(
          type: OccurrenceActionType.complete,
          label: PersianCopy.occurrenceActionsAvailableOccurrenceActionsLabel,
          consequence: PersianCopy
              .occurrenceActionsAvailableOccurrenceActionsConsequence,
        ),
      );
      actions.add(
        OccurrenceAction(
          type: OccurrenceActionType.providerCancelled,
          label: PersianCopy.occurrenceActionsAvailableOccurrenceActionsLabel2,
          consequence:
              sessionPolicy
                  .resolve(outcome: SessionOutcome.providerCancelled)
                  .requiresMakeup
              ? PersianCopy
                    .occurrenceActionsAvailableOccurrenceActionsConsequence2
              : PersianCopy
                    .occurrenceActionsAvailableOccurrenceActionsConsequence3,
          requiresReason: true,
        ),
      );
      actions.add(
        OccurrenceAction(
          type: OccurrenceActionType.userCancelled,
          label: PersianCopy.occurrenceActionsAvailableOccurrenceActionsLabel3,
          consequence: PersianCopy
              .occurrenceActionsAvailableOccurrenceActionsConsequence4,
          requiresReason: true,
        ),
      );
      actions.add(
        const OccurrenceAction(
          type: OccurrenceActionType.noShow,
          label: PersianCopy.occurrenceSkipped,
          consequence: PersianCopy
              .occurrenceActionsAvailableOccurrenceActionsConsequence5,
          requiresReason: true,
        ),
      );
      actions.add(
        const OccurrenceAction(
          type: OccurrenceActionType.reschedule,
          label: PersianCopy.occurrenceActionsAvailableOccurrenceActionsLabel4,
          consequence: PersianCopy
              .occurrenceActionsAvailableOccurrenceActionsConsequence6,
        ),
      );
      if (occurrence.status == OccurrenceStatus.pendingDecision &&
          occurrence.resultRevision > 0) {
        actions.add(
          const OccurrenceAction(
            type: OccurrenceActionType.restore,
            label:
                PersianCopy.occurrenceActionsAvailableOccurrenceActionsLabel7,
            consequence: PersianCopy
                .occurrenceActionsAvailableOccurrenceActionsConsequence9,
          ),
        );
      }
    case OccurrenceStatus.cancelled:
    case OccurrenceStatus.skipped:
      actions.add(
        const OccurrenceAction(
          type: OccurrenceActionType.restore,
          label: PersianCopy.occurrenceActionsAvailableOccurrenceActionsLabel5,
          consequence: PersianCopy
              .occurrenceActionsAvailableOccurrenceActionsConsequence7,
        ),
      );
      actions.add(
        const OccurrenceAction(
          type: OccurrenceActionType.makeup,
          label: PersianCopy.occurrenceActionsAvailableOccurrenceActionsLabel6,
          consequence: PersianCopy
              .occurrenceActionsAvailableOccurrenceActionsConsequence8,
        ),
      );
    case OccurrenceStatus.completed:
      actions.add(
        const OccurrenceAction(
          type: OccurrenceActionType.restore,
          label: PersianCopy.occurrenceActionsAvailableOccurrenceActionsLabel7,
          consequence: PersianCopy
              .occurrenceActionsAvailableOccurrenceActionsConsequence9,
        ),
      );
  }
  return List.unmodifiable(actions);
}

/// The occurrence is committed; only external reminder delivery needs retry.
class OccurrenceReminderDeliveryPending implements Exception {
  const OccurrenceReminderDeliveryPending(this.occurrence);
  final Occurrence occurrence;
}

abstract interface class OccurrenceActionExecutor {
  Future<Occurrence> complete(Occurrence occurrence);
  Future<Occurrence> cancel(
    Occurrence occurrence, {
    required SessionOutcome outcome,
  });
  Future<void> reschedule(Occurrence occurrence, DateTime scheduledAt);
  Future<Occurrence> restore(Occurrence occurrence);
  Future<void> createMakeup(Occurrence occurrence, DateTime scheduledAt);
}

/// Executes occurrence actions through the domain and durable repositories.
///
/// The executor intentionally records the occurrence outcome separately from
/// any entitlement accounting. A later ledger command can fold the same
/// outcome with the cycle's approved policy without mutating history here.
class PersistedOccurrenceActionExecutor implements OccurrenceActionExecutor {
  PersistedOccurrenceActionExecutor({
    required this.plans,
    this.replacements,
    this.policyRepository,
    this.reminders,
    this.actuals,
  });

  final CommitmentPlanRepository plans;
  final ReplacementRepository? replacements;
  final SessionPolicyRepository? policyRepository;
  final ReminderService? reminders;
  final OccurrenceActualWriter? actuals;

  Future<Occurrence> recordResult(
    Occurrence occurrence,
    ActualOutcome outcome, {
    String? note,
  }) => CommandGate.runFor(plans, () async {
    final writer = actuals;
    if (writer == null) {
      throw StateError('An atomic actual writer is required.');
    }
    final updated = await writer.recordOccurrenceActual(
      expected: occurrence,
      outcome: outcome,
      recordedAt: DateTime.now().toUtc(),
      note: note,
    );
    await _synchronize(updated);
    return updated;
  });

  Future<void> _synchronize(Occurrence occurrence) async {
    final resolved =
        occurrence.status == OccurrenceStatus.completed ||
        occurrence.status == OccurrenceStatus.cancelled ||
        occurrence.status == OccurrenceStatus.skipped;
    try {
      await reminders?.synchronizeOccurrence(
        occurrenceId: occurrence.id,
        occurrenceStart: occurrence.currentScheduledAt is DateTime
            ? occurrence.currentScheduledAt as DateTime
            : null,
        resolved: resolved,
      );
    } catch (_) {
      throw OccurrenceReminderDeliveryPending(occurrence);
    }
  }

  Future<void> execute({
    required Occurrence occurrence,
    required OccurrenceActionType action,
    DateTime? scheduledAt,
  }) => CommandGate.runFor(plans, () async {
    final available = availableOccurrenceActions(
      occurrence,
      policy: await policyRepository?.findByCycle(occurrence.cycleId),
    );
    if (!available.any((item) => item.type == action)) {
      throw const ValidationError('This occurrence action is not available.');
    }
    switch (action) {
      case OccurrenceActionType.complete:
        await complete(occurrence);
      case OccurrenceActionType.providerCancelled:
        await cancel(occurrence, outcome: SessionOutcome.providerCancelled);
      case OccurrenceActionType.userCancelled:
        await cancel(occurrence, outcome: SessionOutcome.userCancelled);
      case OccurrenceActionType.noShow:
        await cancel(occurrence, outcome: SessionOutcome.noShow);
      case OccurrenceActionType.reschedule:
        await reschedule(
          occurrence,
          _requireDate(scheduledAt, 'A new time is required.'),
        );
      case OccurrenceActionType.restore:
        await restore(occurrence);
      case OccurrenceActionType.makeup:
        await createMakeup(
          occurrence,
          _requireDate(scheduledAt, 'A makeup time is required.'),
        );
      case OccurrenceActionType.cancel:
        await cancel(occurrence, outcome: SessionOutcome.userCancelled);
    }
  });

  @override
  Future<Occurrence> complete(Occurrence occurrence) =>
      CommandGate.runFor(plans, () async {
        if (actuals != null) {
          return recordResult(occurrence, ActualOutcome.completed);
        }
        final updated = occurrence.withStatus(OccurrenceStatus.completed);
        await plans.saveOccurrence(updated);
        await _synchronize(updated);
        return updated;
      });

  @override
  Future<Occurrence> cancel(
    Occurrence occurrence, {
    required SessionOutcome outcome,
  }) => CommandGate.runFor(plans, () async {
    if (actuals != null) {
      return recordResult(
        occurrence,
        outcome == SessionOutcome.noShow
            ? ActualOutcome.noShow
            : ActualOutcome.cancelled,
      );
    }
    final nextStatus = outcome == SessionOutcome.noShow
        ? OccurrenceStatus.skipped
        : OccurrenceStatus.cancelled;
    final updated = occurrence.withStatus(nextStatus);
    await plans.saveOccurrence(updated);
    await _synchronize(updated);
    return updated;
  });

  @override
  Future<void> reschedule(Occurrence occurrence, DateTime scheduledAt) =>
      CommandGate.runFor(plans, () async {
        final updated = occurrence.reschedule(scheduledAt);
        await plans.saveOccurrence(updated);
        await _synchronize(updated);
      });

  @override
  Future<Occurrence> restore(Occurrence occurrence) =>
      CommandGate.runFor(plans, () async {
        if (actuals != null) {
          return recordResult(occurrence, ActualOutcome.reopened);
        }
        final updated = occurrence.withStatus(OccurrenceStatus.scheduled);
        await plans.saveOccurrence(updated);
        await _synchronize(updated);
        return updated;
      });

  @override
  Future<void> createMakeup(Occurrence occurrence, DateTime scheduledAt) =>
      CommandGate.runFor(plans, () async {
        final repository = replacements;
        if (repository == null) {
          throw StateError('A replacement repository is required for makeup.');
        }
        final existing = await repository.listByOriginal(occurrence.id);
        if (existing.any((item) => item.scheduledAt == scheduledAt.toUtc())) {
          return;
        }
        await repository.save(
          ReplacementOccurrence.create(
            originalOccurrenceId: occurrence.id,
            scheduledAt: scheduledAt,
            reason: ReplacementReason.makeup,
          ),
        );
      });

  DateTime _requireDate(DateTime? value, String message) {
    if (value == null) throw ValidationError(message);
    return value;
  }
}
