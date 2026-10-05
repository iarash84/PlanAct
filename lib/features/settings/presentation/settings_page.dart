import 'package:flutter/material.dart';
import 'package:planact/features/reminders/presentation/reminder_permissions_card.dart';
import 'package:planact/features/backup/application/backup_actions.dart';
import 'package:planact/features/backup/presentation/backup_settings_card.dart';
import 'package:planact/app/app_lock.dart';
import 'package:planact/app/app_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
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
                selected: {themeMode},
                onSelectionChanged: (selection) => _change(selection.first),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text('امنیت', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Card(
        child: SwitchListTile.adaptive(
          secondary: const Icon(Icons.lock_outline),
          title: const Text('قفل برنامه'),
          subtitle: const Text(
            'هنگام بازگشت از پس‌زمینه، احراز هویت دستگاه را درخواست می‌کند.',
          ),
          value: appLockEnabled,
          onChanged: onAppLockChanged == null
              ? null
              : (enabled) async {
                  if (!enabled) {
                    await onAppLockChanged!(false);
                    return;
                  }
                  final controller = appLockController;
                  if (controller == null ||
                      await controller.authenticator.isAvailable()) {
                    await onAppLockChanged!(true);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('احراز هویت دستگاه در دسترس نیست.'),
                      ),
                    );
                  }
                },
        ),
      ),
      const SizedBox(height: 20),
      if (enableReminders != null)
        ReminderPermissionsCard(enable: enableReminders!),
      if (backupActions != null)
        BackupSettingsCard(actions: backupActions!, message: backupMessage),
      Text('درباره', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('درباره پلن‌اکت'),
          subtitle: const Text('نسخه، build و اطلاعات محلی برنامه'),
          trailing: const Icon(Icons.chevron_left),
          onTap: onAbout,
        ),
      ),
    ],
  );

  void _change(ThemeMode? value) {
    if (value != null) onThemeModeChanged(value);
  }
}
