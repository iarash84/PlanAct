import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/notes/data/drift_calendar_note_repository.dart';
import 'package:planact/features/notes/domain/calendar_note.dart';
import 'package:planact/features/notes/presentation/calendar_note_editor.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/search/application/search_reader.dart';
import 'package:planact/features/search/domain/search.dart';
import 'package:planact/features/search/presentation/search_page.dart';

const queryKey = ValueKey('global-search-query');

Future<void> settleIo(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  await tester.pumpAndSettle();
}

Future<void> query(WidgetTester tester, String value) async {
  await tester.enterText(find.byKey(queryKey), value);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

class Reader implements SearchReader {
  Reader(this.load);
  final Future<List<SearchDocument>> Function() load;
  @override
  Future<List<SearchDocument>> read() => load();
}

SearchDocument doc(String title) {
  final commitment = Commitment.create(title: title);
  return SearchDocument(
    target: CommitmentSearchTarget(commitment),
    title: title,
    description: '',
    keywords: const [],
    sortDate: commitment.createdAt,
  );
}

Widget app(
  SearchReader reader, {
  Brightness brightness = Brightness.light,
  double scale = 1,
  Future<void> Function(Commitment)? onOpen,
}) => MaterialApp(
  locale: const Locale('fa'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: brightness == Brightness.light
      ? PlanActTheme.light()
      : PlanActTheme.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: SearchPage(
    reader: reader,
    onOpenCommitment: onOpen ?? (_) async {},
    onOpenNote: (_) async {},
  ),
);

void main() {
  testWidgets(
    'real shell → all record types → existing details/note edit → refreshed results and root',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final commitments = DriftCommitmentRepository(database);
      final commitment = Commitment.create(
        title: 'كلاس موسيقي',
        description: 'پاییز',
      ).archive();
      await commitments.save(commitment);
      final finance = DriftFinanceRepository(database);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'حساب موسیقی',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await finance.saveAccount(account);
      final entry = AccountEntry(
        id: StableId.generate(),
        accountId: account.id,
        type: AccountEntryType.income,
        amount: Money(minorUnits: 1234567, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 10, 14),
        note: 'واریزی موسیقی',
        category: 'آموزش',
      );
      await finance.saveEntry(entry);
      final note = CalendarNote(
        id: StableId.generate(),
        title: 'یادداشت موسیقی',
        description: 'متن کامل',
        date: LocalDate.fromDateTime(DateTime.now()),
        color: CommitmentColor.rose,
        revision: 1,
      );
      await DriftCalendarNoteRepository(database)
          .save(note, expectedRevision: 0);
      await tester.pumpWidget(PlanActApp(repository: commitments));
      await settleIo(tester);
      await tester.tap(find.byKey(const ValueKey('shell-search')));
      await settleIo(tester);
      expect(
        Directionality.of(tester.element(find.byType(SearchPage))),
        TextDirection.rtl,
      );
      await query(tester, 'موسیقی');
      expect(find.text('۴ نتیجه'), findsOneWidget);
      expect(find.textContaining('بایگانی‌شده'), findsOneWidget);

      await tester.tap(
        find.byKey(ValueKey('search-result-commitment-${commitment.id.value}')),
      );
      await settleIo(tester);
      expect(find.byType(CommitmentDetailsPage), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settleIo(tester);
      expect(
        tester.widget<TextField>(find.byKey(queryKey)).controller!.text,
        'موسیقی',
      );

      await tester.tap(find.byKey(const ValueKey('search-filter-transaction')));
      await tester.pumpAndSettle();
      expect(find.text('۱ نتیجه'), findsOneWidget);
      await tester.tap(
        find.byKey(ValueKey('search-result-transaction-${entry.id.value}')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('۱,۲۳۴,۵۶۷ ریال'), findsOneWidget);
      expect(find.textContaining('واریز'), findsWidgets);
      await tester.binding.handlePopRoute();
      await settleIo(tester);
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('search-filter-transaction')),
            )
            .selected,
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('search-filter-account')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('search-result-account-${account.id.value}')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('۱,۲۳۴,۵۶۷ ریال'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settleIo(tester);

      await tester.tap(find.byKey(const ValueKey('search-filter-note')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('search-result-note-${note.id.value}')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CalendarNoteEditor), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('calendar-note-title')),
        'پیش‌نویس ذخیره‌نشده',
      );
      await tester.binding.handlePopRoute();
      await settleIo(tester);
      expect(
        (await DriftCalendarNoteRepository(database).list()).single.revision,
        1,
      );
      expect(find.text('یادداشت موسیقی'), findsOneWidget);
      await tester.tap(
        find.byKey(ValueKey('search-result-note-${note.id.value}')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('calendar-note-title')),
        'یادداشت تازه',
      );
      await tester.tap(find.byKey(const ValueKey('calendar-note-save')));
      await settleIo(tester);
      expect(find.textContaining('موردی پیدا نشد'), findsOneWidget);
      await query(tester, 'تازه');
      expect(find.text('یادداشت تازه'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settleIo(tester);
      await tester.tap(find.text('تقویم').last);
      await settleIo(tester);
      expect(find.text('یادداشت تازه'), findsWidgets);
      // Entry point remains available from Calendar, Finance and More.
      for (final tab in ['مالی', 'بیشتر']) {
        await tester.tap(find.text(tab).last);
        await settleIo(tester);
        await tester.tap(find.byKey(const ValueKey('shell-search')));
        await settleIo(tester);
        expect(find.byType(SearchPage), findsOneWidget);
        await tester.binding.handlePopRoute();
        await settleIo(tester);
      }
      final saved = (await DriftCalendarNoteRepository(database).list()).single;
      expect(saved.revision, 2);
      expect((await finance.listEntries()).single.amount.minorUnits, 1234567);
      expect(await database.select(database.occurrences).get(), isEmpty);
      expect(await database.select(database.reminderRules).get(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failure/retry, empty, clear and opening failure have Persian recovery',
    (tester) async {
      var fail = true;
      final reader = Reader(() async {
        if (fail) throw StateError('read failure');
        return [doc('کلاس زبان')];
      });
      await tester.pumpWidget(
        app(reader, onOpen: (_) async => throw StateError('open failed')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('خواندن اطلاعات'), findsOneWidget);
      expect(find.textContaining('موردی پیدا نشد'), findsNothing);
      fail = false;
      await tester.tap(find.text('تلاش دوباره'));
      await tester.pumpAndSettle();
      await query(tester, 'ورزش');
      expect(find.textContaining('موردی پیدا نشد'), findsOneWidget);
      await query(tester, 'زبان');
      await tester.tap(find.text('کلاس زبان'));
      await tester.pumpAndSettle();
      expect(find.textContaining('بازکردن مورد'), findsOneWidget);
      await tester.tap(find.text('تلاش دوباره'));
      await tester.pumpAndSettle();
      expect(find.textContaining('بازکردن مورد'), findsNothing);
      await tester.tap(find.byTooltip('پاک‌کردن عبارت جست‌وجو'));
      await tester.pumpAndSettle();
      expect(find.text('کلاس زبان'), findsNothing);
      expect(find.textContaining('برای جست‌وجو در'), findsOneWidget);
    },
  );

  testWidgets(
    'latest query wins while loading and superseded snapshot is ignored',
    (tester) async {
      final first = Completer<List<SearchDocument>>();
      final second = Completer<List<SearchDocument>>();
      var calls = 0;
      await tester.pumpWidget(
        app(Reader(() => ++calls == 1 ? first.future : second.future)),
      );
      await tester.pump();
      await tester.enterText(find.byKey(queryKey), 'زبان');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byTooltip('تازه‌سازی نتایج'));
      await tester.pump();
      second.complete([doc('زبان جدید'), doc('موسیقی جدید')]);
      await tester.pumpAndSettle();
      expect(find.text('زبان جدید'), findsOneWidget);
      first.complete([doc('زبان قدیمی')]);
      await tester.pumpAndSettle();
      expect(find.text('زبان قدیمی'), findsNothing);
      expect(find.text('زبان جدید'), findsOneWidget);
    },
  );

  testWidgets(
    'reloading after result selection preserves scroll, query and filter',
    (tester) async {
      final documents = List.generate(80, (i) => doc('زبان $i'));
      final last = searchDocuments(documents, 'زبان').last;
      var reads = 0;
      await tester.pumpWidget(
        app(
          Reader(() async {
            reads++;
            return documents;
          }),
        ),
      );
      await tester.pumpAndSettle();
      await query(tester, 'زبان');
      await tester.tap(find.byKey(const ValueKey('search-filter-commitment')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(last.title),
        400,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 80,
      );
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).last)
          .position;
      final before = position.pixels;
      expect(before, greaterThan(0));
      await tester.tap(find.text(last.title));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(position.pixels, before);
      expect(
        tester.widget<TextField>(find.byKey(queryKey)).controller!.text,
        'زبان',
      );
      // Bring filters back into view without losing their selected state.
      position.jumpTo(0);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('search-filter-commitment')),
            )
            .selected,
        isTrue,
      );
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('narrow RTL large text filters/results scroll in $brightness', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        app(
          Reader(
            () async => [
              doc(
                'عنوان طولانی کلاس زبان برای آزمون چیدمان و خوانایی متن فارسی',
              ),
              ...List.generate(100, (i) => doc('زبان $i')),
            ],
          ),
          brightness: brightness,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      await query(tester, 'زبان');
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text(
          'عنوان طولانی کلاس زبان برای آزمون چیدمان و خوانایی متن فارسی',
        ),
        300,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 100,
      );
      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(tester.element(find.byType(SearchPage))),
        TextDirection.rtl,
      );
    });
  }
}
