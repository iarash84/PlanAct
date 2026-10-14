import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/presentation/holiday_provider_scope.dart';
import 'package:planact/core/presentation/planact_month_swipe.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';

class PlanActJalaliDatePicker extends StatefulWidget {
  const PlanActJalaliDatePicker({
    super.key,
    required this.initialDate,
    this.holidayProvider,
  });
  final DateTime initialDate;
  final IranianHolidayProvider? holidayProvider;
  @override
  State<PlanActJalaliDatePicker> createState() =>
      PlanActJalaliDatePickerState();
}

class PlanActJalaliDatePickerState extends State<PlanActJalaliDatePicker> {
  late JalaliDate _selected;
  late JalaliDate _month;

  @override
  void initState() {
    super.initState();
    _selected = JalaliDate.fromDateTime(widget.initialDate);
    _month = JalaliDate(_selected.year, _selected.month, 1);
  }

  static String _kindLabel(CalendarHolidayKind kind) => switch (kind) {
    CalendarHolidayKind.weekend =>
      PersianCopy.planactJalaliDatePickerCalendarHolidayKindWeekend,
    CalendarHolidayKind.officialFixed || CalendarHolidayKind.officialVariable =>
      PersianCopy.planactJalaliDatePickerKindLabelMessage,
    CalendarHolidayKind.special =>
      PersianCopy.planactJalaliDatePickerCalendarHolidayKindSpecial,
  };

  static IconData _kindIcon(CalendarHolidayKind kind) => switch (kind) {
    CalendarHolidayKind.weekend => Icons.weekend_outlined,
    CalendarHolidayKind.officialFixed ||
    CalendarHolidayKind.officialVariable => Icons.event_busy_outlined,
    CalendarHolidayKind.special => Icons.location_off_outlined,
  };

  String _dateLabel(JalaliDate date) =>
      '${PersianDateFormatter.date(date)} ${PersianNumbers.format(date.year)}';

  @override
  Widget build(BuildContext context) {
    final provider = widget.holidayProvider ?? HolidayProviderScope.of(context);
    final offset = _month.weekDay - 1;
    final count = offset + _month.monthLength;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = PlanActStatusColors.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final holidays = provider.holidaysFor(_selected);
    // Only the dense seven-column grid has the approved touch-width exception.
    // Number/marker height grows with text scale; no forced 80dp columns or
    // independent information target under each day.
    final painter = TextPainter(
      text: TextSpan(
        text: PersianNumbers.format(31),
        style: theme.textTheme.bodyMedium,
      ),
      textDirection: TextDirection.rtl,
      textScaler: scaler,
    )..layout();
    final cellHeight = math.max(
      PlanActSpacing.touchTarget,
      painter.height + 16 + PlanActSpacing.xs,
    );
    painter.dispose();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: PlanActSpacing.md,
          vertical: PlanActSpacing.lg,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PlanActSpacing.md,
          vertical: PlanActSpacing.sm,
        ),
        scrollable: true,
        title: Row(
          children: [
            IconButton(
              tooltip: planActL10n(context).planactJalaliDatePickerBuildTooltip,
              onPressed: () => setState(() => _month = _month.addMonths(-1)),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                PersianDateFormatter.month(_month),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: planActL10n(context)
                  .planactJalaliDatePickerBuildTooltip2,
              onPressed: () => setState(() => _month = _month.addMonths(1)),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Builder(
                builder: (context) {
                  // AlertDialog measures intrinsic dimensions; LayoutBuilder
                  // cannot participate in that pass. Account for the explicit
                  // dialog insets and content padding before measuring labels.
                  final width =
                      math.min(
                        420.0,
                        MediaQuery.sizeOf(context).width -
                            4 * PlanActSpacing.md,
                      ) /
                      7;
                  var fullNamesFit = true;
                  for (final name in PersianDateFormatter.weekdayNames) {
                    final heading = TextPainter(
                      text: TextSpan(
                        text: name,
                        style: theme.textTheme.labelMedium,
                      ),
                      textDirection: TextDirection.rtl,
                      textScaler: scaler,
                    )..layout();
                    if (heading.width + PlanActSpacing.xs > width) {
                      fullNamesFit = false;
                    }
                    heading.dispose();
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          for (var index = 0; index < 7; index++)
                            Expanded(
                              child: Semantics(
                                header: true,
                                label: PersianDateFormatter.weekdayNames[index],
                                child: ExcludeSemantics(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: PlanActSpacing.sm,
                                    ),
                                    child: Text(
                                      fullNamesFit
                                          ? PersianDateFormatter
                                                .weekdayNames[index]
                                          : PersianDateFormatter
                                                .compactWeekdayNames[index],
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      PlanActMonthSwipe(
                        onMonthStep: (step) =>
                            setState(() => _month = _month.addMonths(step)),
                        child: SizedBox(
                          key: const ValueKey('date-picker-grid'),
                          height: ((count + 6) ~/ 7) * cellHeight,
                          child: GridView.builder(
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: count,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisExtent: cellHeight,
                                ),
                            itemBuilder: (_, index) {
                              if (index < offset) return const SizedBox();
                              final day = index - offset + 1;
                              final date = JalaliDate(
                                _month.year,
                                _month.month,
                                day,
                              );
                              final selected = date == _selected;
                              final reasons = provider.holidaysFor(date);
                              final kinds = reasons
                                  .map((h) => _kindIcon(h.kind))
                                  .toSet();
                              return Semantics(
                                label:
                                    [
                                      _dateLabel(date),
                                      ...reasons.map(
                                        (h) =>
                                            '${_kindLabel(h.kind)}: ${h.title}',
                                      ),
                                    ].join(
                                      planActL10n(context).commonListSeparator,
                                    ),
                                selected: selected,
                                button: true,
                                child: InkWell(
                                  key: ValueKey('capture-date-$day'),
                                  onTap: () => setState(() => _selected = date),
                                  child: ExcludeSemantics(
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: selected
                                          ? BoxDecoration(
                                              color: scheme.primaryContainer,
                                              shape: BoxShape.circle,
                                            )
                                          : null,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            PersianNumbers.format(day),
                                            maxLines: 1,
                                            softWrap: false,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: selected
                                                      ? scheme
                                                            .onPrimaryContainer
                                                      : reasons.isNotEmpty
                                                      ? status.holiday
                                                      : scheme.onSurface,
                                                ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              if (selected && kinds.isEmpty)
                                                Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color:
                                                      scheme.onPrimaryContainer,
                                                ),
                                              for (final icon in kinds)
                                                Icon(
                                                  icon,
                                                  size: 12,
                                                  color: selected
                                                      ? scheme
                                                            .onPrimaryContainer
                                                      : status.holiday,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: PlanActSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  _dateLabel(_selected),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              for (final holiday in holidays)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _kindIcon(holiday.kind),
                      size: 16,
                      color: status.holiday,
                    ),
                    const SizedBox(width: PlanActSpacing.xs),
                    Expanded(
                      child: Text(
                        '${_kindLabel(holiday.kind)}: ${holiday.title}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              if (holidays.isNotEmpty)
                ExpansionTile(
                  key: const ValueKey('date-reasons'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    planActL10n(context).planactJalaliDatePickerBuildTitle,
                  ),
                  children: [
                    for (final holiday in holidays)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          planActL10n(context)
                              .planactJalaliDatePickerBuildChildren(
                                (holiday.title).toString(),
                                (holiday.source).toString(),
                                (holiday.version).toString(),
                                (holiday.scope).toString(),
                              ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              if (!provider.hasCompleteOfficialCoverage(_month.year))
                Semantics(
                  liveRegion: true,
                  child: Text(
                    planActL10n(context).planactJalaliDatePickerBuildChildren2,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: status.attention,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(planActL10n(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _selected.toDateTime()),
            child: Text(
              planActL10n(context).planactJalaliDatePickerBuildActions,
            ),
          ),
        ],
      ),
    );
  }
}
