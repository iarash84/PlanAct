import 'package:planact/core/errors/app_error.dart';
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
          label: 'انجام شد / حضور داشت',
          consequence: 'این نوبت به‌عنوان انجام‌شده ثبت می‌شود.',
        ),
      );
      actions.add(
        OccurrenceAction(
          type: OccurrenceActionType.providerCancelled,
          label: 'لغو توسط ارائه‌دهنده',
          consequence:
              sessionPolicy
                  .resolve(outcome: SessionOutcome.providerCancelled)
                  .requiresMakeup
              ? 'اعتبار طبق سیاست ثبت می‌شود و جلسهٔ جبرانی لازم است.'
              : 'اعتبار طبق سیاست لغو ارائه‌دهنده ثبت می‌شود.',
          requiresReason: true,
        ),
      );
      actions.add(
        OccurrenceAction(
          type: OccurrenceActionType.userCancelled,
          label: 'لغو توسط من',
          consequence:
              'اثر لغو بر اعتبار به زمان اعلام و سیاست جلسه بستگی دارد.',
          requiresReason: true,
        ),
      );
      actions.add(
        const OccurrenceAction(
          type: OccurrenceActionType.noShow,
          label: 'عدم حضور',
          consequence: 'اثر عدم حضور بر اعتبار طبق سیاست جلسه ثبت می‌شود.',
          requiresReason: true,
        ),
      );
      actions.add(
        const OccurrenceAction(
          type: OccurrenceActionType.reschedule,
          label: 'جابه‌جایی زمان',
          consequence:
              'زمان این نوبت تغییر می‌کند و یادآوری‌ها باید بازسازی شوند.',
        ),
      );
    case OccurrenceStatus.cancelled:
    case OccurrenceStatus.skipped:
      actions.add(
        const OccurrenceAction(
          type: OccurrenceActionType.restore,
          label: 'بازگردانی / بازگشایی',
          consequence: 'این نوبت دوباره برای اقدام در دسترس قرار می‌گیرد.',
        ),
      );
      actions.add(
        const OccurrenceAction(
          type: OccurrenceActionType.makeup,
          label: 'ساخت جلسهٔ جبرانی',
          consequence: 'جلسهٔ جبرانی بدون حذف سابقه ساخته می‌شود.',
        ),
      );
    case OccurrenceStatus.completed:
      // Completed occurrences are historical and cannot be reopened silently.
      break;
  }
  return List.unmodifiable(actions);
}

abstract interface class OccurrenceActionExecutor {
  Future<void> complete(Occurrence occurrence);
  Future<void> cancel(Occurrence occurrence, {required SessionOutcome outcome});
  Future<void> reschedule(Occurrence occurrence, DateTime scheduledAt);
  Future<void> restore(Occurrence occurrence);
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
  });

  final CommitmentPlanRepository plans;
  final ReplacementRepository? replacements;
  final SessionPolicyRepository? policyRepository;

  Future<void> execute({
    required Occurrence occurrence,
    required OccurrenceActionType action,
    DateTime? scheduledAt,
  }) async {
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
  }

  @override
  Future<void> complete(Occurrence occurrence) async {
    if (occurrence.status == OccurrenceStatus.completed) return;
    await plans.saveOccurrence(
      occurrence.withStatus(OccurrenceStatus.completed),
    );
  }

  @override
  Future<void> cancel(
    Occurrence occurrence, {
    required SessionOutcome outcome,
  }) async {
    final nextStatus = outcome == SessionOutcome.noShow
        ? OccurrenceStatus.skipped
        : OccurrenceStatus.cancelled;
    if (occurrence.status == nextStatus) return;
    await plans.saveOccurrence(occurrence.withStatus(nextStatus));
  }

  @override
  Future<void> reschedule(Occurrence occurrence, DateTime scheduledAt) async {
    if (occurrence.currentScheduledAt == scheduledAt &&
        occurrence.status == OccurrenceStatus.rescheduled) {
      return;
    }
    await plans.saveOccurrence(occurrence.reschedule(scheduledAt));
  }

  @override
  Future<void> restore(Occurrence occurrence) async {
    if (occurrence.status == OccurrenceStatus.scheduled) return;
    await plans.saveOccurrence(
      occurrence.withStatus(OccurrenceStatus.scheduled),
    );
  }

  @override
  Future<void> createMakeup(Occurrence occurrence, DateTime scheduledAt) async {
    final repository = replacements;
    if (repository == null) {
      throw StateError('A replacement repository is required for makeup.');
    }
    final existing = await repository.listByOriginal(occurrence.id);
    if (existing.any((item) => item.scheduledAt == scheduledAt.toUtc())) return;
    await repository.save(
      ReplacementOccurrence.create(
        originalOccurrenceId: occurrence.id,
        scheduledAt: scheduledAt,
        reason: ReplacementReason.makeup,
      ),
    );
  }

  DateTime _requireDate(DateTime? value, String message) {
    if (value == null) throw ValidationError(message);
    return value;
  }
}
