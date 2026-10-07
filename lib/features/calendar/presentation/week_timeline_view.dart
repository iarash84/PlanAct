import 'package:planact/features/scheduling/presentation/occurrence_status_label.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/app/theme/commitment_identity_palette.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/application/week_timeline.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/presentation/commitment_identity_marker.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

abstract final class WeekTimelineGeometry {
  static const hourHeight = 120.0;
  static const minimumDayWidth = 112.0;
  static const minimumLaneWidth = 112.0;
  static const gutterWidth = 64.0;
  static double top(double minute) => minute * hourHeight / 60;
}

String calendarStatusLabel(OccurrenceStatus status) =>
    occurrenceStatusLabel(status);
IconData calendarStatusIcon(OccurrenceStatus status) => switch (status) {
  OccurrenceStatus.completed => Icons.check_circle_outline,
  OccurrenceStatus.cancelled => Icons.cancel_outlined,
  OccurrenceStatus.skipped => Icons.person_off_outlined,
  OccurrenceStatus.overdue => Icons.history,
  OccurrenceStatus.rescheduled => Icons.swap_horiz,
  OccurrenceStatus.deferred => Icons.update,
  OccurrenceStatus.pendingDecision => Icons.help_outline,
  OccurrenceStatus.due => Icons.notifications_active_outlined,
  OccurrenceStatus.scheduled => Icons.schedule,
};

class WeekTimelineView extends StatefulWidget {
  const WeekTimelineView({
    super.key,
    required this.date,
    required this.commitments,
    required this.occurrences,
    required this.holidays,
    this.loader,
    this.onTap,
    this.onAdd,
  });
  final JalaliDate date;
  final List<Commitment> commitments;
  final Map<String, List<Occurrence>> occurrences;
  final IranianHolidayProvider holidays;
  final Future<Map<String, List<Occurrence>>> Function(LocalDate)? loader;
  final ValueChanged<Commitment>? onTap;
  final VoidCallback? onAdd;
  @override
  State<WeekTimelineView> createState() => _WeekTimelineViewState();
}

class _WeekTimelineViewState extends State<WeekTimelineView> {
  late final ScrollController _vertical;
  final _agendaScroll = ScrollController();
  final _dayKeys = List.generate(7, (_) => GlobalKey());
  final _dayBodyKeys = List.generate(7, (_) => GlobalKey());
  bool _positionAgenda = true;
  final _headerScroll = ScrollController();
  final _bodyScroll = ScrollController();
  bool _syncing = false;
  Future<Map<String, List<Occurrence>>>? _future;
  void _sync(ScrollController source, ScrollController target) {
    if (_syncing || !source.hasClients || !target.hasClients) return;
    _syncing = true;
    target.jumpTo(source.offset.clamp(0, target.position.maxScrollExtent));
    _syncing = false;
  }

  @override
  void initState() {
    super.initState();
    _vertical = ScrollController(
      initialScrollOffset: WeekTimelineGeometry.top(
        WeekTimeline.initialMinute(widget.date, DateTime.now()),
      ),
    );
    _headerScroll.addListener(() => _sync(_headerScroll, _bodyScroll));
    _bodyScroll.addListener(() => _sync(_bodyScroll, _headerScroll));
    _load();
  }

  bool _resetScroll = false;

  void _load() {
    final loader = widget.loader;
    _future = loader == null
        ? null
        : Future.sync(
            () => loader(
              WeekTimeline.localDate(WeekTimeline.startOfWeek(widget.date)),
            ),
          );
  }

  @override
  void didUpdateWidget(WeekTimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date ||
        oldWidget.occurrences != widget.occurrences ||
        oldWidget.commitments != widget.commitments ||
        oldWidget.loader != widget.loader) {
      _load();
      if (oldWidget.date != widget.date) {
        _resetScroll = true;
        _positionAgenda = true;
      }
    }
  }

  @override
  void dispose() {
    _vertical.dispose();
    _agendaScroll.dispose();
    _headerScroll.dispose();
    _bodyScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) return _content(widget.occurrences);
    return FutureBuilder<Map<String, List<Occurrence>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(semanticsLabel: 'بارگذاری هفته'),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('بارگذاری هفته انجام نشد.'),
                TextButton(
                  onPressed: () => setState(_load),
                  child: const Text('تلاش دوباره'),
                ),
              ],
            ),
          );
        }
        return _content(snapshot.data ?? const {});
      },
    );
  }

  Widget _content(Map<String, List<Occurrence>> data) {
    if (_resetScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _resetScroll && _vertical.hasClients) {
          _resetScroll = false;
          _vertical.jumpTo(
            WeekTimelineGeometry.top(
              WeekTimeline.initialMinute(widget.date, DateTime.now()),
            ).clamp(0, _vertical.position.maxScrollExtent),
          );
        }
      });
    }
    final days = WeekTimeline.dates(widget.date);
    final entries = <String, (Commitment, Occurrence)>{};
    for (final commitment in widget.commitments) {
      for (final occurrence in data[commitment.id.value] ?? <Occurrence>[]) {
        final day = JalaliDate.fromDateTime(
          WeekTimeline.displayDate(occurrence.currentScheduledAt),
        );
        if (days.contains(day)) {
          entries[occurrence.id.value] = (commitment, occurrence);
        }
      }
    }
    final scaler = MediaQuery.textScalerOf(context);
    final theme = Theme.of(context);
    double measured(String text, TextStyle? style, double width) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout(maxWidth: width);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final laneWidth =
        WeekTimelineGeometry.minimumLaneWidth * math.max(1, scaler.scale(1));
    // A visual footprint, never an inferred scheduled duration.
    final cardHeight = math.max(
      96.0,
      measured('عنوان', theme.textTheme.titleMedium, laneWidth - 16) +
          measured('۲۳:۵۹', theme.textTheme.bodySmall, laneWidth - 16) +
          OccurrenceStatus.values
              .map(
                (s) => measured(
                  calendarStatusLabel(s),
                  theme.textTheme.bodySmall,
                  laneWidth - 38,
                ),
              )
              .reduce(math.max) +
          20,
    );
    final segments = [
      for (final entry in entries.entries)
        if (entry.value.$2.currentScheduledAt is DateTime)
          ...segmentTimelineSpan(
            TimelineSpan(
              entry.key,
              WeekTimeline.displayDate(entry.value.$2.currentScheduledAt),
            ),
          ),
    ];
    final lanes = layoutTimelineLanes(
      segments,
      pointFootprintMinutes:
          (cardHeight + 4) * 60 / WeekTimelineGeometry.hourHeight,
    );
    final maxLanes = lanes.fold<int>(
      1,
      (value, lane) => math.max(value, lane.laneCount),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use actual available width, including text scaling and point lanes.
        // Dense starts are not conflicts; prefer readable rows over wider columns.
        if (constraints.maxWidth <
            WeekTimelineGeometry.gutterWidth + 7 * laneWidth * maxLanes) {
          return _agenda(
            days,
            entries.values.toList(),
            constraints.maxWidth,
            constraints.maxHeight,
          );
        }
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(PlanActSpacing.sm),
              child: Text(
                'کارت‌ها زمان شروع را نشان می‌دهند؛ زمان پایان ثبت نشده است.',
              ),
            ),
            if (entries.isEmpty)
              const Text('برای این هفته رخدادی ثبت نشده است.'),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.max(
                    (constraints.maxWidth - WeekTimelineGeometry.gutterWidth) /
                        7,
                    laneWidth * maxLanes,
                  );
                  // The all-day region scrolls independently for dense days; headers stay
                  // above hours. Header and body horizontal offsets are synchronized.
                  final headerHeight = math.min(
                    constraints.maxHeight * .4,
                    math.max(120.0, scaler.scale(16) * 5),
                  );
                  final timelineHeight =
                      24 * WeekTimelineGeometry.hourHeight + cardHeight;
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: WeekTimelineGeometry.gutterWidth,
                            height: headerHeight,
                            child: const Center(child: Text('تمام‌روز')),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              key: const ValueKey('week-header-scroll'),
                              controller: _headerScroll,
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final day in days)
                                    SizedBox(
                                      width: width,
                                      height: headerHeight,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            Text(
                                              PersianDateFormatter.date(day),
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    color:
                                                        widget.holidays
                                                            .holidaysFor(day)
                                                            .isNotEmpty
                                                        ? PlanActStatusColors.of(
                                                            context,
                                                          ).holiday
                                                        : null,
                                                  ),
                                            ),
                                            for (final holiday
                                                in widget.holidays.holidaysFor(
                                                  day,
                                                ))
                                              Text(
                                                holiday.title,
                                                textAlign: TextAlign.center,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color:
                                                          PlanActStatusColors.of(
                                                            context,
                                                          ).holiday,
                                                    ),
                                              ),
                                            if (!widget.holidays
                                                .hasCompleteOfficialCoverage(
                                                  day.year,
                                                ))
                                              const Text(
                                                'دادهٔ تعطیلات کامل نیست؛ نبود نشان تعطیلی به معنی روز کاری قطعی نیست.',
                                              ),
                                            for (final entry in entries.values)
                                              if (entry.$2.currentScheduledAt
                                                      is LocalDate &&
                                                  JalaliDate.fromDateTime(
                                                        WeekTimeline.displayDate(
                                                          entry
                                                              .$2
                                                              .currentScheduledAt,
                                                        ),
                                                      ) ==
                                                      day)
                                                _card(entry.$1, entry.$2, null),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('week-hour-scroll'),
                          controller: _vertical,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: WeekTimelineGeometry.gutterWidth,
                                height: timelineHeight,
                                child: Stack(
                                  children: [
                                    for (var hour = 0; hour < 24; hour++)
                                      Positioned(
                                        top:
                                            hour *
                                            WeekTimelineGeometry.hourHeight,
                                        left: 0,
                                        right: 0,
                                        child: Text(
                                          PersianNumbers.format(
                                            '${hour.toString().padLeft(2, '0')}:00',
                                          ),
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.labelMedium,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  key: const ValueKey('week-body-scroll'),
                                  controller: _bodyScroll,
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (final day in days)
                                        SizedBox(
                                          width: width,
                                          height: timelineHeight,
                                          child: Stack(
                                            children: [
                                              for (
                                                var hour = 0;
                                                hour < 24;
                                                hour++
                                              )
                                                Positioned(
                                                  top:
                                                      hour *
                                                      WeekTimelineGeometry
                                                          .hourHeight,
                                                  left: 0,
                                                  right: 0,
                                                  child: const Divider(
                                                    height: 1,
                                                  ),
                                                ),
                                              for (final lane in lanes)
                                                if (lane.segment.day == day)
                                                  PositionedDirectional(
                                                    top:
                                                        WeekTimelineGeometry.top(
                                                          lane
                                                              .segment
                                                              .startMinute,
                                                        ),
                                                    start:
                                                        lane.lane *
                                                        width /
                                                        lane.laneCount,
                                                    width:
                                                        width / lane.laneCount,
                                                    height: cardHeight,
                                                    child: _card(
                                                      entries[lane.segment.id]!
                                                          .$1,
                                                      entries[lane.segment.id]!
                                                          .$2,
                                                      lane.segment.startMinute,
                                                    ),
                                                  ),
                                              Positioned.fill(
                                                child: IgnorePointer(
                                                  child: _CurrentTimeIndicator(
                                                    day: day,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _agenda(
    List<JalaliDate> days,
    List<(Commitment, Occurrence)> entries,
    double width,
    double viewportHeight,
  ) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleMedium!;
    var headingHeight = 48.0;
    for (final day in days) {
      final painter = TextPainter(
        text: TextSpan(
          text: '${PersianDateFormatter.date(day)} · امروز',
          style: style,
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: math.max(1, width - 2 * PlanActSpacing.lg));
      headingHeight = math.max(
        headingHeight,
        painter.height + 2 * PlanActSpacing.sm,
      );
      painter.dispose();
    }
    if (_positionAgenda) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_agendaScroll.hasClients || !_positionAgenda) return;
        final today = days.indexOf(JalaliDate.now());
        var offset = 0.0;
        for (var index = 0; index < (today < 0 ? 0 : today); index++) {
          final body =
              _dayBodyKeys[index].currentContext?.findRenderObject()
                  as RenderSliver?;
          if (body?.geometry == null) return;
          offset += headingHeight + body!.geometry!.scrollExtent;
        }
        _agendaScroll.jumpTo(
          offset.clamp(0, _agendaScroll.position.maxScrollExtent),
        );
        _positionAgenda = false;
      });
    }
    final todayIndex = days.indexOf(JalaliDate.now());
    final initialDay = todayIndex < 0 ? 0 : todayIndex;
    return CustomScrollView(
      key: const ValueKey('week-agenda-scroll'),
      // Only seven durable days are loaded. Lay out that bounded content so the
      // initial day can be revealed exactly, including dense earlier days.
      scrollCacheExtent: const ScrollCacheExtent.pixels(double.maxFinite),
      controller: _agendaScroll,
      slivers: [
        for (var index = 0; index < days.length; index++)
          SliverMainAxisGroup(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _AgendaDayHeading(
                  height: headingHeight,
                  child: Material(
                    key: _dayKeys[index],
                    color: days[index] == JalaliDate.now()
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PlanActSpacing.lg,
                        vertical: PlanActSpacing.sm,
                      ),
                      child: Semantics(
                        header: true,
                        child: Text(
                          '${PersianDateFormatter.date(days[index])}${days[index] == JalaliDate.now() ? ' · امروز' : ''}',
                          style: style.copyWith(
                            color: days[index] == JalaliDate.now()
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                key: _dayBodyKeys[index],
                child: Padding(
                  padding: const EdgeInsets.all(PlanActSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (entries.isEmpty && index == initialDay) ...[
                        const Text('برای این هفته رخدادی ثبت نشده است.'),
                        if (widget.onAdd != null)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              onPressed: widget.onAdd,
                              icon: const Icon(Icons.add),
                              label: const Text('افزودن سریع'),
                            ),
                          ),
                      ],
                      for (final holiday in widget.holidays.holidaysFor(
                        days[index],
                      ))
                        Text(
                          holiday.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: PlanActStatusColors.of(context).holiday,
                          ),
                        ),
                      if (!widget.holidays.hasCompleteOfficialCoverage(
                        days[index].year,
                      ))
                        const Text(
                          'دادهٔ تعطیلات کامل نیست؛ نبود نشان تعطیلی به معنی روز کاری قطعی نیست.',
                        ),
                      ..._agendaEntries(days[index], entries),
                    ],
                  ),
                ),
              ),
            ],
          ),
        // Allow Friday/today to align at the top without hiding earlier days.
        SliverToBoxAdapter(child: SizedBox(height: viewportHeight)),
      ],
    );
  }

  List<Widget> _agendaEntries(
    JalaliDate day,
    List<(Commitment, Occurrence)> entries,
  ) {
    final items =
        entries
            .where(
              (entry) =>
                  JalaliDate.fromDateTime(
                    WeekTimeline.displayDate(entry.$2.currentScheduledAt),
                  ) ==
                  day,
            )
            .toList()
          ..sort((a, b) {
            final aStart = a.$2.currentScheduledAt;
            final bStart = b.$2.currentScheduledAt;
            if (aStart is LocalDate && bStart is! LocalDate) return -1;
            if (bStart is LocalDate && aStart is! LocalDate) return 1;
            final order = WeekTimeline.displayDate(aStart)
                .compareTo(WeekTimeline.displayDate(bStart));
            return order != 0 ? order : a.$2.id.value.compareTo(b.$2.id.value);
          });
    if (items.isEmpty) return [const Text('رخدادی ثبت نشده است.')];
    return [for (final entry in items) _agendaRow(entry.$1, entry.$2)];
  }

  Widget _agendaRow(Commitment commitment, Occurrence occurrence) {
    final theme = Theme.of(context);
    final start = occurrence.currentScheduledAt;
    final dateTime = WeekTimeline.displayDate(start);
    final time = start is LocalDate
        ? 'تمام‌روز'
        : PersianNumbers.format(
            '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
          );
    return Material(
      key: ValueKey('week-card-${occurrence.id.value}'),
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: widget.onTap == null ? null : () => widget.onTap!(commitment),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: PlanActSpacing.md,
              horizontal: PlanActSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommitmentIdentityMarker(commitment: commitment),
                const SizedBox(width: PlanActSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(time, style: theme.textTheme.labelLarge),
                      Text(
                        commitment.title,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: PlanActSpacing.xs),
                      Row(
                        children: [
                          Icon(calendarStatusIcon(occurrence.status)),
                          const SizedBox(width: PlanActSpacing.xs),
                          Expanded(
                            child: Text(
                              calendarStatusLabel(occurrence.status),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(Commitment commitment, Occurrence occurrence, double? minute) {
    final theme = Theme.of(context);
    final color = CommitmentIdentityPalette.resolve(
      commitment.color,
      commitment.id,
    );
    final foreground = CommitmentIdentityPalette.foreground(
      color,
      theme.brightness,
    );
    final time = minute == null
        ? 'تمام‌روز (بدون ساعت)'
        : PersianNumbers.format(
            '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute.toInt() % 60).toString().padLeft(2, '0')}',
          );
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        key: ValueKey('week-card-${occurrence.id.value}'),
        color: CommitmentIdentityPalette.background(color, theme.brightness),
        borderRadius: PlanActRadius.chip,
        child: InkWell(
          onTap: widget.onTap == null ? null : () => widget.onTap!(commitment),
          borderRadius: PlanActRadius.chip,
          child: Semantics(
            button: true,
            label:
                '${commitment.title}، $time، ${calendarStatusLabel(occurrence.status)}، ${minute == null ? '' : 'زمان پایان ثبت نشده'}',
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.all(PlanActSpacing.xs),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: commitment.title,
                        child: Text(
                          commitment.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: foreground,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: foreground,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            calendarStatusIcon(occurrence.status),
                            color: foreground,
                            size: 18,
                          ),
                          const SizedBox(width: PlanActSpacing.xs),
                          Expanded(
                            child: Text(
                              calendarStatusLabel(occurrence.status),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: foreground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgendaDayHeading extends SliverPersistentHeaderDelegate {
  const _AgendaDayHeading({required this.height, required this.child});
  final double height;
  final Widget child;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox.expand(child: child);
  @override
  bool shouldRebuild(_AgendaDayHeading oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

class _CurrentTimeIndicator extends StatefulWidget {
  const _CurrentTimeIndicator({required this.day});
  final JalaliDate day;
  @override
  State<_CurrentTimeIndicator> createState() => _CurrentTimeIndicatorState();
}

class _CurrentTimeIndicatorState extends State<_CurrentTimeIndicator> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minute = WeekTimeline.indicatorMinute(widget.day, _now);
    return Stack(
      children: [
        if (minute != null)
          Positioned(
            top: WeekTimelineGeometry.top(minute),
            left: 0,
            right: 0,
            child: Semantics(
              label: 'زمان اکنون',
              child: Container(
                height: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
