import 'dart:typed_data';

import 'package:planact/features/backup/domain/backup_package.dart';

abstract interface class BackupStorage {
  Future<void> writeCurrent(Uint8List payload);
  Future<Uint8List> readCurrent();
  Future<void> writeSafetySnapshot(Uint8List payload);
}

abstract interface class BackupRebuildHook {
  Future<void> rebuild();
}

class BackupService {
  const BackupService({
    required this.storage,
    required this.validator,
    required this.rebuildHook,
  });

  final BackupStorage storage;
  final BackupValidator validator;
  final BackupRebuildHook rebuildHook;

  Future<BackupPackage> create({
    required Uint8List payload,
    required String appVersion,
    required DateTime createdAt,
    Map<String, String> encryptionMetadata = const {},
    List<String> attachmentManifest = const [],
  }) async {
    final package = BackupPackage(
      schemaVersion: validator.currentSchemaVersion,
      appVersion: appVersion,
      createdAt: createdAt,
      payload: payload,
      encryptionMetadata: encryptionMetadata,
      attachmentManifest: attachmentManifest,
    );
    validator.validate(package);
    return package;
  }

  Future<void> restore(BackupPackage package) async {
    validator.validate(package);
    final current = await storage.readCurrent();
    await storage.writeSafetySnapshot(current);
    await storage.writeCurrent(package.payload);
    await rebuildHook.rebuild();
  }
}
