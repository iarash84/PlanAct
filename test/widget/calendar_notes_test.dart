import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/commitment_identity_palette.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment_color.dart';
import 'package:planact/features/notes/application/calendar_note_repository.dart';
import 'package:planact/features/notes/data/drift_calendar_note_repository.dart';
import 'package:planact/features/notes/domain/calendar_note.dart';
import 'package:planact/features/notes/presentation/calendar_note_editor.dart';
import 'package:planact/features/notes/presentation/calendar_note_tile.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

Future<void> settleIo(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'production global Add → note → month → week → edit refreshes without side effects',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await tester.pumpWidget(
        PlanActApp(repository: DriftCommitmentRepository(database)),
      );
      await settleIo(tester);
      await tester.tap(find.byKey(const ValueKey('shell-quick-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quick-add-note')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-note-save')));
      await tester.pumpAndSettle();
      expect(find.text('عنوان یادداشت را وارد کنید.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('calendar-note-title')),
        'خاطرهٔ امروز',
      );
      await tester.enterText(
        find.byKey(const ValueKey('calendar-note-description')),
        'یک روز خوب',
      );
      await tester.tap(find.byKey(const ValueKey('calendar-note-save')));
      await tester.pumpAndSettle();
      expect(find.text('تاریخ یادداشت را انتخاب کنید.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('calendar-note-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید تاریخ'));
      await tester.pumpAndSettle();
      final rose = find.byKey(const ValueKey('commitment-color-rose'));
      await tester.ensureVisible(rose);
      await tester.tap(rose);
      await tester.tap(find.byKey(const ValueKey('calendar-note-save')));
      await settleIo(tester);
      expect(find.byType(CalendarNoteEditor), findsNothing);
      final day = LocalDate.fromDateTime(DateTime.now());
      final repository = DriftCalendarNoteRepository(database);
      final notes = await repository.loadRange(day, day.addDays(1));
      expect(notes, hasLength(1));
      expect(notes.single.color, CommitmentColor.rose);
      await tester.tap(find.text('تقویم').last);
      await settleIo(tester);
      expect(
        find.byKey(
          ValueKey(
            'month-title-${JalaliDate.now().day}-${notes.single.id.value}',
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('هفته'));
      await settleIo(tester);
      final tile = find.byType(CalendarNoteTile);
      expect(tile, findsOneWidget);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('calendar-note-title')),
        'خاطرهٔ ویرایش‌شده',
      );
      await tester.tap(find.byKey(const ValueKey('calendar-note-save')));
      await settleIo(tester);
      expect(find.text('خاطرهٔ ویرایش‌شده'), findsOneWidget);
      expect(
        (await repository.loadRange(day, day.addDays(1))).single.revision,
        2,
      );
      for (final rows in [
        await database.select(database.commitments).get(),
        await database.select(database.occurrences).get(),
        await database.select(database.reminderRules).get(),
        await database.select(database.reminderInstances).get(),
        await database.select(database.accountEntries).get(),
        await database.select(database.entitlementLedgerEntries).get(),
      ]) {
        expect(rows, isEmpty);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 1100.0]) {
      testWidgets(
        'note color/title survive month and week $brightness width $width / large text',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 1200));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final repository = InMemoryCalendarNoteRepository();
          const jalali = JalaliDate(1405, 1, 1);
          final note = CalendarNote(
            id: StableId.generate(),
            title: 'یادداشت با عنوان کامل و بلند',
            description: 'توضیحات چندخطی برای نمایش روی تقویم',
            date: LocalDate.fromDateTime(jalali.toDateTime()),
            color: CommitmentColor.violet,
            revision: 1,
          );
          await repository.save(note, expectedRevision: 0);
          CalendarNote? opened;
          await tester.pumpWidget(
            MaterialApp(
              theme: brightness == Brightness.light
                  ? PlanActTheme.light()
                  : PlanActTheme.dark(),
              home: MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(width == 320 ? 2 : 1),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Scaffold(
                    body: CalendarPage(
                      commitments: const [],
                      scheduledDates: const {},
                      initialDate: jalali,
                      noteLoader: repository.loadRange,
                      onNoteTap: (value) => opened = value,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final marker = tester.widget<Container>(
            find.byKey(ValueKey('month-title-1-${note.id.value}')),
          );
          expect(
            (marker.decoration as BoxDecoration).color,
            CommitmentIdentityPalette.background(note.color, brightness),
          );
          final semantics = tester.widget<Semantics>(
            find.byKey(const ValueKey('calendar-day-1')),
          );
          expect(semantics.properties.label, contains('۱ یادداشت'));
          expect(semantics.properties.label, contains(note.title));
          await tester.tap(find.text('هفته'));
          await tester.pumpAndSettle();
          expect(find.byType(CalendarNoteTile), findsOneWidget);
          await tester.ensureVisible(find.byType(CalendarNoteTile));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(CalendarNoteTile));
          expect(opened, note);
          expect(find.text(note.title), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets(
    'calendar rejects stale month results and retries failed note reads in both modes',
    (tester) async {
      const initial = JalaliDate(1405, 1, 1);
      final old = Completer<List<CalendarNote>>();
      var calls = 0;
      var fail = false;
      final current = CalendarNote(
        id: StableId.generate(),
        title: 'ماه تازه',
        description: '',
        date: LocalDate.fromDateTime(initial.addMonths(1).toDateTime()),
        color: CommitmentColor.rose,
        revision: 1,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: CalendarPage(
                commitments: const [],
                scheduledDates: const {},
                initialDate: initial,
                noteLoader: (start, end) async {
                  if (++calls == 1) return old.future;
                  if (fail) throw StateError('injected read failure');
                  return [current];
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('ماه بعد'));
      await tester.pumpAndSettle();
      final marker = find.byKey(ValueKey('month-title-1-${current.id.value}'));
      expect(marker, findsOneWidget);
      old.complete([]);
      await tester.pumpAndSettle();
      expect(marker, findsOneWidget);
      fail = true;
      await tester.tap(find.byTooltip('ماه بعد'));
      await tester.pumpAndSettle();
      expect(find.text('بارگذاری رخدادهای ماه انجام نشد.'), findsOneWidget);
      expect(find.byType(CalendarNoteTile), findsNothing);
      fail = false;
      await tester.tap(find.text('تلاش دوباره'));
      await tester.pumpAndSettle();
      expect(find.text('بارگذاری رخدادهای ماه انجام نشد.'), findsNothing);
      fail = true;
      await tester.tap(find.text('هفته'));
      await tester.pumpAndSettle();
      expect(find.text('بارگذاری هفته انجام نشد.'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('تلاش دوباره'));
      await tester.pumpAndSettle();
      expect(find.text('بارگذاری هفته انجام نشد.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancel writes nothing; failed save preserves input; pending blocks duplicate and edits',
    (tester) async {
      final repository = ControlledNotes();
      final existing = CalendarNote(
        id: StableId.generate(),
        title: 'متن قبلی',
        description: '',
        date: LocalDate(2026, 10, 14),
        color: CommitmentColor.teal,
        revision: 1,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => CalendarNoteEditor.show(
                  context,
                  repository,
                  note: existing,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(repository.calls, 0);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('calendar-note-title')),
        'متن تازه',
      );
      await tester.tap(find.byKey(const ValueKey('calendar-note-save')));
      await tester.pump();
      expect(repository.calls, 1);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('calendar-note-title')),
            )
            .enabled,
        false,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('calendar-note-save')),
            )
            .onPressed,
        isNull,
      );
      repository.pending.completeError(StateError('injected'));
      await tester.pumpAndSettle();
      expect(find.text('یادداشت ذخیره نشد. دوباره تلاش کنید.'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('calendar-note-title')),
            )
            .controller!
            .text,
        'متن تازه',
      );
      repository.pending = Completer<void>();
      await tester.tap(find.byKey(const ValueKey('calendar-note-save')));
      await tester.pump();
      expect(repository.calls, 2);
      repository.pending.completeError(const StaleCalendarNote());
      await tester.pumpAndSettle();
      expect(
        find.text(
          'این یادداشت تغییر کرده است. فرم را ببندید و دوباره باز کنید.',
        ),
        findsOneWidget,
      );
    },
  );
}

class ControlledNotes implements CalendarNoteRepository {
  int calls = 0;
  Completer<void> pending = Completer<void>();
  @override
  Future<List<CalendarNote>> loadRange(
    LocalDate start,
    LocalDate endExclusive,
  ) async => [];
  @override
  Future<void> save(CalendarNote note, {required int expectedRevision}) {
    calls++;
    return pending.future;
  }
}
