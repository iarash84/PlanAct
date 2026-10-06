import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/app/theme/planact_radius.dart';
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
    this.initialDate,
    this.holidayProvider = const IranianHolidayProvider(),
  });

  final List<Commitment> commitments;
  final JalaliDate? initialDate;
  final IranianHolidayProvider holidayProvider;
  final Map<String, List<DateTime>> scheduledDates;
  final Map<String, List<Occurrence>> occurrences;
  final List<ReminderRule> reminderRules;
  final ValueChanged<Commitment>? onCommitmentTap;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  IranianHolidayProvider get _holidayProvider => widget.holidayProvider;
  late JalaliDate _month;
  late JalaliDate _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = widget.initialDate ?? JalaliDate.now();
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
        if (!_holidayProvider.hasCompleteOfficialCoverage(_month.year))
          const Padding(
            padding: EdgeInsets.symmetric(vertical: PlanActSpacing.sm),
            child: Text(
              'دادهٔ تعطیلات رسمی این سال کامل نیست؛ تعطیلات قمری نمایش داده نمی‌شوند. نبودن نشان تعطیلی به معنی روز کاری قطعی نیست.',
            ),
          ),
        const SizedBox(height: PlanActSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final scaler = MediaQuery.textScalerOf(context);
            final cellWidth = math.max(
              PlanActSpacing.touchTarget,
              scaler.scale(40) + 16,
            );
            final width = math.max(constraints.maxWidth, cellWidth * 7 + 18);
            final cellHeight = math.max(96.0, scaler.scale(80) + 24);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
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
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 3,
                        mainAxisSpacing: 3,
                        mainAxisExtent: cellHeight,
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
                          holidays: holidays
                              .where((holiday) => holiday.date == date)
                              .toList(),
                          commitments: items,
                          onTap: () => setState(() => _selectedDay = date),
                        );
                      },
                    ),
                  ],
                ),
              ),
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
        for (final holiday in _holidayProvider.holidaysFor(_selectedDay))
          Padding(
            padding: const EdgeInsets.only(bottom: PlanActSpacing.xs),
            child: Text(
              _holidayLabel(holiday),
              style: theme.textTheme.bodyMedium,
            ),
          ),
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

String _holidayLabel(CalendarHoliday holiday) => switch (holiday.kind) {
  CalendarHolidayKind.weekend => holiday.title,
  CalendarHolidayKind.officialFixed ||
  CalendarHolidayKind.officialVariable => 'تعطیل رسمی: ${holiday.title}',
  CalendarHolidayKind.special =>
    'تعطیلی موردی (${holiday.scope}): ${holiday.title}',
};

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
    required this.holidays,
    required this.commitments,
    required this.onTap,
  });

  final JalaliDate date;
  final bool selected;
  final bool isToday;
  final List<CalendarHoliday> holidays;
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
    final holiday = holidays.isNotEmpty;
    final holidayLabel = holiday
        ? '، ${holidays.map(_holidayLabel).join('، ')}'
        : '';
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
          borderRadius: PlanActRadius.chip,
          child: InkWell(
            onTap: onTap,
            borderRadius: PlanActRadius.chip,
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 5, 4, 3),
              decoration: BoxDecoration(
                borderRadius: PlanActRadius.chip,
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
                      color: holiday
                          ? PlanActStatusColors.of(context).info
                          : selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                    ),
                  ),
                  if (holiday)
                    Text(
                      'تعطیل',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
                    ),
                  if (commitments.isNotEmpty)
                    Text(
                      PersianNumbers.format(commitments.length),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
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
