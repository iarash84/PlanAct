import 'dart:convert';
import 'dart:typed_data';

import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/backup/domain/backup_package.dart';

/// Storage boundary for crash-safe backup replacement.
///
/// Implementations must make [replaceTemporary] an atomic rename/replace at
/// the storage boundary, and must persist the recovery marker before replacing
/// the live file. The marker is intentionally not part of backup data.
abstract interface class BackupStorage {
  Future<Uint8List> readCurrent();
  Future<void> writeSafetySnapshot(Uint8List payload);
  Future<void> writeTemporary(Uint8List payload);
  Future<void> flushTemporary();
  Future<void> writeRecoveryMarker();
  Future<void> replaceTemporary();
  Future<void> clearRecoveryMarker();
  Future<void> recoverIfNeeded();
  Future<void> restoreSafetySnapshot();
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

    await storage.recoverIfNeeded();
    final current = await storage.readCurrent();
    try {
      await storage.writeSafetySnapshot(current);
      await storage.writeTemporary(plaintext);
      await storage.flushTemporary();
      await storage.writeRecoveryMarker();
      await storage.replaceTemporary();
      await rebuildHook.rebuild();
      await storage.clearRecoveryMarker();
    } catch (error, stackTrace) {
      try {
        await storage.restoreSafetySnapshot();
        await storage.clearRecoveryMarker();
      } catch (recoveryError, recoveryStackTrace) {
        Error.throwWithStackTrace(
          BackupRestoreError(
            'Restore failed and recovery failed: $error; '
            'recovery error: $recoveryError',
            cause: recoveryError,
          ),
          recoveryStackTrace,
        );
      }
      Error.throwWithStackTrace(
        BackupRestoreError('Restore failed: $error', cause: error),
        stackTrace,
      );
    }
  }

  static String _encode(Uint8List bytes) => base64Encode(bytes);
  static List<int> _decode(String value) => base64Decode(value);
}
