import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/inbox/application/sms_detection_notifications.dart';

class DriftSmsDetectionNotificationStore
    implements
        SmsDetectionNotificationStore,
        AtomicSmsDetectionNotificationStore,
        CommandGateProvider {
  DriftSmsDetectionNotificationStore(this.database);
  final AppDatabase database;
  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);
  static const metadataKey = 'sms_detection_notifications_v1';

  @override
  Future<String?> read() =>
      CommandGate.runFor(database, () => database.readMetadata(metadataKey));

  @override
  Future<void> compareAndWrite(
    String? expected,
    String value,
  ) => CommandGate.runFor(
    database,
    () => database.transaction(() async {
      await database.customStatement(
        'UPDATE schema_metadata SET value = value WHERE key = ?',
        ['schema_version'],
      );
      if (await database.readMetadata(metadataKey) != expected) {
        throw StateError('SMS notification state changed');
      }
      // Validate before storing; never replace unknown future state silently.
      SmsDetectionNotificationState.decode(value);
      await database.writeMetadata(metadataKey, value);
    }),
  );
}
