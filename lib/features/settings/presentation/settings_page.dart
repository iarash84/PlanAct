import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:flutter/material.dart';
import 'package:planact/features/reminders/presentation/reminder_permissions_card.dart';
import 'package:planact/features/backup/application/backup_actions.dart';
import 'package:planact/app/app_lock.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/features/settings/presentation/app_lock_settings_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.holidayPackages,
    this.onHolidaysChanged,
    this.settings,
    this.backupActions,
    this.backupMessage,
    required this.themeMode,
    required this.onThemeModeChanged,
    this.appLockEnabled = false,
    this.appLockController,
    this.onAppLockChanged,
    this.onAbout,
    this.enableReminders,
  });
  final HolidayPackageService? holidayPackages;
  final VoidCallback? onHolidaysChanged;
  final AppSettings? settings;
  final BackupActions? backupActions;
  final String? backupMessage;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool appLockEnabled;
  final AppLockController? appLockController;
  final Future<void> Function(bool enabled)? onAppLockChanged;
  final VoidCallback? onAbout;
  final Future<bool> Function()? enableReminders;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _themeMode = widget.themeMode;

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode) _themeMode = widget.themeMode;
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('عمومی', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.brightness_6_outlined),
              title: Text('حالت نمایش'),
              subtitle: Text('انتخاب حالت روشن، تاریک یا هماهنگ با دستگاه'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('دستگاه'),
                    icon: Icon(Icons.settings_brightness_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('روشن'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('تاریک'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {_themeMode},
                onSelectionChanged: (selection) => _change(selection.first),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text('امنیت', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      AppLockSettingsCard(
        enabled: widget.appLockEnabled,
        change: widget.onAppLockChanged,
      ),
      const SizedBox(height: 20),
      if (widget.enableReminders != null)
        ReminderPermissionsCard(enable: widget.enableReminders!),
      Text('درباره', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('درباره پلن‌اکت'),
          subtitle: const Text('نسخه، build و اطلاعات محلی برنامه'),
          trailing: const Icon(Icons.chevron_left),
          onTap: widget.onAbout,
        ),
      ),
    ],
  );

  void _change(ThemeMode? value) {
    if (value == null) return;
    setState(() => _themeMode = value);
    widget.onThemeModeChanged(value);
  }
}
