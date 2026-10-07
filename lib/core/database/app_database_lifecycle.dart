import 'package:drift/drift.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart';

/// Owns the single production database instance for the application scope.
/// Repositories receive references but never own or close this resource.
final class AppDatabaseLifecycle {
  AppDatabaseLifecycle(this.database) {
    CommandGate.bind(database, commands);
  }

  final AppDatabase database;
  final CommandGate commands = CommandGate();
  bool _closed = false;

  bool get isClosed => _closed;

  Future<void> close() async {
    if (_closed) return;
    await commands.retire();
    _closed = true;
    await database.close();
  }

  static AppDatabaseLifecycle open(QueryExecutor executor) =>
      AppDatabaseLifecycle(AppDatabase(executor));
}
