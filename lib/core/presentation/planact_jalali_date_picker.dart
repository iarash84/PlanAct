import 'package:flutter/material.dart';
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
    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _month = _month.addMonths(-1)),
            icon: const Icon(Icons.chevron_right),
          ),
          Expanded(
            child: Center(child: Text(PersianDateFormatter.month(_month))),
          ),
          IconButton(
            onPressed: () => setState(() => _month = _month.addMonths(1)),
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: count,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemBuilder: (_, index) {
            if (index < offset) return const SizedBox();
            final day = index - offset + 1;
            final date = JalaliDate(_month.year, _month.month, day);
            final selected = date == _selected;
            return InkWell(
              key: ValueKey('capture-date-$day'),
              onTap: () => Navigator.pop(context, date.toDateTime()),
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: selected
                      ? BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Text(
                    PersianNumbers.format(day),
                    style: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                  ),
                ),
              ),
            );
          },
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
