import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/backup/application/backup_service.dart';
import 'package:planact/features/backup/application/recovery_backup_actions.dart';
import 'package:planact/features/backup/data/secure_backup_keys.dart';
import 'package:planact/features/backup/domain/backup_package.dart';
import 'package:planact/features/backup/domain/backup_recovery_key.dart';

class FileBackupActions implements RecoveryBackupActions {
  FileBackupActions({
    required this.service,
    required this.keys,
    required this.exportPayload,
    required this.exclusive,
  });
  final BackupService service;
  // Retained for legacy import only. New exports never provision storage keys.
  final SecureBackupKeys keys;
  final Future<Uint8List> Function() exportPayload;
  final Future<bool> Function(Future<bool> Function()) exclusive;
  bool _pending = false;

  @override
  Future<bool> exportBackup() async =>
      throw const ValidationError('Recovery key acknowledgement required');

  @override
  Future<bool> importBackup() async =>
      throw const ValidationError('Recovery or legacy confirmation required');

  Future<bool> _admit(Future<bool> Function() operation) async {
    if (_pending) throw const ValidationError('Backup operation in progress');
    _pending = true;
    try {
      return await operation();
    } finally {
      _pending = false;
    }
  }

  @override
  Future<bool> exportRecoveryBackup(Future<bool> Function(String) confirm) =>
      _admit(() async {
        final key = await BackupRecoveryKey.generate();
        try {
          if (!await confirm(key.text)) return false;
          return await exclusive(() async {
            final info = await PackageInfo.fromPlatform();
            final package = await service.create(
              payload: await exportPayload(),
              appVersion: '${info.version}+${info.buildNumber}',
              createdAt: DateTime.now().toUtc(),
              recoveryKey: key.bytes,
            );
            final decoded = BackupPackage.decode(package.encode());
            service.validator.validate(decoded);
            final metadata = decoded.encryptionMetadata;
            final plaintext = await service.encryptor.decrypt(
              ciphertext: decoded.payload,
              key: key.bytes,
              nonce: base64Decode(metadata['nonce']!),
              tag: base64Decode(metadata['tag']!),
              associatedData: Uint8List.fromList(
                '${decoded.formatVersion}:${decoded.schemaVersion}'.codeUnits,
              ),
            );
            await (service.storage as BackupPayloadValidation).validatePayload(
              plaintext,
            );
            final bytes = Uint8List.fromList(utf8.encode(decoded.encode()));
            final path = await FilePicker.platform.saveFile(
              dialogTitle: 'ذخیره نسخه پشتیبان',
              fileName:
                  'planact-${DateTime.now().millisecondsSinceEpoch}.planact',
              bytes: bytes,
            );
            if (path == null) return false;
            if (!Platform.isAndroid && !Platform.isIOS) {
              await File(path).writeAsBytes(bytes, flush: true);
            }
            return true;
          });
        } finally {
          key.dispose();
        }
      });

  @override
  Future<bool> importRecoveryBackup({
    required Future<String?> Function() requestKey,
    required Future<bool> Function() confirmLegacy,
  }) => _admit(() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'انتخاب نسخه پشتیبان',
      withData: false,
    );
    if (result == null) return false;
    final path = result.files.single.path;
    if (path == null) throw const ValidationError('Backup file unavailable');
    final file = File(path);
    if (await file.length() > service.validator.maxPayloadBytes * 2) {
      throw const ValidationError('Backup file too large');
    }
    final package = BackupPackage.decode(await file.readAsString());
    service.validator.validate(package);
    BackupRecoveryKey? key;
    try {
      if (package.formatVersion == recoveryBackupFormatVersion) {
        final text = await requestKey();
        if (text == null) return false;
        key = BackupRecoveryKey.parse(text);
      } else if (!await confirmLegacy()) {
        return false;
      }
      return await exclusive(() async {
        await service.restore(package, recoveryKey: key?.bytes);
        return true;
      });
    } finally {
      key?.dispose();
    }
  });
}
