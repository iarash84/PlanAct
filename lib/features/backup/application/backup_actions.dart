abstract interface class BackupActions {
  /// False means the user cancelled the system picker.
  Future<bool> exportBackup();
  Future<bool> importBackup();
}
