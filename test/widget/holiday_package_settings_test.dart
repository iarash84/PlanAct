import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:planact/features/calendar/domain/holiday_data_package.dart';
import 'package:planact/features/calendar/presentation/holiday_package_settings_card.dart';

import '../fixtures/holiday_package_fixture.dart';

class Store implements HolidayPackageStore {
  final values = <String>[];
  @override
  Future<List<String>> load() async => values;
  @override
  Future<void> save(HolidayDataPackage package) async =>
      values.add(package.encoded);
}

class Source implements HolidayPackageFileSource {
  String? value;
  @override
  Future<String?> pick() async => value;
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'explicit approval, cancellation and failure in ${dark ? 'dark' : 'light'} RTL',
      (tester) async {
        final store = Store();
        final source = Source()..value = await holidayFixture();
        final service = HolidayPackageService(store, source);
        var refreshes = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: ListView(
                  children: [
                    HolidayPackageSettingsCard(
                      service: service,
                      onInstalled: () => refreshes++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          await tester.tap(find.text('ورود بسته از فایل'));
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
        expect(find.text('تأیید ناشر و ورود بسته'), findsOneWidget);
        expect(store.values, isEmpty);
        await tester.tap(find.text('انصراف'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
        expect(store.values, isEmpty);
        await tester.runAsync(() async {
          await tester.tap(find.text('ورود بسته از فایل'));
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
        await tester.tap(find.text('تأیید ناشر و ورود بسته'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
        expect(store.values.length, 1);
        expect(refreshes, 1);
        expect(find.textContaining('بدون اینترنت در دسترس'), findsOneWidget);
        source.value = '{}';
        await tester.runAsync(() async {
          await tester.tap(find.text('ورود بسته از فایل'));
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
        expect(find.textContaining('بسته معتبر نیست'), findsOneWidget);
        expect(store.values.length, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
