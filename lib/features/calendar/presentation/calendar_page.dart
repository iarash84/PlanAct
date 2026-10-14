import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/notes/domain/calendar_note.dart';
import 'package:planact/features/notes/presentation/calendar_note_tile.dart';
import 'package:planact/core/localization/persian_copy.g.dart';

import 'dart:math' as math;

import 'package:planact/features/scheduling/application/planned_occurrences.dart';
import 'package:planact/features/calendar/presentation/planned_occurrence_widgets.dart';

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
import 'package:planact/core/presentation/planact_month_swipe.dart';
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
    this.plannedLoader,
    this.noteLoader,
    this.notesRevision = 0,
    this.onNoteTap,
    this.holidayProvider = const IranianHolidayProvider(),
  });

  final List<Commitment> commitments;
  final Future<List<CalendarNote>> Function(LocalDate, LocalDate)? noteLoader;
  final int notesRevision;
  final ValueChanged<CalendarNote>? onNoteTap;
  final Future<Map<String, List<Occurrence>>> Function(LocalDate)? weekLoader;
  final Future<Map<String, List<Occurrence>>> Function(LocalDate, LocalDate)?
  monthLoader;
  final Future<PlannedOccurrenceRange> Function(LocalDate, LocalDate)?
  plannedLoader;
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
  Map<String, List<PlannedOccurrenceSlot>> _monthPreviews = {};
  Map<LocalDate, List<CalendarNote>> _monthNotes = {};
  final _monthScroll = ScrollController();

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
      for (final slot in _monthPreviews[id] ?? <PlannedOccurrenceSlot>[]) {
        include(JalaliDate.fromDateTime(slot.date.toUtcDateForCalculation()));
      }
      if (widget.monthLoader == null && widget.plannedLoader == null) {
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
    final plannedLoader = widget.plannedLoader;
    final noteLoader = widget.noteLoader;
    _monthNotes = {};
    _monthPreviews = {};
    _monthItems = {};
    _monthOccurrences = {};
    _monthError = false;
    _monthLoading =
        loader != null || plannedLoader != null || noteLoader != null;
    if (!_monthLoading) {
      _groupMonth(widget.occurrences);
      return;
    }
    final start = LocalDate.fromDateTime(_month.toDateTime());
    final end = LocalDate.fromDateTime(
      JalaliDate(_month.year, _month.month, _month.monthLength).toDateTime(),
    );
    try {
      final notes =
          await noteLoader?.call(start, end.addDays(1)) ?? <CalendarNote>[];
      final planned = await plannedLoader?.call(start, end.addDays(1));
      final result =
          planned?.recorded ??
          (loader == null
              ? widget.occurrences
              : await loader(start, end.addDays(1)));
      if (!mounted || revision != _monthRevision) return;
      setState(() {
        _monthPreviews = planned?.preview ?? {};
        _monthNotes = {};
        for (final note in notes) {
          (_monthNotes[note.date] ??= []).add(note);
        }
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
    final selectedNotes = _notesFor(_selectedDay);

    final toggle = SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        key: const ValueKey('calendar-mode-toggle'),
        segments: [
          ButtonSegment(
            value: false,
            label: Text(planActL10n(context).calendarPageToggleLabel),
          ),
          ButtonSegment(
            value: true,
            label: Text(planActL10n(context).calendarPageToggleLabel2),
          ),
        ],
        selected: {_week},
        onSelectionChanged: (value) => setState(() {
          _week = value.single;
          _month = JalaliDate(_selectedDay.year, _selectedDay.month, 1);
          if (!_week) _loadMonth();
        }),
      ),
    );
    final dateButton = TextButton(
      key: const ValueKey('calendar-pick-date'),
      onPressed: () async {
        final date = await pickPlannedDate(context, _selectedDay);
        if (date == null || !mounted) return;
        setState(() {
          _selectedDay = date;
          _month = JalaliDate(date.year, date.month, 1);
          _weekPositionRevision++;
          if (!_week) _loadMonth();
        });
      },
      child: Text(planActL10n(context).calendarPageDateButtonLabel),
    );
    final todayButton = TextButton(
      key: const ValueKey('calendar-return-today'),
      onPressed: () => setState(() {
        final current = JalaliDate.now();
        _weekPositionRevision++;
        _selectedDay = current;
        _month = JalaliDate(current.year, current.month, 1);
        if (!_week) _loadMonth();
      }),
      child: Text(planActL10n(context).calendarPageTodayButtonLabel),
    );
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
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: PlanActSpacing.sm,
              children: [todayButton, if (_week) dateButton],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: PlanActSpacing.md),
          child: _CalendarHeader(
            title: _week
                ? '${PersianDateFormatter.date(dates.first)} — ${PersianDateFormatter.date(dates.last)}'
                : PersianDateFormatter.month(_month),
            previousLabel: _week
                ? planActL10n(context).calendarPageBuildTooltip
                : planActL10n(context).planactJalaliDatePickerBuildTooltip,
            nextLabel: _week
                ? planActL10n(context).calendarPageBuildTooltip2
                : planActL10n(context).planactJalaliDatePickerBuildTooltip2,
            onPrevious: () => _week
                ? setState(() => _selectedDay = _selectedDay.addDays(-7))
                : _moveMonth(-1),
            onNext: () => _week
                ? setState(() => _selectedDay = _selectedDay.addDays(7))
                : _moveMonth(1),
          ),
        ),
        Expanded(
          child: _week
              ? WeekTimelineView(
                  key: ValueKey(_weekPositionRevision),
                  date: _selectedDay,
                  commitments: widget.commitments,
                  occurrences: widget.occurrences,
                  holidays: _holidayProvider,
                  loader: widget.weekLoader,
                  plannedLoader: widget.plannedLoader,
                  onTap: widget.onCommitmentTap,
                  onAdd: widget.onAdd,
                  noteLoader: widget.noteLoader,
                  notesRevision: widget.notesRevision,
                  onNoteTap: widget.onNoteTap,
                )
              : ListView(
                  controller: _monthScroll,
                  padding: const EdgeInsets.fromLTRB(
                    PlanActSpacing.md,
                    0,
                    PlanActSpacing.md,
                    PlanActSpacing.xl,
                  ),
                  children: [
                    if (!_holidayProvider.hasCompleteOfficialCoverage(
                      _month.year,
                    ))
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: PlanActSpacing.sm,
                        ),
                        child: Text(
                          planActL10n(context).calendarPageBuildChildren,
                        ),
                      ),
                    if (_monthLoading)
                      Column(
                        children: [
                          LinearProgressIndicator(),
                          Text(planActL10n(context).calendarPageBuildChildren2),
                        ],
                      )
                    else if (_monthError)
                      Column(
                        children: [
                          Text(planActL10n(context).calendarPageBuildChildren3),
                          TextButton(
                            onPressed: () => setState(() {
                              _loadMonth();
                            }),
                            child: Text(planActL10n(context).commonRetry),
                          ),
                        ],
                      ),
                    if (!_monthLoading &&
                        !_monthError &&
                        _monthItems.isEmpty &&
                        _monthNotes.isEmpty)
                      Text(planActL10n(context).calendarPageBuildChildren4),
                    const SizedBox(height: PlanActSpacing.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final scaler = MediaQuery.textScalerOf(context);
                        // Seven columns stay in the viewport, including on narrow phones.
                        // The documented narrow-grid exception applies to width, not height.
                        final cellWidth = (constraints.maxWidth - 6 * 3) / 7;
                        final labelStyle = theme.textTheme.labelMedium
                            ?.copyWith(
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

                        final compact = PersianDateFormatter.weekdayNames.any((
                          name,
                        ) {
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
                        final markerPainter = TextPainter(
                          text: TextSpan(
                            text: planActL10n(context)
                                .calendarPageMarkerPainterText,
                            style: theme.textTheme.labelSmall,
                          ),
                          textDirection: Directionality.of(context),
                          textScaler: scaler,
                        )..layout(maxWidth: cellWidth - 8);
                        final markerHeight =
                            markerPainter.preferredLineHeight * 2 + 4;
                        markerPainter.dispose();
                        final holidayHeight = textHeight(
                          planActL10n(context).calendarPageHolidayHeightMessage,
                          theme.textTheme.labelSmall,
                        );
                        double weekHeight(int week) {
                          var height = 48.0;
                          for (var column = 0; column < 7; column++) {
                            final day = week * 7 + column - leading + 1;
                            if (day < 1 || day > _month.monthLength) continue;
                            final date = JalaliDate(
                              _month.year,
                              _month.month,
                              day,
                            );
                            final items = _commitmentsFor(date);
                            final itemCount =
                                items.length + _notesFor(date).length;
                            final hasHoliday = holidays.any(
                              (holiday) => holiday.date == date,
                            );
                            final overflowHeight = itemCount > 2
                                ? textHeight(
                                    '+${PersianNumbers.format(itemCount - 2)}',
                                    theme.textTheme.labelSmall,
                                  )
                                : 0.0;
                            height = math.max(
                              height,
                              numberHeight +
                                  (hasHoliday ? holidayHeight : 0) +
                                  math.min(itemCount, 2) * (markerHeight + 2) +
                                  overflowHeight +
                                  PlanActSpacing.sm +
                                  (date == today ? 4 : 0),
                            );
                          }
                          return height;
                        }

                        return Column(
                          children: [
                            Row(
                              children: List.generate(7, (index) {
                                final name =
                                    PersianDateFormatter.weekdayNames[index];
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
                            PlanActMonthSwipe(
                              key: const ValueKey('calendar-month-grid'),
                              onMonthStep: _moveMonth,
                              child: Column(
                                children: List.generate(cellCount ~/ 7, (week) {
                                  final height = weekHeight(week);
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      top: week == 0 ? 0 : 3,
                                    ),
                                    child: SizedBox(
                                      height: height,
                                      child: GridView.builder(
                                        padding: EdgeInsets.zero,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: 7,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 7,
                                              crossAxisSpacing: 3,
                                              mainAxisExtent: height,
                                            ),
                                        itemBuilder: (context, column) {
                                          final index = week * 7 + column;
                                          final day = index - leading + 1;
                                          if (day < 1 ||
                                              day > _month.monthLength) {
                                            return const SizedBox.shrink();
                                          }
                                          final date = JalaliDate(
                                            _month.year,
                                            _month.month,
                                            day,
                                          );
                                          final items = _commitmentsFor(date);
                                          return _CalendarDay(
                                            date: date,
                                            selected: _selectedDay == date,
                                            isToday: today == date,
                                            holidays: holidays
                                                .where(
                                                  (holiday) =>
                                                      holiday.date == date,
                                                )
                                                .toList(),
                                            commitments: items,
                                            notes: _notesFor(date),
                                            markerHeight: markerHeight,
                                            onTap: () => setState(
                                              () => _selectedDay = date,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: PlanActSpacing.lg),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
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
                    for (final holiday in _holidayProvider.holidaysFor(
                      _selectedDay,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: PlanActSpacing.xs,
                        ),
                        child: Text(
                          _holidayLabel(holiday),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: PlanActStatusColors.of(context).holiday,
                          ),
                        ),
                      ),
                    if (_monthLoading || _monthError)
                      Text(planActL10n(context).calendarPageBuildChildren5)
                    else if (selectedItems.isEmpty && selectedNotes.isEmpty)
                      Text(planActL10n(context).calendarPageBuildChildren6)
                    else
                      ...selectedItems.map(
                        (item) => CalendarCommitmentCard(
                          commitment: item,
                          occurrences: _occurrencesFor(item),
                          previews:
                              (_monthPreviews[item.id.value] ??
                                      <PlannedOccurrenceSlot>[])
                                  .where(
                                    (slot) =>
                                        JalaliDate.fromDateTime(
                                          slot.date.toUtcDateForCalculation(),
                                        ) ==
                                        _selectedDay,
                                  )
                                  .toList(),
                          reminderRules: widget.reminderRules,
                          onTap: widget.onCommitmentTap == null
                              ? null
                              : () => widget.onCommitmentTap!(item),
                        ),
                      ),
                    if (!_monthLoading && !_monthError)
                      for (final note in selectedNotes)
                        CalendarNoteTile(
                          note: note,
                          onTap: widget.onNoteTap == null
                              ? null
                              : () => widget.onNoteTap!(note),
                        ),
                  ],
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

  List<CalendarNote> _notesFor(JalaliDate date) =>
      _monthNotes[LocalDate.fromDateTime(date.toDateTime())] ?? const [];
}

String _holidayLabel(CalendarHoliday holiday) => switch (holiday.kind) {
  CalendarHolidayKind.weekend => holiday.title,
  CalendarHolidayKind.officialFixed || CalendarHolidayKind.officialVariable =>
    PersianCopy.calendarPageHolidayLabelMessage((holiday.title).toString()),
  CalendarHolidayKind.special =>
    PersianCopy.calendarPageCalendarHolidayKindSpecial(
      (holiday.scope).toString(),
      (holiday.title).toString(),
    ),
};

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.title,
    required this.previousLabel,
    required this.nextLabel,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final String previousLabel;
  final String nextLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          tooltip: previousLabel,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          tooltip: nextLabel,
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
    required this.notes,
    required this.markerHeight,
    required this.onTap,
  });

  final JalaliDate date;
  final bool selected;
  final bool isToday;
  final List<CalendarHoliday> holidays;
  final List<Commitment> commitments;
  final List<CalendarNote> notes;
  final double markerHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateLabel = PersianDateFormatter.date(date);
    final count = PersianNumbers.format(commitments.length);
    final selectionLabel = selected
        ? planActL10n(context).calendarPageSelectionLabelMessage
        : '';
    final todayLabel = isToday
        ? planActL10n(context).calendarPageTodayLabelMessage
        : '';
    final holiday = holidays.isNotEmpty;
    final holidayLabel = holiday
        ? planActL10n(context).calendarPageHolidayLabelMessage2(
            (holidays
                    .map(_holidayLabel)
                    .join(planActL10n(context).commonListSeparator))
                .toString(),
          )
        : '';
    final countLabel = commitments.isEmpty
        ? planActL10n(context).calendarPageCountLabelMessage
        : planActL10n(context)
              .calendarPageCountLabelMessage2((count).toString());
    final noteLabel = notes.isEmpty
        ? ''
        : planActL10n(context).calendarNoteDaySummary(
            PersianNumbers.format(notes.length),
            notes
                .map((note) => note.title)
                .join(planActL10n(context).commonListSeparator),
          );
    final markers = [
      for (final item in commitments)
        (
          id: item.id.value,
          title: item.title,
          color: CommitmentIdentityPalette.resolve(item.color, item.id),
        ),
      for (final note in notes)
        (id: note.id.value, title: note.title, color: note.color),
    ];
    return Semantics(
      key: ValueKey('calendar-day-${date.day}'),
      button: true,
      selected: selected,
      label:
          '${planActL10n(context).calendarPageBuildLabel2((dateLabel).toString(), (selectionLabel).toString(), (todayLabel).toString(), (holidayLabel).toString(), (countLabel).toString(), (commitments.map((item) => item.title).join(planActL10n(context).commonListSeparator)).toString())} $noteLabel',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          animationDuration: PlanActMotion.duration(
            context,
            PlanActMotion.short,
          ),
          color: selected ? scheme.primaryContainer : scheme.surface,
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
                      planActL10n(context).calendarPageHolidayHeightMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: PlanActStatusColors.of(context).holiday,
                      ),
                    ),
                  for (final item in markers.take(2))
                    Container(
                      key: ValueKey('month-title-${date.day}-${item.id}'),
                      height: markerHeight,
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: PlanActRadius.chip,
                        color: CommitmentIdentityPalette.background(
                          item.color,
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
                            item.color,
                            theme.brightness,
                          ),
                        ),
                      ),
                    ),
                  if (markers.length > 2)
                    Text(
                      '+${PersianNumbers.format(markers.length - 2)}',
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
