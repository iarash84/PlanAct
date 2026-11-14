import 'package:planact/features/calendar/domain/calendar_transaction.dart';
import 'package:planact/features/calendar/domain/calendar_visibility.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

abstract interface class CalendarTransactionReader {
  Future<List<CalendarTransaction>> loadRange(
    LocalDate start,
    LocalDate endExclusive,
    CalendarVisibility visibility,
  );
}
