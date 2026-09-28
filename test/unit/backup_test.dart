import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/backup/application/backup_service.dart';
import 'package:planact/features/backup/domain/backup_encryption.dart';
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

class _Keys implements BackupKeyStorage {
  _Keys(this.key);
  final Uint8List key;
  @override
  Future<Uint8List> loadKey(String keyId) async => key;
}

class _Nonce implements BackupNonceGenerator {
  @override
  Uint8List generate() => Uint8List.fromList(List<int>.filled(12, 7));
}

class _Rebuild implements BackupRebuildHook {
  _Rebuild({this.fail = false});
  final bool fail;
  var calls = 0;
  @override
  Future<void> rebuild() async {
    calls++;
    if (fail) throw StateError('rebuild failed');
  }
}

BackupService _service({bool fail = false, Uint8List? key}) => BackupService(
  storage: _MemoryStorage(Uint8List.fromList([0])),
  validator: const BackupValidator(currentSchemaVersion: 7),
  rebuildHook: _Rebuild(fail: fail),
  keyStorage: _Keys(key ?? Uint8List.fromList(List<int>.filled(32, 1))),
  encryptor: AesGcmBackupEncryptor(),
  nonceGenerator: _Nonce(),
);

void main() {
  test('authenticated encryption round trip', () async {
    final service = _service();
    final package = await service.create(
      payload: Uint8List.fromList([1, 2, 3]),
      appVersion: '1.0.0',
      createdAt: DateTime.utc(2026, 9, 22),
    );
    expect(package.encryptionMetadata['algorithm'], backupAlgorithm);
    expect(package.payload, isNot(orderedEquals([1, 2, 3])));
    final encoded = BackupPackage.decode(package.encode());
    await service.restore(encoded);
  });

  test('rejects tampering, malformed JSON, missing metadata, and incompatible schema', () async {
    final service = _service();
    final package = await service.create(
      payload: Uint8List.fromList([1]),
      appVersion: '1',
      createdAt: DateTime.utc(2026),
    );
    final tampered = BackupPackage(
      payload: Uint8List.fromList([9]),
      schemaVersion: 7,
      appVersion: package.appVersion,
      createdAt: package.createdAt,
      encryptionMetadata: package.encryptionMetadata,
      checksum: package.checksum,
    );
    expect(
      () => const BackupValidator(currentSchemaVersion: 7).validate(tampered),
      throwsA(isA<ValidationError>()),
    );
    expect(() => BackupPackage.decode('{bad'), throwsA(isA<ValidationError>()));
    expect(
      () => BackupPackage.fromJson({'formatVersion': 1}),
      throwsA(isA<ValidationError>()),
    );
    expect(
      () => const BackupValidator(currentSchemaVersion: 6).validate(package),
      throwsA(isA<ValidationError>()),
    );
  });

  test('rejects wrong key and oversized payload', () async {
    final package = await _service().create(
      payload: Uint8List.fromList([1, 2]),
      appVersion: '1',
      createdAt: DateTime.utc(2026),
    );
    final wrong = BackupService(
      storage: _MemoryStorage(Uint8List.fromList([0])),
      validator: const BackupValidator(currentSchemaVersion: 7),
      rebuildHook: _Rebuild(),
      keyStorage: _Keys(Uint8List.fromList(List<int>.filled(32, 2))),
      encryptor: AesGcmBackupEncryptor(),
      nonceGenerator: _Nonce(),
    );
    expect(() => wrong.restore(package), throwsA(isA<ValidationError>()));
    final validator = const BackupValidator(
      currentSchemaVersion: 7,
      maxPayloadBytes: 1,
    );
    expect(() => validator.validate(package), throwsA(isA<ValidationError>()));
  });

  test('rolls back when restore rebuild fails', () async {
    final service = _service(fail: true);
    final storage = service.storage as _MemoryStorage;
    final package = await service.create(
      payload: Uint8List.fromList([9, 8]),
      appVersion: '1',
      createdAt: DateTime.utc(2026),
    );
    await expectLater(service.restore(package), throwsStateError);
    expect(storage.current, orderedEquals([0]));
    expect(storage.safety, orderedEquals([0]));
  });
}
