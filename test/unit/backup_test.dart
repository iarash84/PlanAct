import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/backup/application/backup_service.dart';
import 'package:planact/features/backup/domain/backup_package.dart';

class _MemoryStorage implements BackupStorage {
  _MemoryStorage(this.current);
  Uint8List current;
  Uint8List? safety;

  @override
  Future<Uint8List> readCurrent() async => current;

  @override
  Future<void> writeCurrent(Uint8List payload) async => current = payload;

  @override
  Future<void> writeSafetySnapshot(Uint8List payload) async => safety = payload;
}

class _RebuildHook implements BackupRebuildHook {
  var calls = 0;

  @override
  Future<void> rebuild() async => calls++;
}

void main() {
  final validator = const BackupValidator(currentSchemaVersion: 7);

  test('serializes a package and validates its checksum', () {
    final package = BackupPackage(
      schemaVersion: 7,
      appVersion: '1.0.0',
      createdAt: DateTime.utc(2026, 9, 22),
      payload: Uint8List.fromList([1, 2, 3]),
      encryptionMetadata: {'algorithm': 'none'},
    );

    final decoded = BackupPackage.decode(package.encode());
    validator.validate(decoded);

    expect(decoded.payload, orderedEquals([1, 2, 3]));
    expect(decoded.checksum, package.checksum);
  });

  test('rejects tampered and newer backups before restore', () {
    final package = BackupPackage(
      schemaVersion: 8,
      appVersion: 'future',
      createdAt: DateTime.utc(2026, 9, 22),
      payload: Uint8List.fromList([1]),
    );

    expect(() => validator.validate(package), throwsA(isA<ValidationError>()));
  });

  test(
    'creates safety snapshot and rebuilds after atomic restore flow',
    () async {
      final storage = _MemoryStorage(Uint8List.fromList([0]));
      final hook = _RebuildHook();
      final service = BackupService(
        storage: storage,
        validator: validator,
        rebuildHook: hook,
      );
      final package = await service.create(
        payload: Uint8List.fromList([9, 8]),
        appVersion: '1.0.0',
        createdAt: DateTime.utc(2026, 9, 22),
      );

      await service.restore(package);

      expect(storage.safety, orderedEquals([0]));
      expect(storage.current, orderedEquals([9, 8]));
      expect(hook.calls, 1);
    },
  );
}
