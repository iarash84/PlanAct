import 'package:flutter/material.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/reminders/presentation/occurrence_reminders.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/today/presentation/widgets/planact_commitment_row.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
    required this.commitments,
    required this.scheduledDates,
    this.onCommitmentTap,
    this.occurrences = const {},
    this.reminderRules = const [],
  });

  final List<Commitment> commitments;
  final Map<String, List<DateTime>> scheduledDates;
  final Map<String, List<Occurrence>> occurrences;
  final List<ReminderRule> reminderRules;
  final ValueChanged<Commitment>? onCommitmentTap;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const _holidayProvider = IranianHolidayProvider();
  late JalaliDate _month;
  late JalaliDate _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = JalaliDate.now();
    _month = JalaliDate(today.year, today.month, 1);
    _selectedDay = today;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = JalaliDate.now();
    final holidays = _holidayProvider.holidaysForMonth(
      _month.year,
      _month.month,
    );
    final leading = _month.weekDay - 1;
    final cellCount = ((leading + _month.monthLength + 6) ~/ 7) * 7;
    final selectedItems = _commitmentsFor(_selectedDay);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PlanActSpacing.md,
        PlanActSpacing.sm,
        PlanActSpacing.md,
        PlanActSpacing.xl,
      ),
      children: [
        _CalendarHeader(
          month: _month,
          onPrevious: () => setState(() {
            _month = _month.addMonths(-1);
          }),
          onNext: () => setState(() {
            _month = _month.addMonths(1);
          }),
          onToday: () => setState(() {
            _month = JalaliDate(today.year, today.month, 1);
            _selectedDay = today;
          }),
        ),
        const SizedBox(height: PlanActSpacing.md),
        Row(
          children: PersianDateFormatter.weekdayNames
              .map(
                (name) => Expanded(
                  child: Center(
                    child: Text(
                      name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: PlanActSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
            childAspectRatio: .72,
          ),
          itemBuilder: (context, index) {
            final day = index - leading + 1;
            if (day < 1 || day > _month.monthLength) {
              return const SizedBox.shrink();
            }
            final date = JalaliDate(_month.year, _month.month, day);
            final items = _commitmentsFor(date);
            return _CalendarDay(
              date: date,
              selected: _selectedDay == date,
              isToday: today == date,
              holiday: holidays.any((holiday) => holiday.date == date),
              commitments: items,
              onTap: () => setState(() => _selectedDay = date),
            );
          },
        ),
        const SizedBox(height: PlanActSpacing.lg),
        Text(
          PersianDateFormatter.relative(_selectedDay),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: PlanActSpacing.sm),
        if (selectedItems.isEmpty)
          const Text('برای این روز تعهدی ثبت نشده است.')
        else
          ...selectedItems.map(
            (item) => PlanActCommitmentRow(
              commitment: item,
              scheduledDates: widget.scheduledDates[item.id.value] ?? const [],
              supportingDetails: _detailsFor(item),
              onTap: widget.onCommitmentTap == null
                  ? null
                  : () => widget.onCommitmentTap!(item),
            ),
          ),
      ],
    );
  }

  DateTime _displayDate(Object value) => switch (value) {
    DateTime date => date.isUtc ? date.toLocal() : date,
    LocalDate date => DateTime(date.year, date.month, date.day),
    _ => throw StateError('Unsupported occurrence date'),
  };

  String? _detailsFor(Commitment item) {
    final occurrences = widget.occurrences[item.id.value];
    if (occurrences == null) return null;
    return occurrences
        .where(
          (occurrence) =>
              JalaliDate.fromDateTime(
                _displayDate(occurrence.currentScheduledAt),
              ) ==
              _selectedDay,
        )
        .map((occurrence) {
          final value = occurrence.currentScheduledAt;
          final time = value is DateTime
              ? 'ساعت ${reminderTimeLabel(value)}'
              : 'تمام‌روز (بدون ساعت)';
          final rules = widget.reminderRules.where(
            (rule) => rule.enabled && rule.occurrenceId == occurrence.id,
          );
          final reminders = rules.isEmpty
              ? 'بدون یادآوری'
              : 'یادآوری: ${rules.map(reminderRuleLabel).join('، ')}';
          return '$time • $reminders';
        })
        .join('\n');
  }

  List<Commitment> _commitmentsFor(JalaliDate date) => widget.commitments.where(
    (item) {
      final dates = widget.scheduledDates[item.id.value] ?? const <DateTime>[];
      return dates.any((value) => JalaliDate.fromDateTime(value) == date);
    },
  ).toList();
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final JalaliDate month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          tooltip: 'ماه قبل',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            PersianDateFormatter.month(month),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          tooltip: 'ماه بعد',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          tooltip: 'امروز',
          onPressed: onToday,
          icon: const Icon(Icons.today_outlined),
        ),
      ],
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.holiday,
    required this.commitments,
    required this.onTap,
  });

  final JalaliDate date;
  final bool selected;
  final bool isToday;
  final bool holiday;
  final List<Commitment> commitments;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateLabel = PersianDateFormatter.date(date);
    final count = PersianNumbers.format(commitments.length);
    final selectionLabel = selected ? '، انتخاب‌شده' : '';
    final todayLabel = isToday ? '، امروز' : '';
    final holidayLabel = holiday ? '، تعطیل' : '';
    final countLabel = commitments.isEmpty ? 'بدون تعهد' : '$count تعهد';
    return Semantics(
      button: true,
      selected: selected,
      label: '$dateLabel$selectionLabel$todayLabel$holidayLabel، $countLabel',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest.withValues(alpha: .38),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 5, 4, 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: scheme.primary, width: 2)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    PersianNumbers.format(date.day),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected || isToday
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: holiday ? scheme.error : null,
                    ),
                  ),
                  if (commitments.isNotEmpty)
                    Text(
                      PersianNumbers.format(commitments.length),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
