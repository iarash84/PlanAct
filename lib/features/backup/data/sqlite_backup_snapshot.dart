import 'dart:io';
import 'dart:typed_data';

import 'package:planact/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

/// Consistent SQLite snapshot includes every persisted table, index and ledger.
/// Redaction never modifies live data and VACUUM removes old text from pages.
Future<Uint8List> sqliteBackupSnapshot({
  required AppDatabase database,
  required File target,
  required bool redact,
}) async {
  try {
    if (await target.exists()) await target.delete();
    final escaped = target.path.replaceAll("'", "''");
    await database.customStatement("VACUUM INTO '$escaped'");
    final db = sqlite3.open(target.path);
    try {
      if (redact) {
        db.execute('PRAGMA secure_delete = ON');
        db.execute("UPDATE staged_imports SET raw_text = ''");
        db.execute(
          'UPDATE reminder_instances SET platform_notification_id = NULL',
        );
        db.execute('VACUUM');
      }
    } finally {
      db.close();
    }
    return await target.readAsBytes();
  } finally {
    if (await target.exists()) await target.delete();
  }
}
