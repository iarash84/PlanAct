import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/presentation/planact_state_message.dart';
import 'package:planact/features/calendar/domain/calendar_visibility.dart';
import 'package:planact/features/calendar/presentation/calendar_visibility_controller.dart';

class CalendarVisibilitySettings extends StatefulWidget {
  const CalendarVisibilitySettings({super.key, required this.controller});
  final CalendarVisibilityController controller;
  @override
  State<CalendarVisibilitySettings> createState() =>
      _CalendarVisibilitySettingsState();
}

class _CalendarVisibilitySettingsState
    extends State<CalendarVisibilitySettings> {
  bool _failed = false;
  Future<void> _select(CalendarVisibility next) async {
    setState(() => _failed = false);
    try {
      await widget.controller.select(next);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final value = controller.value;
      final l10n = planActL10n(context);
      final enabled =
          controller.ready && !controller.saving && controller.settings != null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.calendarVisibilityTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: PlanActSpacing.sm),
          Card(
            child: ExpansionTile(
              key: const ValueKey('calendar-visibility-settings'),
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(l10n.calendarVisibilityItems),
              subtitle: Text(l10n.calendarVisibilityDescription),
              children: [
                for (final item in [
                  (
                    l10n.calendarVisibilityCommitments,
                    value.commitments,
                    (bool v) => value.copyWith(commitments: v),
                  ),
                  (
                    l10n.calendarVisibilityNotes,
                    value.notes,
                    (bool v) => value.copyWith(notes: v),
                  ),
                  (
                    l10n.calendarVisibilityIncome,
                    value.income,
                    (bool v) => value.copyWith(income: v),
                  ),
                  (
                    l10n.calendarVisibilityExpense,
                    value.expense,
                    (bool v) => value.copyWith(expense: v),
                  ),
                  (
                    l10n.calendarVisibilityTransfers,
                    value.transfers,
                    (bool v) => value.copyWith(transfers: v),
                  ),
                ])
                  SwitchListTile(
                    title: Text(item.$1),
                    value: item.$2,
                    onChanged: enabled ? (v) => _select(item.$3(v)) : null,
                  ),
              ],
            ),
          ),
          if (controller.saving ||
              (!controller.ready && !controller.loadFailed))
            const LinearProgressIndicator(),
          if (controller.loadFailed)
            PlanActStateMessage(
              message: l10n.calendarVisibilityLoadError,
              kind: PlanActMessageKind.error,
              action: TextButton(
                onPressed: controller.load,
                child: Text(l10n.commonRetry),
              ),
            ),
          if (_failed)
            PlanActStateMessage(
              message: l10n.calendarVisibilityError,
              kind: PlanActMessageKind.error,
            ),
        ],
      );
    },
  );
}
