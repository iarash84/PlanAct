import 'package:flutter/material.dart';
import 'package:planact/core/database/app_database.dart';

class AppSettings {
  AppSettings(this.database);
  final AppDatabase database;
  static const _themeKey = 'theme_mode';
  static const _appLockKey = 'app_lock_enabled';

  Future<ThemeMode> readThemeMode() async {
    final value = await database.readMetadata(_themeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> writeThemeMode(ThemeMode mode) =>
      database.writeMetadata(_themeKey, switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      });

  Future<bool> readAppLockEnabled() async =>
      (await database.readMetadata(_appLockKey)) == 'true';

  Future<void> writeAppLockEnabled(bool enabled) =>
      database.writeMetadata(_appLockKey, enabled.toString());
}
