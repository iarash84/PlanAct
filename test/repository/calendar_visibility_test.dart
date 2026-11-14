import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/calendar/domain/calendar_visibility.dart';
import 'package:planact/features/calendar/presentation/calendar_visibility_controller.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';

void main() {
  test('defaults, persist-before-publish, failure, cold reopen and backup snapshot', () async {
    final directory = await Directory.systemTemp.createTemp(
      'calendar-visibility-',
    );
    final file = File('${directory.path}/live.sqlite');
    var database = AppDatabase.forTesting(NativeDatabase(file));
    try {
      var settings = AppSettings(database);
      final defaults = await settings.readCalendarVisibility();
      expect(defaults.commitments, isTrue);
      expect(defaults.notes, isTrue);
      expect(defaults.hasFinancialItems, isFalse);
      expect(CalendarVisibility.parse('broken').isDefault, isTrue);
      expect(CalendarVisibility.parse('{"version":2}').isDefault, isTrue);
      final controller = CalendarVisibilityController(settings);
      await controller.load();
      const selected = CalendarVisibility(
        commitments: false,
        notes: false,
        income: true,
        expense: true,
        transfers: true,
      );
      final pending = controller.select(selected);
      expect(controller.saving, isTrue);
      expect(controller.value.isDefault, isTrue);
      await pending;
      expect(controller.value.storageValue, selected.storageValue);
      await database.customStatement(
        "CREATE TEMP TRIGGER fail_visibility BEFORE UPDATE ON schema_metadata WHEN NEW.key = 'calendar_visibility_v1' BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      await expectLater(controller.select(defaults), throwsA(anything));
      expect(controller.value.storageValue, selected.storageValue);
      expect(controller.saving, isFalse);
      controller.dispose();
      final bytes = await sqliteBackupSnapshot(
        database: database,
        target: File('${directory.path}/snapshot.sqlite'),
        redact: true,
      );
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      settings = AppSettings(database);
      expect(
        (await settings.readCalendarVisibility()).storageValue,
        selected.storageValue,
      );
      final restored = File('${directory.path}/restored.sqlite');
      await restored.writeAsBytes(bytes);
      final backupDb = AppDatabase.forTesting(NativeDatabase(restored));
      try {
        expect(
          (await AppSettings(backupDb).readCalendarVisibility()).storageValue,
          selected.storageValue,
        );
        expect(await backupDb.select(backupDb.accountEntries).get(), isEmpty);
        expect(await backupDb.select(backupDb.reminderRules).get(), isEmpty);
      } finally {
        await backupDb.close();
      }
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
