import 'package:planact/core/application/command_gate.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

/// Mutating maintenance contract, deliberately separate from read repositories.
abstract interface class RecurringScheduleMaintenance {
  Future<int> extendRecurringSchedules(LocalDate today);
}

class ExtendRecurringSchedules {
  const ExtendRecurringSchedules(this.repository);
  final RecurringScheduleMaintenance repository;

  Future<int> call(DateTime now) => CommandGate.runFor(
    repository,
    () => repository.extendRecurringSchedules(LocalDate.fromDateTime(now)),
  );
}
