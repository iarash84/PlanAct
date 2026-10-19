import 'package:flutter/material.dart';
import 'package:planact/core/money/iranian_money_unit.dart';
import 'package:planact/core/database/app_database.dart';

enum AppBackground { none, botanicalPaper, persianWaves, nightWaves }

extension AppBackgroundAsset on AppBackground {
  String? get assetPath => switch (this) {
    AppBackground.none => null,
    AppBackground.botanicalPaper => 'assets/backgrounds/botanical-paper.png',
    AppBackground.persianWaves => 'assets/backgrounds/persian-waves.png',
    AppBackground.nightWaves => 'assets/backgrounds/night-waves.png',
  };

  String get storageValue => switch (this) {
    AppBackground.none => 'none',
    AppBackground.botanicalPaper => 'botanical_paper',
    AppBackground.persianWaves => 'persian_waves',
    AppBackground.nightWaves => 'night_waves',
  };

  static AppBackground fromStorageValue(String? value) => switch (value) {
    'botanical_paper' => AppBackground.botanicalPaper,
    'persian_waves' => AppBackground.persianWaves,
    'night_waves' => AppBackground.nightWaves,
    _ => AppBackground.none,
  };
}

class AppSettings {
  AppSettings(this.database);
  final AppDatabase database;
  static const _themeKey = 'theme_mode';
  static const _appLockKey = 'app_lock_enabled';
  static const _backgroundKey = 'app_background_v1';

  Future<IranianMoneyUnit> readMoneyUnit() async =>
      await database.readMetadata('iranian_money_unit_v1') == 'toman'
      ? IranianMoneyUnit.toman
      : IranianMoneyUnit.rial;

  Future<void> writeMoneyUnit(IranianMoneyUnit unit) =>
      database.writeMetadata('iranian_money_unit_v1', unit.name);

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

  Future<AppBackground> readBackground() async =>
      AppBackgroundAsset.fromStorageValue(
        await database.readMetadata(_backgroundKey),
      );

  Future<void> writeBackground(AppBackground background) =>
      database.writeMetadata(_backgroundKey, background.storageValue);

  Future<bool> readAppLockEnabled() async =>
      (await database.readMetadata(_appLockKey)) == 'true';

  Future<void> writeAppLockEnabled(bool enabled) =>
      database.writeMetadata(_appLockKey, enabled.toString());
}
