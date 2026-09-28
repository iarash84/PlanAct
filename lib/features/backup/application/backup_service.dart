import 'dart:convert';
import 'dart:typed_data';

import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/backup/domain/backup_package.dart';

abstract interface class BackupStorage {
  Future<void> writeCurrent(Uint8List payload);
  Future<Uint8List> readCurrent();
  Future<void> writeSafetySnapshot(Uint8List payload);
}

abstract interface class BackupRebuildHook {
  Future<void> rebuild();
}

abstract interface class BackupNonceGenerator {
  Uint8List generate();
}

class BackupService {
  const BackupService({
    required this.storage,
    required this.validator,
    required this.rebuildHook,
    required this.keyStorage,
    required this.encryptor,
    required this.nonceGenerator,
  });

  final BackupStorage storage;
  final BackupValidator validator;
  final BackupRebuildHook rebuildHook;
  final BackupKeyStorage keyStorage;
  final BackupEncryptor encryptor;
  final BackupNonceGenerator nonceGenerator;

  Future<BackupPackage> create({
    required Uint8List payload,
    required String appVersion,
    required DateTime createdAt,
    List<String> attachmentManifest = const [],
    bool includeSensitiveRawText = false,
  }) async {
    if (payload.isEmpty || payload.length > validator.maxPayloadBytes) {
      throw const ValidationError('Backup payload is empty or too large');
    }
    final key = await keyStorage.loadKey(backupKeyId);
    final nonce = nonceGenerator.generate();
    if (nonce.length != 12) {
      throw const ValidationError('Backup nonce must be 12 bytes');
    }
    final encrypted = await encryptor.encrypt(
      plaintext: payload,
      key: key,
      nonce: nonce,
      associatedData: Uint8List.fromList(
        '$backupFormatVersion:${validator.currentSchemaVersion}'.codeUnits,
      ),
    );
    final package = BackupPackage(
      schemaVersion: validator.currentSchemaVersion,
      appVersion: appVersion,
      createdAt: createdAt,
      payload: encrypted.ciphertext,
      attachmentManifest: attachmentManifest,
      encryptionMetadata: {
        'algorithm': backupAlgorithm,
        'formatVersion': '$backupFormatVersion',
        'nonce': _encode(nonce),
        'tag': _encode(encrypted.tag),
        'kdf': backupKdf,
        'keyId': backupKeyId,
        'rawTextPolicy': includeSensitiveRawText
            ? 'consented-encrypted'
            : 'redacted',
      },
    );
    validator.validate(package);
    return package;
  }

  Future<void> restore(BackupPackage package) async {
    validator.validate(package);
    final key = await keyStorage.loadKey(package.encryptionMetadata['keyId']!);
    final metadata = package.encryptionMetadata;
    final plaintext = await encryptor.decrypt(
      ciphertext: package.payload,
      key: key,
      nonce: Uint8List.fromList(_decode(metadata['nonce']!)),
      tag: Uint8List.fromList(_decode(metadata['tag']!)),
      associatedData: Uint8List.fromList(
        '${package.formatVersion}:${package.schemaVersion}'.codeUnits,
      ),
    );
    if (plaintext.isEmpty || plaintext.length > validator.maxPayloadBytes) {
      throw const ValidationError('Decrypted backup payload is invalid');
    }
    final current = await storage.readCurrent();
    await storage.writeSafetySnapshot(current);
    try {
      await storage.writeCurrent(plaintext);
      await rebuildHook.rebuild();
    } catch (_) {
      await storage.writeCurrent(current);
      rethrow;
    }
  }

  static String _encode(Uint8List bytes) => base64Encode(bytes);
  static List<int> _decode(String value) => base64Decode(value);
}
