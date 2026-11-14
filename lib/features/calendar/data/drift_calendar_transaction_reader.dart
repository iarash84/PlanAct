import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/calendar/application/calendar_transaction_reader.dart';
import 'package:planact/features/calendar/domain/calendar_transaction.dart';
import 'package:planact/features/calendar/domain/calendar_visibility.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

final class DriftCalendarTransactionReader
    implements CalendarTransactionReader, CommandGateProvider {
  const DriftCalendarTransactionReader(this.database);
  final AppDatabase database;
  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);
  @override
  Future<List<CalendarTransaction>> loadRange(
    LocalDate start,
    LocalDate endExclusive,
    CalendarVisibility visibility,
  ) {
    if (!visibility.hasFinancialItems) return Future.value(const []);
    return CommandGate.runFor(
      this,
      () => database.transaction(() async {
        final entries = await DriftFinanceRepository(database).listEntries();
        return projectCalendarTransactions(
          entries,
          visibility,
          start,
          endExclusive,
        );
      }),
    );
  }
}
