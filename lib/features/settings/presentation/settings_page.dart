import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:flutter/material.dart';
import 'package:planact/features/settings/presentation/money_unit_settings_card.dart';
import 'package:planact/features/reminders/presentation/reminder_permissions_card.dart';
import 'package:planact/features/backup/application/backup_actions.dart';
import 'package:planact/app/app_lock.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/features/settings/presentation/app_lock_settings_card.dart';
import 'package:planact/features/settings/presentation/background_settings_card.dart';

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
    this.showArchivedAccounts = false,
    this.onShowArchivedAccountsChanged,
    this.background = AppBackground.none,
    this.onBackgroundChanged,
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
  final bool showArchivedAccounts;
  final Future<void> Function(bool enabled)? onShowArchivedAccountsChanged;
  final AppBackground background;
  final Future<void> Function(AppBackground background)? onBackgroundChanged;
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
  late bool _showArchivedAccounts = widget.showArchivedAccounts;
  bool _savingAccounts = false;
  bool _accountsSaveFailed = false;

  Future<void> _changeArchivedAccounts(bool enabled) async {
    if (_savingAccounts) return;
    setState(() {
      _savingAccounts = true;
      _accountsSaveFailed = false;
    });
    try {
      await widget.onShowArchivedAccountsChanged!(enabled);
      if (mounted) setState(() => _showArchivedAccounts = enabled);
    } catch (_) {
      if (mounted) setState(() => _accountsSaveFailed = true);
    } finally {
      if (mounted) setState(() => _savingAccounts = false);
    }
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode) _themeMode = widget.themeMode;
    if (oldWidget.showArchivedAccounts != widget.showArchivedAccounts) {
      _showArchivedAccounts = widget.showArchivedAccounts;
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const MoneyUnitSettingsCard(),
      Text(
        planActL10n(context).commonGeneral,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.brightness_6_outlined),
              title: Text(planActL10n(context).settingsAppearance),
              subtitle: Text(
                planActL10n(context).settingsAppearanceDescription,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(planActL10n(context).settingsThemeSystem),
                    icon: Icon(Icons.settings_brightness_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(planActL10n(context).settingsThemeLight),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(planActL10n(context).settingsThemeDark),
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
      if (widget.onBackgroundChanged != null) ...[
        const SizedBox(height: 12),
        BackgroundSettingsCard(
          value: widget.background,
          onChanged: widget.onBackgroundChanged!,
        ),
      ],
      if (widget.onShowArchivedAccountsChanged != null) ...[
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.inventory_2_outlined),
            title: Text(planActL10n(context).financeShowArchivedAccounts),
            subtitle: Text(
              planActL10n(context).financeShowArchivedAccountsDescription,
            ),
            value: _showArchivedAccounts,
            onChanged: _savingAccounts ? null : _changeArchivedAccounts,
          ),
        ),
        if (_savingAccounts) const LinearProgressIndicator(),
        if (_accountsSaveFailed)
          Text(
            planActL10n(context).financeArchivedAccountsSaveError,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
      const SizedBox(height: 20),
      Text(
        planActL10n(context).settingsSecurity,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      AppLockSettingsCard(
        enabled: widget.appLockEnabled,
        change: widget.onAppLockChanged,
      ),
      const SizedBox(height: 20),
      if (widget.enableReminders != null)
        ReminderPermissionsCard(enable: widget.enableReminders!),
      Text(
        planActL10n(context).settingsAbout,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(planActL10n(context).settingsAboutApp),
          subtitle: Text(planActL10n(context).settingsPageBuildSubtitle),
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
