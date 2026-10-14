import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:planact/features/calendar/data/sqlite_holiday_package_store.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';

import '../fixtures/holiday_package_fixture.dart';

class _Source implements HolidayPackageFileSource {
  String? encoded;
  @override
  Future<String?> pick() async => encoded;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'More imports an unbundled year through Calendar and picker, ${brightness.name}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1100);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearPlatformBrightnessTestValue();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        final now = JalaliDate.now();
        final year = now.year < 1407 ? 1407 : now.year + 1;
        final source = _Source();
        late Directory directory;
        late HolidayPackageService service;
        await tester.runAsync(() async {
          directory = await Directory.systemTemp.createTemp('holiday-journey-');
          source.encoded = await holidayFixture(year: year);
          service = HolidayPackageService(
            SqliteHolidayPackageStore(
              File('${directory.path}/holidays.sqlite'),
            ),
            source,
          );
          await service.load();
        });
        addTearDown(() => directory.delete(recursive: true));
        final commitments = InMemoryCommitmentRepository();
        await tester.pumpWidget(
          PlanActApp(repository: commitments, holidayPackages: service),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(NavigationDestination).last);
        await tester.pumpAndSettle();
        final import = find.text('ورود بسته از فایل');
        await tester.scrollUntilVisible(
          import,
          250,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        Future<void> tapAsync(Finder finder) async {
          await tester.runAsync(() async {
            await tester.tap(finder);
            await Future<void>.delayed(const Duration(milliseconds: 350));
          });
          // Import stays busy while the confirmation dialog is open.
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)),
          );
          await tester.pump();
        }

        await tapAsync(import);
        expect(find.text('تأیید ناشر و ورود بسته'), findsOneWidget);
        expect(service.packages, isEmpty);
        await tester.ensureVisible(find.text('انصراف'));
        await tapAsync(find.text('انصراف'));
        await tester.pumpAndSettle();
        expect(service.provider.hasCompleteOfficialCoverage(year), isFalse);
        await tester.ensureVisible(import);
        await tapAsync(import);
        await tester.ensureVisible(find.text('تأیید ناشر و ورود بسته'));
        await tapAsync(find.text('تأیید ناشر و ورود بسته'));
        expect(service.provider.hasCompleteOfficialCoverage(year), isTrue);
        await tester.ensureVisible(find.text('سال‌ها و منابع تعطیلات'));
        await tester.tap(find.text('سال‌ها و منابع تعطیلات'));
        await tester.pumpAndSettle();
        expect(find.textContaining('بستهٔ واردشده'), findsOneWidget);
        expect(find.textContaining('دادهٔ پایه تا سال'), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byType(NavigationDestination).at(1));
        await tester.pumpAndSettle();
        final months = (year - now.year) * 12 + 1 - now.month;
        for (var index = 0; index < months; index++) {
          await tester.tap(find.byTooltip('ماه بعد'));
          await tester.pumpAndSettle();
        }
        final firstDay = find.byKey(const ValueKey('calendar-day-1'));
        await tester.ensureVisible(firstDay);
        await tester.tap(firstDay);
        await tester.pumpAndSettle();
        final reason = find.text('تعطیل رسمی: تعطیلی آزمایشی');
        final calendarList = find
            .descendant(
              of: find.byType(CalendarPage),
              matching: find.byType(ListView),
            )
            .first;
        await tester.scrollUntilVisible(
          reason,
          250,
          scrollable: find
              .descendant(of: calendarList, matching: find.byType(Scrollable))
              .first,
        );
        expect(reason, findsOneWidget);
        expect(
          find.textContaining('دادهٔ تعطیلات رسمی این سال کامل نیست'),
          findsNothing,
        );
        await tester.tap(find.text('هفته'));
        await tester.pumpAndSettle();
        final pick = find.byKey(const ValueKey('calendar-pick-date'));
        await tester.ensureVisible(pick);
        await tester.tap(pick);
        await tester.pumpAndSettle();
        expect(find.byType(PlanActJalaliDatePicker), findsOneWidget);
        expect(find.textContaining('تعطیلی آزمایشی'), findsWidgets);
        expect(
          find.textContaining('پوشش تعطیلات رسمی این سال کامل نیست'),
          findsNothing,
        );
        await tester.ensureVisible(find.text('انصراف'));
        await tester.tap(find.text('انصراف'));
        await tester.pumpAndSettle();
        expect(await commitments.list(), isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          final restarted = HolidayPackageService(
            SqliteHolidayPackageStore(
              File('${directory.path}/holidays.sqlite'),
            ),
            _Source(),
          );
          await restarted.load();
          expect(restarted.calendars.last.year, year);
          expect(restarted.provider.hasCompleteOfficialCoverage(year), isTrue);
        });
      },
    );
  }
}
