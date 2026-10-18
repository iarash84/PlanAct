import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/reminders/domain/reminder.dart';

class ReminderDeliveryPicker extends StatelessWidget {
  const ReminderDeliveryPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final ReminderDelivery value;
  final ValueChanged<ReminderDelivery> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.reminderDeliveryLabel),
        Wrap(
          spacing: PlanActSpacing.sm,
          children: [
            for (final delivery in ReminderDelivery.values)
              ChoiceChip(
                avatar: Icon(
                  delivery == ReminderDelivery.alarm
                      ? Icons.alarm
                      : Icons.notifications_outlined,
                ),
                label: Text(
                  delivery == ReminderDelivery.alarm
                      ? l10n.reminderDeliveryAlarm
                      : l10n.reminderDeliveryNotification,
                ),
                selected: value == delivery,
                onSelected: (_) => onChanged(delivery),
              ),
          ],
        ),
        if (value == ReminderDelivery.alarm) Text(l10n.reminderAlarmHelp),
      ],
    );
  }
}
