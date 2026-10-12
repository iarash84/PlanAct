import 'package:planact/core/application/command_gate.dart';

import 'dart:convert';

import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';

import 'package:planact/features/scheduling/application/extend_recurring_schedules.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

import 'package:planact/features/calendar/application/week_timeline.dart';

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
    implements
        CommandGateProvider,
        CommitmentPlanRepository,
        CommitmentPlanTransaction,
        CalendarRangeRepository,
        RecurringScheduleMaintenance {
  DriftCommitmentPlanRepository(this.database);

  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);
  final db.AppDatabase database;

  @override
  Future<T> runTransaction<T>(Future<T> Function() action) =>
      CommandGate.runFor(this, () async => database.transaction(action));

  @override
  Future<void> save(CommitmentPlan plan) => CommandGate.runFor(this, () async {
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
              recurrenceRule: Value(
                _rule(
                  plan.schedule.recurrenceRule,
                  plan.schedule.generationReminderOffsets,
                  plan.schedule.generationFinancialExpectation,
                ),
              ),
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
  });

  @override
  Future<void> saveOccurrence(
    Occurrence occurrence,
  ) => CommandGate.runFor(this, () async {
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
  });

  @override
  Future<CommitmentPlan?> findByCommitmentId(StableId commitmentId) =>
      CommandGate.runFor(this, () async {
        final cycle =
            await (database.select(database.commitmentCycles)
                  ..where((t) => t.commitmentId.equals(commitmentId.value)))
                .getSingleOrNull();
        if (cycle == null) return null;
        final schedule =
            await (database.select(database.scheduleDefinitions)
                  ..where((t) => t.cycleId.equals(cycle.id))
                  ..orderBy([(t) => OrderingTerm.desc(t.version)])
                  ..limit(1))
                .getSingleOrNull();
        if (schedule == null) return null;
        final rows = await (database.select(
          database.occurrences,
        )..where((t) => t.cycleId.equals(cycle.id))).get();
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
      });

  @override
  Future<int> extendRecurringSchedules(
    LocalDate today, {
    StableId? cycleId,
    StableId? scheduleId,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      // Acquire SQLite's writer before reading: admission is not serialization.
      await database.customStatement(
        'UPDATE schema_metadata SET value = value WHERE key = ?',
        ['schema_version'],
      );
      final cycles = await database.select(database.commitmentCycles).get();
      var inserted = 0;
      for (final cycle in cycles) {
        if (cycleId != null && cycle.id != cycleId.value) continue;
        if (cycle.status != CommitmentCycleStatus.active.index) continue;
        final owner = await DriftCommitmentRepository(database)
            .findById(StableId.parse(cycle.commitmentId));
        if (owner == null || owner.status != CommitmentStatus.active) continue;
        final rows =
            await (database.select(database.scheduleDefinitions)
                  ..where((t) => t.cycleId.equals(cycle.id))
                  ..orderBy([(t) => OrderingTerm.asc(t.version)]))
                .get();
        final existing = await (database.select(
          database.occurrences,
        )..where((t) => t.cycleId.equals(cycle.id))).get();
        final occupiedKeys = existing.map((r) => r.occurrenceKey).toSet();
        final occupiedDates = existing.map((r) {
          final value = _parseValue(r.originalScheduledValue);
          return value is LocalDate
              ? value
              : LocalDate.fromDateTime(value as DateTime);
        }).toSet();
        for (var i = 0; i < rows.length; i++) {
          if (scheduleId != null && rows[i].id != scheduleId.value) continue;
          var schedule = _schedule(rows[i]);
          if (schedule.mode == ScheduleMode.oneOff) continue;
          var through = today.addDays(schedule.generationHorizonDays);
          if (i + 1 < rows.length) {
            final boundary = _parseDate(rows[i + 1].effectiveFrom).addDays(-1);
            if (boundary.compareTo(through) < 0) through = boundary;
          }
          if (through.compareTo(today) < 0) continue;
          final metadata =
              jsonDecode(rows[i].recurrenceRule!) as Map<String, dynamic>;
          final originals = existing
              .where(
                (r) =>
                    r.scheduleDefinitionId == rows[i].id &&
                    !r.isManualOverride &&
                    r.originalScheduledValue == r.currentScheduledValue &&
                    r.occurrenceKey ==
                        '${rows[i].id}:${_date(occupiedDate(r))}',
              )
              .toList();
          var changedMetadata = false;
          if (!metadata.containsKey('generationReminderMinutes')) {
            final inferred = await _inferReminders(originals, owner.title);
            if (inferred != null) {
              metadata['generationReminderMinutes'] = inferred;
              changedMetadata = true;
            }
          }
          if (!metadata.containsKey('generationFinancialExpectation')) {
            final inferred = await _inferFinancial(originals);
            if (inferred != null) {
              metadata['generationFinancialExpectation'] = inferred;
              changedMetadata = true;
            }
          }
          if (changedMetadata) {
            // Upgrading payload must not reinterpret old null-day/yearly rules.
            metadata['legacyCalendarSemantics'] =
                schedule.recurrenceRule!.legacyCalendarSemantics;
            metadata['formatVersion'] = 2;
            await (database.update(
              database.scheduleDefinitions,
            )..where((t) => t.id.equals(rows[i].id))).write(
              db.ScheduleDefinitionsCompanion(
                recurrenceRule: Value(jsonEncode(metadata)),
              ),
            );
            final fresh = await (database.select(
              database.scheduleDefinitions,
            )..where((t) => t.id.equals(rows[i].id))).getSingle();
            schedule = _schedule(fresh);
          }
          final generated = const OccurrenceGenerator().generate(
            schedule: schedule,
            through: through,
            windowStart: today,
          );
          for (final occurrence in generated) {
            final date = occurrence.currentScheduledAt is LocalDate
                ? occurrence.currentScheduledAt as LocalDate
                : LocalDate.fromDateTime(
                    occurrence.currentScheduledAt as DateTime,
                  );
            // Edits retain stable keys/IDs from prior versions. A migrated or
            // resolved slot already owns its original date, even if moved.
            final occupied =
                occupiedKeys.contains(occurrence.occurrenceKey) ||
                occupiedDates.contains(date);
            if (occupied) continue;
            await database
                .into(database.occurrences)
                .insert(
                  db.OccurrencesCompanion.insert(
                    id: occurrence.id.value,
                    cycleId: cycle.id,
                    scheduleDefinitionId: schedule.id.value,
                    occurrenceKey: occurrence.occurrenceKey,
                    timeSemantics: schedule.timeSemantics.index,
                    originalScheduledValue: _value(
                      occurrence.originalScheduledAt,
                      schedule.timeSemantics,
                    ),
                    currentScheduledValue: _value(
                      occurrence.currentScheduledAt,
                      schedule.timeSemantics,
                    ),
                    status: occurrence.status.index,
                    isManualOverride: false,
                  ),
                  mode: InsertMode.insertOrIgnore,
                );
            final changed = await database
                .customSelect('SELECT changes() AS n')
                .getSingle();
            if (changed.read<int>('n') == 0) continue;
            inserted++;
            occupiedKeys.add(occurrence.occurrenceKey);
            occupiedDates.add(date);
            final template = schedule.generationFinancialExpectation;
            if (template != null) {
              final now = DateTime.now().toUtc();
              await DriftFinancialExpectationRepository(database)
                  .saveExpectation(
                    FinancialExpectation(
                      id: StableId.generate(),
                      occurrenceId: occurrence.id,
                      direction: template.direction,
                      amount: template.amount,
                      currency: template.currency,
                      accountId: template.accountId,
                      createdAt: now,
                      updatedAt: now,
                    ),
                  );
            }
            final reminders = DriftReminderRepository(database);
            for (final offset in schedule.generationReminderOffsets) {
              final rule = ReminderRule.beforeOccurrence(
                occurrenceId: occurrence.id,
                offset: offset,
                title: owner.title,
              );
              await reminders.saveRule(rule);
              if (occurrence.currentScheduledAt is DateTime) {
                await reminders.saveInstance(
                  ReminderInstance.fromRule(
                    rule: rule,
                    occurrenceStart: occurrence.currentScheduledAt as DateTime,
                  ),
                );
              }
            }
          }
        }
      }
      return inserted;
    }),
  );

  static LocalDate occupiedDate(db.Occurrence r) {
    final value = _parseValue(r.originalScheduledValue);
    return value is LocalDate
        ? value
        : LocalDate.fromDateTime(value as DateTime);
  }

  Future<List<int>?> _inferReminders(
    List<db.Occurrence> originals,
    String title,
  ) async {
    if (originals.isEmpty) return null;
    List<int>? template;
    for (final occurrence in originals) {
      final rules = await (database.select(
        database.reminderRules,
      )..where((t) => t.occurrenceId.equals(occurrence.id))).get();
      if (rules.isEmpty ||
          rules.any(
            (r) =>
                !r.enabled ||
                r.anchor != ReminderAnchor.occurrenceStart.index ||
                r.absoluteAt != null ||
                r.offsetSeconds > 0 ||
                r.offsetSeconds % 60 != 0 ||
                r.body != null ||
                (r.title != null && r.title != title),
          )) {
        return null;
      }
      final offsets = rules.map((r) => -r.offsetSeconds ~/ 60).toSet().toList()
        ..sort();
      if (offsets.length != rules.length) return null;
      if (template != null && jsonEncode(template) != jsonEncode(offsets)) {
        return null;
      }
      template = offsets;
    }
    return template;
  }

  Future<Map<String, Object?>?> _inferFinancial(
    List<db.Occurrence> originals,
  ) async {
    if (originals.isEmpty) return null;
    Map<String, Object?>? template;
    for (final occurrence in originals) {
      final items = await (database.select(
        database.financialExpectations,
      )..where((t) => t.occurrenceId.equals(occurrence.id))).get();
      if (items.length != 1 ||
          items.single.status != FinancialExpectationStatus.active.index) {
        return null;
      }
      final item = items.single;
      final current = <String, Object?>{
        'direction': item.direction,
        'amount': item.minorUnits,
        'currency': item.currency,
        'accountId': item.accountId,
      };
      if (template != null && jsonEncode(template) != jsonEncode(current)) {
        return null;
      }
      template = current;
    }
    return template;
  }

  @override
  Future<Map<String, List<Occurrence>>> loadWeek(LocalDate start) =>
      _loadRange(start, start.addDays(7));

  /// Reads a half-open range of 1–31 local dates without materializing schedules.
  Future<Map<String, List<Occurrence>>> loadMonth(
    LocalDate start,
    LocalDate endExclusive,
  ) => _loadRange(start, endExclusive);

  Future<Map<String, List<Occurrence>>> _loadRange(
    LocalDate start,
    LocalDate endExclusive,
  ) => CommandGate.runFor(this, () async {
    // Count calendar dates in UTC, not elapsed local hours across DST changes.
    final days = endExclusive
        .toUtcDateForCalculation()
        .difference(start.toUtcDateForCalculation())
        .inDays;
    if (days < 1 || days > 31) {
      throw ArgumentError('Calendar range must contain 1–31 local dates.');
    }
    final localStart = DateTime(start.year, start.month, start.day);
    final localEnd = DateTime(
      endExclusive.year,
      endExclusive.month,
      endExclusive.day,
    );
    final predicates = <String>[];
    final variables = <Variable>[];
    for (var i = 0; i < days; i++) {
      final date = _date(start.addDays(i));
      predicates.add(
        '(o.current_scheduled_value = ? OR o.current_scheduled_value LIKE ?)',
      );
      variables.add(Variable<String>('date:$date'));
      variables.add(Variable<String>('local:${date}T%'));
    }
    predicates.add(
      '(o.current_scheduled_value >= ? AND o.current_scheduled_value < ?)',
    );
    variables.add(
      Variable<String>('instant:${localStart.toUtc().toIso8601String()}'),
    );
    variables.add(
      Variable<String>('instant:${localEnd.toUtc().toIso8601String()}'),
    );
    final rows = await database
        .customSelect(
          'SELECT o.*, c.commitment_id AS owner_id FROM occurrences o '
          'JOIN commitment_cycles c ON c.id = o.cycle_id '
          'WHERE ${predicates.join(' OR ')}',
          variables: variables,
          readsFrom: {database.occurrences, database.commitmentCycles},
        )
        .get();
    final result = <String, List<Occurrence>>{};
    for (final row in rows) {
      final occurrence = _occurrence(database.occurrences.map(row.data));
      result
          .putIfAbsent(row.read<String>('owner_id'), () => [])
          .add(occurrence);
    }
    return result;
  });

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

  static Map<String, Object?>? _financialJson(
    FinancialExpectationTemplate? t,
  ) => t == null
      ? null
      : {
          'direction': t.direction.index,
          'amount': t.amount,
          'currency': t.currency,
          'accountId': t.accountId?.value,
        };

  static FinancialExpectationTemplate? _parseFinancial(String? json) {
    if (json == null) return null;
    final m =
        (jsonDecode(json)
                as Map<String, dynamic>)['generationFinancialExpectation']
            as Map<String, dynamic>?;
    if (m == null) return null;
    return FinancialExpectationTemplate(
      direction: FinancialExpectationDirection.values[m['direction'] as int],
      amount: m['amount'] as int,
      currency: m['currency'] as String?,
      accountId: m['accountId'] == null
          ? null
          : StableId.parse(m['accountId'] as String),
    );
  }

  static String? _rule(
    RecurrenceRule? value,
    List<Duration> offsets,
    FinancialExpectationTemplate? financial,
  ) => value == null
      ? null
      : jsonEncode({
          'formatVersion': 2,
          'generationFinancialExpectation': _financialJson(financial),
          'legacyCalendarSemantics': value.legacyCalendarSemantics,
          'calendar': value.calendar.name,
          'monthOfYear': value.monthOfYear,
          'generationReminderMinutes': offsets.map((o) => o.inMinutes).toList(),
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
      monthOfYear: m['monthOfYear'] as int?,
      legacyCalendarSemantics:
          m['legacyCalendarSemantics'] == true || m['formatVersion'] == null,
      calendar: m['calendar'] == null
          ? RecurrenceCalendar.gregorian
          : RecurrenceCalendar.values.byName(m['calendar'] as String),
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
    generationFinancialExpectation: _parseFinancial(r.recurrenceRule),
    generationReminderOffsets: r.recurrenceRule == null
        ? const []
        : ((jsonDecode(r.recurrenceRule!)
                          as Map<String, dynamic>)['generationReminderMinutes']
                      as List? ??
                  const [])
              .map((m) => Duration(minutes: m as int))
              .toList(),
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
