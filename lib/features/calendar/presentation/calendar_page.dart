import 'dart:math' as math;

import 'package:planact/app/theme/commitment_identity_palette.dart';
import 'package:planact/features/calendar/application/week_timeline.dart';
import 'package:planact/features/calendar/presentation/week_timeline_view.dart';

import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/calendar/presentation/calendar_commitment_card.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
    required this.commitments,
    required this.scheduledDates,
    this.onCommitmentTap,
    this.onAdd,
    this.occurrences = const {},
    this.reminderRules = const [],
    this.initialDate,
    this.weekLoader,
    this.monthLoader,
    this.holidayProvider = const IranianHolidayProvider(),
  });

  final List<Commitment> commitments;
  final Future<Map<String, List<Occurrence>>> Function(LocalDate)? weekLoader;
  final Future<Map<String, List<Occurrence>>> Function(LocalDate, LocalDate)?
  monthLoader;
  final JalaliDate? initialDate;
  final IranianHolidayProvider holidayProvider;
  final Map<String, List<DateTime>> scheduledDates;
  final Map<String, List<Occurrence>> occurrences;
  final List<ReminderRule> reminderRules;
  final ValueChanged<Commitment>? onCommitmentTap;
  final VoidCallback? onAdd;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  IranianHolidayProvider get _holidayProvider => widget.holidayProvider;
  late JalaliDate _month;
  late JalaliDate _selectedDay;
  bool _week = false;
  int _weekPositionRevision = 0;
  int _monthRevision = 0;
  bool _monthLoading = false;
  bool _monthError = false;
  Map<JalaliDate, List<Commitment>> _monthItems = {};
  Map<JalaliDate, Map<String, List<Occurrence>>> _monthOccurrences = {};
  final _dayHeadingKey = GlobalKey();
  final _monthScroll = ScrollController();
  double _swipeDistance = 0;

  @override
  void dispose() {
    _monthRevision++;
    _monthScroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadMonth();
  }

  void _groupMonth(Map<String, List<Occurrence>> occurrences) {
    final items = <JalaliDate, Map<String, Commitment>>{};
    final grouped = <JalaliDate, Map<String, List<Occurrence>>>{};
    for (final item in widget.commitments) {
      final id = item.id.value;
      void include(JalaliDate date) {
        if (date.year == _month.year && date.month == _month.month) {
          (items[date] ??= {})[id] = item;
        }
      }

      for (final occurrence in occurrences[id] ?? const <Occurrence>[]) {
        final date = JalaliDate.fromDateTime(
          _displayDate(occurrence.currentScheduledAt),
        );
        if (date.year != _month.year || date.month != _month.month) continue;
        include(date);
        ((grouped[date] ??= {})[id] ??= []).add(occurrence);
      }
      // Legacy fixtures may have dates without recorded occurrence details.
      if (widget.monthLoader == null) {
        for (final date in widget.scheduledDates[id] ?? const <DateTime>[]) {
          include(JalaliDate.fromDateTime(_displayDate(date)));
        }
      }
    }
    _monthItems = {
      for (final entry in items.entries) entry.key: entry.value.values.toList(),
    };
    _monthOccurrences = grouped;
  }

  Future<void> _loadMonth() async {
    final revision = ++_monthRevision;
    final loader = widget.monthLoader;
    _monthItems = {};
    _monthOccurrences = {};
    _monthError = false;
    _monthLoading = loader != null;
    if (loader == null) {
      _groupMonth(widget.occurrences);
      return;
    }
    final start = LocalDate.fromDateTime(_month.toDateTime());
    final end = LocalDate.fromDateTime(
      JalaliDate(_month.year, _month.month, _month.monthLength).toDateTime(),
    );
    try {
      final result = await loader(start, end.addDays(1));
      if (!mounted || revision != _monthRevision) return;
      setState(() {
        _groupMonth(result);
        _monthLoading = false;
      });
    } catch (_) {
      if (!mounted || revision != _monthRevision) return;
      setState(() {
        _monthLoading = false;
        _monthError = true;
      });
    }
  }

  void _moveMonth(int delta) {
    setState(() {
      _month = _month.addMonths(delta);
      _selectedDay = JalaliDate(
        _month.year,
        _month.month,
        math.min(_selectedDay.day, _month.monthLength),
      );
      _loadMonth();
    });
  }

  void _showDayList() {
    final heading = _dayHeadingKey.currentContext;
    if (heading != null) Scrollable.ensureVisible(heading);
  }

  @override
  void initState() {
    super.initState();
    final today = widget.initialDate ?? JalaliDate.now();
    _month = JalaliDate(today.year, today.month, 1);
    _selectedDay = today;
    _loadMonth();
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

    final toggle = SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        key: const ValueKey('calendar-mode-toggle'),
        segments: const [
          ButtonSegment(value: false, label: Text('ماه')),
          ButtonSegment(value: true, label: Text('هفته')),
        ],
        selected: {_week},
        onSelectionChanged: (value) => setState(() {
          _week = value.single;
          _month = JalaliDate(_selectedDay.year, _selectedDay.month, 1);
          if (!_week) _loadMonth();
        }),
      ),
    );
    final todayButton = Align(
      alignment: AlignmentDirectional.centerEnd,
      child: TextButton.icon(
        key: const ValueKey('calendar-return-today'),
        onPressed: () => setState(() {
          final current = JalaliDate.now();
          _weekPositionRevision++;
          _selectedDay = current;
          _month = JalaliDate(current.year, current.month, 1);
          if (!_week) _loadMonth();
        }),
        icon: const Icon(Icons.today_outlined),
        label: const Text('بازگشت به امروز'),
      ),
    );
    if (_week) {
      final dates = WeekTimeline.dates(_selectedDay);
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PlanActSpacing.md,
              vertical: PlanActSpacing.sm,
            ),
            child: toggle,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PlanActSpacing.md),
            child: todayButton,
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'هفته قبل',
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    setState(() => _selectedDay = _selectedDay.addDays(-7)),
              ),
              Expanded(
                child: Text(
                  '${PersianDateFormatter.date(dates.first)} — ${PersianDateFormatter.date(dates.last)}',
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                tooltip: 'هفته بعد',
                icon: const Icon(Icons.chevron_right),
                onPressed: () =>
                    setState(() => _selectedDay = _selectedDay.addDays(7)),
              ),
            ],
          ),
          Expanded(
            child: WeekTimelineView(
              key: ValueKey(_weekPositionRevision),
              date: _selectedDay,
              commitments: widget.commitments,
              occurrences: widget.occurrences,
              holidays: _holidayProvider,
              loader: widget.weekLoader,
              onTap: widget.onCommitmentTap,
              onAdd: widget.onAdd,
            ),
          ),
        ],
      );
    }
    return ListView(
      controller: _monthScroll,
      padding: const EdgeInsets.fromLTRB(
        PlanActSpacing.md,
        PlanActSpacing.sm,
        PlanActSpacing.md,
        PlanActSpacing.xl,
      ),
      children: [
        toggle,
        todayButton,
        _CalendarHeader(
          month: _month,
          onPrevious: () => _moveMonth(-1),
          onNext: () => _moveMonth(1),
        ),
        if (!_holidayProvider.hasCompleteOfficialCoverage(_month.year))
          const Padding(
            padding: EdgeInsets.symmetric(vertical: PlanActSpacing.sm),
            child: Text(
              'دادهٔ تعطیلات رسمی این سال کامل نیست؛ تعطیلات قمری نمایش داده نمی‌شوند. نبودن نشان تعطیلی به معنی روز کاری قطعی نیست.',
            ),
          ),
        if (_monthLoading)
          const Column(
            children: [
              LinearProgressIndicator(),
              Text('در حال بارگذاری رخدادهای ماه…'),
            ],
          )
        else if (_monthError)
          Column(
            children: [
              const Text('بارگذاری رخدادهای ماه انجام نشد.'),
              TextButton(
                onPressed: () => setState(() {
                  _loadMonth();
                }),
                child: const Text('تلاش دوباره'),
              ),
            ],
          ),
        if (!_monthLoading && !_monthError && _monthItems.isEmpty)
          const Text('برای این ماه تعهدی ثبت نشده است.'),
        const SizedBox(height: PlanActSpacing.md),
        TextButton.icon(
          key: const ValueKey('calendar-show-day-list'),
          onPressed: _showDayList,
          icon: const Icon(Icons.list_alt),
          label: const Text('نمایش فهرست روز انتخاب‌شده'),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final scaler = MediaQuery.textScalerOf(context);
            // Seven columns stay in the viewport, including on narrow phones.
            // The documented narrow-grid exception applies to width, not height.
            final cellWidth = (constraints.maxWidth - 6 * 3) / 7;
            final labelStyle = theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            );
            double textHeight(String text, TextStyle? style) {
              final painter = TextPainter(
                text: TextSpan(text: text, style: style),
                textDirection: Directionality.of(context),
                textScaler: scaler,
              )..layout(maxWidth: cellWidth - 4);
              final height = painter.height;
              painter.dispose();
              return height;
            }

            final compact = PersianDateFormatter.weekdayNames.any((name) {
              final painter = TextPainter(
                text: TextSpan(text: name, style: labelStyle),
                textDirection: Directionality.of(context),
                textScaler: scaler,
              )..layout();
              final tooWide = painter.width > cellWidth;
              painter.dispose();
              return tooWide;
            });
            final numberHeight = List.generate(
              _month.monthLength,
              (index) => textHeight(
                PersianNumbers.format(index + 1),
                theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).reduce(math.max);
            final countHeight = textHeight(
              '+${PersianNumbers.format(widget.commitments.length)}',
              theme.textTheme.labelSmall,
            );
            final markerPainter = TextPainter(
              text: TextSpan(text: 'تعهد', style: theme.textTheme.labelSmall),
              textDirection: Directionality.of(context),
              textScaler: scaler,
            )..layout(maxWidth: cellWidth - 8);
            final markerHeight = markerPainter.preferredLineHeight * 2 + 4;
            markerPainter.dispose();
            final cellHeight = math.max(
              96.0,
              numberHeight +
                  textHeight('تعطیل', theme.textTheme.labelSmall) +
                  countHeight +
                  2 * markerHeight +
                  PlanActSpacing.lg,
            );
            return Column(
              children: [
                Row(
                  children: List.generate(7, (index) {
                    final name = PersianDateFormatter.weekdayNames[index];
                    return Expanded(
                      child: Semantics(
                        label: name,
                        child: ExcludeSemantics(
                          child: Text(
                            compact
                                ? PersianDateFormatter
                                      .compactWeekdayNames[index]
                                : name,
                            textAlign: TextAlign.center,
                            style: labelStyle,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: PlanActSpacing.xs),
                GestureDetector(
                  key: const ValueKey('calendar-month-grid'),
                  onHorizontalDragStart: (_) => _swipeDistance = 0,
                  onHorizontalDragUpdate: (details) =>
                      _swipeDistance += details.delta.dx,
                  onHorizontalDragCancel: () => _swipeDistance = 0,
                  onHorizontalDragEnd: (_) {
                    if (_swipeDistance.abs() >= 48) {
                      _moveMonth(_swipeDistance > 0 ? 1 : -1);
                    }
                    _swipeDistance = 0;
                  },
                  child: GridView.builder(
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
                        markerHeight: markerHeight,
                        onTap: () => setState(() => _selectedDay = date),
                      );
                    },
                  ),
                ),
                const SizedBox(height: PlanActSpacing.lg),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    key: _dayHeadingKey,
                    PersianDateFormatter.relative(_selectedDay),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: PlanActSpacing.sm),
        for (final holiday in _holidayProvider.holidaysFor(_selectedDay))
          Padding(
            padding: const EdgeInsets.only(bottom: PlanActSpacing.xs),
            child: Text(
              _holidayLabel(holiday),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: PlanActStatusColors.of(context).holiday,
              ),
            ),
          ),
        if (_monthLoading || _monthError)
          const Text('فهرست رخدادها هنوز در دسترس نیست.')
        else if (selectedItems.isEmpty)
          const Text('برای این روز تعهدی ثبت نشده است.')
        else
          ...selectedItems.map(
            (item) => CalendarCommitmentCard(
              commitment: item,
              occurrences: _occurrencesFor(item),
              reminderRules: widget.reminderRules,
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

  List<Occurrence> _occurrencesFor(Commitment item) =>
      _monthOccurrences[_selectedDay]?[item.id.value] ?? const [];

  List<Commitment> _commitmentsFor(JalaliDate date) =>
      _monthItems[date] ?? const [];
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
  });

  final JalaliDate month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

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
    required this.markerHeight,
    required this.onTap,
  });

  final JalaliDate date;
  final bool selected;
  final bool isToday;
  final List<CalendarHoliday> holidays;
  final List<Commitment> commitments;
  final double markerHeight;
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
      key: ValueKey('calendar-day-${date.day}'),
      button: true,
      selected: selected,
      label:
          '$dateLabel$selectionLabel$todayLabel$holidayLabel، $countLabel، '
          '${commitments.map((item) => item.title).join('، ')}، نمایش فهرست روز',
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
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
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
                          ? PlanActStatusColors.of(context).holiday
                          : selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                    ),
                  ),
                  if (holiday)
                    Text(
                      'تعطیل',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: PlanActStatusColors.of(context).holiday,
                      ),
                    ),
                  for (final item in commitments.take(2))
                    Container(
                      key: ValueKey('month-title-${date.day}-${item.id.value}'),
                      height: markerHeight,
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: PlanActRadius.chip,
                        color: CommitmentIdentityPalette.background(
                          CommitmentIdentityPalette.resolve(
                            item.color,
                            item.id,
                          ),
                          theme.brightness,
                        ),
                      ),
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: CommitmentIdentityPalette.foreground(
                            CommitmentIdentityPalette.resolve(
                              item.color,
                              item.id,
                            ),
                            theme.brightness,
                          ),
                        ),
                      ),
                    ),
                  if (commitments.length > 2)
                    Text(
                      '+${PersianNumbers.format(commitments.length - 2)}',
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
