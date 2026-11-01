import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';

void main() {
  // This test intentionally opens independent databases for reopen and restore.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('default, unknown, cold reopen and personal snapshot preserve preference without currency mutation', () async {
    final directory = await Directory.systemTemp.createTemp('money-unit-');
    final file = File('${directory.path}/live.sqlite');
    var database = AppDatabase(NativeDatabase(file));
    try {
      var settings = AppSettings(database);
      expect(await settings.readMoneyUnit(), IranianMoneyUnit.rial);
      await database.writeMetadata('iranian_money_unit_v1', 'unknown');
      expect(await settings.readMoneyUnit(), IranianMoneyUnit.rial);
      await database.customStatement(
        "INSERT INTO financial_accounts(id,name,type,currency,status) VALUES('legacy','legacy',0,'تومان',0)",
      );
      await settings.writeMoneyUnit(IranianMoneyUnit.toman);
      await database.close();
      database = AppDatabase(NativeDatabase(file));
      settings = AppSettings(database);
      expect(await settings.readMoneyUnit(), IranianMoneyUnit.toman);
      expect(
        (await database
                .customSelect('SELECT currency FROM financial_accounts')
                .getSingle())
            .read<String>('currency'),
        'تومان',
      );
      final target = File('${directory.path}/backup.sqlite');
      final bytes = await sqliteBackupSnapshot(
        database: database,
        target: target,
        redact: true,
      );
      await target.writeAsBytes(bytes, flush: true);
      final restored = AppDatabase(NativeDatabase(target));
      try {
        expect(
          await AppSettings(restored).readMoneyUnit(),
          IranianMoneyUnit.toman,
        );
        final controller = MoneyUnitController(AppSettings(restored));
        await controller.load();
        expect(controller.value, IranianMoneyUnit.toman);
        controller.dispose();
      } finally {
        await restored.close();
      }
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
  test('failed durable preference change preserves effective unit', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final controller = MoneyUnitController(AppSettings(database));
    await controller.load();
    await database.close();
    await expectLater(
      controller.select(IranianMoneyUnit.toman),
      throwsA(anything),
    );
    expect(controller.value, IranianMoneyUnit.rial);
    expect(controller.saving, isFalse);
    controller.dispose();
  });
}
