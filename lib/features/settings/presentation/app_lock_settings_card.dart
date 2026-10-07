import 'package:flutter/material.dart';

/// The callback authenticates and persists before this control reports success.
class AppLockSettingsCard extends StatefulWidget {
  const AppLockSettingsCard({
    super.key,
    required this.enabled,
    required this.change,
  });

  final bool enabled;
  final Future<void> Function(bool)? change;

  @override
  State<AppLockSettingsCard> createState() => _AppLockSettingsCardState();
}

class _AppLockSettingsCardState extends State<AppLockSettingsCard> {
  bool _busy = false;
  String? _message;

  Future<void> _change(bool enabled) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.change!(enabled);
      if (mounted) {
        setState(
          () => _message = enabled
              ? 'قفل برنامه فعال شد.'
              : 'قفل برنامه غیرفعال شد.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'تغییر قفل انجام نشد. احراز هویت و قفل دستگاه را بررسی و دوباره تلاش کنید.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.lock_outline),
          title: const Text('قفل برنامه'),
          subtitle: Text(
            _busy ? 'در حال تأیید و ذخیره…' : 'ورود و بازگشت به برنامه با اثر انگشت یا رمز قفل دستگاه؛ تغییر این گزینه نیز نیازمند تأیید هویت است.',
          ),
          value: widget.enabled,
          onChanged: _busy || widget.change == null ? null : _change,
        ),
        if (_message != null)
          ListTile(title: Semantics(liveRegion: true, child: Text(_message!))),
      ],
    ),
  );
}
