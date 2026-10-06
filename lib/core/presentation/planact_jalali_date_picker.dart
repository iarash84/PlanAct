import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';

class PlanActJalaliDatePicker extends StatefulWidget {
  const PlanActJalaliDatePicker({super.key, required this.initialDate});
  final DateTime initialDate;
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

  @override
  Widget build(BuildContext context) {
    final offset = _month.weekDay - 1;
    final count = offset + _month.monthLength;
    final scheme = Theme.of(context).colorScheme;
    final cellSize = math.max(
      PlanActSpacing.touchTarget,
      MediaQuery.textScalerOf(context).scale(24) + PlanActSpacing.lg,
    );
    return AlertDialog(
      scrollable: true,
      title: Column(
        children: [
          Text(PersianDateFormatter.month(_month), textAlign: TextAlign.center),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'ماه قبل',
                onPressed: () => setState(() => _month = _month.addMonths(-1)),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: 'ماه بعد',
                onPressed: () => setState(() => _month = _month.addMonths(1)),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 7 * cellSize,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 7 * cellSize,
            height: ((count + 6) ~/ 7) * cellSize,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: count,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: cellSize,
              ),
              itemBuilder: (_, index) {
                if (index < offset) return const SizedBox();
                final day = index - offset + 1;
                final date = JalaliDate(_month.year, _month.month, day);
                final selected = date == _selected;
                return Semantics(
                  label: PersianDateFormatter.date(date),
                  selected: selected,
                  button: true,
                  child: InkWell(
                    key: ValueKey('capture-date-$day'),
                    onTap: () => Navigator.pop(context, date.toDateTime()),
                    child: Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.all(PlanActSpacing.xs),
                      decoration: selected
                          ? BoxDecoration(
                              color: scheme.primaryContainer,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: Text(
                        PersianNumbers.format(day),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
      ],
    );
  }
}
