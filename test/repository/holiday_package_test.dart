import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:planact/features/calendar/data/sqlite_holiday_package_store.dart';
import 'package:planact/features/calendar/domain/holiday_data_package.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../fixtures/holiday_package_fixture.dart';

class Files implements HolidayPackageFileSource {
  String? value;
  @override
  Future<String?> pick() async => value;
}

void main() {
  late Directory directory;
  late File file;
  late Files files;
  late HolidayPackageService service;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('holiday-package-test-');
    file = File('${directory.path}/holidays.sqlite');
    files = Files();
    service = HolidayPackageService(SqliteHolidayPackageStore(file), files);
    await service.load();
  });
  tearDown(() async => directory.delete(recursive: true));

  test(
    'new unbundled year and explicit revision correction survive cold reopen',
    () async {
      expect(service.provider.hasCompleteOfficialCoverage(1407), isFalse);
      files.value = await holidayFixture(year: 1407);
      final prepared = (await service.prepare())!;
      expect(service.provider.hasCompleteOfficialCoverage(1407), isFalse);
      await service.install(prepared, publisherApproved: true);
      final corrected = await HolidayDataPackage.verify(
        await holidayFixture(
          year: 1407,
          revision: 2,
          mutate: (data) {
            ((data['holidays'] as List).first as Map)['title'] =
                'دلیل اصلاح‌شده';
          },
        ),
      );
      // Preparing a correction is read-only; only installation admits it.
      files.value = corrected.encoded;
      await service.prepare();
      expect(service.packages.single.revision, 1);
      await service.install(corrected, publisherApproved: false);
      service = HolidayPackageService(SqliteHolidayPackageStore(file), Files());
      await service.load();
      expect(service.provider.hasCompleteOfficialCoverage(1407), isTrue);
      expect(service.provider.hasCompleteOfficialCoverage(1408), isFalse);
      expect(service.calendars.last, (
        year: 1407,
        revision: 2,
        source: 'https://example.test/calendar',
        imported: true,
      ));
      expect(
        service.provider
            .holidaysFor(const JalaliDate(1407, 1, 1))
            .any((h) => h.title == 'دلیل اصلاح‌شده'),
        isTrue,
      );
      await expectLater(
        service.install(prepared, publisherApproved: false),
        throwsA(isA<HolidayPackageException>()),
      );
      expect(service.packages.single.revision, 2);
    },
  );

  test(
    'first trust requires approval; durable reload retains overlapping reasons',
    () async {
      final package = await HolidayDataPackage.verify(await holidayFixture());
      await expectLater(
        service.install(package, publisherApproved: false),
        throwsA(isA<HolidayPackageException>()),
      );
      expect(service.packages, isEmpty);
      await service.install(package, publisherApproved: true);
      final restarted = HolidayPackageService(
        SqliteHolidayPackageStore(file),
        Files(),
      );
      await restarted.load();
      expect(restarted.provider.hasCompleteOfficialCoverage(1406), isTrue);
      expect(
        restarted.provider
            .holidaysFor(JalaliDate(1406, 1, 1))
            .where((h) => h.kind != CalendarHolidayKind.weekend)
            .length,
        2,
      );
      expect(restarted.packages.single.fingerprint, package.fingerprint);
      final db = sqlite3.open(file.path);
      expect(db.select('PRAGMA user_version').single.values.first, 1);
      db.close();
    },
  );

  test('rejects tampering, incomplete coverage and invalid markers', () async {
    final valid = jsonDecode(await holidayFixture()) as Map<String, dynamic>;
    valid['payload'] = base64Encode(utf8.encode('{}'));
    await expectLater(
      HolidayDataPackage.verify(jsonEncode(valid)),
      throwsA(isA<HolidayPackageException>()),
    );
    for (final mutate in <void Function(Map<String, Object>)>[
      (d) => (d['months'] as List).removeLast(),
      (d) => ((d['months'] as List).first as Map)['officialDays'] = [2],
      (d) => ((d['holidays'] as List).first as Map)['day'] = 32,
      (d) => ((d['holidays'] as List).first as Map)['kind'] = 'special',
      (d) => (d['holidays'] as List).add((d['holidays'] as List).first),
    ]) {
      await expectLater(
        HolidayDataPackage.verify(await holidayFixture(mutate: mutate)),
        throwsA(isA<HolidayPackageException>()),
      );
    }
    expect(service.packages, isEmpty);
  });

  test(
    'revision upgrade succeeds; wrong publisher and rollback preserve bytes',
    () async {
      final first = await HolidayDataPackage.verify(await holidayFixture());
      await service.install(first, publisherApproved: true);
      final before = await file.readAsBytes();
      for (final incoming in [
        first,
        await HolidayDataPackage.verify(
          await holidayFixture(publisher: 2, revision: 2),
        ),
      ]) {
        await expectLater(
          service.install(incoming, publisherApproved: true),
          throwsA(isA<HolidayPackageException>()),
        );
        expect(await file.readAsBytes(), before);
      }
      await service.install(
        await HolidayDataPackage.verify(await holidayFixture(revision: 2)),
        publisherApproved: false,
      );
      expect(service.packages.single.revision, 2);
    },
  );

  test(
    'transaction write failure preserves old year and service state',
    () async {
      await service.install(
        await HolidayDataPackage.verify(await holidayFixture()),
        publisherApproved: true,
      );
      final db = sqlite3.open(file.path);
      db.execute(
        "CREATE TRIGGER fail_update BEFORE UPDATE ON holiday_packages BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      db.close();
      await expectLater(
        service.install(
          await HolidayDataPackage.verify(await holidayFixture(revision: 2)),
          publisherApproved: false,
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(service.packages.single.revision, 1);
      await service.load();
      expect(service.packages.single.revision, 1);
    },
  );

  test(
    'second store cannot replace a trusted publisher or downgrade',
    () async {
      await service.install(
        await HolidayDataPackage.verify(await holidayFixture(revision: 2)),
        publisherApproved: true,
      );
      final other = SqliteHolidayPackageStore(file);
      await expectLater(
        other.save(await HolidayDataPackage.verify(await holidayFixture())),
        throwsA(isA<HolidayPackageException>()),
      );
      await expectLater(
        other.save(
          await HolidayDataPackage.verify(
            await holidayFixture(revision: 3, publisher: 2),
          ),
        ),
        throwsA(isA<HolidayPackageException>()),
      );
      await service.load();
      expect(service.packages.single.revision, 2);
    },
  );

  test(
    'picker cancellation has no effect; corrupt storage is never overwritten',
    () async {
      expect(await service.prepare(), isNull);
      await service.install(
        await HolidayDataPackage.verify(await holidayFixture()),
        publisherApproved: true,
      );
      final db = sqlite3.open(file.path);
      db.execute("UPDATE holiday_packages SET envelope='corrupted'");
      db.close();
      final before = await file.readAsBytes();
      await expectLater(
        service.load(),
        throwsA(isA<HolidayPackageException>()),
      );
      await expectLater(
        service.install(
          await HolidayDataPackage.verify(await holidayFixture(revision: 2)),
          publisherApproved: false,
        ),
        throwsA(isA<HolidayPackageException>()),
      );
      expect(await file.readAsBytes(), before);
      expect(service.packages.single.revision, 1);
    },
  );
}
