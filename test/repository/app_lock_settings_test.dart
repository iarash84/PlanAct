import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/core/database/app_database.dart';

void main() {
  test('app lock enable and disable survive file database reopen', () async {
    final directory = await Directory.systemTemp.createTemp('planact-lock-');
    final file = File('${directory.path}/state.sqlite');
    var database = AppDatabase(NativeDatabase(file));
    try {
      expect(await AppSettings(database).readAppLockEnabled(), isFalse);
      await AppSettings(database).writeAppLockEnabled(true);
      await database.close();
      database = AppDatabase(NativeDatabase(file));
      expect(await AppSettings(database).readAppLockEnabled(), isTrue);
      await AppSettings(database).writeAppLockEnabled(false);
      await database.close();
      database = AppDatabase(NativeDatabase(file));
      expect(await AppSettings(database).readAppLockEnabled(), isFalse);
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
