import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:planact/features/calendar/data/sqlite_holiday_package_store.dart';
import 'package:planact/features/calendar/domain/holiday_data_package.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';

import '../fixtures/holiday_package_fixture.dart';

class _NoFiles implements HolidayPackageFileSource {
  @override
  Future<String?> pick() async => null;
}

Future<HolidayDataPackage> _package(
  int year,
) async => HolidayDataPackage.verify(
  // The former local test required absent release files and an unavailable
  // publisher key. Exercise the real shared payload with a test-only signer;
  // this is NOT verification of a delivered production signing identity.
  await signHolidayPayload(
    await File('third_party/iranian_holidays/reviewed/iran-$year-r1.json')
        .readAsString(),
  ),
);

void main() {
  for (final year in [1405, 1406]) {
    test(
      '$year shared payload signature and all published dates/reasons',
      () async {
        final package = await _package(year);
        expect(package.year, year);
        expect(package.revision, 1);
        expect(
          package.publisherKey,
          (await HolidayDataPackage.verify(await holidayFixture()))
              .publisherKey,
        );
        final annual = jsonDecode(
          await File('third_party/iranian_holidays/time_ir_$year.json')
              .readAsString(),
        ) as Map<String, dynamic>;
        final provider = IranianHolidayProvider(
          annualOverrides: {year: package.holidays},
        );
        expect(package.holidays.length, year == 1405 ? 30 : 28);
        var days = 0;
        for (var month = 1; month <= 12; month++) {
          final published = (annual['months'] as List)[month - 1] as Map;
          for (
            var day = 1;
            day <= JalaliDate(year, month, 1).monthLength;
            day++
          ) {
            days++;
            final date = JalaliDate(year, month, day);
            final delivered = provider.holidaysFor(date);
            final official = delivered
                .where((h) => h.kind != CalendarHolidayKind.weekend)
                .toList();
            expect(
              official.isNotEmpty,
              (published['official_days'] as List).contains(day),
              reason: '$date published marker',
            );
            // Existing bundled data was reviewed independently against the source.
            final bundled = const IranianHolidayProvider()
                .holidaysFor(date)
                .where((h) => h.kind != CalendarHolidayKind.weekend)
                .map((h) => '${h.kind.name}/${h.title}')
                .toList();
            expect(
              official.map((h) => '${h.kind.name}/${h.title}'),
              unorderedEquals(bundled),
              reason: '$date exact reasons, including overlaps',
            );
            expect(
              delivered.any((h) => h.kind == CalendarHolidayKind.weekend),
              date.weekDay == 7,
            );
          }
        }
        expect(days, 365);
        final envelope = jsonDecode(package.encoded) as Map<String, dynamic>;
        envelope['payload'] = base64Encode(utf8.encode('{}'));
        await expectLater(
          HolidayDataPackage.verify(jsonEncode(envelope)),
          throwsA(isA<HolidayPackageException>()),
        );
      },
    );
  }

  for (final order in <List<int>>[
    [1405],
    [1406],
    [1405, 1406],
    [1406, 1405],
  ]) {
    test('independent installation and cold reopen: $order', () async {
      final directory = await Directory.systemTemp.createTemp(
        'delivered-holidays-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/holidays.sqlite');
      HolidayPackageService create() =>
          HolidayPackageService(SqliteHolidayPackageStore(file), _NoFiles());
      var service = create();
      await service.load();
      expect(await service.prepare(), isNull);
      expect(service.packages, isEmpty);
      for (final year in order) {
        final package = await _package(year);
        if (service.packages.isEmpty) {
          await expectLater(
            service.install(package, publisherApproved: false),
            throwsA(isA<HolidayPackageException>()),
          );
          expect(service.packages, isEmpty);
        }
        final first = service.needsPublisherApproval(package);
        await service.install(package, publisherApproved: first);
        service = create();
        await service.load();
        expect(service.packages.any((p) => p.year == year), isTrue);
        final bytes = await file.readAsBytes();
        await expectLater(
          service.install(package, publisherApproved: true),
          throwsA(isA<HolidayPackageException>()),
        );
        expect(await file.readAsBytes(), bytes);
      }
      expect(service.packages.map((p) => p.year), unorderedEquals(order));
      for (final year in order) {
        expect(service.provider.hasCompleteOfficialCoverage(year), isTrue);
      }
      for (var year = 1407; year <= 1415; year++) {
        expect(service.provider.hasCompleteOfficialCoverage(year), isFalse);
        expect(
          File('holiday-packages/iran-$year-r1.planact-holidays.json')
              .existsSync(),
          isFalse,
        );
      }
    });
  }
}
