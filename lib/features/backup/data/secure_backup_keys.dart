import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/backup/application/backup_service.dart';
import 'package:planact/features/backup/domain/backup_package.dart';

class SecureBackupKeys implements BackupKeyStorage {
  const SecureBackupKeys({
    this.storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  });
  final FlutterSecureStorage storage;

  /// Only export may provision a key. Import never replaces a missing key.
  Future<void> provisionForExport() async {
    if (await storage.read(key: backupKeyId) != null) return;
    final bytes = _randomBytes(32);
    await storage.write(key: backupKeyId, value: base64Encode(bytes));
    await loadKey(backupKeyId);
  }

  @override
  Future<Uint8List> loadKey(String keyId) async {
    if (keyId != backupKeyId) throw const ValidationError('Unknown backup key');
    final encoded = await storage.read(key: keyId);
    if (encoded == null) throw const ValidationError('Backup key unavailable');
    try {
      final key = base64Decode(encoded);
      if (key.length != 32) throw const FormatException();
      return key;
    } catch (_) {
      throw const ValidationError('Backup key invalid');
    }
  }
}

Uint8List _randomBytes(int count) {
  final random = Random.secure();
  return Uint8List.fromList(List.generate(count, (_) => random.nextInt(256)));
}

class SecureBackupNonce implements BackupNonceGenerator {
  @override
  Uint8List generate() => _randomBytes(12);
}
