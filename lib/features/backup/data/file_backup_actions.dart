import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/backup/application/backup_actions.dart';
import 'package:planact/features/backup/application/backup_service.dart';
import 'package:planact/features/backup/data/secure_backup_keys.dart';
import 'package:planact/features/backup/domain/backup_package.dart';

class FileBackupActions implements BackupActions {
  FileBackupActions({
    required this.service,
    required this.keys,
    required this.exportPayload,
    required this.exclusive,
  });
  final BackupService service;
  final SecureBackupKeys keys;
  final Future<Uint8List> Function() exportPayload;
  final Future<bool> Function(Future<bool> Function()) exclusive;

  @override
  Future<bool> exportBackup() => exclusive(() async {
    await keys.provisionForExport();
    final info = await PackageInfo.fromPlatform();
    final package = await service.create(
      payload: await exportPayload(),
      appVersion: '${info.version}+${info.buildNumber}',
      createdAt: DateTime.now().toUtc(),
    );
    // Validate the exact serialized package and its authenticated plaintext.
    final decoded = BackupPackage.decode(package.encode());
    service.validator.validate(decoded);
    final metadata = decoded.encryptionMetadata;
    final plaintext = await service.encryptor.decrypt(
      ciphertext: decoded.payload,
      key: await keys.loadKey(backupKeyId),
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
      fileName: 'planact-${DateTime.now().millisecondsSinceEpoch}.planact',
      bytes: bytes,
    );
    if (path == null) return false;
    if (!Platform.isAndroid && !Platform.isIOS) {
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return true;
  });

  @override
  Future<bool> importBackup() => exclusive(() async {
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
    await service.restore(package);
    return true;
  });
}
