import 'package:flutter/material.dart';
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
  });
  final List<Commitment> commitments;
  final Map<String, List<DateTime>> scheduledDates;
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
    final today = JalaliDate.now();
    final scheduled = widget.scheduledDates.values
        .expand((dates) => dates.map(JalaliDate.fromDateTime))
        .toList();
    final holidays = _holidayProvider.holidaysForMonth(
      _month.year,
      _month.month,
    );
    final leading = _month.weekDay - 1;
    final selectedItems = <Commitment>[];
    for (final item in widget.commitments) {
      final dates = widget.scheduledDates[item.id.value] ?? const <DateTime>[];
      if (dates.any((date) => JalaliDate.fromDateTime(date) == _selectedDay)) {
        selectedItems.add(item);
      }
    }
    return ListView(
      padding: const EdgeInsets.all(PlanActSpacing.lg),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'ماه قبل',
              onPressed: () => setState(() {
                _month = _month.addMonths(-1);
              }),
              icon: const Icon(Icons.chevron_right),
            ),
            Expanded(
              child: Center(
                child: Text(
                  PersianDateFormatter.month(_month),
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              tooltip: 'ماه بعد',
              onPressed: () => setState(() {
                _month = _month.addMonths(1);
              }),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'امروز',
              onPressed: () => setState(() {
                _month = JalaliDate(today.year, today.month, 1);
                _selectedDay = today;
              }),
              icon: const Icon(Icons.today),
            ),
          ],
        ),
        const SizedBox(height: PlanActSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: PersianDateFormatter.weekdayNames
              .map((name) => Text(name.substring(0, 1)))
              .toList(),
        ),
        const SizedBox(height: PlanActSpacing.sm),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          children: [
            for (var i = 0; i < leading; i++) const SizedBox.shrink(),
            for (var day = 1; day <= _month.monthLength; day++)
              _CalendarDay(
                day: day,
                selected:
                    _selectedDay == JalaliDate(_month.year, _month.month, day),
                isToday: today == JalaliDate(_month.year, _month.month, day),
                highlighted: scheduled.any(
                  (date) =>
                      date.year == _month.year &&
                      date.month == _month.month &&
                      date.day == day,
                ),
                holiday: holidays.any((holiday) => holiday.date.day == day),
                onTap: () => setState(
                  () =>
                      _selectedDay = JalaliDate(_month.year, _month.month, day),
                ),
              ),
          ],
        ),
        const SizedBox(height: PlanActSpacing.xl),
        Text(
          PersianDateFormatter.relative(_selectedDay),
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: PlanActSpacing.sm),
        if (selectedItems.isEmpty)
          const Text('برای این روز برنامه‌ای ثبت نشده.')
        else
          ...selectedItems.map(
            (item) => PlanActCommitmentRow(
              commitment: item,
              scheduledDates: widget.scheduledDates[item.id.value] ?? const [],
            ),
          ),
      ],
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.highlighted,
    required this.holiday,
    required this.onTap,
  });
  final int day;
  final bool selected;
  final bool isToday;
  final bool highlighted;
  final bool holiday;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(32),
    child: Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: selected ? Theme.of(context).colorScheme.primary : null,
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            PersianNumbers.format(day),
            style: TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : holiday
                  ? Theme.of(context).colorScheme.error
                  : null,
              fontWeight: highlighted || selected ? FontWeight.bold : null,
            ),
          ),
          if (highlighted) const Text('•', style: TextStyle(height: .4)),
        ],
      ),
    ),
  );
}
