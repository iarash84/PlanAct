import 'dart:io';

import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:planact/features/calendar/domain/holiday_data_package.dart';
import 'package:sqlite3/sqlite3.dart';

/// Public reference data, separate from personal backup/restore state.
/// SQLite transactions atomically replace a year; user_version is explicit.
class SqliteHolidayPackageStore implements HolidayPackageStore {
  SqliteHolidayPackageStore(this.file);
  final File file;

  Database _open() {
    file.parent.createSync(recursive: true);
    final db = sqlite3.open(file.path);
    try {
      db.execute('PRAGMA synchronous = FULL');
      final version =
          db.select('PRAGMA user_version').single.values.first as int;
      if (version == 0) {
        db.execute('BEGIN IMMEDIATE');
        db.execute(
          'CREATE TABLE holiday_packages (year INTEGER PRIMARY KEY, revision INTEGER NOT NULL, envelope TEXT NOT NULL)',
        );
        db.execute('PRAGMA user_version = 1');
        db.execute('COMMIT');
      } else if (version != 1) {
        throw StateError('Unsupported holiday store version');
      }
      return db;
    } catch (_) {
      db.close();
      rethrow;
    }
  }

  @override
  Future<List<String>> load() async {
    final db = _open();
    try {
      return db
          .select('SELECT envelope FROM holiday_packages ORDER BY year')
          .map((row) => row['envelope'] as String)
          .toList();
    } finally {
      db.close();
    }
  }

  @override
  Future<void> save(HolidayDataPackage package) async {
    // Cryptographic work must not suspend while holding a synchronous SQLite
    // write lock. Verify a snapshot, then compare it inside the transaction.
    final snapshot = await load();
    final verified = <HolidayDataPackage>[];
    for (final encoded in snapshot) {
      final current = await HolidayDataPackage.verify(encoded);
      verified.add(current);
      if (current.publisherKey != package.publisherKey ||
          (current.year == package.year &&
              current.revision >= package.revision)) {
        throw const HolidayPackageException(
          'ناشر یا نسخهٔ بسته با دادهٔ ذخیره‌شده سازگار نیست.',
        );
      }
    }
    final db = _open();
    var transaction = false;
    try {
      db.execute('BEGIN IMMEDIATE');
      transaction = true;
      final rows = db.select(
        'SELECT year, revision, envelope FROM holiday_packages ORDER BY year',
      );
      if (rows.length != snapshot.length ||
          List.generate(
            rows.length,
            (i) => rows[i]['envelope'] == snapshot[i],
          ).contains(false)) {
        throw const HolidayPackageException(
          'دادهٔ تعطیلات هم‌زمان تغییر کرده است؛ دوباره تلاش کنید.',
        );
      }
      for (var i = 0; i < rows.length; i++) {
        if (rows[i]['year'] != verified[i].year ||
            rows[i]['revision'] != verified[i].revision) {
          throw const HolidayPackageException('دادهٔ ذخیره‌شده معتبر نیست.');
        }
      }
      db.execute(
        'INSERT INTO holiday_packages(year, revision, envelope) VALUES (?, ?, ?) ON CONFLICT(year) DO UPDATE SET revision=excluded.revision, envelope=excluded.envelope',
        [package.year, package.revision, package.encoded],
      );
      db.execute('COMMIT');
    } catch (_) {
      if (transaction) db.execute('ROLLBACK');
      rethrow;
    } finally {
      db.close();
    }
  }
}
