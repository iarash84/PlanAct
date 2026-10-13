import 'package:planact/features/backup/application/backup_actions.dart';

/// UI interaction stays outside the database owner's exclusive lifecycle.
abstract interface class RecoveryBackupActions implements BackupActions {
  Future<bool> exportRecoveryBackup(Future<bool> Function(String key) confirm);
  Future<bool> importRecoveryBackup({
    required Future<String?> Function() requestKey,
    required Future<bool> Function() confirmLegacy,
  });
}
