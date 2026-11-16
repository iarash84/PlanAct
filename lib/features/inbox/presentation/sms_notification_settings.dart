import 'package:flutter/material.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/inbox/application/sms_detection_notifications.dart';
import 'package:planact/features/inbox/data/android_sms_detection_notifications.dart';

class SmsNotificationSettings extends StatefulWidget {
  const SmsNotificationSettings({super.key, required this.notifications});
  final SmsDetectionNotifications notifications;
  @override
  State<SmsNotificationSettings> createState() =>
      _SmsNotificationSettingsState();
}

class _SmsNotificationSettingsState extends State<SmsNotificationSettings> {
  SmsDetectionNotificationState? _state;
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final state = SmsDetectionNotificationState.decode(
        await widget.notifications.store.read(),
      );
      if (mounted) {
        setState(() {
          _state = state;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _save({bool? enabled, bool? amounts}) async {
    if (_busy || _state == null) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      if (enabled == true &&
          widget.notifications.platform is AndroidSmsDetectionNotifications) {
        if (!await (widget.notifications.platform
                as AndroidSmsDetectionNotifications)
            .requestPermission()) {
          throw StateError('Notification permission not granted');
        }
      }
      await widget.notifications.configure(
        enabled: enabled ?? _state!.enabled,
        showAmounts: amounts ?? _state!.showAmounts,
      );
      await _load();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      // A delivery failure may follow a committed preference. Reload durable state.
      try {
        final state = SmsDetectionNotificationState.decode(
          await widget.notifications.store.read(),
        );
        if (mounted) setState(() => _state = state);
      } catch (_) {
        // Retain the last usable snapshot; the retry remains visible.
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: Text(l10n.smsDetectionEnabled),
            subtitle: Text(l10n.smsDetectionPrivacy),
            value: _state?.enabled ?? false,
            onChanged: _busy || _state == null
                ? null
                : (value) => _save(enabled: value),
          ),
          SwitchListTile(
            title: Text(l10n.smsDetectionAmounts),
            value: _state?.showAmounts ?? false,
            onChanged: _busy || _state == null
                ? null
                : (value) => _save(amounts: value),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_failed)
            ListTile(
              title: Text(l10n.smsDetectionFailure),
              onTap: _busy ? null : _load,
              trailing: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }
}
