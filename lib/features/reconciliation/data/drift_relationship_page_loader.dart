import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';

/// Keeps the entire page context in one admitted SQLite read snapshot.
final class DriftRelationshipPageLoader implements CommandGateProvider {
  const DriftRelationshipPageLoader(this.database);

  final AppDatabase database;

  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);

  Future<TransactionRelationshipContext> load(
    Future<TransactionRelationshipContext> Function() read,
  ) => CommandGate.runFor(this, () => database.transaction(read));
}
