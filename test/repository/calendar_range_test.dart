import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

void main() {
  test(
    'file-backed week range preserves starts/status/history after restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'planact-calendar-',
      );
      final file = File('${directory.path}/calendar.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      try {
        var plans = DriftCommitmentPlanRepository(database);
        final create = CreateCommitmentPlan(
          commitments: DriftCommitmentRepository(database),
          plans: plans,
        );
        final expected = <String>{};
        for (final date in [
          DateTime(2026, 9, 30, 23, 59),
          DateTime(2026, 10, 1),
          DateTime(2026, 10, 7, 23, 59),
          DateTime(2026, 10, 8),
          DateTime(2026, 10, 10),
        ]) {
          final plan = await create(title: 'بازه', startAt: date);
          if (date.day == 1 || date.day == 7) {
            expected.add(plan.occurrences.single.id.value);
          }
        }
        final allDay = await create(
          title: 'تمام‌روز',
          startAt: DateTime(2026, 10, 3),
        );
        final changed = allDay.occurrences.single
            .reschedule(LocalDate(2026, 10, 3))
            .withStatus(OccurrenceStatus.cancelled);
        await plans.saveOccurrence(changed);
        expected.add(changed.id.value);
        final instant = await create(
          title: 'لحظه',
          startAt: DateTime.utc(2026, 10, 4, 12),
        );
        final fixedSchedule = ScheduleDefinition.create(
          cycleId: instant.cycle.id,
          mode: ScheduleMode.oneOff,
          timeSemantics: TimeSemantics.fixedInstant,
          startDate: LocalDate(2026, 10, 4),
          fixedInstant: DateTime.utc(2026, 10, 4, 12),
        );
        final fixedOccurrences = const OccurrenceGenerator().generate(
          schedule: fixedSchedule,
          through: LocalDate(2026, 10, 7),
        );
        await plans.save(
          CommitmentPlan(
            commitment: instant.commitment,
            cycle: instant.cycle,
            schedule: fixedSchedule,
            occurrences: fixedOccurrences,
            reminders: const [],
          ),
        );
        // Saving is additive; the original floating occurrence is retained.
        expected.add(instant.occurrences.single.id.value);
        expected.add(fixedOccurrences.single.id.value);
        final before = await plans.loadWeek(LocalDate(2026, 10, 1));
        expect(
          before.values.expand((x) => x).map((x) => x.id.value).toSet(),
          expected,
        );
        expect(
          before[instant.commitment.id.value]!
              .where((item) => item.id == fixedOccurrences.single.id)
              .single
              .currentScheduledAt,
          DateTime.utc(2026, 10, 4, 12),
        );
        expect(
          before[allDay.commitment.id.value]!.single.currentScheduledAt,
          LocalDate(2026, 10, 3),
        );
        expect(
          before[allDay.commitment.id.value]!.single.status,
          OccurrenceStatus.cancelled,
        );
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        plans = DriftCommitmentPlanRepository(database);
        final after = await plans.loadWeek(LocalDate(2026, 10, 1));
        expect(
          after.values.expand((x) => x).map((x) => x.id.value).toSet(),
          expected,
        );
        expect(
          (await plans.findByCommitmentId(allDay.commitment.id))!
              .occurrences
              .single
              .originalScheduledAt,
          DateTime(2026, 10, 3),
        );
        expect(await plans.loadWeek(LocalDate(2040, 1, 1)), isEmpty);
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
