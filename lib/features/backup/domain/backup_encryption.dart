import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/backup/domain/backup_package.dart';

class AesGcmBackupEncryptor implements BackupEncryptor {
  AesGcmBackupEncryptor();
  final _algorithm = AesGcm.with256bits();

  @override
  Future<EncryptedBackupPayload> encrypt({
    required Uint8List plaintext,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List associatedData,
  }) async {
    if (key.length != 32) {
      throw const ValidationError('Backup key must be 32 bytes');
    }
    final box = await _algorithm.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: nonce,
      aad: associatedData,
    );
    return EncryptedBackupPayload(
      ciphertext: Uint8List.fromList(box.cipherText),
      tag: Uint8List.fromList(box.mac.bytes),
    );
  }

  @override
  Future<Uint8List> decrypt({
    required Uint8List ciphertext,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List tag,
    required Uint8List associatedData,
  }) async {
    if (key.length != 32) {
      throw const ValidationError('Backup key must be 32 bytes');
    }
    try {
      final plaintext = await _algorithm.decrypt(
        SecretBox(ciphertext, nonce: nonce, mac: Mac(tag)),
        secretKey: SecretKey(key),
        aad: associatedData,
      );
      return Uint8List.fromList(plaintext);
    } catch (_) {
      throw const ValidationError('Backup authentication failed');
    }
  }
}
