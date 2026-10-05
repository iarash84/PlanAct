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
              ? 'مجوزها فعال شدند و یادآوری‌های آینده دوباره زمان‌بندی شدند.'
              : 'مجوز اعلان یا زنگ دقیق فعال نیست. یادآوری‌ها ذخیره شده‌اند؛ مجوزها را بررسی کنید و دوباره تلاش کنید.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'فعال‌سازی یادآوری‌ها انجام نشد. اطلاعات شما محفوظ است؛ دوباره تلاش کنید.',
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
        const ListTile(
          leading: Icon(Icons.notifications_outlined),
          title: Text('یادآوری‌های دستگاه'),
          subtitle: Text(
            'برای نمایش به‌موقع یادآوری‌ها، اجازهٔ اعلان و زنگ دقیق لازم است. ثبت و نگهداری تعهدها به این مجوزها وابسته نیست.',
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
                      ? 'در حال بررسی مجوزها'
                      : 'فعال‌سازی و بازسازی یادآوری‌ها',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
