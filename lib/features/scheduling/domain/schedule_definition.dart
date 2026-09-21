import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';

enum ScheduleMode {
  oneOff,
  openEndedRecurring,
  fixedDateRangeRecurring,
  fixedCount,
}

enum TimeSemantics { floatingLocalTime, fixedInstant, allDayLocalDate }

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

enum MonthEndPolicy { skip, clampToLastDay }

class LocalDate implements Comparable<LocalDate> {
  LocalDate(this.year, this.month, this.day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      throw const ValidationError('Invalid local date');
    }
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw const ValidationError('Invalid local date');
    }
  }

  factory LocalDate.fromDateTime(DateTime value) =>
      LocalDate(value.year, value.month, value.day);

  final int year;
  final int month;
  final int day;

  DateTime toUtcDateForCalculation() => DateTime.utc(year, month, day);

  LocalDate addDays(int days) => LocalDate.fromDateTime(
    toUtcDateForCalculation().add(Duration(days: days)),
  );

  @override
  int compareTo(LocalDate other) =>
      toUtcDateForCalculation().compareTo(other.toUtcDateForCalculation());

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

class LocalTime {
  LocalTime(this.hour, this.minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw const ValidationError('Invalid local time');
    }
  }

  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is LocalTime && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

class RecurrenceRule {
  RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    Set<int> weekdays = const {},
    this.dayOfMonth,
    this.monthEndPolicy = MonthEndPolicy.skip,
  }) : weekdays = Set.unmodifiable(weekdays) {
    if (interval < 1) {
      throw const ValidationError('Recurrence interval must be positive');
    }
    if (this.weekdays.any((day) => day < 1 || day > 7)) {
      throw const ValidationError('Weekday must be between 1 and 7');
    }
    if (dayOfMonth != null && (dayOfMonth! < 1 || dayOfMonth! > 31)) {
      throw const ValidationError('Day of month must be between 1 and 31');
    }
  }

  final RecurrenceFrequency frequency;
  final int interval;
  final Set<int> weekdays;
  final int? dayOfMonth;
  final MonthEndPolicy monthEndPolicy;
}

class ScheduleDefinition {
  ScheduleDefinition({
    required this.id,
    required this.cycleId,
    required this.mode,
    required this.timeSemantics,
    required this.startDate,
    required this.version,
    required this.effectiveFrom,
    required this.generationHorizonDays,
    this.localTime,
    this.timeZoneId,
    this.fixedInstant,
    this.recurrenceRule,
    this.endDate,
    this.occurrenceCount,
  }) {
    _validate();
  }

  factory ScheduleDefinition.create({
    required StableId cycleId,
    required ScheduleMode mode,
    required TimeSemantics timeSemantics,
    required LocalDate startDate,
    LocalTime? localTime,
    String? timeZoneId,
    DateTime? fixedInstant,
    RecurrenceRule? recurrenceRule,
    LocalDate? endDate,
    int? occurrenceCount,
    int generationHorizonDays = 90,
  }) => ScheduleDefinition(
    id: StableId.generate(),
    cycleId: cycleId,
    mode: mode,
    timeSemantics: timeSemantics,
    startDate: startDate,
    localTime: localTime,
    timeZoneId: timeZoneId,
    fixedInstant: fixedInstant?.toUtc(),
    recurrenceRule: recurrenceRule,
    endDate: endDate,
    occurrenceCount: occurrenceCount,
    version: 1,
    effectiveFrom: startDate,
    generationHorizonDays: generationHorizonDays,
  );

  final StableId id;
  final StableId cycleId;
  final ScheduleMode mode;
  final TimeSemantics timeSemantics;
  final LocalDate startDate;
  final LocalTime? localTime;
  final String? timeZoneId;
  final DateTime? fixedInstant;
  final RecurrenceRule? recurrenceRule;
  final LocalDate? endDate;
  final int? occurrenceCount;
  final int version;
  final LocalDate effectiveFrom;
  final int generationHorizonDays;

  ScheduleDefinition nextVersion({
    required LocalDate effectiveFrom,
    LocalTime? localTime,
    RecurrenceRule? recurrenceRule,
  }) {
    if (effectiveFrom.compareTo(this.effectiveFrom) <= 0) {
      throw const ValidationError(
        'A schedule version must start after the current version',
      );
    }
    return ScheduleDefinition(
      id: StableId.generate(),
      cycleId: cycleId,
      mode: mode,
      timeSemantics: timeSemantics,
      startDate: effectiveFrom,
      localTime: localTime ?? this.localTime,
      timeZoneId: timeZoneId,
      fixedInstant: fixedInstant,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      endDate: endDate,
      occurrenceCount: occurrenceCount,
      version: version + 1,
      effectiveFrom: effectiveFrom,
      generationHorizonDays: generationHorizonDays,
    );
  }

  void _validate() {
    if (version < 1 || generationHorizonDays < 1) {
      throw const ValidationError('Invalid schedule version or horizon');
    }
    if (endDate != null && endDate!.compareTo(startDate) < 0) {
      throw const ValidationError(
        'Schedule end date cannot precede start date',
      );
    }
    if (timeSemantics == TimeSemantics.fixedInstant) {
      if (fixedInstant == null || !fixedInstant!.isUtc) {
        throw const ValidationError(
          'Fixed instant must be an explicit UTC instant',
        );
      }
    } else if (fixedInstant != null) {
      throw const ValidationError(
        'Only fixed-instant schedules may store an instant',
      );
    }
    if (timeSemantics == TimeSemantics.floatingLocalTime &&
        (localTime == null ||
            timeZoneId == null ||
            timeZoneId!.trim().isEmpty)) {
      throw const ValidationError(
        'Floating local time requires local time and timezone identifier',
      );
    }
    if (timeSemantics == TimeSemantics.allDayLocalDate && localTime != null) {
      throw const ValidationError(
        'All-day schedules cannot contain a local time',
      );
    }
    if (mode == ScheduleMode.oneOff && recurrenceRule != null) {
      throw const ValidationError('One-off schedules cannot recur');
    }
    if (mode != ScheduleMode.oneOff && recurrenceRule == null) {
      throw const ValidationError(
        'Recurring schedules require a recurrence rule',
      );
    }
    if (mode == ScheduleMode.fixedDateRangeRecurring && endDate == null) {
      throw const ValidationError(
        'Fixed date-range schedules require an end date',
      );
    }
    if (mode == ScheduleMode.fixedCount &&
        (occurrenceCount == null || occurrenceCount! < 1)) {
      throw const ValidationError(
        'Fixed-count schedules require a positive count',
      );
    }
  }
}
