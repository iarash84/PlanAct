import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:flutter/material.dart';

/// Explicit user action is the only entry point to Android permission prompts.
class ReminderPermissionsCard extends StatefulWidget {
  const ReminderPermissionsCard({super.key, required this.enable});
  final Future<bool> Function() enable;

  @override
  State<ReminderPermissionsCard> createState() =>
      _ReminderPermissionsCardState();
}

class _ReminderPermissionsCardState extends State<ReminderPermissionsCard> {
  bool _busy = false;
  String? _message;

  Future<void> _enable() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final allowed = await widget.enable();
      if (mounted) {
        setState(
          () => _message = allowed
              ? PersianCopy.reminderPermissionsCardEnableMessage
              : PersianCopy.reminderPermissionsCardEnableMessage2,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = PersianCopy.reminderPermissionsCardEnableMessage3,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(Icons.notifications_outlined),
          title: Text(planActL10n(context).reminderPermissionsCardBuildTitle),
          subtitle: Text(
            planActL10n(context).reminderPermissionsCardBuildSubtitle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_message != null) Text(_message!),
              FilledButton.icon(
                onPressed: _busy ? null : _enable,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(),
                      )
                    : const Icon(Icons.notifications_active_outlined),
                label: Text(
                  _busy
                      ? planActL10n(context).reminderPermissionsCardBuildLabel
                      : planActL10n(context).reminderPermissionsCardBuildLabel2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
