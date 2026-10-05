import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';

class DriftCommitmentPlanRepository
    implements CommitmentPlanRepository, CommitmentPlanTransaction {
  DriftCommitmentPlanRepository(this.database);
  final db.AppDatabase database;

  @override
  Future<T> runTransaction<T>(Future<T> Function() action) =>
      database.transaction(action);

  @override
  Future<void> save(CommitmentPlan plan) async {
    await database.transaction(() async {
      await database
          .into(database.commitmentCycles)
          .insertOnConflictUpdate(
            db.CommitmentCyclesCompanion.insert(
              id: plan.cycle.id.value,
              commitmentId: plan.cycle.commitmentId.value,
              cycleType: plan.cycle.cycleType.index,
              startDate: plan.cycle.startDate,
              plannedEndDate: Value(plan.cycle.plannedEndDate),
              actualEndDate: Value(plan.cycle.actualEndDate),
              targetUnits: Value(plan.cycle.targetUnits),
              consumedUnits: plan.cycle.consumedUnits,
              completionRule: plan.cycle.completionRule.index,
              status: plan.cycle.status.index,
            ),
          );
      await database
          .into(database.scheduleDefinitions)
          .insertOnConflictUpdate(
            db.ScheduleDefinitionsCompanion.insert(
              id: plan.schedule.id.value,
              cycleId: plan.schedule.cycleId.value,
              mode: plan.schedule.mode.index,
              timeSemantics: plan.schedule.timeSemantics.index,
              startDate: _date(plan.schedule.startDate),
              localTime: Value(_time(plan.schedule.localTime)),
              timeZoneId: Value(plan.schedule.timeZoneId),
              fixedInstant: Value(plan.schedule.fixedInstant),
              recurrenceRule: Value(_rule(plan.schedule.recurrenceRule)),
              endDate: Value(
                plan.schedule.endDate == null
                    ? null
                    : _date(plan.schedule.endDate!),
              ),
              occurrenceCount: Value(plan.schedule.occurrenceCount),
              version: plan.schedule.version,
              effectiveFrom: _date(plan.schedule.effectiveFrom),
              generationHorizonDays: plan.schedule.generationHorizonDays,
            ),
          );
      for (final occurrence in plan.occurrences) {
        await database
            .into(database.occurrences)
            .insertOnConflictUpdate(
              db.OccurrencesCompanion.insert(
                id: occurrence.id.value,
                cycleId: occurrence.cycleId.value,
                scheduleDefinitionId: occurrence.scheduleDefinitionId.value,
                occurrenceKey: occurrence.occurrenceKey,
                timeSemantics: plan.schedule.timeSemantics.index,
                originalScheduledValue: _value(
                  occurrence.originalScheduledAt,
                  plan.schedule.timeSemantics,
                ),
                currentScheduledValue: _value(
                  occurrence.currentScheduledAt,
                  plan.schedule.timeSemantics,
                ),
                status: occurrence.status.index,
                isManualOverride: occurrence.isManualOverride,
              ),
            );
      }
      final reminders = DriftReminderRepository(database);
      for (final rule in plan.reminders) {
        await reminders.saveRule(rule);
      }
    });
  }

  @override
  Future<void> saveOccurrence(Occurrence occurrence) async {
    final schedule =
        await (database.select(database.scheduleDefinitions)..where(
              (table) => table.id.equals(occurrence.scheduleDefinitionId.value),
            ))
            .getSingleOrNull();
    if (schedule == null) throw StateError('Schedule was not found.');
    await database
        .into(database.occurrences)
        .insertOnConflictUpdate(
          db.OccurrencesCompanion.insert(
            id: occurrence.id.value,
            cycleId: occurrence.cycleId.value,
            scheduleDefinitionId: occurrence.scheduleDefinitionId.value,
            occurrenceKey: occurrence.occurrenceKey,
            timeSemantics: schedule.timeSemantics,
            originalScheduledValue: occurrence.originalScheduledAt is LocalDate
                ? 'date:${_date(occurrence.originalScheduledAt as LocalDate)}'
                : _value(
                    occurrence.originalScheduledAt,
                    TimeSemantics.values[schedule.timeSemantics],
                  ),
            currentScheduledValue: _value(
              occurrence.currentScheduledAt,
              TimeSemantics.values[schedule.timeSemantics],
            ),
            status: occurrence.status.index,
            isManualOverride: occurrence.isManualOverride,
          ),
        );
  }

  @override
  Future<CommitmentPlan?> findByCommitmentId(StableId commitmentId) async {
    final cycle =
        await (database.select(database.commitmentCycles)
              ..where((t) => t.commitmentId.equals(commitmentId.value)))
            .getSingleOrNull();
    if (cycle == null) return null;
    final schedule = await (database.select(
      database.scheduleDefinitions,
    )..where((t) => t.cycleId.equals(cycle.id))).getSingleOrNull();
    if (schedule == null) return null;
    final rows = await (database.select(
      database.occurrences,
    )..where((t) => t.scheduleDefinitionId.equals(schedule.id))).get();
    final commitment = await DriftCommitmentRepository(database)
        .findById(commitmentId);
    if (commitment == null) return null;
    final rules = await DriftReminderRepository(database).listRules();
    final occurrenceIds = rows.map((row) => row.id).toSet();
    return CommitmentPlan(
      commitment: commitment,
      cycle: _cycle(cycle),
      schedule: _schedule(schedule),
      occurrences: rows.map(_occurrence).toList(growable: false),
      reminders: rules
          .where((rule) => occurrenceIds.contains(rule.occurrenceId.value))
          .toList(growable: false),
    );
  }

  static String _date(LocalDate value) =>
      '${value.year}-${value.month}-${value.day}';
  static LocalDate _parseDate(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return LocalDate(parts[0], parts[1], parts[2]);
  }

  static String? _time(LocalTime? value) =>
      value == null ? null : '${value.hour}:${value.minute}';
  static LocalTime? _parseTime(String? value) {
    if (value == null) return null;
    final p = value.split(':').map(int.parse).toList();
    return LocalTime(p[0], p[1]);
  }

  static String? _rule(RecurrenceRule? value) => value == null
      ? null
      : jsonEncode({
          'frequency': value.frequency.index,
          'interval': value.interval,
          'weekdays': value.weekdays.toList(),
          'dayOfMonth': value.dayOfMonth,
          'monthEndPolicy': value.monthEndPolicy.index,
        });
  static RecurrenceRule? _parseRule(String? value) {
    if (value == null) return null;
    final m = jsonDecode(value) as Map<String, dynamic>;
    return RecurrenceRule(
      frequency: RecurrenceFrequency.values[m['frequency'] as int],
      interval: m['interval'] as int,
      weekdays: (m['weekdays'] as List).cast<int>().toSet(),
      dayOfMonth: m['dayOfMonth'] as int?,
      monthEndPolicy: MonthEndPolicy.values[m['monthEndPolicy'] as int],
    );
  }

  static String _value(Object value, TimeSemantics semantics) {
    if (value is LocalDate) return 'date:${_date(value)}';
    final dateTime = value as DateTime;
    if (semantics == TimeSemantics.floatingLocalTime) {
      return 'local:${dateTime.year}-${dateTime.month}-${dateTime.day}T'
          '${dateTime.hour}:${dateTime.minute}:${dateTime.second}.'
          '${dateTime.millisecond.toString().padLeft(3, '0')}';
    }
    return 'instant:${dateTime.toUtc().toIso8601String()}';
  }

  static Object _parseValue(String value) {
    if (value.startsWith('date:')) return _parseDate(value.substring(5));
    if (value.startsWith('local:')) {
      final parts = value.substring(6).split('T');
      final date = parts[0].split('-').map(int.parse).toList();
      final time = parts[1].split(':');
      final seconds = time[2].split('.');
      return DateTime(
        date[0],
        date[1],
        date[2],
        int.parse(time[0]),
        int.parse(time[1]),
        int.parse(seconds[0]),
        int.parse(seconds[1]),
      );
    }
    return DateTime.parse(value.substring(8)).toUtc();
  }

  CommitmentCycle _cycle(db.CommitmentCycle r) => CommitmentCycle(
    id: StableId.parse(r.id),
    commitmentId: StableId.parse(r.commitmentId),
    cycleType: CommitmentCycleType.values[r.cycleType],
    startDate: r.startDate,
    plannedEndDate: r.plannedEndDate,
    actualEndDate: r.actualEndDate,
    targetUnits: r.targetUnits,
    consumedUnits: r.consumedUnits,
    completionRule: CompletionRule.values[r.completionRule],
    status: CommitmentCycleStatus.values[r.status],
  );
  ScheduleDefinition _schedule(db.ScheduleDefinition r) => ScheduleDefinition(
    id: StableId.parse(r.id),
    cycleId: StableId.parse(r.cycleId),
    mode: ScheduleMode.values[r.mode],
    timeSemantics: TimeSemantics.values[r.timeSemantics],
    startDate: _parseDate(r.startDate),
    localTime: _parseTime(r.localTime),
    timeZoneId: r.timeZoneId,
    fixedInstant: r.fixedInstant,
    recurrenceRule: _parseRule(r.recurrenceRule),
    endDate: r.endDate == null ? null : _parseDate(r.endDate!),
    occurrenceCount: r.occurrenceCount,
    version: r.version,
    effectiveFrom: _parseDate(r.effectiveFrom),
    generationHorizonDays: r.generationHorizonDays,
  );
  Occurrence _occurrence(db.Occurrence r) => Occurrence(
    id: StableId.parse(r.id),
    cycleId: StableId.parse(r.cycleId),
    scheduleDefinitionId: StableId.parse(r.scheduleDefinitionId),
    occurrenceKey: r.occurrenceKey,
    originalScheduledAt: _parseValue(r.originalScheduledValue),
    currentScheduledAt: _parseValue(r.currentScheduledValue),
    status: OccurrenceStatus.values[r.status],
    isManualOverride: r.isManualOverride,
  );
}
