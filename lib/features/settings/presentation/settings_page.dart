import 'package:flutter/material.dart';
import 'package:planact/app/app_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    this.settings,
    required this.themeMode,
    required this.onThemeModeChanged,
  });
  final AppSettings? settings;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('تنظیمات عمومی', style: Theme.of(context).textTheme.titleLarge),
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
    ],
  );

  void _change(ThemeMode? value) {
    if (value != null) onThemeModeChanged(value);
  }
}
