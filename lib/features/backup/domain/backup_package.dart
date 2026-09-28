import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:planact/core/errors/app_error.dart';

const backupFormatVersion = 1;
const backupAlgorithm = 'AES-256-GCM';
const backupKdf = 'external-key-storage';
const backupKeyId = 'backup-key-v1';

abstract interface class BackupKeyStorage {
  Future<Uint8List> loadKey(String keyId);
}

abstract interface class BackupEncryptor {
  Future<EncryptedBackupPayload> encrypt({
    required Uint8List plaintext,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List associatedData,
  });

  Future<Uint8List> decrypt({
    required Uint8List ciphertext,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List tag,
    required Uint8List associatedData,
  });
}

class EncryptedBackupPayload {
  const EncryptedBackupPayload({required this.ciphertext, required this.tag});
  final Uint8List ciphertext;
  final Uint8List tag;
}

class BackupPackage {
  BackupPackage({
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAt,
    required this.payload,
    required this.encryptionMetadata,
    this.attachmentManifest = const [],
    String? checksum,
    this.formatVersion = backupFormatVersion,
  }) : checksum = checksum ?? _checksum(payload);

  final int schemaVersion;
  final String appVersion;
  final DateTime createdAt;
  final Uint8List payload;
  final Map<String, String> encryptionMetadata;
  final List<String> attachmentManifest;
  final String checksum;
  final int formatVersion;

  Map<String, Object?> toJson() => {
    'formatVersion': formatVersion,
    'schemaVersion': schemaVersion,
    'appVersion': appVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'payload': base64Encode(payload),
    'encryptionMetadata': encryptionMetadata,
    'attachmentManifest': attachmentManifest,
    'checksum': checksum,
  };

  factory BackupPackage.fromJson(Map<String, Object?> json) {
    try {
      final metadata = Map<String, String>.from(
        json['encryptionMetadata']! as Map,
      );
      return BackupPackage(
        formatVersion: json['formatVersion']! as int,
        schemaVersion: json['schemaVersion']! as int,
        appVersion: json['appVersion']! as String,
        createdAt: DateTime.parse(json['createdAt']! as String),
        payload: Uint8List.fromList(base64Decode(json['payload']! as String)),
        encryptionMetadata: metadata,
        attachmentManifest: List<String>.from(
          json['attachmentManifest']! as List,
        ),
        checksum: json['checksum']! as String,
      );
    } catch (_) {
      throw const ValidationError('Backup JSON is malformed or incomplete');
    }
  }

  String encode() => jsonEncode(toJson());

  static BackupPackage decode(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) throw const FormatException();
      return BackupPackage.fromJson(Map<String, Object?>.from(decoded));
    } catch (_) {
      throw const ValidationError('Backup JSON is malformed or incomplete');
    }
  }

  static String _checksum(Uint8List bytes) => sha256.convert(bytes).toString();
}

class BackupValidator {
  const BackupValidator({
    required this.currentSchemaVersion,
    this.maxPayloadBytes = 50 * 1024 * 1024,
  });
  final int currentSchemaVersion;
  final int maxPayloadBytes;

  void validate(BackupPackage package) {
    if (package.formatVersion != backupFormatVersion) {
      throw ValidationError(
        'Unsupported backup format version: ${package.formatVersion}',
      );
    }
    if (package.schemaVersion != currentSchemaVersion) {
      throw ValidationError(
        'Backup schema ${package.schemaVersion} is incompatible with schema $currentSchemaVersion',
      );
    }
    if (package.payload.isEmpty) {
      throw const ValidationError('Backup payload cannot be empty');
    }
    if (package.payload.length > maxPayloadBytes) {
      throw const ValidationError('Backup payload is too large');
    }
    final metadata = package.encryptionMetadata;
    const required = [
      'algorithm',
      'nonce',
      'tag',
      'kdf',
      'keyId',
      'rawTextPolicy',
    ];
    if (required.any(
      (key) => metadata[key] == null || metadata[key]!.isEmpty,
    )) {
      throw const ValidationError(
        'Backup encryption metadata is missing or invalid',
      );
    }
    if (metadata['algorithm'] != backupAlgorithm ||
        metadata['kdf'] != backupKdf ||
        metadata['keyId'] != backupKeyId) {
      throw const ValidationError('Backup encryption metadata is unsupported');
    }
    if (metadata['rawTextPolicy'] != 'redacted' &&
        metadata['rawTextPolicy'] != 'consented-encrypted') {
      throw const ValidationError('Backup raw text policy is unsupported');
    }
    try {
      if (base64Decode(metadata['nonce']!).length != 12 ||
          base64Decode(metadata['tag']!).length != 16) {
        throw const FormatException();
      }
    } catch (_) {
      throw const ValidationError(
        'Backup nonce or authentication tag is invalid',
      );
    }
    if (package.checksum != BackupPackage._checksum(package.payload)) {
      throw const ValidationError('Backup integrity checksum is invalid');
    }
  }
}
