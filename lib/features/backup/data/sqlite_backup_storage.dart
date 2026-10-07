import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/backup/application/backup_service.dart';
import 'package:sqlite3/sqlite3.dart';

/// File operations run only while the owning application scope is suspended.
/// Recovery always chooses the old snapshot until the marker is committed.
class SqliteBackupStorage implements BackupStorage, BackupPayloadValidation {
  SqliteBackupStorage({
    required this.live,
    required this.schemaVersion,
    required this.expectedSchema,
    required this.snapshot,
    required this.closeLive,
  });

  final File live;
  final int schemaVersion;
  final List<String> expectedSchema;
  final Future<Uint8List> Function() snapshot;
  final Future<void> Function() closeLive;
  File get safety => File('${live.path}.restore-safety');
  File get temporary => File('${live.path}.restore-new');
  File get marker => File('${live.path}.restore-marker');

  static List<String> schema(Database db) => db
      .select(
        "SELECT type, name, tbl_name, sql FROM sqlite_master "
        "WHERE name NOT LIKE 'sqlite_%' ORDER BY type, name",
      )
      .map(
        (row) =>
            '${row['type']}|${row['name']}|${row['tbl_name']}|'
            '${(row['sql'] as String? ?? '').replaceAll(RegExp(r'\s+'), ' ').replaceAll('IF NOT EXISTS ', '').trim()}',
      )
      .toList();

  // Exact sqlite_master signatures from committed historical Drift schemas,
  // upgraded by AppDatabase's real migrations to v17. Full declarations live in
  // test/fixtures/backup_schema; never add a signature from an incoming payload.
  // These approve whole historical constraint sets, not arbitrary missing FKs,
  // CHECKs, indexes, or a mixture of individually permitted table variants.
  static const _trustedMigratedV17 = {
    // Actual fresh historical v10/v11 -> v17.
    'eab3f04cb6f0e4b96950a6d5b068876d830c7f6ad3d7450cc6289e04732e53ce',
    // Actual fresh historical v12, v13, v14, v15/v16 -> v17.
    'a4ada7abc1de59757638e9dec9660bae699f727c5a7cd93178b33c03103f55ff',
    '0f3b8ed67b94a08c54d6383bb7aaa43d9d38bc93d1a106181cabc09cf4a009af',
    '3861e21b8d6f92232810ca29f2883a8e0c348f48743398daf8f8c4f51084db20',
    'df1c53ffee960d7b21f43f6025e43007f3597e96fc8fc01b0c5ee9cfcaec6268',
    // Sequential committed v1 -> ... -> v10..v15 -> v17.
    '0b420de072d994a6ce0894775e1c121ff4690e2149b1281aac283f5d258ffedc',
  };

  bool _matchesSchema(Database db) {
    final declarations = schema(db).join('\n');
    if (declarations == expectedSchema.join('\n')) return true;
    return schemaVersion == 17 &&
        _trustedMigratedV17.contains(
          sha256.convert(utf8.encode(declarations)).toString(),
        );
  }

  /// Legacy migrations retained some tables without current FK declarations.
  /// Copy logical rows into an isolated trusted current schema to enforce all
  /// current CHECK/NOT NULL/unique/FK constraints too. Never modify the payload.
  void _validateLegacyRows(Database source) {
    final reference = sqlite3.openInMemory();
    try {
      // sqlite_master is type-sorted: indexes precede their tables.
      for (final declaration in [
        ...expectedSchema.where((s) => s.startsWith('table|')),
        ...expectedSchema.where((s) => !s.startsWith('table|')),
      ]) {
        final parts = declaration.split('|');
        reference.execute(parts.skip(3).join('|'));
      }
      reference.execute('PRAGMA foreign_keys = OFF');
      reference.execute('BEGIN');
      for (final row in reference.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%'",
      )) {
        final table = (row['name'] as String).replaceAll('"', '""');
        final rows = source.select('SELECT * FROM "$table"');
        final columns = rows.columnNames
            .map((name) => '"${name.replaceAll('"', '""')}"')
            .join(',');
        final parameters = List.filled(rows.columnNames.length, '?').join(',');
        final insert = reference.prepare(
          'INSERT INTO "$table" ($columns) VALUES ($parameters)',
        );
        try {
          for (final data in rows) {
            insert.execute(data.values.toList());
          }
        } finally {
          insert.close();
        }
      }
      if (reference.select('PRAGMA foreign_key_check').isNotEmpty) {
        throw const ValidationError('Backup database has invalid references');
      }
    } on SqliteException {
      throw const ValidationError(
        'Backup database violates schema constraints',
      );
    } finally {
      reference.close();
    }
  }

  void validateFile(File file) {
    final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
    try {
      if (db.select('PRAGMA user_version').single.values.single !=
              schemaVersion ||
          !_matchesSchema(db) ||
          db.select('PRAGMA integrity_check').single.values.single != 'ok' ||
          db.select('PRAGMA foreign_key_check').isNotEmpty) {
        throw const ValidationError(
          'Backup database is incompatible or damaged',
        );
      }
      if (schema(db).join('\n') != expectedSchema.join('\n')) {
        _validateLegacyRows(db);
      }
      final metadata = db.select(
        "SELECT value FROM schema_metadata WHERE key = 'schema_version'",
      );
      if (metadata.length != 1 ||
          metadata.single['value'] != '$schemaVersion') {
        throw const ValidationError(
          'Backup database schema metadata is invalid',
        );
      }
    } finally {
      db.close();
    }
  }

  @override
  Future<void> validatePayload(Uint8List payload) async {
    final file = File('${live.path}.restore-validation');
    try {
      await file.writeAsBytes(payload, flush: true);
      validateFile(file);
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Future<Uint8List> readCurrent() => snapshot();

  @override
  Future<void> writeSafetySnapshot(Uint8List payload) async {
    // Validate before overwriting the previous recovery artifact.
    await validatePayload(payload);
    await safety.writeAsBytes(payload, flush: true);
    validateFile(safety);
  }

  @override
  Future<void> writeTemporary(Uint8List payload) async {
    await temporary.writeAsBytes(payload, flush: true);
    validateFile(temporary);
  }

  @override
  Future<void> flushTemporary() async {
    final handle = await temporary.open(mode: FileMode.append);
    try {
      await handle.flush();
    } finally {
      await handle.close();
    }
  }

  @override
  Future<void> writeRecoveryMarker() async {
    final digest = sha256.convert(await safety.readAsBytes()).toString();
    await marker.writeAsString(digest, flush: true);
  }

  Future<void> _replace(File source) async {
    await closeLive();
    // No SQLite connection may retain a journal for the replaced database.
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final sidecar = File('${live.path}$suffix');
      if (await sidecar.exists()) await sidecar.delete();
    }
    await source.rename(live.path);
  }

  @override
  Future<void> replaceTemporary() => _replace(temporary);

  @override
  Future<void> restoreSafetySnapshot() async {
    validateFile(safety);
    if (await marker.exists() &&
        await marker.readAsString() !=
            sha256.convert(await safety.readAsBytes()).toString()) {
      throw const ValidationError('Recovery snapshot checksum is invalid');
    }
    final rollback = File('${live.path}.restore-rollback');
    await safety.copy(rollback.path);
    final handle = await rollback.open(mode: FileMode.append);
    await handle.flush();
    await handle.close();
    await _replace(rollback);
  }

  @override
  Future<void> clearRecoveryMarker() async {
    if (await marker.exists()) await marker.delete();
  }

  @override
  Future<void> recoverIfNeeded() async {
    if (!await marker.exists()) return;
    await restoreSafetySnapshot();
    await clearRecoveryMarker();
  }
}
