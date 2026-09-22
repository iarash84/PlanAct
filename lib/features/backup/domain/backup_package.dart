import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:planact/core/errors/app_error.dart';

class BackupPackage {
  BackupPackage({
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAt,
    required this.payload,
    this.encryptionMetadata = const {},
    this.attachmentManifest = const [],
    String? checksum,
  }) : checksum = checksum ?? _checksum(payload);

  final int schemaVersion;
  final String appVersion;
  final DateTime createdAt;
  final Uint8List payload;
  final Map<String, String> encryptionMetadata;
  final List<String> attachmentManifest;
  final String checksum;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'appVersion': appVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'payload': base64Encode(payload),
    'encryptionMetadata': encryptionMetadata,
    'attachmentManifest': attachmentManifest,
    'checksum': checksum,
  };

  factory BackupPackage.fromJson(Map<String, Object?> json) {
    final payload = Uint8List.fromList(
      base64Decode(json['payload']! as String),
    );
    return BackupPackage(
      schemaVersion: json['schemaVersion']! as int,
      appVersion: json['appVersion']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      payload: payload,
      encryptionMetadata: Map<String, String>.from(
        json['encryptionMetadata']! as Map,
      ),
      attachmentManifest: List<String>.from(
        json['attachmentManifest']! as List,
      ),
      checksum: json['checksum']! as String,
    );
  }

  String encode() => jsonEncode(toJson());

  static BackupPackage decode(String value) =>
      BackupPackage.fromJson(jsonDecode(value) as Map<String, Object?>);

  static String _checksum(Uint8List bytes) => sha256.convert(bytes).toString();
}

class BackupValidator {
  const BackupValidator({required this.currentSchemaVersion});
  final int currentSchemaVersion;

  void validate(BackupPackage package) {
    if (package.schemaVersion > currentSchemaVersion) {
      throw ValidationError(
        'Backup schema ${package.schemaVersion} is newer than supported schema $currentSchemaVersion',
      );
    }
    if (package.payload.isEmpty) {
      throw const ValidationError('Backup payload cannot be empty');
    }
    final expected = BackupPackage._checksum(package.payload);
    if (package.checksum != expected) {
      throw const ValidationError('Backup checksum is invalid');
    }
  }
}
