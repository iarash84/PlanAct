import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart'
    hide Commitment, Occurrence;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/calendar/presentation/planned_occurrence_widgets.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/application/planned_occurrences.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

// Acceptance: failed reads retry visibly; rejected admission writes nothing;
// platform failure after durable admission does not masquerade as write failure.
void main() {
  testWidgets('Details retry, stale admission and committed delivery failure', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = _FailingPlans(db);
    late CommitmentPlan plan;
    await tester.runAsync(() async {
      plan =
          await CreateCommitmentPlan(
            commitments: DriftCommitmentRepository(db),
            plans: repository,
          ).call(
            title: 'برنامه بلندمدت',
            kind: CommitmentKind.recurring,
            startAt: DateTime.now(),
            frequency: RecurrenceFrequency.monthly,
            occurrenceCount: 60,
          );
    });
    addTearDown(() async => tester.runAsync(db.close));
    var refreshed = 0;
    repository.failRead = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: PlanActTheme.light(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              child: PlannedDetailsRange(
                commitment: plan.commitment,
                repository: repository,
                builder: (_, occurrences) => Column(
                  children: [
                    for (final occurrence in occurrences)
                      Text('recorded:${occurrence.id.value}'),
                  ],
                ),
                onSaved: () async => refreshed++,
                synchronizeReminders: () async => throw StateError('delivery'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await _drain(tester);
    expect(find.text('بارگذاری نوبت‌ها انجام نشد.'), findsOneWidget);
    await tester.tap(find.text('تلاش دوباره'));
    await _drain(tester);
    expect(find.text('تعداد کل برنامه: ۶۰ نوبت'), findsOneWidget);
    for (var i = 0; i < 24; i++) {
      await tester.tap(find.byTooltip('ماه بعد نوبت‌ها'));
      await _drain(tester);
    }
    expect(find.byType(PlannedSlotTile), findsOneWidget);
    late int before;
    await tester.runAsync(() async {
      before = (await db.select(db.occurrences).get()).length;
    });
    repository.rejectAdmission = true;
    await tester.tap(find.byTooltip('ثبت نوبت'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأیید و ثبت نوبت'));
    await _drain(tester);
    expect(find.textContaining('ثبت نوبت انجام نشد'), findsOneWidget);
    expect(find.byType(PlannedSlotTile), findsOneWidget);
    expect(refreshed, 0);
    await tester.runAsync(() async {
      expect((await db.select(db.occurrences).get()).length, before);
    });
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    repository.rejectAdmission = false;
    await tester.tap(find.byTooltip('ثبت نوبت'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأیید و ثبت نوبت'));
    await _drain(tester);
    expect(
      find.text('نوبت ثبت شد؛ هماهنگ‌سازی یادآوری در انتظار است.'),
      findsOneWidget,
    );
    expect(refreshed, 1);
    expect(find.byType(PlannedSlotTile), findsNothing);
    expect(find.textContaining('recorded:'), findsOneWidget);
    await tester.runAsync(() async {
      expect((await db.select(db.occurrences).get()).length, before + 1);
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _FailingPlans extends DriftCommitmentPlanRepository {
  _FailingPlans(super.db);
  bool failRead = false;
  bool rejectAdmission = false;

  @override
  Future<PlannedOccurrenceRange> loadPlannedRange(
    LocalDate start,
    LocalDate endExclusive,
    LocalDate today, {
    StableId? commitmentId,
  }) {
    if (failRead) {
      failRead = false;
      return Future.error(StateError('read'));
    }
    return super.loadPlannedRange(
      start,
      endExclusive,
      today,
      commitmentId: commitmentId,
    );
  }

  @override
  Future<Occurrence> preparePlannedOccurrence(
    PlannedOccurrenceSlot slot,
    LocalDate today,
  ) {
    if (rejectAdmission) return Future.error(StateError('stale'));
    return super.preparePlannedOccurrence(slot, today);
  }
}

Future<void> _drain(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}
