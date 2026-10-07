import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:planact/features/calendar/data/sqlite_holiday_package_store.dart';
import 'package:planact/features/calendar/domain/holiday_data_package.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';

import '../fixtures/holiday_package_fixture.dart';

class NoFile implements HolidayPackageFileSource {
  @override
  Future<String?> pick() async => null;
}

void main() {
  testWidgets(
    'live calendar refresh and disk restart use installed official reasons',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late Directory directory;
      late HolidayPackageService service;
      await tester.runAsync(() async {
        directory = await Directory.systemTemp.createTemp('holiday-calendar-');
        service = HolidayPackageService(
          SqliteHolidayPackageStore(File('${directory.path}/packages.sqlite')),
          NoFile(),
        );
        await service.load();
      });
      addTearDown(() => directory.delete(recursive: true));
      Future<void> show() => tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: CalendarPage(
                initialDate: const JalaliDate(1406, 1, 1),
                holidayProvider: service.provider,
                commitments: const [],
                scheduledDates: const {},
              ),
            ),
          ),
        ),
      );
      await show();
      expect(
        find.textContaining('دادهٔ تعطیلات رسمی این سال کامل نیست'),
        findsOneWidget,
      );
      await tester.runAsync(() async {
        await service.install(
          await HolidayDataPackage.verify(await holidayFixture()),
          publisherApproved: true,
        );
      });
      await show();
      expect(find.text('تعطیل رسمی: تعطیلی آزمایشی'), findsOneWidget);
      expect(find.text('تعطیل رسمی: دلیل هم‌زمان آزمایشی'), findsOneWidget);
      expect(
        find.textContaining('دادهٔ تعطیلات رسمی این سال کامل نیست'),
        findsNothing,
      );
      await tester.runAsync(() async {
        service = HolidayPackageService(
          SqliteHolidayPackageStore(File('${directory.path}/packages.sqlite')),
          NoFile(),
        );
        await service.load();
      });
      await show();
      expect(find.text('تعطیل رسمی: تعطیلی آزمایشی'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
